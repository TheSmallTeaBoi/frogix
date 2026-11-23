// surplus-provider.ts — Surplus Intelligence provider for pi (frogix).
//
// Registers surplus as an openai-completions endpoint and discovers the
// catalog live from /v1/models on every pi refresh, so new marketplace
// models and price changes appear without touching this repo. The static
// `models` entry below is only the offline/bootstrap fallback that keeps
// frogix's default model (glm-5.3-flash) resolvable before a refresh.
//
// Prices are key-scoped. The /api/markets summary is the public order
// book, but a key's scope decides which providers a request can actually
// route to: a `providers` allow-list, a `providers_blocked` deny-list,
// and a trusted-only provider preference. The extension identifies the
// calling key via /v1/keys (the listing never returns secrets, but it
// does return each key's secret prefix) and /v1/providers (provider id
// -> host), filters each model's provider rows through that scope, and
// recomputes best prices from the surviving rows — so /model shows what
// THIS key would really pay, not market-best prices from providers the
// key refuses. Concretely: Hermes blocks dashscope.aliyuncs.com and
// dashscope is the cheapest seller for many qwen/glm models, so an
// unscoped list would advertise prices this account can never get. If
// surplus ever enforces key scope server-side on the markets summary,
// this client-side filter simply becomes a no-op.
//
// Needs SURPLUS_API_KEY in the environment — frogix.pi.envFile sources the
// sops dotenv (hermes_env) before pi starts.

const API_BASE = "https://api.surplusintelligence.ai";
const BASE_URL = `${API_BASE}/v1`;

// blended ranking weights: coding turns are input-heavy (system prompt +
// accumulated context vs comparatively few output tokens), so cost is
// ranked as 90% input / 10% output; /models-by-price shows every raw rate
const IN_W = 0.9;
const OUT_W = 0.1;

// pi's openai-completions adapter sends the system prompt as role
// "developer" for any reasoning model on a "standard" (non-OpenAI-lookalike)
// endpoint — surplus's api host matches none of its special cases, so every
// reasoning model here gets `developer`. surplus is a marketplace router: the
// upstream seller varies per request, and the plain OpenAI-schema sellers
// reject that tag with 400 request_rejected / union_tag_invalid "Input tag
// 'developer' found using 'role'", which surfaced intermittently (same
// conversation worked or failed depending on who the router picked). pinning
// the role to "system" is the portable option: identical prompt, accepted by
// every seller.
const COMPAT = { supportsDeveloperRole: false };

// keep chat-shaped catalog entries only: pi chat models take text in and
// reply text. surplus also lists image/video/tts/music/embedding models and
// Decisions-API classifiers that would need pi implementations we do not
// provide, so they are filtered out here.
const isChat = (m) =>
  (m.architecture?.output_modalities ?? []).join(",") === "text" &&
  (m.architecture?.input_modalities ?? []).includes("text") &&
  !/decisions|^jev/.test(m.id);

// micro-USD per 1M tokens -> compact display dollars
const fmt = (micro) => {
  if (typeof micro !== "number") return "?";
  const v = micro / 1e6;
  if (v >= 100) return v.toFixed(0);
  if (v >= 1) return v.toFixed(2);
  if (v >= 0.01) return v.toFixed(3);
  return v > 0 ? v.toPrecision(2) : "0";
};

// a scope entry matches a provider by exact id, exact host, or — for bare
// families like "dashscope" — as a prefix of either, mirroring the
// "family or host" matching surplus's own router applies to these lists
const providerMatches = (entry, id, host) =>
  entry === id ||
  entry === host ||
  (!entry.includes(".") && (id.startsWith(entry) || host.startsWith(entry)));

const apiKey = process.env.SURPLUS_API_KEY ?? "";
const authHeaders = () => (apiKey ? { Authorization: `Bearer ${apiKey}` } : {});

// routing scope of the calling key, refreshed alongside the catalog.
// unset fields degrade to "no restriction", which is also the honest
// answer when /v1/keys is unavailable
let scopeState = { allow: null, block: [], trustedOnly: false, provIndex: new Map() };
let scopeAt = 0;
let marketCache = { at: 0, markets: [] };

async function fetchScope(signal) {
  const [keysRes, provRes] = await Promise.all([
    fetch(`${BASE_URL}/keys`, { headers: authHeaders(), signal }).catch(() => null),
    fetch(`${BASE_URL}/providers`, { signal }).catch(() => null),
  ]);
  if (!keysRes?.ok || !provRes?.ok) return;

  const provIndex = new Map();
  const provs = (await provRes.json().catch(() => null))?.data ?? [];
  for (const p of provs) provIndex.set(p.id, p);

  const body = await keysRes.json().catch(() => null);
  if (!body) return;
  // the keys listing wraps in {keys: [...]}
  const keys = Array.isArray(body) ? body : (body?.keys ?? body?.data ?? []);
  // recognize our own key by its longest non-empty secret prefix; fall through
  // to no scope when it cannot be identified (never guess between sibling keys)
  const self = apiKey
    ? keys
        .filter(
          (k) =>
            typeof k.key_prefix === "string" &&
            k.key_prefix.length > 0 &&
            apiKey.startsWith(k.key_prefix),
        )
        .sort((a, b) => b.key_prefix.length - a.key_prefix.length)[0] ?? null
    : null;
  const scope = self?.scope ?? {};

  scopeState = {
    allow: Array.isArray(scope.providers) ? scope.providers : null,
    block: Array.isArray(scope.providers_blocked) ? scope.providers_blocked : [],
    // observed provider_trust values: "default" (no constraint) and
    // "trusted" (route via trusted providers only); older keys used a
    // boolean scope.trusted_only
    trustedOnly:
      self?.provider_trust === "trusted" ||
      self?.provider_trust === "trusted_only" ||
      scope.trusted_only === true,
    provIndex,
  };
  scopeAt = Date.now();
}

async function fetchMarkets(signal) {
  const res = await fetch(`${API_BASE}/api/markets`, { headers: authHeaders(), signal });
  if (!res.ok) throw new Error(`surplus /api/markets: HTTP ${res.status}`);
  return (await res.json()).markets ?? [];
}

// best reachable price for one model as THIS key can route it: take the
// market summary's per-provider rows, drop providers the key's scope
// refuses, and keep the cheapest surviving rate per field. blended ranks
// 9:1 in:out; discount compares that against going direct at the same mix
function scopedBest(market) {
  const rows = (market?.providers ?? []).filter((row) => {
    const host = scopeState.provIndex.get(row.provider)?.host ?? "";
    if (scopeState.allow && !scopeState.allow.some((e) => providerMatches(e, row.provider, host)))
      return false;
    if (scopeState.block.some((e) => providerMatches(e, row.provider, host))) return false;
    if (scopeState.trustedOnly && row.trusted !== true) return false;
    return true;
  });
  const best = (field) => {
    const vals = rows.map((r) => r[field]).filter((v) => typeof v === "number");
    return vals.length ? Math.min(...vals) : null;
  };
  const input = best("best_input_per_1m");
  const output = best("best_output_per_1m");
  const blended = input != null && output != null ? IN_W * input + OUT_W * output : null;
  const dIn = market?.direct_input_per_1m;
  const dOut = market?.direct_output_per_1m;
  const direct =
    typeof dIn === "number" && typeof dOut === "number" ? IN_W * dIn + OUT_W * dOut : null;
  const discount =
    blended != null && direct ? Math.round((1 - blended / direct) * 100) : null;
  const sellers =
    rows.reduce((n, r) => n + (r.healthy_seller_count ?? 0), 0) || null;
  return {
    input,
    output,
    cacheRead: best("best_cache_read_per_1m"),
    cacheWrite: best("best_cache_write_per_1m"),
    blended,
    discount,
    sellers,
  };
}

const toPiModel = (m, market) => {
  const p = scopedBest(market);
  const routable = p.input != null && p.output != null;
  const disc =
    p.discount == null ? "" : ` ${p.discount < 0 ? "+" : "-"}${Math.abs(p.discount)}%`;
  const name = routable
    ? `${m.name ?? m.id} · $${fmt(p.blended)}/M bl${disc}`
    : `${m.name ?? m.id} · no reachable sellers`;
  return {
    type: "chat",
    id: m.id,
    name,
    reasoning:
      (m.supported_parameters ?? []).includes("reasoning") ||
      (m.supported_features ?? []).includes("reasoning"),
    // pi models declare text|image input; video-capable entries (glm-5v-*)
    // just lose the video modality
    input: (m.architecture?.input_modalities ?? []).filter((x) => x === "text" || x === "image"),
    contextWindow: m.context_length ?? 128000,
    maxTokens: m.top_provider?.max_completion_tokens ?? 16384,
    compat: COMPAT,
    // live key-scoped marketplace rates converted micro-USD/1M -> USD/1M;
    // the catalog list price (USD per token, ×1e6) only covers fields the
    // market summary lacked or whole models with no live seller rows
    cost: {
      input: (p.input != null ? p.input / 1e6 : Number(m.pricing?.prompt ?? 0) * 1e6),
      output: (p.output != null ? p.output / 1e6 : Number(m.pricing?.completion ?? 0) * 1e6),
      cacheRead: (p.cacheRead != null ? p.cacheRead / 1e6 : Number(m.pricing?.input_cache_read ?? 0) * 1e6),
      cacheWrite: (p.cacheWrite != null ? p.cacheWrite / 1e6 : Number(m.pricing?.input_cache_write ?? 0) * 1e6),
    },
  };
};

export default function (pi) {
  // surplus bills the marketplace-discounted rate, not the catalog's list
  // price, so the model `cost` rates below overstate every request badly (this
  // account pays single-digit percentages of list on its main models). each
  // response reports the real charge in usage.buyer_cost_micro (integer
  // micro-USD — "what you were charged"); usage.cost carries the upstream cost.
  // pi's openai-completions path only honours a provider-reported cost for
  // OpenRouter-shaped providers, so read the raw stream event and overwrite the
  // finalized assistant message's cost. the catalog rates stay as the fallback
  // when surplus omits the charge (buyer_cost_micro is absent for unknown
  // priced requests).
  let buyerCostUsd;

  pi.on("turn_start", () => {
    buyerCostUsd = undefined;
  });

  pi.on("provider_stream_event", (event) => {
    if (event.provider !== "surplus") return;
    const usage = (
      event.data as { usage?: { buyer_cost_micro?: unknown; cost?: unknown } } | undefined
    )?.usage;
    if (typeof usage?.buyer_cost_micro === "number" && Number.isFinite(usage.buyer_cost_micro)) {
      buyerCostUsd = usage.buyer_cost_micro / 1e6;
    } else if (typeof usage?.cost === "number" && Number.isFinite(usage.cost)) {
      buyerCostUsd = usage.cost;
    }
  });

  pi.on("message_end", (event) => {
    if (event.message.role !== "assistant" || event.message.provider !== "surplus") return;
    if (buyerCostUsd === undefined) return;
    const total = buyerCostUsd;
    buyerCostUsd = undefined;
    const prevUsage = event.message.usage ?? {};
    return {
      message: {
        ...event.message,
        usage: {
          ...prevUsage,
          cost: { ...(prevUsage.cost ?? {}), total, totalFromProvider: true },
        },
      },
    };
  });

  // ranked, price-first picker over the live key-scoped order book: the
  // native /model list cannot be re-sorted from an extension, so this
  // mirrors it with blended $/1M ascending and switches on selection
  pi.registerCommand("models-by-price", {
    description:
      "Surplus: pick a model by live key-scoped price (9:1 blended $/1M, cheapest first)",
    handler: async (_args, ctx) => {
      try {
        const timeout = AbortSignal.timeout(15_000);
        if (Date.now() - scopeAt > 600_000) await fetchScope(timeout);
        if (Date.now() - marketCache.at > 30_000)
          marketCache = { at: Date.now(), markets: await fetchMarkets(timeout) };
        const rows = marketCache.markets
          .map((mk) => ({ mk, p: scopedBest(mk) }))
          .filter((r) => r.p.blended != null)
          .sort((a, b) => a.p.blended - b.p.blended || a.mk.model.localeCompare(b.mk.model));
        if (!rows.length) {
          ctx.ui.notify("surplus: no routable models for this key right now", "error");
          return;
        }
        const labels = rows.map(
          (r) =>
            `$${fmt(r.p.blended)}/M bl · in $${fmt(r.p.input)} out $${fmt(r.p.output)} · ` +
            `${r.p.discount == null ? "?" : `${r.p.discount < 0 ? "+" : "-"}${Math.abs(r.p.discount)}%`} vs direct · ` +
            `${r.p.sellers ?? "?"} sellers · ${r.mk.model}`,
        );
        const pick = await ctx.ui.select(
          "surplus models — cheapest first · blended = 90% in + 10% out, your key's scope applied",
          labels,
        );
        if (!pick) return;
        const row = rows[labels.indexOf(pick)];
        const model = ctx.modelRegistry?.find("surplus", row.mk.model);
        if (!model) {
          ctx.ui.notify(`surplus: ${row.mk.model} is not in the live catalog`, "error");
          return;
        }
        const ok = await pi.setModel(model);
        ctx.ui.notify(
          ok ? `model: ${model.name ?? row.mk.model}` : "no API key configured for surplus",
          ok ? "info" : "error",
        );
      } catch (e) {
        ctx.ui.notify(`models-by-price: ${e?.message ?? e}`, "error");
      }
    },
  });

  pi.registerProvider("surplus", {
    name: "Surplus Intelligence",
    baseUrl: BASE_URL,
    apiKey: "$SURPLUS_API_KEY",
    api: "openai-completions",
    models: [
      {
        type: "chat",
        id: "deepseek-v4.1-flash",
        name: "DeepSeek V4.1 Flash",
        reasoning: true,
        input: ["text"],
        contextWindow: 131072,
        maxTokens: 65536,
        compat: COMPAT,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      },
      {
        type: "chat",
        id: "glm-5.3-flash",
        name: "GLM 5.3 Flash",
        reasoning: true,
        input: ["text", "image"],
        contextWindow: 1048576,
        maxTokens: 131072,
        compat: COMPAT,
        cost: { input: 0.0399, output: 0.0784, cacheRead: 0.03, cacheWrite: 0.0399 },
      },
    ],
    refreshModels: async (context) => {
      const signal = context?.signal;
      const [catRes] = await Promise.all([
        fetch(`${BASE_URL}/models`, { headers: authHeaders(), signal }),
        fetchScope(signal).catch(() => {}),
        fetchMarkets(signal)
          .then((markets) => {
            marketCache = { at: Date.now(), markets };
          })
          .catch(() => {}),
      ]);
      if (!catRes.ok) throw new Error(`surplus /v1/models: HTTP ${catRes.status}`);
      const byId = new Map(marketCache.markets.map((mk) => [mk.model, mk]));
      const catalog = (await catRes.json()).data ?? [];
      return catalog.filter(isChat).map((m) => toPiModel(m, byId.get(m.id)));
    },
  });
}

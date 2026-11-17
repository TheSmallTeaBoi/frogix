// surplus-provider.ts — Surplus Intelligence provider for pi (frogix).
//
// Registers surplus as an openai-completions endpoint and discovers the
// catalog live from /v1/models on every pi refresh, so new marketplace
// models and price changes appear without touching this repo. The static
// `models` entry below is only the offline/bootstrap fallback that keeps
// frogix's default model (glm-5.3-flash) resolvable before a refresh.
//
// Needs SURPLUS_API_KEY in the environment — frogix.pi.envFile sources the
// sops dotenv (hermes_env) before pi starts.

const BASE_URL = "https://api.surplusintelligence.ai/v1";

// keep chat-shaped catalog entries only: pi chat models take text in and
// reply text. surplus also lists image/video/tts/music/embedding models and
// Decisions-API classifiers that would need pi implementations we do not
// provide, so they are filtered out here.
const isChat = (m) =>
  (m.architecture?.output_modalities ?? []).join(",") === "text" &&
  (m.architecture?.input_modalities ?? []).includes("text") &&
  !/decisions|^jev/.test(m.id);

const toPiModel = (m) => ({
  type: "chat",
  id: m.id,
  name: m.name ?? m.id,
  reasoning:
    (m.supported_parameters ?? []).includes("reasoning") ||
    (m.supported_features ?? []).includes("reasoning"),
  // pi models declare text|image input; video-capable entries (glm-5v-*)
  // just lose the video modality
  input: (m.architecture?.input_modalities ?? []).filter((x) => x === "text" || x === "image"),
  contextWindow: m.context_length ?? 128000,
  maxTokens: m.top_provider?.max_completion_tokens ?? 16384,
  // catalog prices are USD per token; pi wants USD per million tokens
  cost: {
    input: Number(m.pricing?.prompt ?? 0) * 1e6,
    output: Number(m.pricing?.completion ?? 0) * 1e6,
    cacheRead: Number(m.pricing?.input_cache_read ?? 0) * 1e6,
    cacheWrite: Number(m.pricing?.input_cache_write ?? 0) * 1e6,
  },
});

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

  pi.on("provider_stream_event", (event) => {
    if (event.provider !== "surplus") return;
    const usage = (
      event.data as { usage?: { buyer_cost_micro?: unknown; cost?: unknown } } | undefined
    )?.usage;
    if (typeof usage?.buyer_cost_micro === "number") {
      buyerCostUsd = usage.buyer_cost_micro / 1e6;
    } else if (typeof usage?.cost === "number") {
      buyerCostUsd = usage.cost;
    }
  });

  pi.on("message_end", (event) => {
    if (event.message.role !== "assistant" || event.message.provider !== "surplus") return;
    if (buyerCostUsd === undefined) return;
    const total = buyerCostUsd;
    buyerCostUsd = undefined;
    return {
      message: {
        ...event.message,
        usage: {
          ...event.message.usage,
          cost: { ...event.message.usage.cost, total, totalFromProvider: true },
        },
      },
    };
  });

  pi.registerProvider("surplus", {
    name: "Surplus Intelligence",
    baseUrl: BASE_URL,
    apiKey: "$SURPLUS_API_KEY",
    api: "openai-completions",
    models: [
      {
        type: "chat",
        id: "glm-5.3-flash",
        name: "GLM 5.3 Flash",
        reasoning: true,
        input: ["text", "image"],
        contextWindow: 1048576,
        maxTokens: 131072,
        cost: { input: 0.0399, output: 0.0784, cacheRead: 0.03, cacheWrite: 0.0399 },
      },
    ],
    refreshModels: async (context) => {
      const res = await fetch(`${BASE_URL}/models`, { signal: context?.signal });
      if (!res.ok) throw new Error(`surplus /v1/models: HTTP ${res.status}`);
      const body = await res.json();
      return (body.data ?? []).filter(isChat).map(toPiModel);
    },
  });
}

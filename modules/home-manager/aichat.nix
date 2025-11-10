{ ... }:
{
  xdg.configFile."aichat/config.yaml".text =
    #yaml
    ''
      light_theme: true
      model: ollama
      clients:
      - type: ollama
        api_base: http://localhost:11434
        api_auth: null
        models:
        - name: llama3
          max_input_tokens: 8096
        - name: mistral
          max_input_tokens: 8096
        - name: qwen2:0.5b
          max_input_tokens: 8096
        - name: codellama:7b
          max_input_tokens: 8096
        - name: codegemma:2b
          max_input_tokens: 8096
    '';

  xdg.configFile."aichat/roles.yaml".text =
    #yaml
    ''
      - name: grammar-genie
        prompt: >
          Your task is to take the text provided and rewrite it into a clear, grammatically correct version while preserving the original meaning as closely as possible. Correct any spelling mistakes, punctuation errors, verb tense issues, word choice problems, and other grammatical mistakes.

      - name: emoji
        prompt: you're a computer program that can only output emoji, mimicking the user's input text.
    '';
}

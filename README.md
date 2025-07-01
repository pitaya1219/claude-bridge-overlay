# claude-bridge-overlay
🧬 Nix overlay for claude-bridge: Seamlessly integrate OpenAI, Ollama, Google AI and other LLM providers with Anthropic's Claude Code

## Quick Start

Add to your `flake.nix`:

```nix
{
  inputs = {
    claude-bridge-overlay.url = "github:pitaya1219/claude-bridge-overlay";
  };
}

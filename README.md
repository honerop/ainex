# Ainex

A general-purpose AI client implemented in [Ain](https://github.com/honerop/ain), with a **native GTK4 desktop interface** for NixOS and other Linux systems. The GUI is not a browser app, webview, or Electron shell.

The Ain entry point is [`main.ain`](main.ain). Ain's experimental `desktop` builtin implements the native GTK4 window and provider adapters in its Rust code-generation runtime. This is an initial desktop chat client, not yet a fully autonomous tool-using agent.

## Run on NixOS

```sh
nix run github:honerop/ainex
```

Or use a development checkout:

```sh
git clone https://github.com/honerop/ainex.git
cd ainex
nix develop
ainc check main.ain
ainc run main.ain
```

The flake pins an Ain revision containing the native GTK4 desktop builtin, installs GTK4 build dependencies, and includes curl, jq, and Codex when available in nixpkgs.

## Providers

### ChatGPT via the official Codex CLI

```sh
codex login
nix run .
```

Choose **ChatGPT / Codex**. This uses the authenticated Codex CLI (subject to subscription entitlements and limits), not an unofficial ChatGPT API. A ChatGPT Plus subscription is not an OpenAI API token. Ainex does not read Codex's credential files. Codex operates in read-only mode in this version.

If the Nix environment lacks a `codex` binary, install the official Codex CLI and ensure it is on your PATH.

### DeepInfra

```sh
export DEEPINFRA_API_KEY="YOUR_DEEPINFRA_TOKEN"
nix run .
```

Choose **DeepInfra** and optionally enter the exact model identifier. The default is `deepseek-ai/DeepSeek-V4-Flash-0731`. DeepInfra's OpenAI-compatible chat-completions endpoint is used. Never commit credentials.

## Vim-style navigation

| Key | Action |
| --- | --- |
| `i` | Focus composer / insert mode |
| `Esc` | Normal mode |
| `j` / `k` | Scroll conversation |
| `gg` / `G` | Jump to top / bottom |
| `:` | Start a command |
| `Enter` | Send a message or run a command |
| `:help` | Show shortcuts |
| `:clear` | Clear on-screen history |
| `:deepinfra` / `:chatgpt` | Switch provider |
| `:model MODEL` | Set model |

## Limitations

- Linux-only native GTK4 GUI, with NixOS packaging.
- Single-line composer and plain-text replies.
- Conversations are kept in memory in the UI; requests do **not** retain model history yet.
- Ain's LLVM backend does not currently implement the desktop builtin; use the Rust backend.
- No arbitrary command execution, browser control, or persistent agent tasks yet.

License: MIT.

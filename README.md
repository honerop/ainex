# Ainex

Ainex is an experimental, general-purpose AI assistant with a **native GTK4 window** and browser tools. The entry point is written in [Ain](https://github.com/honerop/ain), a general-purpose language designed exclusively for AI-generated source code. GTK, model provider integrations, and the isolated browser runner live in Ainex, not inside the Ain compiler.

This is a desktop application, **not** an Electron app or a browser UI. Browser actions are explicit commands for now; the model does not autonomously click or submit forms.

## NixOS

```sh
nix run github:honerop/ainex
```

For development:

```sh
git clone https://github.com/honerop/ainex.git
cd ainex
nix develop
nix run .
```

The Nix flake compiles the Ain entry point and native GTK4 executable and provides Playwright, Chromium, curl, and jq.

## Browser usage

In the native window press **i**, then type one of these commands:

| Command | Purpose |
| --- | --- |
| `:browse https://example.com` | Open a public site in isolated Chromium and read its text |
| `:page` | Read the current page |
| `:links` | List the page's links |
| `:click CSS_SELECTOR` | Click the first matching element |
| `:fill CSS_SELECTOR \| value` | Fill the first matching field |
| `:back` | Navigate back |
| `:screenshot name.png` | Save a PNG in the XDG cache directory |
| `:ask QUESTION` | Ask the selected model about the most recently read page |

The Playwright session has an ephemeral browser profile, blocks downloads and local/private URLs, and does not reuse personal browser cookies. It defaults to headless mode; set `AINEX_BROWSER_HEADLESS=0` to see the controlled Chromium window.

**Safety:** browser pages are untrusted. Extracted page text is only shared with the chosen AI model when using `:ask`; the browser never acts on model-generated instructions automatically. This version is intended for public sites rather than authenticated accounts.

## Providers

**ChatGPT / Codex:** Install the official Codex CLI, run `codex login`, and choose **ChatGPT / Codex**. It uses Codex's official ChatGPT login and plan entitlements, not an unofficial subscription API. Codex runs read-only here. A ChatGPT Plus subscription is not an OpenAI API key.

**DeepInfra:** Set `DEEPINFRA_API_KEY` before launch, then choose **DeepInfra**. The default model is `zai-org/GLM-5.3-Flash`, or enter another available model ID in the window.

Credentials are never stored in the Ainex repository. Provider credentials and live API behavior need user-side validation.

## Keyboard commands

`i` inserts, `Esc` goes to normal mode, `j`/`k` scroll, `gg`/`G` jump to top/bottom, `:` starts a command, and `Enter` sends. Other commands: `:help`, `:clear`, `:deepinfra`, `:chatgpt`, and `:model MODEL`.

## Architecture

```text
main.ain --Ain run--> ainex-host (GTK4 window)
                             |-- official Codex CLI
                             |-- DeepInfra chat-completions
                             +-- browser/driver.py -> Chromium (Playwright)
```

Ain's `run` primitive is generic, rather than teaching the compiler about GTK4, providers, or browsers. App-specific integration stays in Ainex.

## Current limitations

- Native GTK4 desktop on Linux/NixOS only
- Plain-text replies and a single-line composer; the last twelve exchanges are remembered in RAM, not saved to disk
- Browser sessions are temporary and actions require explicit user input
- No autonomous agent tool loop yet
- CI verifies compiler, packaging, and local tests, but does not authenticate with live model providers

MIT licensed.

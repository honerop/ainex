# Ainex

Ainex is a **general-purpose native GTK4 desktop assistant written entirely in [Ain](https://github.com/honerop/ain)**. Every part of the application behavior lives in [`main.ain`](main.ain): native GUI layout, navigation, chat/provider choices, and browser commands.

**No Rust, Python, JavaScript or other application source code exists in this repository.** Ain's compiler and reusable standard runtime are responsible for translating Ain to native code and providing GTK4 widgets, HTTP/AI support and isolated Playwright Chromium automation. Nix is only used for packaging and dependencies.

Ain is a general-purpose programming language designed **exclusively for AI-generated code**, with a deliberately extensive built-in library.

## Run on NixOS

```sh
nix run github:honerop/ainex
```

For development:

```sh
git clone https://github.com/honerop/ainex.git
cd ainex
nix develop
ainc run main.ain
```

## Native GUI in Ain

The graphical interface is built using Ain's general `gui title layout` operation, which constructs a real GTK4 window and returns keyboard/button events to the Ain program.

```text
layout = "header\\tAinex\\nentry\\tmessage\\tMessage\\nbutton\\tsend\\tSend\\nvim\\t1\\n"
print gui "Ainex" layout
```

An Ain program can define and render windows, read typed messages, handle events, switch providers, and update the interface without introducing a second programming language.

## Browser commands

Inside the native window, press **i** to type:

| Command | Behavior |
| --- | --- |
| `:browse https://example.com` | Open a public HTTP(S) page in isolated Chromium |
| `:page` | Read the current page |
| `:links` | List its links |
| `:click CSS_SELECTOR` | Click the first matching element |
| `:fill CSS_SELECTOR\|value` | Fill a field |
| `:back` | Go back |
| `:screenshot name.png` | Save a screenshot under your XDG cache directory |
| `:ask QUESTION` | Ask the selected model about the current page |

Browser operations are implemented by Ain's general `browser operation argument` builtin. Each action must be requested by the user. Ainex does **not** allow the model to autonomously browse, log in or submit forms.

## Model providers

**ChatGPT Plus:** Install the official Codex CLI and authenticate with `codex login`. Select **ChatGPT** in the GTK4 window (or enter `:chatgpt`). This uses Codex's supported ChatGPT authentication rather than unofficial API access. ChatGPT Plus does not include an OpenAI API key.

**DeepInfra:** Export `DEEPINFRA_API_KEY`, then select **DeepInfra** or type `:deepinfra`. By default Ain uses `zai-org/GLM-5.3-Flash`; use `:model IDENTIFIER` to change it. Tokens stay outside the repository.

The Ain built-in operation is `chat provider model prompt`, reusable in other Ain programs.

## Vim-style navigation

`i` inserts; `Esc` returns to normal mode; `j`/`k` scroll; `gg`/`G` move to top/bottom; `:` starts a command; `Enter` sends. Type `:help` for the full command list.

## Current limitations

- Only Linux/NixOS GTK4 is supported.
- The UI is synchronous and currently single-line; API requests temporarily block its event loop.
- Conversation history exists only while the process runs and is not persisted.
- Browser automation is explicit, not model-directed autonomous tool use.
- Provider logins and live model responses have not been tested with personal credentials.
- GUI, browser and chat builtins are currently supported through Ain's Rust code-generation backend, not its LLVM or self-hosted C backend. **The Ainex application itself does not contain Rust.**

MIT license.

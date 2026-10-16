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

## OpenBot Free via OpenCode

Select **OpenBot Free** in the Ainex window, or enter `:openbot`. This selects
Ain's OpenCode CLI adapter and defaults to
`opencode/mimo-v2.6-flash-free` when the model field is blank.

OpenBot itself is a separate, local-first multi-agent desktop workspace.
**Ainex does not run or embed the OpenBot desktop application.** It connects
to the OpenCode free-model CLI, which is also an engine supported by OpenBot.
The free offering may impose rate limits or change its model catalog. Live
provider access requires an installed and functioning OpenCode CLI; provider
availability is not guaranteed by offline CI.

Ain's native runtime runs the OpenCode CLI as an explicit argument-vector
process, defaults to the plan agent, reads JSONL `text` events, and produces
a plain assistant response. The OpenCode binary is packaged where available
in nixpkgs. This is a chat integration, not automatic unrestricted execution.

## Explicit agent and workspace commands

Ainex adds local desktop features inspired by OpenBot and Grok Bot. Every
filesystem or process action is initiated by a user command and does **not**
give the model blanket permission to execute commands.

| Command | Meaning |
| --- | --- |
| `:openbot` / `:opencode` | Select the free OpenCode model provider |
| `:files PATH` | List directory entries in sorted order |
| `:read PATH` | Show an existing UTF-8 file |
| `:save PATH` | Save the current chat transcript to an explicit path |
| `:load PATH` | Restore a text transcript from a file |
| `:cwd` | Show the process working directory |
| `:exec {"program":"git","args":["status","--short"]}` | Run a user-supplied program without a shell, returning exit code and bounded stdout/stderr |
| `:agent ROLE|TASK` | Give a one-shot role-specific task to the selected provider |

The saved session is a text transcript, not a native OpenCode/Codex session.
It is not automatically synchronized or encrypted. A subprocess runs with
your normal OS account permissions; **only run commands you trust**. Ainex
does not automatically approve model-proposed changes or execute model text.

These commands are a first step toward richer agent workspaces. Independent
persistent agent identities, multi-agent delegation, durable task queues,
embedded collaborative channels, remote phone access and per-tool consent
prompts are still unfinished.

## Vim-style navigation

`i` inserts; `Esc` returns to normal mode; `j`/`k` scroll; `gg`/`G` move to top/bottom; `:` starts a command; `Enter` sends. Type `:help` for the full command list.

## Current limitations

- Only Linux/NixOS GTK4 is supported.
- The native GTK4 GUI continues processing input during model generation through Ain background tasks; the composer is still single-line.
- Browser commands remain synchronous and can temporarily block the window.
- Conversation history remains in memory unless you explicitly save it with `:save PATH`; use `:load PATH` to restore a text transcript.
- Browser automation is explicit, not model-directed autonomous tool use.
- Provider logins and live model responses have not been tested with personal credentials.
- GUI, browser and chat builtins are currently supported through Ain's Rust code-generation backend, not its LLVM or self-hosted C backend. **The Ainex application itself does not contain Rust.**

MIT license.

## Responsive AI generation

Ainex launches model requests using Ain's `spawn` builtin and a named Ain
function returning `Data`. While the request executes, `guitick 50` pumps the
native GTK4 event loop without destroying the input widget, and `guiupdate`
repaints the result when it arrives. No Rust or Python application source is
required. The browser integration is still synchronous; fully autonomous
agent actions remain unimplemented.

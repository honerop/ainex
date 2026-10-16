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

## OpenCode Free model provider

Select **OpenCode Free** in the GTK4 window, or type `:opencode`. The
backend is the installed OpenCode CLI using
`opencode/mimo-v2.6-flash-free` by default. This is a provider option,
not an OpenBot integration. Free-model availability and limits depend on
OpenCode's current offering; account access and live responses aren't verified
in CI.

The native Ain runtime invokes the OpenCode CLI directly using argument arrays
and parses JSONL text events. Ainex includes the CLI in its Nix closure when
available in the selected nixpkgs revision.

## Agent-workspace features inspired by OpenBot and Grok Bot

The design references are
[OpenBot](https://github.com/nightly-labs/openbot) and
[Grok Bot](https://github.com/grok-bot-app/grok-bot).
Both are agent workspaces, not the model used by OpenCode Free.

Ainex now supports **named, persistent local agent profiles**. Each agent
keeps its instructions, selected provider, model, and chat history. Switching
agents reloads that profile, and finished model replies update its history.
Profiles live in `~/.local/share/ainex/agents.json`; they remain on the
local computer, not in Ainex's repository or a hosted Ainex account.

| Command | Meaning |
| --- | --- |
| `:agent-new NAME|ROLE` | Create/select an agent with role instructions and the current provider/model |
| `:agents` | List agent names |
| `:agent-use NAME` | Switch to the agent's stored provider, model and conversation |
| `:agent-info` | Display the selected agent's saved profile |
| `:task-add TASK` | Enqueue an instruction for the currently selected agent |
| `:tasks` | Show the agent's saved FIFO queue and next-task position |
| `:task-next` | Manually start the next pending task; advance only after a successful model reply |
| `:agent ROLE|TASK` | One-off specialized role prompt, without creating a profile |
| `:opencode` | Switch to the OpenCode Free backend |
| `:files PATH` | List directory entries |
| `:read PATH` | Read a UTF-8 file |
| `:save PATH` / `:load PATH` | Save or restore a plain-text transcript |
| `:cwd` | Show the working directory |
| `:exec {"program":"git","args":["status","--short"]}` | Run an explicitly requested command with bounded output, without a shell |
| `:review PATH` | Ask the selected model to review a file |
| `:plan TASK` | Ask the selected model for a plan without executing it |

All local tool invocations are initiated by explicit user commands. The model
does not automatically approve, plan-and-execute, or run arbitrary returned
commands. Agent names cannot contain path separators or parent-directory
components. The agent database is **plaintext and not encrypted**. Running
Ainex grants its process normal OS file access; use OS sandboxing and restrict
access to sensitive directories if you run untrusted tasks.

**Not implemented yet:** unattended/autonomous background task execution,
automatic multi-agent delegation, bot-to-bot messaging, remote cloud computers,
learn-by-demonstration routines, per-tool confirmation dialogs, durable browser
sessions, and task execution after the app closes. Ainex is not at full
OpenBot/Grok Bot feature parity. Agent workspaces currently share the process's
filesystem access; there is no per-agent OS sandbox.


### Queue execution semantics

The `:task-add` queue is stored in the selected agent's JSON profile under
`tasks`, with a persisted `next` index. `:task-next` runs exactly one
queued task with the agent's saved instructions/provider. If the provider
returns an error, the index is not advanced, so the next manual attempt
retries the same task. A successful model reply advances the cursor and
saves the conversation.

This is **local, manually driven FIFO task execution**, not an always-on
worker. Nothing continues after the Ainex process exits. The queue stores
prompt strings and simple completion progress, not arbitrary background
jobs, timers, inter-agent messages, delivery schedules or audit logs.

## Vim-style navigation

`i` inserts; `Esc` returns to normal mode; `j`/`k` scroll; `gg`/`G` move to top/bottom; `:` starts a command; `Enter` sends. Type `:help` for the full command list.

## Current limitations

- Only Linux/NixOS GTK4 is supported.
- The native GTK4 GUI continues processing input during model generation through Ain background tasks; the composer is still single-line.
- Browser commands remain synchronous and can temporarily block the window.
- Named agents persist their histories locally in `agents.json`; conversations without a named agent remain in memory unless saved explicitly.
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

# Ainex

Ainex is a **general-purpose native GTK4 desktop and terminal assistant written entirely in [Ain](https://github.com/honerop/ain)**. Every part of the application behavior lives in [`main.ain`](main.ain): native GUI layout, navigation, chat/provider choices, and browser commands.

**No Rust, Python, JavaScript or other application source code exists in this repository.** Ain's compiler and reusable standard runtime are responsible for translating Ain to native code and providing GTK4 widgets, HTTP/AI support and isolated Playwright Chromium automation. Nix is only used for packaging and dependencies.

Ain is a general-purpose programming language designed **exclusively for AI-generated code**, with a deliberately extensive built-in library.

## Terminal interface

Ainex includes a separate native **`ainex-cli` executable**, built entirely from [`cli.ain`](cli.ain). The CLI does not require a GTK display.

```sh
# One-shot question
nix run github:honerop/ainex#cli -- "Explain monads"

# Interactive terminal conversation
nix run github:honerop/ainex#cli -- --interactive

# Switch provider or model
ainex-cli --provider opencode --model opencode/mimo-v2.6-flash-free -p "Hello"

# Read a named agent's role and history from your existing local agent store
ainex-cli --agent Teacher --interactive
```

Run `ainex-cli --help` for all flags. Inside interactive mode use `/help`, `/clear`, or `/quit`. The terminal client reads saved agents but does not overwrite GUI profile files; unsaved CLI history stays in the current process. The new reusable Ain builtins `argv _` and `readline _` allow terminal apps without Rust application code or GTK.

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

## Redesigned GTK interface

The conversation is no longer a single unstructured log. Ain's reusable native GUI renderer now supports a `conversation` container and individually styled `message<TAB>role<TAB>text` cards. User messages, agent responses, system notes, and **errors** render in distinct GTK panels. The cyan design uses responsive button rows and a dedicated message composer, all without Electron or web views.

## Native GUI in Ain

The graphical interface is built using Ain's general `gui title layout` operation, which constructs a real GTK4 window and returns keyboard/button events to the Ain program. Ainex opts into the runtime's cyan theme using `theme\tcyan` in the layout.

```text
layout = "header\\tAinex\\nentry\\tmessage\\tMessage\\nbutton\\tsend\\tSend\\nvim\\t1\\n"
print gui "Ainex" layout
```

An Ain program can define and render windows, read typed messages, handle events, switch providers, and update the interface without introducing a second programming language.

## Browser commands

The native window opens in **insert mode** with the composer focused. Type straight away. Press **Esc** to navigate the transcript; press **i** or click the entry to return to typing:

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

Browser operations are implemented by Ain's general `browser operation argument` builtin. Manual commands still work as before. **Named agents can now browse autonomously** within a strict whitelist, and `:web TASK` starts a browser-enabled agent without creating a profile. Browser inspection exposes visible links, fields, and buttons as numbered `@N` handles so agents can click or fill them without guessing CSS selectors.

### Autonomous browser agents

Select or create a named agent, then write an ordinary request:

```text
Find running shoes under $100 on Amazon. Compare three choices and leave checkout to me.
```

Or, without a named agent:

```text
:web Open https://www.amazon.com, search for USB-C hubs, and compare the best options.
```

The agent makes one model decision at a time (JSON action), executes an allowed Chromium action, reads the result, and repeats for **at most 20 actions**. It can open URLs, inspect visible controls, read pages, follow safe clicks, fill ordinary search/text fields, use back navigation, and report findings. `:task-next` uses the same browser agent loop for a named agent's next queued task, and only advances the queue when the model finishes with a `done` action.

**Approval boundary:** autonomous clicks are blocked for likely purchases, checkout/payment, sensitive fields, and non-GET form submissions. Browser shopping is meant for researching, comparing, and navigating toward a cart. To purchase, log in, enter card data, or submit an order, use the browser directly. A failed action stops the run, rather than letting the model invent a successful order. The filters are defense-in-depth, not a proof that arbitrary websites cannot implement misleading buttons or side effects.

Browser content is **untrusted** and agents are explicitly told not to obey instructions from webpages. The browser uses a separate Playwright Chromium context, not a personal Firefox/Chrome profile. It does not automatically share your site logins. This is interactive while Ainex remains open, not an unattended hosted browser or a background worker.

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
| `:task-next` | Manually start the next queued browser-enabled agent task; advance only after a completed run |
| `:agent ROLE|TASK` | One-off specialized role prompt, without creating a profile |
| `:opencode` | Switch to the OpenCode Free backend |
| `:files PATH` | List directory entries |
| `:read PATH` | Read a UTF-8 file |
| `:save PATH` / `:load PATH` | Save or restore a plain-text transcript |
| `:cwd` | Show the working directory |
| `:exec {"program":"git","args":["status","--short"]}` | Run an explicitly requested command with bounded output, without a shell |
| `:review PATH` | Ask the selected model to review a file |
| `:plan TASK` | Ask the selected model for a plan without executing it |

File reads, writes, and local process commands require explicit user commands. Browser-capable agents can plan and execute only the limited Chromium tools described above. The model cannot automatically run shell commands or read arbitrary files through the agent tool protocol. Agent names cannot contain path separators or parent-directory
components. The agent database is **plaintext and not encrypted**. Running
Ainex grants its process normal OS file access; use OS sandboxing and restrict
access to sensitive directories if you run untrusted tasks.

**Not implemented yet:** unattended/background task execution,
automatic multi-agent delegation, bot-to-bot messaging, remote cloud computers,
learn-by-demonstration routines, per-tool confirmation dialogs, durable browser
sessions, and task execution after the app closes. Ainex is not at full
OpenBot/Grok Bot feature parity. Agent workspaces currently share the process's
filesystem access; there is no per-agent OS sandbox.


### Queue execution semantics

The `:task-add` queue is stored in the selected agent's JSON profile under
`tasks`, with a persisted `next` index. `:task-next` runs one
queued task through the bounded browser agent loop. Provider errors, blocked actions,
and requests for manual input do not advance the cursor. Only an explicit
`done` response from the model advances the queue and saves the conversation.

This is **local, manually driven FIFO task execution**, not an always-on
worker. Nothing continues after the Ainex process exits. The queue stores
prompt strings and simple completion progress, not arbitrary background
jobs, timers, inter-agent messages, delivery schedules or audit logs.

## Vim-style navigation

Ainex starts in insert mode. In that mode **all characters**, including `i`, `j`, `k`, `g`, `G` and `:`, are ordinary input. `Esc` switches to normal mode; `i` or clicking the composer enters insert mode again. Only in normal mode do `j`/`k` scroll, `gg`/`G` jump to the ends, and `:` start a command. `Enter` sends a message.

The GTK4 interface uses a dark cyan workspace with a separate transcript panel, composer, send button, and a compact top toolbar. The toolbar has **native GTK4 drop-down selects** for the model provider (OpenCode Free, ChatGPT, DeepInfra) and the active saved agent, plus direct **Manage agents** and **Task queue** controls. The provider and agent menus send stable selection values to Ain; selecting a provider updates that agent's saved provider and resets its model override. Selecting **No agent** returns to the unsaved general workspace. **Clear conversation** and **Exit** remain below the composer. The app remains written in Ain; the reusable `select` control and toolbar rendering live in the Ain runtime.

Use `:model ID` for custom model identifiers; the provider drop-down chooses a backend, not a fixed list of every model that backend might offer. A drop-down has normal GTK keyboard focus and does not trigger Vim composer shortcuts.

## Current limitations

- Only Linux/NixOS GTK4 is supported.
- The native GTK4 GUI continues processing input during model generation through Ain background tasks; the composer is still single-line.
- Browser commands remain synchronous and can temporarily block the window.
- Named agents persist their histories locally in `agents.json`; conversations without a named agent remain in memory unless saved explicitly.
- Browser agents can run up to 20 bounded model-directed actions, but not purchases or unattended background runs.
- Provider logins and live model responses have not been tested with personal credentials.
- GUI, browser and chat builtins are currently supported through Ain's Rust code-generation backend, not its LLVM or self-hosted C backend. **The Ainex application itself does not contain Rust.**

MIT license.

## Responsive AI generation

Ainex launches model requests using Ain's `spawn` builtin and a named Ain
function returning `Data`. While the request executes, `guitick 50` pumps the
native GTK4 event loop without destroying the input widget, and `guiupdate`
repaints the result when it arrives. No Rust or Python application source is
required. Browser actions remain synchronous and can briefly block the GTK window.
Agent model calls run asynchronously; browser actions are executed only on
the app thread with a bounded tool whitelist.

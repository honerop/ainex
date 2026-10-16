# Ainex contributor notes

This is a general-purpose native GTK4 desktop application written in Ain.
Do not replace GTK4 with a browser GUI, Electron, or a local HTTP server.
The Ain application entrypoint is `main.ain`; native GTK support comes from the `desktop` compiler builtin in `honerop/ain`.
Ain expressions use fixed-arity prefix syntax without call parentheses or braces.
NixOS support is required. Test with `nix build` and `nix develop`.
Never log, commit, or copy credentials from the Codex login store or `DEEPINFRA_API_KEY`.
Keep tool execution read-only until an explicit permission system is implemented.

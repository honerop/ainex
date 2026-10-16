# Ainex rules

Write **all application code in Ain**. Main application file is `main.ain`.
No Rust, Python, TypeScript, JavaScript, C, or other application source is allowed in this repo.
Nix configuration and documentation are fine.

The `honerop/ain` language runtime provides generic builtins `gui`, `chat` and `browser`.
Extend Ain's reusable builtins when functionality is missing; do not add special-purpose native host implementations to Ainex.

Ain source uses one expression per line and fixed-arity prefix functions; no braces, parentheses, or handwritten Rust.
Keep a real GTK4 native window (not Electron, webview, or a browser UI). Keep Vim navigation.
No untrusted page may cause automatic tool execution. Do not store or commit credentials.

Build on NixOS with `nix build`, and run the packaged app in a virtual display in CI.

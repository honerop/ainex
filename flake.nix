{
  description = "Ainex: native GTK4 AI assistant with isolated Chromium browser tools";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    babel = {
      url = "github:honerop/babel/063dca2abb02a480019ee820f82359fa20b574a3";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, babel }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f (import nixpkgs { inherit system; }));
    in {
      packages = forAllSystems (pkgs:
        let
          lib = pkgs.lib;
          python = pkgs.python3.withPackages (p: [ p.playwright ]);
          dependencies = [ pkgs.curl pkgs.jq python pkgs.chromium ]
            ++ lib.optionals (pkgs ? codex) [ pkgs.codex ]
            ++ lib.optionals (pkgs ? opencode) [ pkgs.opencode ];
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "ainex";
            version = "0.3.0";
            src = self;
            nativeBuildInputs = with pkgs; [ cargo rustc pkg-config makeWrapper curl ];
            buildInputs = with pkgs; [ gtk4 glib sqlite zlib ];
            dontConfigure = true;
            buildPhase = ''
              runHook preBuild
              export CARGO_MANIFEST_DIR=${babel}
              rustc --edition=2021 --crate-name babel_compiler --crate-type rlib -O ${babel}/src/lib.rs -o libbabel_compiler.rlib
              rustc --edition=2021 -O ${babel}/src/main.rs --extern babel_compiler=libbabel_compiler.rlib -L dependency=. -o babelc
              ./babelc build main.babel -o ainex
              ./babelc build cli.babel -o ainex-cli
              runHook postBuild
            '';
            doCheck = true;
            checkPhase = ''
              runHook preCheck
              ./babelc check main.babel
              ./babelc check cli.babel
              ./ainex-cli --help > /tmp/ainex-cli-help.log
              grep -F "ainex-cli --interactive" /tmp/ainex-cli-help.log
              cat > opencode-mock <<'EOF'
              #!/bin/sh
              printf '%s\n' '{"type":"text","part":{"type":"text","text":"CLI smoke reply"}}'
              EOF
              chmod +x opencode-mock
              BABEL_OPENCODE_BIN="$PWD/opencode-mock" ./ainex-cli -p "test" > /tmp/ainex-cli-reply.log
              grep -F "CLI smoke reply" /tmp/ainex-cli-reply.log
              printf 'hello\n/quit\n' | BABEL_OPENCODE_BIN="$PWD/opencode-mock" ./ainex-cli --interactive > /tmp/ainex-cli-session.log
              grep -F "CLI smoke reply" /tmp/ainex-cli-session.log
              ./babelc build tests/browser.babel -o browser-test
              ./babelc build tests/gui_task.babel -o gui-task-test
              ./babelc build tests/gui_keys.babel -o gui-keys-test
              ./babelc build tests/workspace.babel -o workspace-test
              ./babelc build tests/agent_store.babel -o agent-store-test
              ./babelc build tests/task_queue.babel -o task-queue-test
              ./task-queue-test > /tmp/ainex-task-queue.log
              grep -x '2' /tmp/ainex-task-queue.log
              grep -x 'Explain monads' /tmp/ainex-task-queue.log
              grep -x '1' /tmp/ainex-task-queue.log
              grep -x 'Review source' /tmp/ainex-task-queue.log
              ./agent-store-test > /tmp/ainex-agent-store.log
              grep -x 'true' /tmp/ainex-agent-store.log
              grep -x 'Teacher' /tmp/ainex-agent-store.log
              grep -x 'Haskell tutor' /tmp/ainex-agent-store.log
              grep -x 'opencode' /tmp/ainex-agent-store.log
              ./workspace-test > /tmp/ainex-workspace.log
              grep -x "true" /tmp/ainex-workspace.log
              grep -F "Hello Ainex" /tmp/ainex-workspace.log
              BABEL_BROWSER_PYTHON="${python}/bin/python3" AINEX_CHROMIUM_BROWSER="${pkgs.chromium}/bin/chromium" ./browser-test
              runHook postCheck
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/bin" "$out/libexec/ainex-tests"
              install -m 0755 ainex "$out/bin/ainex"
              install -m 0755 ainex-cli "$out/bin/ainex-cli"
              install -m 0755 gui-task-test "$out/libexec/ainex-tests/gui-task"
              install -m 0755 gui-keys-test "$out/libexec/ainex-tests/gui-keys"
              wrapProgram "$out/bin/ainex-cli" \
                --prefix PATH : "${lib.makeBinPath dependencies}"
              wrapProgram "$out/bin/ainex" \
                --prefix PATH : "${lib.makeBinPath dependencies}" \
                --set BABEL_BROWSER_PYTHON "${python}/bin/python3" \
                --set AINEX_CHROMIUM_BROWSER "${pkgs.chromium}/bin/chromium"
              runHook postInstall
            '';
            meta = {
              description = "Native GTK4 general-purpose AI client with browser tools";
              mainProgram = "ainex";
              platforms = lib.platforms.linux;
              license = lib.licenses.mit;
            };
          };

        });
      apps = forAllSystems (pkgs: {
        cli = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ainex-cli";
        };
      });
      devShells = forAllSystems (pkgs:
        let python = pkgs.python3.withPackages (p: [ p.playwright ]);
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ rustc cargo pkg-config gtk4 glib sqlite zlib curl jq chromium ] ++
              [ python ] ++ pkgs.lib.optionals (pkgs ? codex) [ pkgs.codex ]
              ++ pkgs.lib.optionals (pkgs ? opencode) [ pkgs.opencode ];
            shellHook = ''
              export CARGO_TARGET_DIR="$PWD/.babel-target"
              export BABEL_BROWSER_PYTHON="${python}/bin/python3"
              export AINEX_CHROMIUM_BROWSER="${pkgs.chromium}/bin/chromium"
              babelc() { cargo run --quiet --manifest-path "${babel}/Cargo.toml" -- "$@"; }
              export -f babelc
            '';
          };
        });
    };
}
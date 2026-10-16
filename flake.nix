{
  description = "Ainex: native GTK4 AI assistant with isolated Chromium browser tools";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ain = {
      url = "github:honerop/ain/7670b77401f4b3ee889471f1aafa77ba86b77539";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, ain }:
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
            ++ lib.optionals (pkgs ? codex) [ pkgs.codex ];
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "ainex";
            version = "0.3.0";
            src = self;
            nativeBuildInputs = with pkgs; [ cargo rustc pkg-config makeWrapper ];
            buildInputs = with pkgs; [ gtk4 glib ];
            dontConfigure = true;
            buildPhase = ''
              runHook preBuild
              cp -R ${ain} ain-source
              chmod -R u+w ain-source
              export CARGO_TARGET_DIR="$PWD/ain-target"
              cargo build --offline --release --manifest-path ain-source/Cargo.toml
              "$CARGO_TARGET_DIR/release/ainc" build main.ain -o ainex
              runHook postBuild
            '';
            doCheck = true;
            checkPhase = ''
              runHook preCheck
              cargo test --offline --manifest-path ain-source/Cargo.toml
              "$CARGO_TARGET_DIR/release/ainc" check main.ain
              "$CARGO_TARGET_DIR/release/ainc" build tests/browser.ain -o browser-test
              AIN_BROWSER_PYTHON="${python}/bin/python3" AINEX_CHROMIUM_BROWSER="${pkgs.chromium}/bin/chromium" ./browser-test
              runHook postCheck
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/bin"
              install -m 0755 ainex "$out/bin/ainex"
              wrapProgram "$out/bin/ainex" \
                --prefix PATH : "${lib.makeBinPath dependencies}" \
                --set AIN_BROWSER_PYTHON "${python}/bin/python3" \
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
      devShells = forAllSystems (pkgs:
        let python = pkgs.python3.withPackages (p: [ p.playwright ]);
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ rustc cargo pkg-config gtk4 glib curl jq chromium ] ++
              [ python ] ++ pkgs.lib.optionals (pkgs ? codex) [ pkgs.codex ];
            shellHook = ''
              export CARGO_TARGET_DIR="$PWD/.ain-target"
              export AIN_BROWSER_PYTHON="${python}/bin/python3"
              export AINEX_CHROMIUM_BROWSER="${pkgs.chromium}/bin/chromium"
              ainc() { cargo run --quiet --manifest-path "${ain}/Cargo.toml" -- "$@"; }
              export -f ainc
            '';
          };
        });
    };
}
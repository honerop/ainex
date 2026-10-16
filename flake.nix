{
  description = "Ainex: native GTK4 AI assistant with isolated Chromium browser tools";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ain = {
      url = "github:honerop/ain/b93ea337e4bf8db6b0c8e34a4808d4f3d59fb2e7";
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
            version = "0.2.0";
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
              gtk_links=()
              for flag in $(pkg-config --libs-only-L gtk4); do
                case "$flag" in
                  -L*) gtk_links+=(-L "native=''${flag#-L}") ;;
                esac
              done
              rustc --edition=2021 -O src/main.rs -o ainex-host "''${gtk_links[@]}"
              runHook postBuild
            '';
            doCheck = true;
            checkPhase = ''
              runHook preCheck
              cargo test --offline --manifest-path ain-source/Cargo.toml
              "$CARGO_TARGET_DIR/release/ainc" check main.ain
              ${python}/bin/python3 browser/driver.py --self-test
              runHook postCheck
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/bin" "$out/libexec" "$out/share/ainex/browser"
              install -m 0755 ainex "$out/bin/ainex"
              install -m 0755 ainex-host "$out/libexec/ainex-host"
              install -m 0644 browser/driver.py "$out/share/ainex/browser/driver.py"
              wrapProgram "$out/bin/ainex" \
                --prefix PATH : "$out/libexec:${lib.makeBinPath dependencies}" \
                --set AINEX_BROWSER_DRIVER "$out/share/ainex/browser/driver.py" \
                --set AINEX_PYTHON "${python}/bin/python3" \
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
              export AINEX_BROWSER_DRIVER="$PWD/browser/driver.py"
              export AINEX_PYTHON="${python}/bin/python3"
              export AINEX_CHROMIUM_BROWSER="${pkgs.chromium}/bin/chromium"
              ainc() { cargo run --quiet --manifest-path "${ain}/Cargo.toml" -- "$@"; }
              export -f ainc
            '';
          };
        });
    };
}
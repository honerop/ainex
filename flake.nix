{
  description = "Ainex, a native GTK4 AI desktop application written in Ain";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ain = {
      url = "github:honerop/ain/39e4dd8b0dc503018eddeea8cd3bbaad8d3f88ed";
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
          tools = with pkgs; [ curl jq ] ++ lib.optionals (pkgs ? codex) [ pkgs.codex ];
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "ainex";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = with pkgs; [ rustc cargo pkg-config makeWrapper ];
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
              runHook postCheck
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/bin"
              install -m 0755 ainex "$out/bin/ainex"
              wrapProgram "$out/bin/ainex" --prefix PATH : "${lib.makeBinPath tools}"
              runHook postInstall
            '';
            meta = {
              description = "A native GTK4 general-purpose AI client written in Ain";
              mainProgram = "ainex";
              platforms = lib.platforms.linux;
              license = lib.licenses.mit;
            };
          };
        });
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ rustc cargo pkg-config gtk4 glib curl jq ]
            ++ pkgs.lib.optionals (pkgs ? codex) [ pkgs.codex ];
          shellHook = ''
            export CARGO_TARGET_DIR="$PWD/.ain-target"
            ainc() {
              cargo run --quiet --manifest-path "${ain}/Cargo.toml" -- "$@"
            }
            export -f ainc
          '';
        };
      });
    };
}

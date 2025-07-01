{
  description = "Nix overlay for claude-bridge: Seamlessly integrate OpenAI, Ollama, Google AI and other LLM providers with Anthropic's Claude Code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    claude-bridge-src = {
      url = "github:badlogic/lemmy";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, claude-bridge-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        claude-bridge = pkgs.buildNpmPackage rec {
          pname = "claude-bridge";
          version = "1.0.10";

          src = "${claude-bridge-src}/apps/claude-bridge";

          npmDepsHash = pkgs.lib.fakeHash;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = [ pkgs.nodejs ];

          buildPhase = ''
            runHook preBuild
            npm run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/lib/node_modules/claude-bridge
            cp -r dist/* $out/lib/node_modules/claude-bridge/
            cp -r node_modules $out/lib/node_modules/claude-bridge/
            cp package.json $out/lib/node_modules/claude-bridge/
            
            mkdir -p $out/bin
            makeWrapper ${pkgs.nodejs}/bin/node $out/bin/claude-bridge \
              --add-flags "$out/lib/node_modules/claude-bridge/cli.js"
            
            runHook postInstall
          '';
        };

        overlay = final: prev: {
          inherit claude-bridge;
        };
      in
      {
        overlays.default = overlay;
        packages.default = claude-bridge;
        packages.claude-bridge = claude-bridge;
      }
    ) // {
      overlays.default = final: prev: {
        claude-bridge = final.buildNpmPackage rec {
          pname = "claude-bridge";
          version = "1.0.10";

          src = "${claude-bridge-src}/apps/claude-bridge";

          npmDepsHash = final.lib.fakeHash;

          nativeBuildInputs = [ final.makeWrapper ];
          buildInputs = [ final.nodejs ];

          buildPhase = ''
            runHook preBuild
            npm run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/lib/node_modules/claude-bridge
            cp -r dist/* $out/lib/node_modules/claude-bridge/
            cp -r node_modules $out/lib/node_modules/claude-bridge/
            cp package.json $out/lib/node_modules/claude-bridge/
            
            mkdir -p $out/bin
            makeWrapper ${final.nodejs}/bin/node $out/bin/claude-bridge \
              --add-flags "$out/lib/node_modules/claude-bridge/cli.js"
            
            runHook postInstall
          '';
        };
      };
    };
}
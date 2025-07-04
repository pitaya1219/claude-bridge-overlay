{
  description = "Nix overlay for claude-bridge: Seamlessly integrate OpenAI, Ollama, Google AI and other LLM providers with Anthropic's Claude Code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        claudeBridgeOverlay = final: prev: {
          claude-bridge = prev.stdenv.mkDerivation {
            pname = "claude-bridge";
            version = "0.1.0";
            
            #src = prev.fetchFromGitHub {
            #  owner = "badlogic";
            #  repo = "lemmy";
            #  rev = "main";
            #  hash = ""; # 空文字列で正しいハッシュを取得
            #};
            src = /tmp/lemmy;
            
            #sourceRoot = "${src.name}/apps/claude-bridge";
            sourceRoot = "lemmy/apps/claude-bridge";
            
            buildInputs = with prev; [ nodejs ];
            nativeBuildInputs = with prev; [ nodejs ];
            
            buildPhase = ''
              runHook preBuild
              
              # npm用の環境変数を設定
              export HOME=$PWD
              export npm_config_cache=$PWD/.npm-cache
              export npm_config_userconfig=$PWD/.npmrc
              export npm_config_prefix=$PWD/.npm-global
              export npm_config_audit=false
              export npm_config_fund=false
              export npm_config_update_notifier=false
              
              # SSL証明書の設定
              export SSL_CERT_FILE="/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem"
              export NODE_EXTRA_CA_CERTS="/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem"
              
              # 必要なディレクトリを作成
              mkdir -p .npm-cache .npm-global              
              if [ -f package.json ]; then
                echo "Installing npm dependencies..."
                npm install --no-package-lock --legacy-peer-deps --registry https://registry.npmjs.org/ --cache $PWD/.npm-cache --userconfig $PWD/.npmrc
                if npm run build --if-present 2>/dev/null; then
                  echo "Build completed successfully"
                else
                  echo "Build command not found or failed, continuing..."
                fi
              else
                echo "No package.json found, skipping npm install"
              fi
              runHook postBuild
            '';
            
            installPhase = ''
              runHook preInstall
              mkdir -p $out/lib/claude-bridge
              cp -r . $out/lib/claude-bridge/

              if [ -d ../../packages ]; then
                mkdir -p $out/packages
                cp -r ../../packages/* $out/packages/
              fi

              find $out/lib/claude-bridge -type l -exec test ! -e {} \; -delete 2>/dev/null || true

              # npmキャッシュディレクトリは除外
              rm -rf $out/lib/claude-bridge/.npm-cache
              rm -rf $out/lib/claude-bridge/.npm-global
              
              mkdir -p $out/bin
              cat > $out/bin/claude-bridge << 'EOF'
#!/usr/bin/env bash
cd $out/lib/claude-bridge && exec ${prev.nodejs}/bin/node src/cli.js "$@"
EOF
              chmod +x $out/bin/claude-bridge
              runHook postInstall
            '';
          };
        };

        overlayedPkgs = import nixpkgs {
          inherit system;
          overlays = [ claudeBridgeOverlay ];
        };
      in
      {
        overlays.default = claudeBridgeOverlay;
        packages.default = overlayedPkgs.claude-bridge;
        packages.claude-bridge = overlayedPkgs.claude-bridge;

        apps = {
          default = {
            type = "app";
            program = "${overlayedPkgs.claude-bridge}/bin/claude-bridge";
          };
          claude-bridge = {
            type = "app";
            program = "${overlayedPkgs.claude-bridge}/bin/claude-bridge";
          };
        };

        devShells.default = overlayedPkgs.mkShell {
          packages = with overlayedPkgs; [ claude-bridge ];
        };
      }
    );
}

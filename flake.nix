{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-21.11;
    flake-utils.url = github:numtide/flake-utils;
    gomod2nix.url = github:tweag/gomod2nix;
    grpc-gateway.url = github:thegergo02/grpc-gateway-flake;
    protoc-gen-validate.url = github:thegergo02/protoc-gen-validate-flake;
    zitadel-src = {
      type = "git";
      flake = false;
      url = "https://github.com/zitadel/zitadel";
      ref = "refs/tags/v1.84.5";
    };
  };

  outputs =
    { self, nixpkgs, flake-utils, gomod2nix, grpc-gateway, protoc-gen-validate, zitadel-src }:
    let
      overlays = [ gomod2nix.overlays.default ];
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { 
          inherit system overlays; 
          config = { allowUnfree = true;  }; # NOTE: needed for cockroachdb
        };
        
        setup = pkgs.writeScriptBin "setup" ''
          export GOPATH=$(pwd)/gopath
          export SRC_PATH=$GOPATH/src/github.com/zitadel/zitadel

          export GATEWAY_VERSION=2.6.0
          export VALIDATOR_VERSION=0.6.2

          export PROTO_PATH=$(pwd)/protoext
          export PROTO_INC_PATH=$PROTO_PATH/include
          export PROTO_ZITADEL_PATH=$PROTO_INC_PATH/zitadel

          export ZITADEL_PATH=$GOPATH/src/github.com/zitadel/zitadel
          export DOCS_PATH=$ZITADEL_PATH/docs/apis/proto
          export OPENAPI_PATH=$ZITADEL_PATH/openapi/v2
          export GRPC_PATH=$ZITADEL_PATH/pkg/grpc

          mkdir -p $SRC_PATH
          pushd $SRC_PATH
          cp -r ${zitadel-src}/* .
          chmod -R +w $ZITADEL_PATH
          popd
        '';
        gen-statik0 = (pkgs.writeScriptBin "gen-statik0" (builtins.readFile ./scripts/generate-statik0.sh)).overrideAttrs(old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
        gen-grpc = (pkgs.writeScriptBin "gen-grpc" (builtins.readFile ./scripts/generate-grpc.sh)).overrideAttrs(old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
        gen-statik1 = (pkgs.writeScriptBin "gen-statik1" (builtins.readFile ./scripts/generate-statik1.sh)).overrideAttrs(old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
        gen-assets = (pkgs.writeScriptBin "gen-assets" (builtins.readFile ./scripts/generate-assets.sh)).overrideAttrs(old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
        gen = pkgs.writeScriptBin "gen" ''
          ${gen-statik0}/bin/gen-statik0
          ${gen-grpc}/bin/gen-grpc
          ${gen-statik1}/bin/gen-statik1
          ${gen-assets}/bin/gen-assets
        '';
      in
      rec {
        packages = flake-utils.lib.flattenTree
          { zitadel-base = pkgs.buildGoApplication {
              name = "zitadel-base";
              src = "${zitadel-src}";
              modules = ./gomod2nix.toml;
              subPackages = [ "cmd/zitadel" ];
              buildInputs = [
                grpc-gateway.defaultPackage.${system} 
                protoc-gen-validate.defaultPackage.${system} 
                setup 
                gen-statik0 gen-grpc gen-statik1 gen-assets gen 
              ];
              postConfigure = ''
                source ${setup}/bin/setup
                ${gen}/bin/gen
              '';
            };
          };

        defaultPackage = packages.zitadel-base;

        devShell =
          pkgs.mkShell {
            buildInputs = [ 
              pkgs.gomod2nix 
              grpc-gateway.defaultPackage.${system} 
              protoc-gen-validate.defaultPackage.${system} 
              setup 
              gen-statik0 gen-grpc gen-statik1 gen-assets gen 
            ];
            packages = with pkgs; [
              protobuf3_18
              protoc-gen-grpc-web
              protoc-gen-go
              protoc-gen-go-grpc
              go_1_17
              go-bindata
              protoc-gen-doc
              cockroachdb
              statik
            ];
          };

        apps.zitadel-base = flake-utils.lib.mkApp { name = "zitadel-base"; drv = packages.zitadel-base; };
      });
}


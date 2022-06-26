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
        pkgs = import nixpkgs { inherit system overlays; };
        
        setup = (pkgs.writeScriptBin "setup" ''
          export GOPATH=$(pwd)/gopath
          export SRC_PATH=$GOPATH/src/github.com/zitadel/zitadel
          mkdir -p $SRC_PATH
          pushd $SRC_PATH
          cp -r ${zitadel-src}/* .
          popd
        '').overrideAttrs(old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
        gen-grpc = (pkgs.writeScriptBin "gen-grpc" (builtins.readFile ./scripts/generate-grpc.sh)).overrideAttrs(old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
      in
      rec {
        packages = flake-utils.lib.flattenTree
          { zitadel-base = pkgs.buildGoApplication {
              name = "zitadel-base";
              src = "${zitadel-src}";
              modules = ./gomod2nix.toml;
              subPackages = [ "zitadel" ];
            };
          };

        defaultPackage = packages.zitadel-base;

        devShell =
          pkgs.mkShell {
            buildInputs = [ 
              pkgs.gomod2nix 
              grpc-gateway.defaultPackage.${system} 
              protoc-gen-validate.defaultPackage.${system} 
              setup gen-grpc 
            ];
            packages = with pkgs; [
              protobuf3_18
              protoc-gen-grpc-web
              protoc-gen-go
              protoc-gen-go-grpc
              go_1_17
              go-bindata
              protoc-gen-doc
            ];
          };

        apps.zitadel-base = flake-utils.lib.mkApp { name = "zitadel-base"; drv = packages.zitadel-base; };
      });
}


{
  description = "A very basic flake";
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
    let
      overlays = [ haskellNix.overlay
        (final: prev: {
          helloProject =
            final.haskell-nix.project' {
              src = ./.;
              compiler-nix-name = "ghc902";
              shell.tools = {
                cabal = {};
                hlint = {};
                haskell-language-server = {};
              };
            };
        })
      ];
      pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
      flake = pkgs.helloProject.flake {};
    in flake // {
      defaultPackage = flake.packages."hello:exe:hello";
      packages.devContainerImage = pkgs.dockerTools.buildLayeredImage {
        name = "hello-devcontainer";
        tag = "latest";
        extraCommands = ''
          #!${pkgs.runtimeShell}
        '';
        contents = with pkgs; [
          bash coreutils cacert tzdata fd git  busybox
          ((pkgs.helloProject.shellFor {}).buildInputs)
        ];
      };
    });
}
# nix build .#devContainerImage && docker load < result && docker run -v $PWD:/workspace/hello --rm -it hello-nix-devcontainer bash
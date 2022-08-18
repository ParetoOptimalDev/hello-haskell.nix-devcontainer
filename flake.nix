# success criteria: This command returns a matching line indicating that aeson was loaded into the ghc package database
# nix build .#devContainerImage && docker load < result && docker run -v $PWD:/workspace/hello --rm -it hello-nix-devcontainer bash -c "ghc-pkg list | grep aeson"
# currently returns: bash: line 1: ghc-pkg: command not found


{
  inputs = {
    msb.url = github:rrbutani/nix-mk-shell-bin;
    nixpkgs.url = github:nixOS/nixpkgs/22.05;
    flu.url = github:numtide/flake-utils;
  };

  outputs = { self, msb, nixpkgs, flu, ... }: with msb.lib; with flu.lib; eachDefaultSystem(system: let
    np = import nixpkgs { inherit system; };

    haskellPackages = np.haskellPackages;
    packageName = "hello";
    
    # Like `nix-shell`, this will build the dependencies of `pkg` but not
    # `pkg` itself.
    pkg = haskellPackages.callCabal2nix packageName self rec {
            # Dependency overrides go here
          };
    pkgShellBin = mkShellBin { drv = pkg; nixpkgs = np; };

    # Here, `shellBin` *will* build `pkg`. This is like `nix develop`.
    shell = np.mkShell { name = "example"; buildInputs = [pkg]; nativeBuildInputs = [pkg]; };
    shellBin = msb.lib.mkShellBin { drv = shell; nixpkgs = np; bashPrompt = "[hithere]$ "; };

  in {
    # You can run `nix bundle` and get a self-contained executable that,
    # when run, drops you into a shell containing `pkg`.
    packages.default = shellBin;
    packages.pkgShellBin = pkgShellBin;

    packages.devContainerImage = np.dockerTools.buildLayeredImage {
        name = "hello-nix-devcontainer";
        tag = "latest";
        extraCommands = ''
          #!${pkgShellBin}/bin/example-shell
        '';
        contents = with np; [
          bash coreutils cacert tzdata fd git  busybox
          shellBin
          pkgShellBin
        ];
      };

    # You can run the derivations `mkShellBin` produces:
    apps.default = { type = "app"; program = "${shellBin}/bin/${shellBin.name}"; };

    # The above is more or less equivalent to:
    devShells.default = shell;
  });
}

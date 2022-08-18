{
  inputs = {
    msb.url = github:rrbutani/nix-mk-shell-bin;
    nixpkgs.url = github:nixOS/nixpkgs/22.05;
    flu.url = github:numtide/flake-utils;
  };

  outputs = { msb, nixpkgs, flu, ... }: with msb.lib; with flu.lib; eachDefaultSystem(system: let
    np = import nixpkgs { inherit system; };

    # Like `nix-shell`, this will build the dependencies of `pkg` but not
    # `pkg` itself.
    pkg = np.hello;
    pkgShellBin = mkShellBin { drv = pkg; nixpkgs = np; };

    # Here, `shellBin` *will* build `pkg`. This is like `nix develop`.
    shell = np.mkShell { name = "example"; nativeBuildInputs = [pkg]; };
    shellBin = msb.lib.mkShellBin { drv = shell; nixpkgs = np; bashPrompt = "[hello]$ "; };

  in {
    # You can run `nix bundle` and get a self-contained executable that,
    # when run, drops you into a shell containing `pkg`.
    packages.default = shellBin;
    packages.pkgShellBin = pkgShellBin;

    # You can run the derivations `mkShellBin` produces:
    apps.default = { type = "app"; program = "${shellBin}/bin/${shellBin.name}"; };

    # The above is more or less equivalent to:
    devShells.default = shell;
  });
}

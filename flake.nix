{
  description = "Notmuch email tagging and indexing";

  inputs.pre-commit-hooks = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, pre-commit-hooks, ... }:
    let
      inherit (nixpkgs) lib;
      each = lib.genAttrs [ "x86_64-darwin" "x86_64-linux" ];
    in {

      overlay = final: prev: {
        notmuch = prev.notmuch.overrideAttrs (old: {
          version = lib.removeSuffix "\n" (lib.readFile ./version.txt);
          src = ./.;
          buildInputs = old.buildInputs ++ [
            final.bash-completion
            final.cppcheck
            (final.python3.withPackages (p: [ p.setuptools p.cffi p.pytest ]))
          ];
        });
      };

      packages = each (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in { inherit (self.overlay pkgs pkgs) notmuch; });

      checks = each (system: {
        pre-commit = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks.nixfmt.enable = true;
          hooks.nix-linter.enable = true;
        };
      });

      devShell = each (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          pkg-inputs = with self.packages.${system}.notmuch;
            nativeBuildInputs ++ buildInputs;

          check-tools = with pre-commit-hooks.packages.${system}; [
            nixfmt
            nix-linter
          ];

        in pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit) shellHook;
          buildInputs = pkg-inputs ++ check-tools;
        });
    };
}

# Local Variables:
# fill-column: 80
# End:

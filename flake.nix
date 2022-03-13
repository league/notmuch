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
      version = lib.removeSuffix "\n" (lib.readFile ./version.txt);
    in {

      overlay = final: prev: {
        notmuch = prev.notmuch.overrideAttrs (old: {
          inherit version;
          src = ./.;
          buildInputs = old.buildInputs ++ [
            final.bash-completion
            final.cppcheck
            (final.python3.withPackages (p: [ p.setuptools p.cffi p.pytest ]))
          ];
        });

        emacsPackagesFor = em:
          (prev.emacsPackagesFor em).overrideScope' (_: super: {
            notmuch = super.notmuch.overrideAttrs (_: {
              name = "emacs-notmuch-${version}";
              inherit version;
              src = ./.;
            });
          });
      };

      packages = each (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlay ];
          };
        in {
          inherit (pkgs) notmuch;
          emacs-notmuch = pkgs.emacsPackages.notmuch;
        });

      checks = each (system: {
        pre-commit = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks.nixfmt.enable = true;
          hooks.nix-linter.enable = true;
          hooks.yamllint.enable = true;
          hooks.yamllint.excludes = [ "vim/notmuch\\.yaml" "\\.travis\\.yml" ];
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
          NOTMUCH_SKIP_TESTS = "libconfig.18 libconfig.31";
        });
    };
}

# Local Variables:
# fill-column: 80
# End:

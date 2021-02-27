{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShell { buildInputs = [ dtach gmime3 openssl pkgconfig talloc xapian zlib ]; }

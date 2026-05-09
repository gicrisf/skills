{ pkgs ? import <nixpkgs> {} }:

let
  eldev = pkgs.stdenv.mkDerivation {
    pname = "eldev";
    version = "1.11.1";
    src = pkgs.fetchFromGitHub {
      owner = "doublep";
      repo = "eldev";
      rev = "1.11.1";
      sha256 = "0sf8xyzblc0fs2d65jgcycavnzmrp1wg0sfr29gjkq1kvzyl7phb";
    };
    buildInputs = [ pkgs.emacs ];
    installPhase = ''
      mkdir -p $out/bin
      cp bin/eldev $out/bin/
      chmod +x $out/bin/eldev
    '';
  };
in
pkgs.mkShell {
  buildInputs = [ pkgs.emacs eldev pkgs.stow ];
  shellHook = ''
    echo "skills development shell"
    echo "  Export: eldev emacs --batch -l export-skills.el"
  '';
}

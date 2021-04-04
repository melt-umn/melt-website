{ pkgs ? import <nixpkgs> {}
}:

let
  hugo-geekdoc = pkgs.fetchzip {
    url = https://github.com/thegeeklab/hugo-geekdoc/releases/download/v0.10.1/hugo-geekdoc.tar.gz;
    sha256 = "0q9zskkhfgkc37mnhs0f62n53y1svpa19snhc691pybbidmwk6gi";
    stripRoot = false;
  };
in

pkgs.stdenvNoCC.mkDerivation {
  name = "melt-website";
  src = pkgs.nix-gitignore.gitignoreSource [] ./.;
  buildInputs = [ pkgs.hugo ];

  buildPhase = ''
    mkdir -p themes
    ln -s ${hugo-geekdoc} themes/hugo-geekdoc
    echo ${hugo-geekdoc}
    hugo
  '';
  installPhase = "cp -r public $out";
}

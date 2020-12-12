with import <nixpkgs> {};

let

  python = python3.withPackages (py: with py; [
    jinja2
  ]);
in
stdenv.mkDerivation {
    name = "impurePythonEnv";

    buildInputs = [
      python
      black
      python3Packages.isort
  ];
}


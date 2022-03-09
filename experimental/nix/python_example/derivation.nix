{ lib, python3Packages }:
with python3Packages;
buildPythonApplication {
  pname = "demo-flask-vuejs-rest";
  version = "1.0";

  propagatedBuildInputs = [ flask ];

  src = ./.;
}

{
  lib,
  buildPythonPackage,
  fetchurl,
  playwright,
  nodejs,
}:
buildPythonPackage rec {
  pname = "patchright";
  version = "1.59.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/3b/cc/f62063e59db98b154d9faf79603164d548f5117c95acc9d2a8104df9607a/patchright-1.59.1-py3-none-manylinux1_x86_64.whl";
    hash = "sha256-8KfuMeVjkals2B+awdsTDoFmxgg7fz+zvJuhnYDWgSc=";
  };

  dependencies = [
    playwright
    nodejs
  ];

  pythonRelaxDeps = [ "playwright" ];

  pythonImportsCheck = [ "patchright" ];

  meta = with lib; {
    description = "Playwright fork with anti-detect patches";
    homepage = "https://github.com/Kaliiiiiiiiii-Vinyzu/patchright";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}

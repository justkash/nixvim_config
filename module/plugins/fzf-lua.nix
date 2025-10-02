# Build plugin from scratch to avoid problems with tests in a headless
# environment like the Raspberry Pi.
{ lib, fetchFromGitHub, vimUtils, ... }: vimUtils.buildVimPlugin {
  pname = "fzf-lua";
  version = "2025-10-2";
  src = fetchFromGitHub {
    owner = "ibhagwan";
    repo = "fzf-lua";
    rev = "23fca9ac345b8b7da326f16d0d1db239f293b43c";
    sha256 = "sha256-RJIfWVq2GH95n3zg81sTTumYcTSCRqveVpwX2r/2+kM=";
  };
  doCheck = false;
  doInstallCheck = false;
}

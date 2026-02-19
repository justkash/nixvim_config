# Build plugin from scratch to avoid problems with tests in a headless
# environment like the Raspberry Pi.
{ lib, fetchFromGitHub, vimUtils, ... }: vimUtils.buildVimPlugin {
  pname = "editable-term";
  version = "2026-2-19";
  src = fetchFromGitHub {
    owner = "xb-bx";
    repo = "editable-term.nvim";
    rev = "16ac164615d465fedbbb4918a4182731e1beb53b";
    sha256 = "sha256-JbiBnMKEf7rfpS0PCodBNTM4P7nWPKoFhOUbO4i7uSI=";
  };
  doCheck = false;
  doInstallCheck = false;
}

# Pin the plugin revision and disable derivation checks for headless builds.
{
  fetchFromGitHub,
  vimUtils,
  ...
}:
vimUtils.buildVimPlugin {
  pname = "editable-term";
  version = "2026-2-19";
  src = fetchFromGitHub {
    owner = "xb-bx";
    repo = "editable-term.nvim";
    rev = "16ac164615d465fedbbb4918a4182731e1beb53b";
    sha256 = "sha256-i2W+7ZV7la/QgfJ4NDrOuj/+zRw2/rLQ4QukXdrn29M=";
  };
  doCheck = false;
  doInstallCheck = false;
}

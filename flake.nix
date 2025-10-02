{
  description = "Nixvim configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixvim = {
      url  = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, ...  }: 
  let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    module = import ./module;
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: 
    let
      pkgs = import nixpkgs {
        inherit system;
	overlays = [ self.overlays.default ];
      };
      nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule { inherit pkgs module; };
    in f { inherit nvim; });
  in {
    overlays.default = final: prev: { nvim = self.packages.${final.system}.nvim; };
    packages = forEachSupportedSystem ({ nvim }: {
      inherit nvim;
      default = nvim;
    });
  };
}

{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = { inherit self inputs; };

    modules = [
      ({ inputs, ... }: {
        nixpkgs.overlays = [ inputs.niri.overlays.default ];
      })

      self.nixosModules.myMachineConfiguration

      ./hardware.nix
    ];
  };
}

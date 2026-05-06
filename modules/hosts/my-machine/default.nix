{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = { inherit self inputs; };

    modules = [
      # Usamos os argumentos que o próprio NixOS recebe
      ({ inputs, ... }: {
        # Testaremos o 'default' que é mais comum em versões novas
        nixpkgs.overlays = [ inputs.niri.overlays.default ];
      })

      self.nixosModules.myMachineConfiguration
    ];
  };
}

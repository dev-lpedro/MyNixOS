{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    # Isso garante que o 'inputs' do Flake chegue lá embaixo
    specialArgs = { inherit self inputs; };

    modules = [
      # MUDANÇA AQUI: Pedimos o 'inputs' explicitamente nos argumentos do módulo
      ({ inputs, ... }: {
        nixpkgs.overlays = [
          # Tentaremos 'overlays.niri' e, se falhar, você pode testar 'overlays.default'
          inputs.niri.overlays.niri
        ];
      })

      self.nixosModules.myMachineConfiguration
    ];
  };
}

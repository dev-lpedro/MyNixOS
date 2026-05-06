{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    # Repassamos o self e inputs para os arquivos que o Maestro importar
    specialArgs = { inherit self inputs; };

    modules = [
      # MUDANÇA AQUI: Tiramos o 'inputs' dos argumentos locais.
      # Assim ele usa o 'inputs' lá da primeira linha do arquivo.
      ({ ... }: {
        nixpkgs.overlays = [
          inputs.niri.overlays.niri
        ];
      })

      self.nixosModules.myMachineConfiguration
    ];
  };
}

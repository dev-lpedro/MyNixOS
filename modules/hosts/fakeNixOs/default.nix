# ==============================================================================
# Ponto de Entrada da Configuração do Host 'fakeNixOs'
# Instancia a arquitetura, ativa overlays do Niri e conecta o Home Manager.
# ==============================================================================
{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.fakeNixOs = inputs.nixpkgs.lib.nixosSystem {
    # Disponibiliza as variáveis do Flake (inputs) para os submódulos
    specialArgs = {inherit self inputs;};

    modules = [
      # Define a plataforma no padrão moderno do NixOS (Remove o aviso do terminal)
      {nixpkgs.hostPlatform = "x86_64-linux";}

      /*
      # Overlay oficial do Niri para compilação upstream
      ({ inputs, ... }: {
        nixpkgs.overlays = [ inputs.niri.overlays.niri ];
      })
      */

      # Módulo integrado do Home Manager
      inputs.home-manager.nixosModules.home-manager

      # Módulo do banco de dados  do nix-index
      inputs.nix-index-database.nixosModules.default

      # Módulo oficial do Niri Compositor
      #inputs.niri.nixosModules.niri

      # Arquivos de configuração gráfica e de hardware do sistema
      ./configuration.nix
      ./hardware.nix
    ];
  };
}

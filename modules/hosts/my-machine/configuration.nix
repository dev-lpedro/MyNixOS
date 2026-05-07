{ self, inputs, ... }: {

  flake.nixosModules.myMachineConfiguration = { pkgs, lib, ... }: {

    imports = [
      # ==========================================
      # 1. HARDWARE E DRIVERS ESPECÍFICOS DESTA MÁQUINA
      # ==========================================
      ./conf_machine.nix

      # ==========================================
      # 2. CONFIGURAÇÕES UNIVERSAIS (SISTEMA E USUÁRIO)
      # ==========================================
      ../../features/config/conf_system.nix
      ../../features/config/conf_users.nix

      # ==========================================
      # 3. PACOTES
      # ==========================================
      ../../features/packages/pkgs_system.nix
      ../../features/packages/pkgs_users.nix

      # ==========================================
      # 4. AMBIENTE GRÁFICO (NIRI E NOCTALIA)
      # ==========================================
      self.nixosModules.niri
    ];

  };
}

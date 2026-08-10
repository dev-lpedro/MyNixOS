{ pkgs, config, inputs, ... }: {

  # ==========================================
  # INTEGRAÇÃO DO HOME MANAGER NO NIXOS
  # ==========================================
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup"; # Posição correta da opção no módulo NixOS
    extraSpecialArgs = { inherit inputs; };

    users.leonardo = { config, ... }: {
      home.stateVersion = "24.11";

      # Link simbólico dinâmico da pasta inteira do Niri
      xdg.configFile."niri" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/niri/cfg_niri";
        force = true;
      };

      # Link simbólico dinâmico da PASTA INTEIRA do Noctalia (Settings, Plugins, Cores)
      xdg.configFile."noctalia" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/niri/cfg_noctalia";
        force = true;
      };

      # Link de compatibilidade para ~/.config/noctalia-shell
      xdg.configFile."noctalia-shell" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/niri/cfg_noctalia";
        force = true;
      };

      # Pacotes do usuário
      home.packages = [
        # Noctalia v4 oficial do Nixpkgs (Iniciada com o comando: noctalia-shell)
        pkgs.noctalia-shell

        # Wrapper para testes da Noctalia v5 (Iniciada com o comando: noctalia-v5)
        (pkgs.writeShellScriptBin "noctalia-v5" ''
          exec ${inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia "$@"
        '')

        # Utilitários de sistema
        pkgs.xwayland-satellite
        pkgs.capitaine-cursors
        pkgs.xwayland
        pkgs.wl-clipboard
        pkgs.cliphist
        pkgs.spice-vdagent
        pkgs.dart-sass
      ];
    };
  };

  # Ativa a versão mais recente do Niri
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };
}
{ pkgs, config, inputs, ... }: {

  # ==========================================
  # CONFIGURAÇÕES DO COMPOSITOR NIRI VIA HOME MANAGER
  # ==========================================
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };

    users.leonardo = { config, ... }: {
      home.stateVersion = "24.11";

      # Link simbólico dinâmico da pasta de configurações do Niri
      xdg.configFile."niri" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/niri/cfg_niri";
        force = true;
      };

      # Pacotes auxiliares essenciais para o Niri e Wayland
      home.packages = with pkgs; [
        xwayland-satellite # Suporte a janelas X11 no Niri
        capitaine-cursors  # Tema de cursor
        xwayland           # Servidor XWayland
        wl-clipboard       # Suporte a Ctrl+C / Ctrl+V no Wayland
        cliphist           # Histórico de área de transferência
        # spice-vdagent      # Suporte a clipboard em VM (SPICE)
      ];
    };
  };

  # Ativa o compositor Niri no nível do sistema NixOS
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };
}
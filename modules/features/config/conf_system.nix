{ config, pkgs, lib, ... }: {

  # ==========================================
  # CONFIGURAÇÕES GERAIS DO NIX
  # ==========================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # ==========================================
  # REDE (Apenas o serviço universal)
  # ==========================================
  networking.networkmanager.enable = true;

  # ==========================================
  # BLUETOOTH
  # ==========================================
  # Habilita os drivers e o serviço do Bluetooth
  hardware.bluetooth.enable = true;

  # Liga o Bluetooth automaticamente quando o PC iniciar
  hardware.bluetooth.powerOnBoot = true;

  # Habilita o Blueman (Gerenciador gráfico e Applet de bandeja)
  services.blueman.enable = true;

  # ==========================================
  # IDIOMA, LOCALIZAÇÃO E TECLADO
  # ==========================================
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };
  console.keyMap = "br-abnt2";
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # ==========================================
  # AMBIENTE GRÁFICO (KDE PLASMA & SDDM)
  # ==========================================
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;
  services.desktopManager.plasma6.enable = true;

  # ==========================================
  # ÁUDIO E MULTIMÍDIA (PIPEWIRE)
  # ==========================================
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ==========================================
  # SERVIÇOS DO SISTEMA (POLKIT, ZRAM, IMPRESSÃO)
  # ==========================================
  security.polkit.enable = true;
  zramSwap.enable = true;
  services.printing.enable = true;
  programs.fish.enable = true;
  services.flatpak.enable = true;

  # ==========================================
  # VARIÁVEIS DE AMBIENTE GERAIS
  # ==========================================
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    KWIN_FORCE_SOFTWARE_CURSORS = "1";
    KWIN_DRM_NO_AMS = "1";
    MESA_SHADER_CACHE_MAX_SIZE = "12G";
    GSK_RENDERER = "gl";
  };
}

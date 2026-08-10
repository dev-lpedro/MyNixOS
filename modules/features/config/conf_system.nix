# ==============================================================================
# Configurações do Sistema Operacional (Rede, Bluetooth, Nix-LD, Portais XDG)
# ==============================================================================
{ pkgs, ... }: {

  # ==========================================
  # GERENCIADOR DE REDE E RESOLUÇÃO DE DNS
  # ==========================================
  networking.networkmanager.enable = true;
  # Servidores de DNS públicos resilientes para garantir conectividade na VM e no host
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # ==========================================
  # BLUETOOTH
  # ==========================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Inicializa o adaptador Bluetooth no boot
  };
  services.blueman.enable = true; # Daemon e applet gráfico do Bluetooth para a tray

  # ==========================================
  # BATERIA
  # ==========================================
  services.upower.enable = true;

  # ==========================================
  # REGRAS DO GERENCIADOR NIX E CACHES
  # ==========================================
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "leonardo" "@wheel" ]; # Usuários com permissão para adicionar substitutores
    
    # Limites para evitar travamentos de CPU/RAM durante compilações locais
    max-jobs = 1;
    cores = 6;

    # Repositórios oficiais de binários pré-compilados
    substituters = [
      "https://cache.nixos.org"
      "https://xddxdd.cachix.org"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "xddxdd.cachix.org-1:ay1HJyNDYmlSwj5NXQG065C8LfoqqKaTNCyzeixGjf8="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # ==========================================
  # COMPATIBILIDADE COM PROJETOS LEGADOS (NIX-LD)
  # ==========================================
  # Permite executar binários dinâmicos baixados via npm, pip, cargo ou VS Code
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      openssl
      glib
    ];
  };

  # ==========================================
  # XDG DESKTOP PORTALS (Niri + KDE)
  # ==========================================
  # Permite seletores de arquivos, captura de tela e atalhos globais
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [ "kde" "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };

  # ==========================================
  # APLICATIVOS DE INFRAESTRUTURA E KDE
  # ==========================================
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin                  # Gerenciador de arquivos
    kdePackages.kate                     # Editor de texto
    kdePackages.kio-extras               # Miniaturas e integração de rede no Dolphin
    kdePackages.kdegraphics-thumbnailers # Gerador de pré-visualizações de imagem
    kdePackages.kded                     # Daemon de plano de fundo do KDE
    kdePackages.polkit-kde-agent-1       # Agente de autenticação gráfica para senhas de admin
    direnv                               # Gerenciador de ambientes virtuais automáticos
    devenv                               # Ferramenta para shells de desenvolvimento
    blueman                              # Gerenciador gráfico de dispositivos Bluetooth
  ];

  # Ativa o suporte ao direnv no shell
  programs.direnv.enable = true;
}
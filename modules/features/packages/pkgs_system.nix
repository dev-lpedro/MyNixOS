# modules/hosts/my-machine/packages/pkgs_system.nix
# ==============================================================================
# Pacotes de Sistema e Utilitários
# ==============================================================================
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Ferramentas Básicas de Terminal
    git
    git-lfs
    wget
    curl

    # Laboratório do Niri e Noctalia
    alacritty # Terminal leve
    kitty
    kdePackages.polkit-kde-agent-1 # Janelinha de senha de administrador

    # Ferramentas do sistema para os widgets do Noctalia funcionarem
    playerctl # Controlar músicas
    pamixer # Controlar volume
    brightnessctl # Controlar brilho da tela
    upower # Ler status da bateria
    wl-clipboard # Área de transferência (Ctrl+C / Ctrl+V) no Wayland
    dart-sass # Renderizar cores em alguns temas do Quickshell

    cliphist
    unzip
    pciutils
    usbutils

    gparted

    btrfs-assistant
  ];

  # Instalação declarativa de fontes do sistema
  fonts.packages = with pkgs; [
    font-awesome
    cantarell-fonts
    roboto
    material-symbols
    
    
    noto-fonts-color-emoji     # Emojis coloridos 
    nerd-fonts.symbols-only    # Fallback universal para ícones Nerd Fonts
    
    # Fontes Monospaçadas com Ícones Integrados para Código/Terminal
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code

    # Fallback de texto global
    noto-fonts
  ];
}

# modules/hosts/my-machine/packages/pkgs_system.nix
{ pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    # Ferramentas Básicas de Terminal
    git
    wget
    curl

    # Laboratório do Niri e Noctalia
    alacritty                 # Terminal leve
    kitty                     # Seu terminal configurado no Niri
    kdePackages.polkit-kde-agent-1 # Janelinha de senha de administrador

    # Ferramentas do sistema para os widgets do Noctalia funcionarem
    playerctl                 # Controlar músicas
    pamixer                   # Controlar volume
    brightnessctl             # Controlar brilho da tela
    upower                    # Ler status da bateria
    wl-clipboard              # Área de transferência (Ctrl+C / Ctrl+V) no Wayland
    dart-sass                 # Renderizar cores em alguns temas do Quickshell

    cliphist
    unzip
    pciutils
    usbutils

    # Fontes (Instalação dos binários)
    font-awesome
    cantarell-fonts
    roboto
    material-symbols


  ];

  fonts.packages = with pkgs; [
    font-awesome
    cantarell-fonts
    roboto
    material-symbols
  ];
}

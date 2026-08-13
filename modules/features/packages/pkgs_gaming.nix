# ==============================================================================
# Configuração de Jogos, Desempenho e Emuladores
# ==============================================================================
{pkgs, ...}: {
  # Pacotes de jogos, utilitários e monitoramento
  environment.systemPackages = with pkgs; [
    # Performance, HUD e Gravador
    #mangohud
    gamemode
    nvtopPackages.nvidia
    gpu-screen-recorder

    protonup-qt

    # Launchers e Emuladores
    heroic
    #dolphin-emu
    #cemu
    gamescope
  ];

  # Ativa os daemons de suporte a jogos no NixOS
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # Configuração do Steam com GE-Proton
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;

    # Injeta a versão mais recente do GE-Proton na Steam
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
}

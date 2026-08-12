# ==============================================================================
# Configuração de Jogos, Desempenho e Emuladores
# ==============================================================================
{ pkgs, ... }: {

  # Ativa o escalonador eBPF (SCX) para priorizar tarefas de jogos
  services.scx.enable = true;
  services.scx.scheduler = "scx_rusty";

  # Pacotes de jogos, utilitários e monitoramento
  environment.systemPackages = with pkgs; [
    # Performance, HUD e Gravador
    #mangohud
    gamemode
    nvtopPackages.nvidia
    gpu-screen-recorder

    # Launchers e Emuladores
    heroic
    #dolphin-emu
    #cemu
    gamescope
  ];

  # Ativa os daemons de suporte a jogos no NixOS
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
}
{ pkgs, lib, ... }: {
  # Forçamos o uso do Kernel Zen para sobrescrever o que está no conf_machine.nix
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;

  # Agendador de processos moderno (Nativo do NixOS!)
  services.scx.enable = true;
  services.scx.scheduler = "scx_rusty";

  environment.systemPackages = with pkgs; [
    # Performance & Monitoramento
    mangohud
    gamemode
    nvtopPackages.nvidia
    gpu-screen-recorder

    # Launchers & Emuladores
    heroic
    #bottles <- adicionar flatpak depois
    dolphin-emu
    cemu
    gamescope

  ];

  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
}

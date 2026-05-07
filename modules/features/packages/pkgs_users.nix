{ pkgs, ... }: {
  imports = [
    ./pkgs_dev.nix
    ./pkgs_internet.nix
    ./pkgs_media.nix
    ./pkgs_gaming.nix
  ];

  environment.systemPackages = with pkgs; [
    # ==========================================
    # LABORATÓRIO (Pacotes novos/em teste)
    # ==========================================
    fastfetch
    # Adicione novos apps aqui antes de categorizá-los
  ];
}

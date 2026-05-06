# modules/hosts/my-machine/packages/pkgs_users.nix
{ pkgs, ... }: {

  # ==========================================
  # PACOTES PESSOAIS
  # ==========================================

  users.users.leonardo.packages = with pkgs; [
    # Navegadores
    firefox

    # Desenvolvimento
    vscode

    # Edição de texto e leitura
    kdePackages.kate

    github-desktop
  ];
}

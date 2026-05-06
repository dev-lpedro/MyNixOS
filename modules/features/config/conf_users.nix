# modules/hosts/my-machine/users.nix
{ pkgs, ... }: {

  # ==========================================
  # CONFIGURAÇÃO DE USUÁRIOS
  # ==========================================

  users.users.leonardo = {
    isNormalUser = true;
    description = "Leonardo dos Santos Pedro";

    # "wheel" permite usar o sudo. "networkmanager" permite gerenciar o Wi-Fi.
    extraGroups = [ "networkmanager" "wheel" ];

    # Define o Fish como o seu terminal padrão
    shell = pkgs.fish;
  };

  # (Opcional) Se você quiser garantir que o fish seja ativado no sistema
  # para que o usuário possa usá-lo como padrão, deixe isso aqui:
  programs.fish.enable = true;
}

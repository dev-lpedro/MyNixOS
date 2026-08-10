# ==============================================================================
# Configuração de Usuários do Sistema e Permissões de Grupos
# ==============================================================================
{ pkgs, ... }: {

  # Habilita o shell Fish no nível do sistema operacional
  programs.fish.enable = true;

  # Declaração do usuário principal
  users.users.leonardo = {
    isNormalUser = true;
    description = "Leonardo";
    initialPassword = "123"; #Senha temporaria, mude com passwd
    
    # Grupos de permissões no hardware
    extraGroups = [
      "wheel"          # Acesso ao sudo
      "networkmanager" # Permissão para gerenciar conexões Wi-Fi/Rede
      "video"          # Controle da GPU e brilho da tela (brightnessctl)
      "audio"          # Controle do servidor de áudio Pipewire e volume
      "input"          # Acesso a touchpads, mouses e controles de jogos
      "gamemode"       # Permissão para acionar otimizações em jogos
    ];
    
    # Define o Fish como o shell padrão do usuário
    shell = pkgs.fish;
  };
}
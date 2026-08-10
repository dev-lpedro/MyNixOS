# ==============================================================================
# Módulo Unificador do Sistema
# Conecta as regras de hardware, pacotes globais e o ambiente de usuário.
# ==============================================================================
{ pkgs, lib, inputs, ... }: {

  imports = [
    # 1. Configurações físicas da máquina (CPU, GPU NVIDIA, Kernel CachyOS)
    ./conf_machine.nix

    # 2. Configurações de sistema, rede, Bluetooth, Nix-LD e Usuários
    ../../features/config/conf_system.nix
    ../../features/config/conf_users.nix

    # 3. Listas categorizadas de pacotes
    ../../features/packages/pkgs_system.nix
    ../../features/packages/pkgs_user.nix

    # 4. Interface gráfica Niri + Noctalia Shell + Home Manager
    ../../features/niri/niri-noctalia.nix
  ];

}
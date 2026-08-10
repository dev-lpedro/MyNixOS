# ==============================================================================
# Configurações do Hardware (Acer Nitro V15 - ANV15-51)
# Kernel CachyOS, GPU Híbrida NVIDIA Offload, Btrfs e suporte a VM.
# ==============================================================================
{ config, pkgs, lib, inputs, ... }: {

  # Identificação do computador na rede
  networking.hostName = "fakeNixOs";
  system.stateVersion = "24.11";

  # Permissão para pacotes e drivers proprietários (NVIDIA, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # ==========================================
  # SERVIÇOS DE INTEGRAÇÃO COM MÁQUINA VIRTUAL
  # ==========================================
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # ==========================================
  # BOOTLOADER E KERNEL
  # ==========================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  boot.kernelPackages = inputs.nix-cachyos-kernel.legacyPackages.${pkgs.system}.linuxPackages-cachyos-latest;

  # Escalonador eBPF para o hardware real
  services.scx.enable = true;
  services.scx.scheduler = "scx_rusty";

  # Parâmetros de desempenho e suporte DRM no Kernel
  boot.kernelParams = [
    "quiet"
    "splash"
    "transparent_hugepage=always"
    "preempt=full"
    "nvidia-drm.modeset=1"
  ];

  # Manutenção automática e verificação de erros no Btrfs
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Alternância dinâmica de perfis energéticos da CPU via D-Bus
  services.power-profiles-daemon.enable = true;

  # ==========================================
  # DRIVERS NVIDIA (Modo Híbrido/Offload)
  # ==========================================
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false; # Módulo proprietário estável para arquitetura Ampere (RTX 2050)
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # Desliga a GPU dedicada quando inativa

    prime = {
      # Modo Offload: GPU dedicada é ativada apenas quando invocada (gamemoderun)
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ==========================================
  # MODO DE TESTE EM MÁQUINA VIRTUAL (QEMU)
  # ==========================================
  virtualisation.vmVariant = {
    virtualisation.memorySize = 4096;
    virtualisation.cores = 4;

    # Desativa o SCX eBPF apenas dentro da VM
    services.scx.enable = lib.mkForce false;

    # Compartilha a pasta do repositório hospedeiro diretamente com a VM
    virtualisation.sharedDirectories.mynixos = {
      source = "/home/leonardo/MyNixOs";
      target = "/home/leonardo/MyNixOs";
    };

    # Configurações de vídeo e sessões para QEMU
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
    hardware.nvidia.modesetting.enable = lib.mkForce false;

    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
  };
}
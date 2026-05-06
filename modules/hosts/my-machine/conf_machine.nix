{ config, pkgs, ... }: {

  # ==========================================
  # IDENTIDADE DESTA MÁQUINA
  # ==========================================
  networking.hostName = "fakenix"; # Nome deste PC
  system.stateVersion = "23.11"; # Versão de quando este PC foi instalado

  # ==========================================
  # BOOTLOADER E KERNEL (Otimizado para este hardware)
  # ==========================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernelParams = [
    "quiet"
    "splash"
    "transparent_hugepage=always"
    "preempt=full"
    "nvidia-drm.modeset=1"
  ];

  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
    "kernel.nmi_watchdog" = 0;
    "net.core.netdev_max_backlog" = 4096;
    "fs.file-max" = 2097152;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # ==========================================
  # DRIVERS E HARDWARE (NVIDIA RTX 2050 + INTEL)
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
    open = false;
    nvidiaSettings = true;

    prime = {
      sync.enable = true;
      # IDs exatos das placas de vídeo desta máquina
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}

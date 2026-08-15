# ==============================================================================
# Configurações do Hardware (Acer Nitro V15 - ANV15-51)
# Kernel CachyOS, GPU Híbrida NVIDIA Offload, Btrfs e suporte a VM.
# ==============================================================================
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Identificação do computador na rede
  networking.hostName = "fakeNixOs";
  system.stateVersion = "24.11";

  # Permissão para pacotes e drivers proprietários (NVIDIA, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # ==========================================
  # ANIMAÇÃO DE BOOT (Logo NixOS + Mac-Style)
  # ==========================================
  boot.plymouth = {
    enable = true;
    theme = "mac-style";
    themePackages = [pkgs.mac-style-plymouth];
  };

  boot.initrd.kernelModules = ["i915"];

  # BOOT SILENCIOSO (Foco total na animação central)
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=0"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=0"
    "udev.log_priority=0"
    "nvidia-drm.modeset=1"
    "transparent_hugepage=madvise"
    "preempt=full"
  ];

  # ==========================================
  # BOOTLOADER E KERNEL
  # ==========================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_zen; #kernel zen
  boot.kernelModules = ["tcp_bbr"];

  # Otimizações de Kernel (Sysctl)
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0; # Corrige quedas de FPS em jogos
    "kernel.nmi_watchdog" = 0; # Economiza ciclos de CPU
    "net.core.netdev_max_backlog" = 4096;
    "fs.file-max" = 2097152;
    "net.ipv4.tcp_congestion_control" = "bbr"; # Algoritmo BBR para menor latência de rede
  };

  # ==========================================
  # VARIÁVEIS DE AMBIENTE (Shader Cache NVIDIA/Mesa)
  # ==========================================
  environment.sessionVariables = {
    # Para GPUs Intel e AMD (Mesa)
    MESA_SHADER_CACHE_MAX_SIZE = "12G";

    # Para GPUs NVIDIA (Driver Proprietário)
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # ~12 GB em Bytes
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";

    GSK_RENDERER = "gl";
  };

  # ==========================================
  # AMBIENTES DE TRABALHO E TELA DE LOGIN
  # ==========================================
  services.desktopManager.plasma6.enable = true; # KDE Plasma 6 instalado para fallback

  services.displayManager = {
    defaultSession = lib.mkForce "niri"; # Força o Niri como sessão padrão do SDDM
    sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
      theme = "catppuccin-mocha-mauve";
      settings = {
        Theme = {
          CursorTheme = "capitaine-cursors";
          CursorSize = "24";
        };
      };
    };
  };

  # Instala o tema Catppuccin, o cursor global e dependências do SDDM
  environment.systemPackages = with pkgs; [
    capitaine-cursors
    (catppuccin-sddm.override {
      flavor = "mocha";
      accent = "mauve";
      font = "Noto Sans";
    })
    kdePackages.qt5compat
    kdePackages.qtsvg
  ];

  # ==========================================
  # SERVIÇOS DE INTEGRAÇÃO COM MÁQUINA VIRTUAL
  # ==========================================
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Escalonador eBPF para o hardware real
  #services.scx.enable = true;
  #services.scx.scheduler = "scx_rusty";

  # ==========================================
  # OTIMIZAÇÕES DE DESEMPENHO E MANUTENÇÃO
  # ==========================================
  # Priorização automática de processos estilo CachyOS
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # Proteção contra congelamento por estouro de RAM
  services.earlyoom = {
    enable = true;
    freeSwapThreshold = 2;
    freeMemThreshold = 2;
    extraArgs = [
      "-g"
      "--avoid"
      "'^(X|plasma.*|konsole|kwin|wayland|gnome.*|niri.*)$'"
    ];
  };

  # Regras I/O para agendamento de armazenamento (HDD, SSD SATA e NVMe)
  services.udev = {
    enable = true;
    extraRules = ''
      # HDDs (Usa agendador BFQ)
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      # SSDs SATA (Usa mq-deadline)
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      # NVMe SSDs (Usa agendador direto 'none')
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
    '';
  };

  # Manutenção automática e verificação de erros no Btrfs
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = ["/"];
  };

  # Alternância dinâmica de perfis energéticos da CPU via D-Bus
  services.power-profiles-daemon.enable = true;

  # ==========================================
  # DRIVERS NVIDIA (Modo Híbrido/Offload)
  # ==========================================
  services.xserver.videoDrivers = ["nvidia"];

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
  # HIBERNAÇÃO E RESERVA DE MEMÓRIA
  # ==========================================
  boot.initrd.systemd.enable = true;
  powerManagement.enable = true;

  # Serviço dinâmico para reservar 1% de RAM para emergências do kernel
  systemd.services.set-min-free-mem = {
    description = "Set vm.min_free_kbytes dynamically";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    serviceConfig = {
      User = "root";
      RemainAfterExit = true;
    };
    script = ''
      TOTAL_MEM=$(${pkgs.gawk}/bin/awk '/MemTotal/ {printf "%.0f", $2 * 0.01}' /proc/meminfo)
      if [ -n "$TOTAL_MEM" ] && [ "$TOTAL_MEM" -gt 0 ]; then
        ${pkgs.sysctl}/bin/sysctl -w vm.min_free_kbytes=$TOTAL_MEM
      fi
    '';
  };

  # ==========================================
  # ZRAM (4 GB de Swap Comprimida na RAM)
  # ==========================================
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Algoritmo de compressão
    memoryPercent = 50; # 50% da RAM
    priority = 100; # Prioridade ALTA: usa a ZRAM em primeiro lugar
  };

  # ==========================================
  # SWAPFILE DE DISCO (8 GB no Btrfs)
  # ==========================================
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024; # 8 GB (8192 MB)
      priority = 10; # Prioridade BAIXA: só é usado se os 4 GB de ZRAM lotarem
    }
  ];

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
    services.xserver.videoDrivers = lib.mkForce ["modesetting"];
    hardware.nvidia.modesetting.enable = lib.mkForce false;

    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
  };
}

# ==============================================================================
# Configurações do Sistema Operacional (Rede, Bluetooth, Nix-LD, Portais XDG)
# ==============================================================================
{
  pkgs,
  inputs,
  lib,
  ...
}: {
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"]; # Define o caminho do repositório NixOS

  # ==========================================
  # VARIÁVEIS DE AMBIENTE E INTEGRAÇÃO DO NH (Nix Helper)
  # ==========================================
  # Aponta a pasta do repositório para o comando 'nh'
  environment.sessionVariables.FLAKE = "/home/leonardo/MyNixOs";

  # ==========================================
  # NIX-INDEX (Banco de Dados de Pacotes)
  # ==========================================
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true; # Integra o índice ao Shell Fish
  };

  # Ativa o wrapper oficial do comma que usa o banco de dados semanal do Flake
  programs.nix-index-database.comma.enable = true;

  # ==========================================
  # FUSO HORÁRIO E SINCRONIZAÇÃO DE TEMPO
  # ==========================================
  time.timeZone = "America/Sao_Paulo";

  # ==========================================
  # IDIOMA E LOCALIZAÇÃO (Português do Brasil)
  # ==========================================
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # ==========================================
  # TECLADO ABNT2 NO CONSOLE TTY E X11/WAYLAND
  # ==========================================
  console.keyMap = "br-abnt2";
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # ==========================================
  # SUPORTE A ÁUDIO (Pipewire + ALSA + PulseAudio)
  # ==========================================
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ==========================================
  # GERENCIADOR DE REDE E DNS
  # ==========================================
  networking.networkmanager.enable = true;
  # Servidores de DNS públicos resilientes para garantir conectividade na VM e no host
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  # ==========================================
  # MODO ESCURO GLOBAL DO SISTEMA
  # ==========================================
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "adw-gtk3-dark";
          };
        };
      }
    ];
  };

  # ==========================================
  # BLUETOOTH
  # ==========================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Inicializa o adaptador Bluetooth no boot
  };
  services.blueman.enable = true; # Daemon e applet gráfico do Bluetooth para a tray

  # ==========================================
  # BATERIA
  # ==========================================
  services.upower.enable = true;

  # ==========================================
  # SWAP DINÂMICO EM DISCO
  # ==========================================
  # Cria e apaga arquivos de swap no disco automaticamente conforme a demanda
  services.swapspace.enable = true;

  # ==========================================
  # REGRAS DO GERENCIADOR NIX E CACHES
  # ==========================================
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "leonardo" "@wheel"]; # Usuários com permissão para adicionar substitutores

    # Limites para evitar travamentos de CPU/RAM durante compilações locais
    max-jobs = 1;
    cores = 6;

    # Repositórios oficiais de binários pré-compilados
    substituters = [
      "https://cache.nixos.org"
      "https://xddxdd.cachix.org"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "xddxdd.cachix.org-1:ay1HJyNDYmlSwj5NXQG065C8LfoqqKaTNCyzeixGjf8="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # ==========================================
  # COMPATIBILIDADE COM PROJETOS LEGADOS (NIX-LD)
  # ==========================================
  # Permite executar binários dinâmicos baixados via npm, pip, cargo ou VS Code
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      openssl
      glib
    ];
  };

  # ==========================================
  # XDG DESKTOP PORTALS (Niri + KDE)
  # ==========================================
  # Permite seletores de arquivos, captura de tela e atalhos globais
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = lib.mkForce ["gnome" "gtk" "kde"];
      "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
    };
  };

  # ==========================================
  # LIMPEZA AUTOMÁTICA DE GERAÇÕES / NIX STORE
  # ==========================================
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d"; # Remove arquivos de backups com mais de 7 dias
  };
  nix.settings.auto-optimise-store = true; # Deduplica arquivos idênticos no disco Btrfs

  # ==========================================
  # DISTROBOX E PODMAN (Para projetos legados)
  # ==========================================
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Cria suporte a comandos docker
  };

  # ==========================================
  # PERMISSÕES DO BTOP PARA EXIBIR IGPU INTEL + DGPU NVIDIA
  # ==========================================
  security.wrappers.btop = {
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon+ep"; # Concede leitura do sysfs da Intel sem precisar de sudo
    source = "${pkgs.btop.override {cudaSupport = true;}}/bin/btop";
  };

  # ==========================================
  # VARIÁVEIS DE AMBIENTE PARA APPS CHROMIUM/ELECTRON
  # ==========================================
  environment.sessionVariables = {
    GTK_THEME = "adw-gtk3-dark";
    NIXOS_OZONE_WL = "1"; # Força o Equibop e apps Electron a rodarem nativamente em Wayland
  };

  # ==========================================
  # SNAPSHOTS LOCAIS AUTOMÁTICOS (Snapper)
  # ==========================================
  services.snapper = {
    snapshotInterval = "hourly"; # Frequência dos snapshots
    cleanupInterval = "1d"; # Frequência da limpeza de snapshots antigos

    configs = {
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = ["leonardo"];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;

        # Quantidade de snapshots retidos
        TIMELINE_LIMIT_HOURLY = "12"; # Mantém as últimas 12 horas
        TIMELINE_LIMIT_DAILY = "7"; # Mantém os últimos 7 dias
        TIMELINE_LIMIT_WEEKLY = "4"; # Mantém as últimas 4 semanas
        TIMELINE_LIMIT_MONTHLY = "12"; # Mantém os últimos 12 meses
      };
    };
  };

  # ==========================================
  # APLICATIVOS DE INFRAESTRUTURA E KDE
  # ==========================================
  environment.systemPackages = with pkgs; [
    nh # Nix Helper
    kdePackages.dolphin # Gerenciador de arquivos
    kdePackages.kate # Editor de texto
    kdePackages.kio-extras # Miniaturas e integração de rede no Dolphin
    kdePackages.kdegraphics-thumbnailers # Gerador de pré-visualizações de imagem
    kdePackages.kded # Daemon de plano de fundo do KDE
    kdePackages.polkit-kde-agent-1 # Agente de autenticação gráfica para senhas de admin
    direnv # Gerenciador de ambientes virtuais automáticos
    devenv # Ferramenta para shells de desenvolvimento
    blueman # Gerenciador gráfico de dispositivos Bluetooth
    distrobox # Executa distros em contêineres isolados
    podman # Motor de contêineres para o Distrobox
    (btop.override {cudaSupport = true;})
    mesa-demos
    pavucontrol

    nixd # Servidor de Linguagem Nix
    alejandra # Formatador oficial de código .nix
  ];

  # Ativa o suporte ao direnv no shell
  programs.direnv.enable = true;
}

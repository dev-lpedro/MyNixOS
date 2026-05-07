{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;

      settings = {
        # ==========================================
        # HOT RELOAD (Permanente)
        # ==========================================
        # O shell expandirá o ~/ no runtime, funcionando para qualquer usuário.
        #include = [ "~/myNixOS/modules/features/niri/imports.kdl" ];

        spawn-at-startup = [
          [ "bash" "-c" "sleep 1 && ${lib.getExe self'.packages.myNoctalia}" ]
          [ "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1" ]

          # ==========================================
          # MOTOR DO CLIPBOARD (Histórico de cópias)
          # ==========================================
          [ "bash" "-c" "wl-paste --watch cliphist store" ]
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

        # ==========================================
        # INPUTS & CURSOR
        # ==========================================
        input = {
          keyboard = {
            xkb.layout = "br";
            repeat-delay = 250;
            repeat-rate = 50;
          };
          #touchpad = {
          #  tap = true;
          #  tap-button-map = "left-right-middle";
          #  natural-scroll = true;
          #};
          #mouse = {
          #  accel-profile = "flat";
          #  natural-scroll = true;
          #};
          #mod-key = "Super";
          #mod-key-nested = "Alt";
          #workspace-auto-back-and-forth = true;
          #warp-mouse-to-focus = true;
          #focus-follows-mouse.max-scroll-amount = "5%";
        };

        cursor = {
          xcursor-theme = "capitaine-cursors-light";
          xcursor-size = 24;
          hide-when-typing = true;
        };

        # ==========================================
        # LAYOUT & VISUAIS
        # ==========================================
        layout = {
          gaps = 12;
          center-focused-column = "never";

          default-column-width.proportion = 0.5;
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];

          border = {
            width = 4;
            active-color = "#707070";
            inactive-color = "#d0d0d0";
            urgent-color = "#cc4444";
          };

          # Simplificado para cores sólidas temporariamente!
          focus-ring = {
            width = 3;
            active-color = "#D31F25";
            inactive-color = "#707070";
          };
        };

        # ==========================================
        # REGRAS DE JANELA & LAYER (Transparência)
        # ==========================================
        window-rules = [
          {
            geometry-corner-radius = 16.0;
            clip-to-geometry = true;
          }
          {
            matches = [ { is-active = false; } ];
            opacity = 0.9;
          }
        ];

        layer-rules = [
          { matches = [ { namespace = "quickshell:iiBackdrop"; } ]; place-within-backdrop = true; opacity = 1.0; }
          { matches = [ { namespace = "quickshell:wBackdrop"; } ]; place-within-backdrop = true; opacity = 1.0; }
        ];

        # ==========================================
        # ANIMAÇÕES (Sincronizadas com Noctalia)
        # ==========================================
#         animations = {
#           workspace-switch.spring = { damping-ratio = 0.78; stiffness = 600; epsilon = 0.0001; };
#           window-open.spring = { damping-ratio = 0.82; stiffness = 500; epsilon = 0.0001; };
#           window-close.spring = { damping-ratio = 0.88; stiffness = 900; epsilon = 0.0001; };
#           horizontal-view-movement.spring = { damping-ratio = 0.80; stiffness = 550; epsilon = 0.0001; };
#           window-movement.spring = { damping-ratio = 0.85; stiffness = 650; epsilon = 0.0001; };
#           window-resize.spring = { damping-ratio = 0.88; stiffness = 700; epsilon = 0.0001; };
#           config-notification-open-close.spring = { damping-ratio = 0.90; stiffness = 800; epsilon = 0.0001; };
#           screenshot-ui-open.spring = { damping-ratio = 0.85; stiffness = 750; epsilon = 0.0001; };
#         };

        # ==========================================
        # MONITORES
        # ==========================================

        outputs = {
          "LG Electronics E1941 0x01010101" = {
            mode = "1360x768@60.015";
          };
          "eDP-1" = {
            scale = 1.2;
          };
        };

        # ==========================================
        # ATALHOS DO TECLADO (Binds)
        # ==========================================
        binds = {
          # --- SISTEMA E NOCTALIA ---
          "Mod+Shift+E".quit = {};
          "Mod+Escape".toggle-keyboard-shortcuts-inhibit = {};

          # Reiniciar Noctalia (Permanent Fix)
          #"Ctrl+Super+Alt+R".spawn-sh = "pkill -f noctalia-shell; ${lib.getExe self'.packages.myNoctalia} &";

          # Menus do Noctalia (Usando IPC direto)
          "Mod+Space".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          "Mod+F1".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call shortcuts toggle";
          "Mod+Shift+Q".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call sessionMenu toggle";
          "Mod+Alt+L".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call lockScreen lock";
          "Mod+V".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher clipboard";
          "Ctrl+Shift+Escape".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call systemMonitor toggle";
          "Mod+C".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call controlCenter toggle";

          "Mod+Tab".toggle-overview = {};

          # --- ATALHOS DO FLAKE (EDIÇÃO) ---
          # Caminhos corrigidos para a nova estrutura
          "Mod+I".spawn-sh = "kate ~/myNixOS/modules/features/packages/pkgs_users.nix";
          "Mod+Shift+I".spawn-sh = "kate ~/myNixOS/modules/features/packages/pkgs_system.nix";

          # --- REBUILD AUTOMÁTICO ---
          # Mod + R = Teste (Não salva no boot)
          "Mod+R".spawn-sh = "kitty -- fish -c 'cd ~/myNixOS; git add .; sudo nixos-rebuild test --flake .#myMachine; echo \"\\n[ Teste Finalizado! ]\"; read'";

          # Mod + Shift + Ctrl + R = Switch (Torna a config padrão)
          "Mod+Shift+Control+R".spawn-sh = "kitty -- fish -c 'cd ~/myNixOS; git add .; sudo nixos-rebuild switch --flake .#myMachine; echo \"\\n[ Sistema Atualizado com Sucesso! ]\"; read'";

          # --- APLICATIVOS ---
          "Mod+T".spawn-sh = lib.getExe pkgs.kitty;
          "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
          "Super+E".spawn-sh = "dolphin";
          "Super+W".spawn-sh = "xdg-open https://google.com";

          # --- JANELAS ---
          "Mod+Q".close-window = {};
          "Mod+D".maximize-column = {};
          "Mod+F".fullscreen-window = {};
          "Mod+A".toggle-window-floating = {};

          "Mod+Left".focus-column-left = {};
          "Mod+Right".focus-column-right = {};
          "Mod+Up".focus-window-up = {};
          "Mod+Down".focus-window-down = {};

          # --- SCREENSHOTS ---
          "Print".screenshot = {};
          "Ctrl+Print".screenshot-screen = {};
          "Alt+Print".screenshot-window = {};
          # Novo: Print de área selecionada (Super + Shift + S)
          "Mod+Shift+S".screenshot = {};

          # --- AUDIO E BRILHO ---
          "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86MonBrightnessUp".spawn-sh = "brightnessctl set 5%+";
          "XF86MonBrightnessDown".spawn-sh = "brightnessctl set 5%-";

          #  --- GRAVAÇÃO E ENERGIA ---
          "Ctrl+Alt+Z".spawn-sh = "fish ~/myNixOS/modules/features/scripts/power_manager.fish --toggle";
          "Alt+C".spawn-sh = "fish ~/myNixOS/modules/features/scripts/power_manager.fish --save";
        };
      };
    };
  };
}

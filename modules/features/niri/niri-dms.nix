{ self, inputs, ... }: {

  # Este é o módulo que o seu configuration.nix vai puxar!
  flake.nixosModules.niri = { pkgs, lib, ... }: {

    # Importa o módulo oficial do DMS direto do Flake deles
    imports = [ inputs.dms.nixosModules.dank-material-shell ];

    # Ativa o DankMaterialShell
    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      enableSystemMonitoring = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableClipboardPaste = true;
    };

    # Ativa o Niri
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
        # INICIALIZAÇÃO (DMS inicia via Systemd)
        # ==========================================
        spawn-at-startup = [
          [ "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1" ]
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
          # --- SISTEMA ---
          "Mod+Shift+E".quit = {};
          "Mod+Escape".toggle-keyboard-shortcuts-inhibit = {};
          "Mod+Tab".toggle-overview = {};

          # --- DANK MATERIAL SHELL (DMS) ---
          # Estes são os comandos padrão de invocação da interface gráfica do DMS
          "Mod+Space".spawn-sh = "dms toggle launcher";
          "Mod+Shift+Q".spawn-sh = "dms toggle power";
          "Mod+Alt+L".spawn-sh = "loginctl lock-session"; # O DMS usa o lock do sistema
          "Mod+V".spawn-sh = "dms toggle clipboard";
          "Ctrl+Shift+Escape".spawn-sh = "dms toggle monitor";
          "Mod+C".spawn-sh = "dms toggle quicksettings";

          # --- ATALHOS DO FLAKE (EDIÇÃO) ---
          "Mod+I".spawn-sh = "kate ~/myNixOS/modules/features/packages/pkgs_users.nix";
          "Mod+Shift+I".spawn-sh = "kate ~/myNixOS/modules/features/packages/pkgs_system.nix";

          # --- REBUILD AUTOMÁTICO ---
          "Mod+R".spawn-sh = "kitty -- fish -c 'cd ~/myNixOS; git add .; sudo nixos-rebuild test --flake .#myMachine; echo \"\\n[ Teste Finalizado! ]\"; read'";
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

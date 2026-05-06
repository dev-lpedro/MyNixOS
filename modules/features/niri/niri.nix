{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      # Busca o pacote customizado definido abaixo
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;

      settings = {
        # ==========================================
        # HOT RELOAD
        # ==========================================
        # Nota: O uso de ~/ pode falhar no build se o wrapper validar o arquivo.
        # Se o erro "Homeless Shelter" persistir, comente a linha abaixo.
        #include = [ "/home/leonardo/myNixOS/modules/features/niri/imports.kdl" ];

        spawn-at-startup = [
          # CORREÇÃO: Strings simples, sem as chaves { command = ... }
          (lib.getExe self'.packages.myNoctalia)
          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
        input.keyboard.xkb.layout = "br";
        layout.gaps = 5;

        # ==========================================
        # CONFIGURAÇÃO DE MONITORES
        # ==========================================
        outputs = {
          "LG Electronics E1941 0x01010101" = {
            mode = "1360x768@60.015";
            #position = { x = 0; y = 0; };
          };
          "eDP-1" = {
            scale = 1.2;
            #position = { x = 1360; y = 0; };
          };
        };

        # ==========================================
        # ATALHOS DO TECLADO (Binds)
        # ==========================================
        binds = {
          # --- SISTEMA E SHELL ---
          "Mod+Shift+E".quit = {};
          "Mod+Escape".toggle-keyboard-shortcuts-inhibit = {};
          "Ctrl+Super+Alt+R".spawn-sh = "pkill qs; qs -c noctalia-shell &";
          "Mod+Alt+L".spawn-sh = "qs -c noctalia-shell ipc call lockScreen lock";
          "Mod+Space".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          "Mod+Tab".toggle-overview = {};
          "Mod+Shift+Slash".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call shortcuts toggle";

          # --- ATALHOS CUSTOMIZADOS DO FLAKE ---
          "Mod+I".spawn-sh = "kate /home/leonardo/myNixOS/modules/hosts/my-machine/packages/pkgs_users.nix";
          "Mod+Shift+I".spawn-sh = "kate /home/leonardo/myNixOS/modules/hosts/my-machine/packages/pkgs_system.nix";

          # Super + R = Rebuild automático
          "Mod+R".spawn-sh = "kitty -- fish -c 'cd ~/myNixOS; git add .; sudo nixos-rebuild switch --flake .#myMachine; echo \"\\n[ Rebuild Finalizado! Pressione ENTER para fechar ]\"; read'";

          # --- APLICATIVOS ---
          "Mod+T".spawn-sh = lib.getExe pkgs.kitty;
          "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
          "Super+E".spawn-sh = "dolphin";
          "Super+W".spawn-sh = "xdg-open https://google.com";

          # --- GERENCIAMENTO DE JANELAS ---
          "Mod+Q".close-window = {};
          "Mod+D".maximize-column = {};
          "Mod+F".fullscreen-window = {};
          "Mod+A".toggle-window-floating = {};

          "Mod+Left".focus-column-left = {};
          "Mod+Right".focus-column-right = {};
          "Mod+Up".focus-window-up = {};
          "Mod+Down".focus-window-down = {};
          "Mod+H".focus-column-left = {};
          "Mod+J".focus-window-down = {};
          "Mod+K".focus-window-up = {};
          "Mod+L".focus-column-right = {};

          "Mod+Shift+Left".move-column-left = {};
          "Mod+Shift+Right".move-column-right = {};
          "Mod+Shift+Up".move-window-up = {};
          "Mod+Shift+Down".move-window-down = {};

          # --- WORKSPACES ---
          "Mod+1".focus-workspace = 1;
          "Mod+2".focus-workspace = 2;
          "Mod+3".focus-workspace = 3;
          "Mod+4".focus-workspace = 4;
          "Mod+5".focus-workspace = 5;

          "Mod+Shift+1".move-column-to-workspace = 1;
          "Mod+Shift+2".move-column-to-workspace = 2;
          "Mod+Shift+3".move-column-to-workspace = 3;
          "Mod+Shift+4".move-column-to-workspace = 4;
          "Mod+Shift+5".move-column-to-workspace = 5;

          # --- SCREENSHOTS ---
          "Print".screenshot = {};
          "Ctrl+Print".screenshot-screen = {};
          "Alt+Print".screenshot-window = {};

          # --- SCRIPTS ---
          "Ctrl+Alt+Z".spawn-sh = "fish /home/leonardo/myNixOS/modules/features/scripts/power_manager.fish --toggle";
          "Alt+C".spawn-sh = "fish /home/leonardo/myNixOS/modules/features/scripts/power_manager.fish --save";

          # --- TECLAS DE HARDWARE ---
          "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86MonBrightnessUp".spawn-sh = "brightnessctl set 5%+";
          "XF86MonBrightnessDown".spawn-sh = "brightnessctl set 5%-";
          "XF86AudioPlay".spawn-sh = "playerctl play-pause";
          "XF86AudioNext".spawn-sh = "playerctl next";
          "XF86AudioPrev".spawn-sh = "playerctl previous";
        };
      };
    };
  };
}

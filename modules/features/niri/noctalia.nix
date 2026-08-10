{ pkgs, config, inputs, ... }: {

  # ==========================================
  # CONFIGURAÇÕES DA NOCTALIA SHELL VIA HOME MANAGER
  # ==========================================
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };

    users.leonardo = { config, ... }: {
      home.stateVersion = "24.11";

      # Link simbólico dinâmico da pasta de configurações e temas da Noctalia
      xdg.configFile."noctalia" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/niri/cfg_noctalia";
        force = true;
      };

      # Link de compatibilidade caso a v4 busque por ~/.config/noctalia-shell
      xdg.configFile."noctalia-shell" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/niri/cfg_noctalia";
        force = true;
      };

      # Pacotes e executáveis da Noctalia Shell
      home.packages = [
        # Noctalia v4 oficial do Nixpkgs (Comando: noctalia-shell)
        pkgs.noctalia-shell

        # Wrapper para testes da Noctalia v5 (Comando: noctalia-v5)
        (pkgs.writeShellScriptBin "noctalia-v5" ''
          exec ${inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia "$@"
        '')

        # Compilador CSS necessário para renderizar temas de widgets
        pkgs.dart-sass
      ];
    };
  };
}
{
  pkgs,
  config,
  inputs,
  ...
}: {
  # Instala o VSCodium e VS Code no sistema
  environment.systemPackages = with pkgs; [
    vscodium
    vscode
    nixd
    alejandra
  ];

  # Mapeia as configurações do VS Code e VSCodium via Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};

    users.leonardo = {config, ...}: {
      home.stateVersion = "24.11";

      xdg.configFile."VSCodium/User/settings.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/editor/cfg_vscode/settings.json";
        force = true;
      };

      xdg.configFile."Code/User/settings.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/editor/cfg_vscode/settings.json";
        force = true;
      };
    };
  };
}

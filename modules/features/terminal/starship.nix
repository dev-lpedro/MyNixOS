{
  pkgs,
  config,
  inputs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};

    users.leonardo = {config, ...}: {
      xdg.configFile."starship.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/terminal/cfg_starship/startship.toml";
        force = true;
      };

      # Pacote do Starship
      home.packages = [pkgs.starship];
    };
  };
}

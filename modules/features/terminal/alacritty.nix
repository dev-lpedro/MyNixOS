{ pkgs, config, inputs, ...}: {
  home-manager= { 
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};

    users.leonardo = {config, ...}: {
      home.stateVersion = "24.11";
      
      xdg.configFile."alacritty" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/leonardo/MyNixOs/modules/features/terminal/cfg_alacritty";
        force = true;
      };

      home.packages = [pkgs.alacritty];
    };
  };
}
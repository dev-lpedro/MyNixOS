{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    niri.url = "github:YaLTeR/niri";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Mantivemos a URL aqui só para o seu arquivo flake.lock não reclamar
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} {

    # Aqui nós listamos manualmente SÓ os arquivos que conversam com o Flake!
    # Os arquivos puros do NixOS ficam de fora daqui.
    imports = [
      ./modules/parts.nix
      ./modules/hosts/my-machine/default.nix
      ./modules/hosts/my-machine/configuration.nix
      ./modules/features/niri/niri.nix
      ./modules/features/niri/noctalia.nix
    ];

  };
}

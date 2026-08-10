# ==============================================================================
# Flake Principal do Repositório MyNixOs
# Responsável por definir os canais, repositórios de kernel, Niri e Noctalia.
# ==============================================================================
{
  description = "Configuração declarativa NixOS com Niri, Noctalia Shell e Otimizações CachyOS";

  # Caches de binários confiáveis (Evita compilação de pacotes pesados no processador)
  nixConfig = {
    extra-substituters = [
      "https://xddxdd.cachix.org"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "xddxdd.cachix.org-1:ay1HJyNDYmlSwj5NXQG065C8LfoqqKaTNCyzeixGjf8="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Repositórios e fontes de código de software (Inputs)
  inputs = {
    # Canal principal de pacotes (NixOS Unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Framework para organizar flakes de forma modular
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    # Gerenciador declarativo de ambiente de usuário
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake do Compositor Niri Wayland
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Kernel otimizado com LTO/BORE do CachyOS (Branch release para cache pré-compilado)
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Noctalia v5 (Branch 'cachix' para testes)
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    # Noctalia v4 (Branch 'legacy-v4' para uso estável)
    noctalia-v4 = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
    };
  };

  # Ponto de saída da configuração
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Arquitetura suportada
      systems = [ "x86_64-linux" ];

      # Módulos internos do repositório
      imports = [
        ./modules/parts.nix
        ./modules/hosts/my-machine/default.nix
      ];
    };
}
# ==============================================================================
# Configuração Declarativa de Particionamento e Subvolumes Btrfs (Disko)
# ==============================================================================
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Nome padrão do dispositivo (pode ser sobrescrito via CLI se for um HD externo/SATA)
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # 1. Partição EFI de Boot (FAT32 / 512 MB)
            ESP = {
              priority = 1;
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077"];
              };
            };
            # 2. Partição Principal Btrfs (Restante do espaço)
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Força a formatação
                # Estrutura de subvolumes Btrfs com compressão ZSTD
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

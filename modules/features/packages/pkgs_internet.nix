{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    firefox
    obsidian
    qbittorrent
    libreoffice-fresh
    equibop
  ];
}

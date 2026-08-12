{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gimp
    krita
    vlc
    #mpv
    audacity
    #obs-studio
    #upscayl
  ];
}

{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    vscode
    #netbeans
    #dbeaver-bin
    #mysql-workbench
    #pgmodeler
    #github-desktop
  ];
}

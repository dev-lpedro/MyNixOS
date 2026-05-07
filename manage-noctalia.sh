#!/usr/bin/env bash

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🌌 Noctalia Environment Manager${NC}"
echo "-------------------------------------"
echo "1) Testar (Sessão temporária no Plasma)"
echo "2) Instalar (Adicionar ao menu de Login)"
echo "3) Remover (Limpar tudo do sistema)"
echo "4) Sair"
read -p "Escolha uma opção: " opt

case $opt in
  1)
    echo -e "${GREEN}🚀 Iniciando simulação temporária...${NC}"
    TEMP_DIR=$(mktemp -d -t noctalia-XXXXXX)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    cp ./modules/features/niri/noctalia-config.kdl "$TEMP_DIR/config.kdl"
    nix run --extra-experimental-features "nix-command flakes" github:YaLTeR/niri -- -c "$TEMP_DIR/config.kdl"
    ;;

  2)
    echo -e "${GREEN}📦 Instalando Noctalia como segunda opção...${NC}"
    mkdir -p ~/.config/niri
    cp ./modules/features/niri/noctalia-config.kdl ~/.config/niri/config.kdl
    
    DESKTOP_FILE="/usr/share/wayland-sessions/niri-noctalia.desktop"
    
    echo -e "${BLUE}🔐 Solicitando permissão para adicionar ao menu de login...${NC}"
    sudo bash -c "cat > $DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Niri (Noctalia)
Comment=Sessão Niri customizada pelo Leonardo
Exec=nix run --extra-experimental-features 'nix-command flakes' github:YaLTeR/niri
Type=Application
DesktopNames=niri
EOF
    echo -e "${GREEN}✅ Instalado! Agora você pode selecionar 'Niri (Noctalia)' na tela de login.${NC}"
    ;;

  3)
    echo -e "${RED}🗑️ Removendo Noctalia do sistema...${NC}"
    rm -rf ~/.config/niri
    if [ -f /usr/share/wayland-sessions/niri-noctalia.desktop ]; then
        sudo rm /usr/share/wayland-sessions/niri-noctalia.desktop
    fi
    echo -e "${GREEN}✨ Noctalia removido. O Nix continua intacto.${NC}"
    ;;

  *)
    echo "Saindo..."
    exit 0
    ;;
esac

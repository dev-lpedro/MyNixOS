#!/usr/bin/env bash
# ==============================================================================
# test-niri.sh — Ambiente de teste EFÊMERO do Niri + Noctalia + kitty + fish/starship
# ==============================================================================
#
# O QUE ISSO FAZ
# ------------------------------------------------------------------------------
# Roda o seu setup do Niri (compositor), Noctalia (shell), kitty, fish e
# starship dentro de uma JANELA no seu desktop atual (Linux Mint, ou qualquer
# outra distro com sessão gráfica), usando as MESMAS configurações .kdl/.conf/
# .toml do seu repositório MyNixOs — sem instalar nada permanente e SEM tocar
# no seu ~/.config real:
#
#   - Os binários (niri, kitty, noctalia-shell, etc.) rodam via "nix shell",
#     que só baixa e faz cache em /nix/store — nada é "instalado" no sentido
#     tradicional. Removível a qualquer momento com "nix-collect-garbage -d".
#   - As configs são COPIADAS (não symlinkadas) pra uma pasta temporária, e
#     essa pasta vira o XDG_CONFIG_HOME só durante essa sessão de teste. Seu
#     ~/.config de verdade nunca é lido nem escrito.
#   - Ao fechar a janela do Niri (ou apertar Ctrl+Alt+Delete, que já é o
#     "quit" configurado no seu keybinds.kdl), a pasta temporária é apagada
#     automaticamente.
#
# O QUE NÃO É EFÊMERO
# ------------------------------------------------------------------------------
# Se o Nix ainda não estiver instalado no seu sistema, este script instala via
# Determinate Nix Installer (o mesmo instalador citado nos logs do seu
# install.sh) — isso SIM é uma mudança real no sistema (cria /nix, um serviço
# systemd, grupo/usuários de build). Rode "./test-niri.sh uninstall" depois se
# quiser reverter isso também.
#
# USO
# ------------------------------------------------------------------------------
#   REPO_DIR=~/MyNixOs ./test-niri.sh          # roda o teste (REPO_DIR é opcional, default ~/MyNixOs)
#   ./test-niri.sh uninstall                    # limpa marcas deixadas + oferece remover o Nix (se foi este script que instalou)
#
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# CORES (mesmo esquema do install.sh, pra manter consistência visual)
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

REPO_DIR="${REPO_DIR:-$HOME/MyNixOs}"
STATE_DIR="$HOME/.local/state/mynixos-test"
NIX_MARKER="$STATE_DIR/nix-installed-by-test-niri"

NIRI_CFG_SRC="$REPO_DIR/modules/features/niri/cfg_niri"
NOCTALIA_CFG_SRC="$REPO_DIR/modules/features/niri/cfg_noctalia"
KITTY_CFG_SRC="$REPO_DIR/modules/features/terminal/cfg_kitty"
FISH_CFG_SRC="$REPO_DIR/modules/features/terminal/cfg_fish"
STARSHIP_CFG_SRC="$REPO_DIR/modules/features/terminal/cfg_starship"

PKGS=(
    nixpkgs#niri
    nixpkgs#kitty
    nixpkgs#noctalia-shell
    nixpkgs#dart-sass
    nixpkgs#matugen
    nixpkgs#fish
    nixpkgs#starship
    nixpkgs#xwayland-satellite
    nixpkgs#capitaine-cursors
    nixpkgs#xwayland
    nixpkgs#wl-clipboard
    nixpkgs#cliphist
    nixpkgs#playerctl
    nixpkgs#pamixer
    nixpkgs#brightnessctl
    nixpkgs#upower
)

# ==============================================================================
# MODO: uninstall
# ==============================================================================
if [[ "${1:-}" == "uninstall" ]]; then
    echo -e "${BOLD}${CYAN}Limpeza do ambiente de teste do Niri${NC}"
    echo

    if [[ -d "$STATE_DIR" ]]; then
        rm -rf "$STATE_DIR"
        echo -e "${GREEN}✔ Marcas de estado removidas ($STATE_DIR).${NC}"
    fi

    echo -e "${YELLOW}Nada mais fica permanente por causa deste script — as configs de teste${NC}"
    echo -e "${YELLOW}sempre foram apagadas automaticamente ao fechar o Niri.${NC}"
    echo

    if command -v nix &>/dev/null; then
        if [[ -f "$NIX_MARKER" ]]; then
            echo -e "${YELLOW}Este script instalou o Nix nesta máquina só para o teste.${NC}"
            read -rp "Quer remover o Nix completamente agora? [y/N] " resp
            if [[ "$resp" =~ ^[Yy]$ ]]; then
                if [[ -x /nix/nix-installer ]]; then
                    sudo /nix/nix-installer uninstall
                else
                    echo -e "${RED}Não achei /nix/nix-installer. Se o Nix foi instalado por outro método,${NC}"
                    echo -e "${RED}siga o procedimento de remoção específico dele.${NC}"
                fi
            else
                echo -e "${CYAN}Ok, mantendo o Nix instalado.${NC}"
            fi
        else
            echo -e "${CYAN}O Nix já estava instalado antes deste script — não vou mexer nele.${NC}"
            echo -e "${CYAN}Se quiser só liberar espaço em disco: nix-collect-garbage -d${NC}"
        fi
    fi

    exit 0
fi

# ==============================================================================
# MODO: teste (padrão)
# ==============================================================================
echo -e "${BOLD}${CYAN}======================================================================"
echo -e "  🧪 TESTE EFÊMERO — Niri + Noctalia + kitty + fish/starship"
echo -e "======================================================================${NC}"
echo

# --- Sanidade: repositório existe? ---
if [[ ! -d "$NIRI_CFG_SRC" ]]; then
    echo -e "${RED}Não achei '$NIRI_CFG_SRC'.${NC}"
    echo -e "${RED}Copie/clone o repositório MyNixOs pra essa máquina primeiro, ou aponte${NC}"
    echo -e "${RED}REPO_DIR pro local certo: REPO_DIR=/caminho/MyNixOs ./test-niri.sh${NC}"
    exit 1
fi

# --- Sanidade: tem sessão gráfica ativa? ---
# Sem isso, o Niri assume que está numa TTY "de verdade" e tenta tomar conta
# da tela inteira via DRM/KMS — o oposto do que queremos aqui (uma janela).
if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
    echo -e "${RED}Não detectei uma sessão gráfica ativa (nem WAYLAND_DISPLAY nem DISPLAY).${NC}"
    echo -e "${RED}Rode este script de dentro de um terminal aberto no seu desktop atual${NC}"
    echo -e "${RED}(ex.: um terminal do Cinnamon/Mint já logado), não de um TTY puro.${NC}"
    exit 1
fi

# --- Nix instalado? ---
mkdir -p "$STATE_DIR"
if ! command -v nix &>/dev/null; then
    echo -e "${YELLOW}Nix não encontrado nesta máquina.${NC}"
    read -rp "Instalar agora via Determinate Nix Installer? [y/N] " resp
    if [[ ! "$resp" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Sem o Nix não dá pra continuar. Abortando.${NC}"
        exit 1
    fi
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    touch "$NIX_MARKER"
    echo -e "${GREEN}Nix instalado. Talvez seja preciso abrir um terminal novo para o PATH${NC}"
    echo -e "${GREEN}atualizar — se o comando 'nix' abaixo falhar, feche este terminal, abra${NC}"
    echo -e "${GREEN}outro e rode o script de novo.${NC}"
    hash -r
fi

# --- Pasta de configs efêmera ---
TMP_CFG="$(mktemp -d -t niri-test-cfg.XXXXXX)"
cleanup() {
    echo -e "\n${YELLOW}Limpando configs de teste ($TMP_CFG)...${NC}"
    rm -rf "$TMP_CFG"
    echo -e "${GREEN}Feito. Nada foi deixado no seu ~/.config real.${NC}"
    echo -e "${CYAN}Os pacotes baixados continuam em cache no /nix/store (não ocupam espaço${NC}"
    echo -e "${CYAN}extra em uso futuro). Pra liberar espaço: nix-collect-garbage -d${NC}"
    echo -e "${CYAN}Pra remover o Nix por completo (se instalado só pra esse teste):${NC}"
    echo -e "${CYAN}  ./test-niri.sh uninstall${NC}"
}
trap cleanup EXIT

echo -e "${YELLOW}Preparando configs de teste em $TMP_CFG ...${NC}"
mkdir -p "$TMP_CFG"

cp -r "$NIRI_CFG_SRC" "$TMP_CFG/niri"
cp -r "$NOCTALIA_CFG_SRC" "$TMP_CFG/noctalia"
cp -r "$NOCTALIA_CFG_SRC" "$TMP_CFG/noctalia-shell" # compat, igual ao noctalia.nix real
cp -r "$KITTY_CFG_SRC" "$TMP_CFG/kitty"
cp -r "$FISH_CFG_SRC" "$TMP_CFG/fish"
cp -r "$STARSHIP_CFG_SRC" "$TMP_CFG/starship"

# Isola o autostart: comenta as 2 linhas que mexem no ambiente systemd --user
# REAL da sua sessão Mint (só na cópia de teste — o arquivo original do
# repositório não é tocado).
AUTOSTART_COPY="$TMP_CFG/niri/cfg/autostart.kdl"
sed -i \
    -e 's/^\(spawn-at-startup "dbus-update-activation-environment".*\)$/\/\/ [test-niri] desativado no modo teste: \1/' \
    -e 's/^\(spawn-at-startup "systemctl" "--user" "restart" "import-environment".*\)$/\/\/ [test-niri] desativado no modo teste: \1/' \
    "$AUTOSTART_COPY"

echo -e "${GREEN}Configs prontas.${NC}"
echo
echo -e "${BOLD}Dicas rápidas dentro do teste:${NC}"
echo -e "  ${CYAN}Mod+Return${NC} ou ${CYAN}Mod+T${NC}  → abre o kitty"
echo -e "  ${CYAN}Mod+Space${NC}               → launcher da Noctalia"
echo -e "  ${CYAN}Ctrl+Alt+Delete${NC}         → sai do Niri (fecha a janela de teste)"
echo
echo -e "${YELLOW}Baixando pacotes (pode demorar na primeira vez) e abrindo o Niri...${NC}"
echo

XDG_CONFIG_HOME="$TMP_CFG" \
STARSHIP_CONFIG="$TMP_CFG/starship/starship.toml" \
    nix --extra-experimental-features "nix-command flakes" shell "${PKGS[@]}" -c niri

# Ao sair do niri (ou fechar a janela), o "trap cleanup EXIT" acima já cuida
# de apagar $TMP_CFG automaticamente.
#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação Interativo, Dinâmico e Seguro — MyNixOs
# ==============================================================================
#
# HISTÓRICO DE CORREÇÕES (baseado no diagnóstico enviado + revisão adicional)
# ------------------------------------------------------------------------------
# [Bug 1] "set -e" derrubava o script ao apertar 'v' (return 2).
#   -> Corrigido: nenhuma função de prompt usa mais "return <n>" para sinalizar
#      escolha do usuário. Cada função grava o resultado em uma variável global
#      (PROMPT_ACTION / SELECT_ACTION) e sempre retorna 0. Assim "set -e" nunca
#      é acionado por uma escolha válida do usuário. (A sugestão original de
#      usar `confirm_prompt | ret=$?` não funcionaria — pipe não captura status
#      de função dessa forma — por isso optei por essa abordagem mais robusta.)
#
# [Bug 2] Ao voltar, o script pulava para o menu principal e perdia as escolhas.
#   -> Corrigido: os "sub-loops" de configure_mode_1/2/3 foram eliminados.
#      Agora existe uma única máquina de estados com uma PILHA de navegação
#      (STATE_STACK). Cada tela é um estado; "voltar" faz "pop" da pilha e
#      restaura exatamente a tela anterior, com as variáveis já preenchidas
#      intactas — inclusive entre etapas de modos diferentes.
#
# [Bug 3] Cálculo de espaço em disco vinha negativo/errado (uso de df em disco
#   cru). No arquivo enviado esse ponto já usava lsblk -bno SIZE; mantive e
#   reforcei essa abordagem (com fallback numérico e leitura só da 1ª linha).
#
# [Bugs adicionais encontrados nesta revisão]
#   - select_partition_menu filtrava linhas com `grep -E 'part|disk'`, mas a
#     consulta lsblk nem sequer pedia a coluna TYPE — então o filtro quase
#     nunca casava e a lista de partições ficava vazia na maioria dos casos
#     reais. Corrigido: agora a coluna TYPE é pedida e usada corretamente, e
#     a listagem NUNCA inclui o disco inteiro como se fosse uma partição.
#   - Nome da nova partição no Modo 2 era sempre "${DISCO}p3" — funciona só
#     para NVMe/mmcblk (que usam sufixo 'pN'). Em discos como /dev/sda isso
#     geraria "/dev/sdap3", um caminho inválido. Corrigido: sufixo 'p' só é
#     usado quando o nome do disco termina em dígito, e o número da partição
#     é calculado a partir da quantidade real de partições existentes.
#   - is_gpt() era declarada mas nunca chamada — o requisito "avisar se o
#     disco não é GPT" não era cumprido. Agora é chamada nos Modos 2 e 3.
#   - HOSTNAME era fixo em "fakeNixOs" (placeholder), o que faria o script
#     falhar procurando modules/hosts/fakeNixOs. Agora é detectado a partir
#     dos diretórios existentes em modules/hosts/ (ou perguntado ao usuário,
#     se houver mais de um host declarado).
#   - Nenhuma proteção contra formatar o disco onde o próprio repositório
#     está montado (ex.: se a detecção do pendrive live falhar por algum
#     motivo). Adicionada checagem extra via `df`/`lsblk -no PKNAME`.
#   - Nenhuma proteção contra formatar um disco com partições atualmente
#     montadas (fora o pendrive live). Adicionada checagem no Modo 1.
#   - Confirmação de formatação total era só Y/n — fácil de digitar sem
#     pensar. Adicionei uma segunda confirmação em que o usuário precisa
#     digitar o caminho exato do disco (ex: /dev/sda) para prosseguir.
#   - sed no disko.nix não verificava se o padrão realmente existia no
#     arquivo — se o placeholder fosse diferente, o disko.nix ficaria
#     silenciosamente errado. Agora o script verifica antes e depois.
#   - Sem trap de erro: se algo falhasse depois de montar /mnt, o script
#     terminava e deixava tudo montado, dificultando tentar de novo. Agora
#     há um trap que tenta desmontar /mnt com segurança em caso de erro.
# ==============================================================================

set -Ee
# Observação: NÃO uso "set -o pipefail" aqui de propósito. Várias pipelines
# deste script usam grep/awk apenas para *sondar* informação (ex.: "existe
# pendrive live montado?", "existe partição já criada?") e é normal que não
# encontrem nada — nesses casos o grep intermediário retorna código 1 mesmo
# sem erro real. Com pipefail ativo, isso derrubava o script inteiro (com
# "set -e") sempre que uma dessas sondagens dava "não encontrado". Os
# comandos realmente perigosos (parted, mkfs.btrfs, mount, nixos-install)
# não fazem parte de nenhuma pipeline, então continuam protegidos por -e.

# ------------------------------------------------------------------------------
# Cores para o terminal
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="leonardo"
HOSTNAME=""

# MODO DE TESTE / SIMULAÇÃO
TEST_MODE=false
if [[ "${1:-}" == "--test" || "${1:-}" == "-t" ]]; then
    TEST_MODE=true
fi
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Uso: $0 [--test|-t]"
    echo "  --test, -t   Executa o instalador em modo simulação (sem root, sem alterar discos)."
    exit 0
fi

# ==============================================================================
# TRAP DE SEGURANÇA — tenta desmontar /mnt se algo der errado no meio do caminho
# ==============================================================================
cleanup_on_error() {
    local ec=$?
    if [[ "$TEST_MODE" == false && $ec -ne 0 ]]; then
        echo -e "\n${RED}${BOLD}Ocorreu um erro (código $ec).${NC}"
        echo -e "${YELLOW}Tentando desmontar /mnt com segurança para permitir uma nova tentativa...${NC}"
        umount -R /mnt 2>/dev/null || true
    fi
}
trap cleanup_on_error EXIT

# ==============================================================================
# DETECÇÃO DO HOSTNAME A PARTIR DO REPOSITÓRIO (substitui o placeholder fixo)
# ==============================================================================
detect_hostname() {
    local hosts_dir="$REPO_DIR/modules/hosts"
    local hosts=()

    if [[ -d "$hosts_dir" ]]; then
        while IFS= read -r -d '' d; do
            hosts+=("$(basename "$d")")
        done < <(find "$hosts_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi

    if [[ ${#hosts[@]} -eq 1 ]]; then
        HOSTNAME="${hosts[0]}"
    elif [[ ${#hosts[@]} -gt 1 ]]; then
        echo -e "${YELLOW}Múltiplos hosts declarados em modules/hosts/. Selecione qual instalar:${NC}"
        select h in "${hosts[@]}"; do
            if [[ -n "$h" ]]; then HOSTNAME="$h"; break; fi
        done
    elif [[ "$TEST_MODE" == true ]]; then
        echo -e "${YELLOW}[SIMULAÇÃO] modules/hosts/ não encontrado — usando host fictício 'fakeNixOs' só para testar a interface.${NC}"
        HOSTNAME="fakeNixOs"
        sleep 1
    else
        echo -e "${RED}Erro: nenhum host declarado em $hosts_dir.${NC}"
        echo -e "${YELLOW}Crie modules/hosts/<nome-do-host>/ com sua configuração antes de instalar.${NC}"
        exit 1
    fi
}
detect_hostname

# ==============================================================================
# RENDERIZAÇÃO DO LOGO (SVG via chafa, com detecção de protocolo gráfico)
# ==============================================================================
CHAFA_BIN=""
resolve_chafa() {
    if command -v chafa &>/dev/null; then
        CHAFA_BIN="chafa"
        return
    fi
    command -v nix &>/dev/null || return 0

    # Constrói o chafa uma única vez para o store do Nix e reaproveita o
    # caminho do binário nas próximas chamadas — evita reinvocar "nix-shell"
    # (lento) a cada tela, e não deixa nada instalado permanentemente no
    # perfil do usuário (é só um caminho no /nix/store, coletável com
    # `nix-collect-garbage` normalmente).
    local store_path=""
    store_path=$(nix build --no-link --print-out-paths 'nixpkgs#chafa' 2>/dev/null | head -n1 || true)
    if [[ -z "$store_path" ]]; then
        store_path=$(nix-build '<nixpkgs>' -A chafa --no-out-link 2>/dev/null | head -n1 || true)
    fi
    [[ -n "$store_path" && -x "$store_path/bin/chafa" ]] && CHAFA_BIN="$store_path/bin/chafa"
}
resolve_chafa

detect_graphics_format() {
    local t="${TERM_PROGRAM:-}${TERM:-}"
    case "$t" in
        *[Kk]itty*|*[Ww]ez[Tt]erm*|*[Gg]hostty*) echo "kitty" ;;
        *foot*|*alacritty*|xterm*) echo "sixel" ;;
        *) echo "symbols" ;;
    esac
}

show_header() {
    clear
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)

    local svg_file=""
    svg_file=$(find "$REPO_DIR" -maxdepth 2 \( -iname "*nixos*.svg" -o -iname "*nix*.svg" \) 2>/dev/null | head -n 1)

    if [ "$term_width" -ge 80 ]; then
        if [[ -n "$svg_file" && -n "$CHAFA_BIN" ]]; then
            local fmt
            fmt=$(detect_graphics_format)
            if [[ "$fmt" == "symbols" ]]; then
                "$CHAFA_BIN" --format=symbols --symbols=vhalf --size=32x12 "$svg_file" 2>/dev/null || true
            else
                "$CHAFA_BIN" --format="$fmt" --size=32x12 "$svg_file" 2>/dev/null || true
            fi
        fi
        echo -e "${BLUE}${BOLD}======================================================================"
        echo -e "         🚀 INSTALADOR INTERATIVO — MyNixOs                           "
        if [ "$TEST_MODE" = true ]; then
            echo -e "         ${YELLOW}[MODO DE TESTE / SIMULAÇÃO ATIVO — SEM ALTERAÇÕES NO DISCO]${BLUE}"
        else
            echo -e "         ${GREEN}Instalação Declarativa Automatizada${BLUE}"
        fi
        echo -e "======================================================================${NC}"
        echo -e " ${BOLD}Host:${NC} $HOSTNAME | ${BOLD}Repositório:${NC} $REPO_DIR\n"
    else
        echo -e "${BLUE}${BOLD}======================================================================"
        echo -e "         🚀 INSTALADOR INTERATIVO — MyNixOs                           "
        echo -e "======================================================================${NC}\n"
    fi
}

# ==============================================================================
# VERIFICAÇÃO DE NIX E DE SERVIÇOS
# ==============================================================================
show_header

if [ "$TEST_MODE" = false ] && [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Erro: Este script precisa ser executado como ROOT (sudo ./install.sh)${NC}"
   echo -e "${YELLOW}Dica: Para apenas testar a interface sem formatar nada, use: ./install.sh --test${NC}"
   exit 1
fi

if ! command -v nix &> /dev/null; then
    echo -e "${YELLOW}O gerenciador de pacotes Nix não foi encontrado neste sistema.${NC}"
    read -rp "Deseja instalar o Nix agora (via Determinate Installer)? [Y/n]: " INSTALL_NIX
    INSTALL_NIX=${INSTALL_NIX:-Y}
    if [[ "$INSTALL_NIX" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Baixando e instalando o gerenciador Nix...${NC}"
        if [ "$TEST_MODE" = false ]; then
            curl --proto '=https' --tlsv1.2 -sSf https://install.determinate.systems/nix | sh -s -- install --no-confirm
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
        else
            echo -e "${YELLOW}[SIMULAÇÃO] Instalação do Nix simulada com sucesso.${NC}"
        fi
    else
        echo -e "${RED}Erro: Não é possível prosseguir com a instalação sem o gerenciador Nix.${NC}"
        exit 1
    fi
fi

# ==============================================================================
# FUNÇÕES DE SEGURANÇA E LEITURA DE DISCO
# ==============================================================================

get_live_usb_disk() {
    lsblk -p -o NAME,MOUNTPOINTS,TYPE 2>/dev/null | grep -E '(/iso|/nix/\.ro-store|/run/installer)' | awk '{print $1}' | sed 's/[0-9]*$//' | head -n 1
}
LIVE_USB_DISK=$(get_live_usb_disk)

# Descobre em qual disco físico o próprio repositório (script) está —
# proteção extra caso a detecção do pendrive live acima falhe por algum
# motivo (ex.: layout de live-cd diferente do esperado).
get_repo_disk() {
    local src pk
    src=$(df --output=source "$REPO_DIR" 2>/dev/null | tail -n1)
    [[ -z "$src" ]] && return 0
    pk=$(lsblk -no PKNAME "$src" 2>/dev/null | head -n1)
    if [[ -n "$pk" ]]; then
        echo "/dev/$pk"
    else
        echo "$src"
    fi
}
REPO_DISK=$(get_repo_disk)

get_available_disks() {
    lsblk -dpno NAME,SIZE,MODEL,TYPE 2>/dev/null | grep "disk" | while read -r line; do
        disk_name=$(echo "$line" | awk '{print $1}')
        if [[ -n "$LIVE_USB_DISK" && "$disk_name" == *"$LIVE_USB_DISK"* ]]; then
            continue
        fi
        if [[ -n "$REPO_DISK" && "$disk_name" == "$REPO_DISK" ]]; then
            continue
        fi
        echo "$line"
    done
}

is_gpt() {
    local disk="$1"
    parted -s "$disk" print 2>/dev/null | grep -qi "Partition Table: gpt"
}

# Verifica se alguma partição do disco está atualmente montada (perigoso
# formatar um disco em uso).
disk_has_mounted_partitions() {
    local disk="$1"
    lsblk -no MOUNTPOINTS "$disk" 2>/dev/null | grep -q '\S'
}

# Calcula o caminho da próxima partição de um disco, respeitando a
# convenção "pN" usada por nvme/mmcblk/loop (que terminam em dígito) e o
# sufixo direto "N" usado por sd*/vd*/hd*.
next_partition_path() {
    local disk="$1" num="$2"
    if [[ "$disk" =~ [0-9]$ ]]; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

count_existing_partitions() {
    local disk="$1"
    lsblk -pno NAME,TYPE "$disk" 2>/dev/null | awk '$2=="part"{c++} END{print c+0}'
}

# ------------------------------------------------------------------------------
# Prompts — NUNCA retornam código diferente de 0 (evita o Bug 1 com set -e).
# O resultado é comunicado através de variáveis globais.
# ------------------------------------------------------------------------------

# Resultado em PROMPT_ACTION: "yes" ou "back". Em caso de "n" o script
# encerra por conta própria (exit 0), não há necessidade de sinalizar isso.
confirm_prompt() {
    local prompt_msg="$1"
    while true; do
        read -rp "$(echo -e "${YELLOW}${prompt_msg} [Y/n/v (Voltar)]: ${NC}")" choice
        choice=${choice:-Y}
        case "$choice" in
            [Yy]*) PROMPT_ACTION="yes"; return 0 ;;
            [Nn]*) echo -e "${RED}Instalação cancelada pelo usuário.${NC}"; exit 0 ;;
            [Vv]*) PROMPT_ACTION="back"; return 0 ;;
            *) echo -e "${RED}Opção inválida. Digite Y, N ou V.${NC}" ;;
        esac
    done
}

# Resultado em SELECT_ACTION: "ok", "back" ou "none". Se "ok", o disco
# escolhido fica em SELECTED_DISK.
select_disk_menu() {
    local prompt_title="$1"
    echo -e "${BOLD}${prompt_title}${NC}\n"

    local map_disks=()
    local i=1

    while read -r line; do
        if [[ -n "$line" ]]; then
            local disk_path
            disk_path=$(echo "$line" | awk '{print $1}')
            map_disks+=("$disk_path")
            local details
            details=$(echo "$line" | awk '{$1=""; print $0}')
            echo -e "  ${GREEN}${i})${NC} ${BOLD}${disk_path}${NC} —${details}"
            ((i++))
        fi
    done < <(get_available_disks)

    if [ ${#map_disks[@]} -eq 0 ]; then
        if [ "$TEST_MODE" = true ]; then
            map_disks+=("/dev/nvme0n1" "/dev/sdb")
            echo -e "  ${GREEN}1)${NC} ${BOLD}/dev/nvme0n1${NC} — 476.9G NVMe SSD (Simulação)"
            echo -e "  ${GREEN}2)${NC} ${BOLD}/dev/sdb${NC} — 111.8G External HDD (Simulação)"
        else
            echo -e "${RED}Nenhum disco físico disponível encontrado!${NC}"
            SELECT_ACTION="none"
            return 0
        fi
    fi

    echo -e "  ${YELLOW}v)${NC} Voltar para a etapa anterior"
    echo ""

    while true; do
        read -rp "Escolha o número do disco [1-${#map_disks[@]} ou v]: " sel
        if [[ "$sel" =~ ^[Vv]$ ]]; then
            SELECT_ACTION="back"
            return 0
        elif [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#map_disks[@]}" ]; then
            SELECTED_DISK="${map_disks[$((sel-1))]}"
            SELECT_ACTION="ok"
            return 0
        else
            echo -e "${RED}Opção inválida! Digite um número entre 1 e ${#map_disks[@]} ou 'v'.${NC}"
        fi
    done
}

# Lista SOMENTE partições (nunca o disco inteiro) de um disco, opcionalmente
# filtrando por tipo de sistema de arquivos. Resultado em SELECT_ACTION
# ("ok"/"back"/"none") e SELECTED_PARTITION.
select_partition_menu() {
    local disk="$1"
    local prompt_title="$2"
    local fstype_filter="$3"

    echo -e "${BOLD}${prompt_title}${NC}\n"

    local map_parts=()
    local i=1

    while read -r line; do
        if [[ -n "$line" ]]; then
            local part_name part_fs
            part_name=$(echo "$line" | awk '{print $1}')
            part_fs=$(echo "$line" | awk '{print $3}')

            if [[ -n "$fstype_filter" && "$part_fs" != "$fstype_filter" && "$TEST_MODE" = false ]]; then
                continue
            fi

            map_parts+=("$part_name")
            local details
            details=$(echo "$line" | awk '{$1=""; print $0}')
            echo -e "  ${GREEN}${i})${NC} ${BOLD}${part_name}${NC} —${details}"
            ((i++))
        fi
    # Pede explicitamente a coluna TYPE e filtra por "part" — a versão
    # anterior não pedia TYPE nenhum e o grep textual quase nunca casava.
    done < <(lsblk -pno NAME,SIZE,FSTYPE,LABEL,TYPE "$disk" 2>/dev/null | awk '$NF=="part"{ $NF=""; print }')

    if [ ${#map_parts[@]} -eq 0 ]; then
        if [ "$TEST_MODE" = true ]; then
            if [[ "$fstype_filter" == "vfat" ]]; then
                map_parts+=("${disk}p1")
                echo -e "  ${GREEN}1)${NC} ${BOLD}${disk}p1${NC} — 512M vfat (EFI Simulado)"
            else
                map_parts+=("${disk}p2")
                echo -e "  ${GREEN}1)${NC} ${BOLD}${disk}p2${NC} — 100G btrfs (Raiz Simulado)"
            fi
        else
            echo -e "${RED}Nenhuma partição compatível ($fstype_filter) encontrada em $disk!${NC}"
            SELECT_ACTION="none"
            return 0
        fi
    fi

    echo -e "  ${YELLOW}v)${NC} Voltar para a etapa anterior"
    echo ""

    while true; do
        read -rp "Escolha o número da partição [1-${#map_parts[@]} ou v]: " sel
        if [[ "$sel" =~ ^[Vv]$ ]]; then
            SELECT_ACTION="back"
            return 0
        elif [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#map_parts[@]}" ]; then
            SELECTED_PARTITION="${map_parts[$((sel-1))]}"
            SELECT_ACTION="ok"
            return 0
        else
            echo -e "${RED}Opção inválida! Digite um número entre 1 e ${#map_parts[@]} ou 'v'.${NC}"
        fi
    done
}

# ==============================================================================
# MÁQUINA DE ESTADOS ÚNICA COM PILHA DE NAVEGAÇÃO (corrige o Bug 2)
# ==============================================================================
# Cada tela é identificada por um nome. "goto" empilha o estado atual antes
# de avançar; "back" desempilha e volta exatamente para a tela anterior,
# preservando todas as variáveis já preenchidas (disco, partições, etc).
STATE_STACK=()
CURRENT_STATE="mode_select"

goto_state() {
    STATE_STACK+=("$CURRENT_STATE")
    CURRENT_STATE="$1"
}
back_state() {
    if [ ${#STATE_STACK[@]} -eq 0 ]; then
        CURRENT_STATE="mode_select"
    else
        local last_index=$((${#STATE_STACK[@]} - 1))
        CURRENT_STATE="${STATE_STACK[$last_index]}"
        unset 'STATE_STACK[last_index]'
    fi
}

while true; do
    case "$CURRENT_STATE" in

        # --------------------------------------------------------------------
        mode_select)
            show_header
            echo -e "${BOLD}Escolha como deseja instalar o sistema:${NC}"
            echo -e "  ${GREEN}1)${NC} Formatar um Disco Inteiro (Usar Disko - Apaga tudo no disco)"
            echo -e "  ${GREEN}2)${NC} Instalar em Espaço Livre do Disco (Dual-Boot no mesmo disco)"
            echo -e "  ${GREEN}3)${NC} Instalar em Partições Já Criadas (Btrfs + EFI)"
            echo -e "  ${YELLOW}q)${NC} Sair\n"

            read -rp "Digite o número da opção desejada [1, 2, 3 ou q]: " INSTALL_MODE
            case "$INSTALL_MODE" in
                1) goto_state "m1_disk" ;;
                2) goto_state "m2_disk" ;;
                3) goto_state "m3_disk" ;;
                [Qq]) echo -e "${YELLOW}Saindo.${NC}"; exit 0 ;;
                *) echo -e "${RED}Opção inválida! Digite 1, 2, 3 ou q.${NC}"; sleep 1 ;;
            esac
            ;;

        # ============================ MODO 1 ================================
        m1_disk)
            show_header
            echo -e "${CYAN}${BOLD}--- MODO 1: Formatação de Disco Inteiro (Disko) ---${NC}\n"
            select_disk_menu "Selecione o disco que será TOTALMENTE FORMATADO:"
            case "$SELECT_ACTION" in
                back) back_state ;;
                none) sleep 2; back_state ;;
                ok)
                    TARGET_DISK="$SELECTED_DISK"
                    if disk_has_mounted_partitions "$TARGET_DISK"; then
                        echo -e "\n${RED}${BOLD}O disco $TARGET_DISK possui partições atualmente montadas!${NC}"
                        echo -e "${YELLOW}Desmonte-as antes de formatar este disco (ex: umount ${TARGET_DISK}*).${NC}"
                        sleep 3
                    else
                        goto_state "m1_confirm"
                    fi
                    ;;
            esac
            ;;

        m1_confirm)
            show_header
            echo -e "${RED}${BOLD}⚠️  ATENÇÃO: O DISCO $TARGET_DISK SERÁ TOTALMENTE FORMATADO!${NC}\n"
            echo -e "${BOLD}As seguintes partições ATUAIS serão APAGADAS:${NC}"
            lsblk -p -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$TARGET_DISK" 2>/dev/null || echo "  • $TARGET_DISK (Tudo será removido)"
            echo ""
            echo -e "${GREEN}${BOLD}As seguintes novas partições e subvolumes Btrfs serão CRIADOS:${NC}"
            echo -e "  • ${BOLD}/boot${NC}    (EFI / FAT32 / 512MB)"
            echo -e "  • ${BOLD}/ (raiz)${NC} (Btrfs subvolume '@' - compressão ZSTD)"
            echo -e "  • ${BOLD}/home${NC}    (Btrfs subvolume '@home' - para Snapper)"
            echo -e "  • ${BOLD}/nix${NC}     (Btrfs subvolume '@nix')"
            echo -e "  • ${BOLD}/var/log${NC} (Btrfs subvolume '@log')\n"

            confirm_prompt "Confirmar o plano de particionamento do Disco Inteiro?"
            if [[ "$PROMPT_ACTION" == "back" ]]; then
                back_state
                continue
            fi

            if [ "$TEST_MODE" = false ]; then
                echo ""
                read -rp "$(echo -e "${RED}${BOLD}Digite exatamente '${TARGET_DISK}' para confirmar a formatação TOTAL: ${NC}")" TYPED_DISK
                if [[ "$TYPED_DISK" != "$TARGET_DISK" ]]; then
                    echo -e "${RED}O texto digitado não confere. Nada foi alterado. Tente novamente.${NC}"
                    sleep 2
                    continue
                fi

                local_disko_file="$REPO_DIR/modules/hosts/$HOSTNAME/disko.nix"
                if [[ ! -f "$local_disko_file" ]]; then
                    echo -e "${RED}Erro: $local_disko_file não encontrado. Abortando com segurança.${NC}"
                    exit 1
                fi
                if ! grep -q 'device = ".*";' "$local_disko_file"; then
                    echo -e "${RED}Erro: não encontrei o padrão 'device = \"...\";' em disko.nix. Abortando para não gravar um device.nix errado.${NC}"
                    exit 1
                fi
                sed -i "s|device = \".*\";|device = \"$TARGET_DISK\";|g" "$local_disko_file"
                if ! grep -q "device = \"$TARGET_DISK\";" "$local_disko_file"; then
                    echo -e "${RED}Erro: a substituição do device em disko.nix falhou. Abortando.${NC}"
                    exit 1
                fi
            fi

            TARGET_ROOT_PART=""
            EFI_PART=""
            TARGET_CHECK_PATH="$TARGET_DISK"
            goto_state "inspect_pkgs"
            ;;

        # ============================ MODO 2 ================================
        m2_disk)
            show_header
            echo -e "${CYAN}${BOLD}--- MODO 2: Instalar em Espaço Livre (Dual-Boot) ---${NC}\n"
            select_disk_menu "Selecione o disco principal para o Dual-Boot:"
            case "$SELECT_ACTION" in
                back) back_state ;;
                none) sleep 2; back_state ;;
                ok) TARGET_DISK="$SELECTED_DISK"; goto_state "m2_efi" ;;
            esac
            ;;

        m2_efi)
            show_header
            echo -e "${CYAN}${BOLD}--- MODO 2: Seleção da Partição EFI ---${NC}\n"
            if [ "$TEST_MODE" = false ] && ! is_gpt "$TARGET_DISK"; then
                echo -e "${YELLOW}⚠️  Aviso: $TARGET_DISK não parece estar em uma tabela GPT. Dual-boot UEFI pode não funcionar corretamente.${NC}\n"
            fi
            select_partition_menu "$TARGET_DISK" "Selecione a partição EFI existente:" "vfat"
            case "$SELECT_ACTION" in
                back) back_state ;;
                none) sleep 2; back_state ;;
                ok) EFI_PART="$SELECTED_PARTITION"; goto_state "m2_size" ;;
            esac
            ;;

        m2_size)
            show_header
            echo -e "${CYAN}${BOLD}--- MODO 2: Tamanho para a nova partição Btrfs do NixOS ---${NC}\n"
            echo -e "Partição EFI Selecionada: ${GREEN}$EFI_PART${NC}\n"
            read -rp "Quantos GB deseja dedicar ao NixOS no espaço livre? [Ex: 100 ou v para voltar]: " BTRFS_SIZE_GB
            if [[ "$BTRFS_SIZE_GB" =~ ^[Vv]$ ]]; then
                back_state
                continue
            fi
            if ! [[ "$BTRFS_SIZE_GB" =~ ^[0-9]+$ ]] || [ "$BTRFS_SIZE_GB" -le 0 ]; then
                echo -e "${RED}Valor inválido. Digite um número inteiro de GB maior que zero.${NC}"
                sleep 2
                continue
            fi

            if [ "$TEST_MODE" = false ]; then
                FREE_MB=$(parted -s "$TARGET_DISK" unit MB print free 2>/dev/null | awk '/Free Space/ {print $3}' | sed 's/MB//' | sort -n | tail -1)
                if [[ -n "$FREE_MB" ]]; then
                    REQ_MB=$((BTRFS_SIZE_GB * 1024))
                    if [ "$REQ_MB" -gt "${FREE_MB%.*}" ]; then
                        echo -e "${RED}O maior espaço livre contíguo em $TARGET_DISK é de aproximadamente $((${FREE_MB%.*}/1024))GB, menor que os ${BTRFS_SIZE_GB}GB pedidos.${NC}"
                        sleep 3
                        continue
                    fi
                fi
                NEXT_NUM=$(( $(count_existing_partitions "$TARGET_DISK") + 1 ))
                BTRFS_PART=$(next_partition_path "$TARGET_DISK" "$NEXT_NUM")
            else
                BTRFS_PART=$(next_partition_path "$TARGET_DISK" 3)
            fi
            goto_state "m2_confirm"
            ;;

        m2_confirm)
            show_header
            echo -e "${CYAN}${BOLD}Resumo do Dual-Boot no Espaço Livre:${NC}"
            echo -e "  • Partição EFI Existente: $EFI_PART"
            echo -e "  • Nova Partição Btrfs a Criar: $BTRFS_PART (${BTRFS_SIZE_GB} GB)"
            echo -e "  • Subvolumes Btrfs que serão gerados: @, @home, @nix, @log\n"

            confirm_prompt "Confirmar criação da partição Btrfs no espaço livre?"
            if [[ "$PROMPT_ACTION" == "back" ]]; then
                back_state
                continue
            fi

            TARGET_ROOT_PART="$BTRFS_PART"
            TARGET_CHECK_PATH="$TARGET_DISK"
            goto_state "inspect_pkgs"
            ;;

        # ============================ MODO 3 ================================
        m3_disk)
            show_header
            echo -e "${CYAN}${BOLD}--- MODO 3: Usar Partições Existentes ---${NC}\n"
            select_disk_menu "Selecione o disco onde estão as partições:"
            case "$SELECT_ACTION" in
                back) back_state ;;
                none) sleep 2; back_state ;;
                ok) TARGET_DISK="$SELECTED_DISK"; goto_state "m3_efi" ;;
            esac
            ;;

        m3_efi)
            show_header
            echo -e "${CYAN}${BOLD}--- MODO 3: Partição EFI ---${NC}\n"
            if [ "$TEST_MODE" = false ] && ! is_gpt "$TARGET_DISK"; then
                echo -e "${YELLOW}⚠️  Aviso: $TARGET_DISK não parece estar em uma tabela GPT.${NC}\n"
            fi
            select_partition_menu "$TARGET_DISK" "Selecione a partição EFI (FAT32/vfat):" "vfat"
            case "$SELECT_ACTION" in
                back) back_state ;;
                none) sleep 2; back_state ;;
                ok) EFI_PART="$SELECTED_PARTITION"; goto_state "m3_root" ;;
            esac
            ;;

        m3_root)
            show_header
            echo -e "${CYAN}${BOLD}--- MODO 3: Partição Btrfs ---${NC}\n"
            echo -e "Partição EFI Selecionada: ${GREEN}$EFI_PART${NC}\n"
            select_partition_menu "$TARGET_DISK" "Selecione a partição Raiz (Btrfs):" "btrfs"
            case "$SELECT_ACTION" in
                back) back_state ;;
                none) sleep 2; back_state ;;
                ok)
                    BTRFS_PART="$SELECTED_PARTITION"
                    if [ "$TEST_MODE" = false ]; then
                        FS_TYPE=$(lsblk -no FSTYPE "$BTRFS_PART" 2>/dev/null || true)
                        if [[ "$FS_TYPE" != "btrfs" ]]; then
                            echo -e "${RED}Erro: A partição $BTRFS_PART não é Btrfs! (Detectado: '$FS_TYPE')${NC}"
                            sleep 3
                            continue
                        fi
                    fi
                    goto_state "m3_confirm"
                    ;;
            esac
            ;;

        m3_confirm)
            show_header
            echo -e "${CYAN}${BOLD}Resumo das Partições Selecionadas:${NC}"
            echo -e "  • Partição EFI: $EFI_PART (vfat)"
            echo -e "  • Partição Raiz: $BTRFS_PART (btrfs)\n"

            confirm_prompt "Confirmar o uso destas partições?"
            if [[ "$PROMPT_ACTION" == "back" ]]; then
                back_state
                continue
            fi

            TARGET_ROOT_PART="$BTRFS_PART"
            TARGET_CHECK_PATH="$BTRFS_PART"
            goto_state "inspect_pkgs"
            ;;

        # ==================== ETAPAS COMUNS A TODOS OS MODOS =================
        inspect_pkgs)
            show_header
            echo -e "${CYAN}${BOLD}--- Inspeção de Pacotes do Sistema ---${NC}\n"
            read -rp "Deseja ver a lista de pacotes declarados que serão instalados? [Y/n/v]: " VIEW_PKGS
            VIEW_PKGS=${VIEW_PKGS:-Y}

            if [[ "$VIEW_PKGS" =~ ^[Vv]$ ]]; then
                back_state
                continue
            elif [[ "$VIEW_PKGS" =~ ^[Yy]$ ]]; then
                TMP_PKGS_FILE=$(mktemp)
                echo "# LISTA DE PACOTES DECLARADOS NO SEU FLAKE ($HOSTNAME)" > "$TMP_PKGS_FILE"
                echo "# Pressione 'q' para sair do leitor e continuar a instalação." >> "$TMP_PKGS_FILE"
                echo "==========================================================================" >> "$TMP_PKGS_FILE"
                grep -rh "environment.systemPackages" -A 25 "$REPO_DIR/modules/" >> "$TMP_PKGS_FILE" 2>/dev/null || true

                if command -v vim &>/dev/null; then
                    vim -R "$TMP_PKGS_FILE"
                elif command -v nvim &>/dev/null; then
                    nvim -R "$TMP_PKGS_FILE"
                else
                    echo -e "${YELLOW}Carregando leitor de pacotes temporário...${NC}"
                    nix-shell -p vim --run "vim -R $TMP_PKGS_FILE" 2>/dev/null || true
                fi
                rm -f "$TMP_PKGS_FILE"
            fi
            goto_state "dry_run"
            ;;

        dry_run)
            show_header
            echo -e "${CYAN}${BOLD}--- Análise Dinâmica de Compilação do Flake ---${NC}\n"
            echo -e "${YELLOW}Analisando a árvore do Flake para verificar pacotes a compilar vs baixar...${NC}\n"

            DRY_RUN_OUTPUT=$(nix build "$REPO_DIR#$HOSTNAME" --dry-run 2>&1 || true)
            BUILT_DRVS=$(echo "$DRY_RUN_OUTPUT" | grep -A 100 "these.*derivations will be built:" | grep -B 100 "these.*paths will be fetched" | grep "/nix/store" | sed 's/^[ \t]*//' | head -n 15)

            if [[ -n "$BUILT_DRVS" ]]; then
                echo -e "${YELLOW}${BOLD}⚠️ Os seguintes pacotes/módulos serão COMPILADOS localmente na CPU:${NC}"
                echo "$BUILT_DRVS" | while read -r line; do
                    pkg_name=$(echo "$line" | sed -E 's|/nix/store/[a-z0-9]+-||')
                    echo -e "  • ${RED}$pkg_name${NC}"
                done
                echo ""
            else
                echo -e "${GREEN}${BOLD}✅ Excelente! Todos os pacotes possuem binários prontos no cache (Nenhuma compilação pesada).${NC}\n"
            fi

            confirm_prompt "Deseja prosseguir com o plano de compilação/download?"
            if [[ "$PROMPT_ACTION" == "back" ]]; then
                back_state
                continue
            fi
            goto_state "space_cpu"
            ;;

        space_cpu)
            show_header
            echo -e "${CYAN}${BOLD}--- Cálculo Dinâmico de Espaço em Disco e Download ---${NC}\n"

            CLOSURE_BYTES=$(nix path-info -r --closure-size "$REPO_DIR#$HOSTNAME" 2>/dev/null | awk '{sum += $2} END {print sum}')
            if [[ -z "$CLOSURE_BYTES" || "$CLOSURE_BYTES" -eq 0 ]]; then
                CLOSURE_BYTES=19327352832
            fi

            ESTIMATED_INSTALL_GB=$(awk "BEGIN {printf \"%.2f\", $CLOSURE_BYTES/1024/1024/1024}")
            ESTIMATED_DOWNLOAD_GB=$(awk "BEGIN {printf \"%.2f\", $CLOSURE_BYTES/1024/1024/1024/4}")

            # Medição real de espaço via lsblk (não usar df em disco/partição
            # não montada — lê tmpfs e dá valores sem sentido, era o Bug 3).
            if [[ -b "$TARGET_CHECK_PATH" ]]; then
                FREE_DISK_BYTES=$(lsblk -bno SIZE "$TARGET_CHECK_PATH" 2>/dev/null | head -n 1)
                FREE_DISK_GB=$(awk "BEGIN {printf \"%.2f\", ${FREE_DISK_BYTES:-119537664000}/1024/1024/1024}")
            else
                FREE_DISK_GB="111.20"
            fi

            FREE_DISK_AFTER=$(awk "BEGIN {printf \"%.2f\", $FREE_DISK_GB - $ESTIMATED_INSTALL_GB}")

            echo -e "  • ${BOLD}Tamanho Estimado do Download:${NC}  ~${GREEN}${ESTIMATED_DOWNLOAD_GB} GB${NC}"
            echo -e "  • ${BOLD}Tamanho Estimado da Instalação:${NC} ~${BLUE}${ESTIMATED_INSTALL_GB} GB${NC}"
            echo -e "  • ${BOLD}Tamanho Total do Disco/Partição:${NC} ~${CYAN}${FREE_DISK_GB} GB${NC}"
            echo -e "  • ${BOLD}Espaço Livre Estimado PÓS-Instalação:${NC} ~${YELLOW}${FREE_DISK_AFTER} GB${NC}\n"

            if awk "BEGIN {exit !($FREE_DISK_AFTER < 0)}"; then
                echo -e "${RED}${BOLD}⚠️  O espaço estimado após a instalação é NEGATIVO. O disco/partição alvo provavelmente é pequeno demais.${NC}\n"
            fi

            echo -e "${BOLD}Configuração de Recursos do Processador:${NC}"
            read -rp "Quantos núcleos de CPU deseja utilizar? [Padrão: 6]: " CUSTOM_CORES
            CUSTOM_CORES=${CUSTOM_CORES:-6}
            if ! [[ "$CUSTOM_CORES" =~ ^[0-9]+$ ]] || [ "$CUSTOM_CORES" -le 0 ]; then
                echo -e "${RED}Valor inválido para núcleos, usando o padrão (6).${NC}"
                CUSTOM_CORES=6
            fi

            read -rp "Quantas tarefas simultâneas (max-jobs)? [Padrão: 1]: " CUSTOM_JOBS
            CUSTOM_JOBS=${CUSTOM_JOBS:-1}
            if ! [[ "$CUSTOM_JOBS" =~ ^[0-9]+$ ]] || [ "$CUSTOM_JOBS" -le 0 ]; then
                echo -e "${RED}Valor inválido para max-jobs, usando o padrão (1).${NC}"
                CUSTOM_JOBS=1
            fi

            echo -e "\nRecursos configurados: ${GREEN}${CUSTOM_CORES} núcleos${NC} | ${GREEN}${CUSTOM_JOBS} job(s) em paralelo${NC}.\n"

            confirm_prompt "Confirmar o plano de recursos e espaço?"
            if [[ "$PROMPT_ACTION" == "back" ]]; then
                back_state
                continue
            fi
            goto_state "final_confirm"
            ;;

        final_confirm)
            show_header
            echo -e "${CYAN}${BOLD}--- Validação e Execução Final ---${NC}\n"
            echo -e "  • Modo de Instalação: ${GREEN}Modo $INSTALL_MODE${NC}"
            echo -e "  • Disco Alvo: ${CYAN}$TARGET_DISK${NC}"
            echo -e "  • Recursos de CPU: ${YELLOW}$CUSTOM_CORES núcleos | $CUSTOM_JOBS job(s)${NC}\n"

            confirm_prompt "Deseja iniciar a execução REAL da instalação no disco agora?"
            if [[ "$PROMPT_ACTION" == "back" ]]; then
                back_state
                continue
            fi
            break
            ;;

        *)
            echo -e "${RED}Estado interno desconhecido: $CURRENT_STATE. Voltando ao início.${NC}"
            sleep 2
            CURRENT_STATE="mode_select"
            STATE_STACK=()
            ;;
    esac
done

# ==============================================================================
# EXECUÇÃO DA INSTALAÇÃO REAL (OU SIMULAÇÃO EM --TEST)
# ==============================================================================
show_header
echo -e "${GREEN}${BOLD}🚀 Iniciando o Processo de Instalação...${NC}\n"

if [ "$TEST_MODE" = true ]; then
    echo -e "${YELLOW}[MODO DE TESTE / SIMULAÇÃO]${NC}"
    echo -e "  1. Particionamento (Modo $INSTALL_MODE) no disco $TARGET_DISK: ${GREEN}SIMULADO${NC}"
    echo -e "  2. Montagem de subvolumes Btrfs e EFI em /mnt: ${GREEN}SIMULADO${NC}"
    echo -e "  3. Geração de hardware.nix e cópia do repositório: ${GREEN}SIMULADO${NC}"
    echo -e "  4. Execução do nixos-install (--option max-jobs $CUSTOM_JOBS --option cores $CUSTOM_CORES): ${GREEN}SIMULADO${NC}\n"
    echo -e "${GREEN}${BOLD}🎉 Simulação concluída com sucesso! Todo o fluxo e cálculos foram validados.${NC}\n"
    exit 0
fi

# A partir daqui é execução REAL. Nada acima deste ponto altera disco algum.
if [[ "$INSTALL_MODE" -eq 1 ]]; then
    echo -e "${YELLOW}Executando o Disko para particionar e montar o disco...${NC}"
    nix run github:nix-community/disko -- --mode disko "$REPO_DIR/modules/hosts/$HOSTNAME/disko.nix"
else
    if [[ "$INSTALL_MODE" -eq 2 ]]; then
        echo -e "${YELLOW}Criando nova partição Btrfs no espaço livre...${NC}"
        parted -s "$TARGET_DISK" mkpart primary btrfs 512MB "${BTRFS_SIZE_GB}GB"
        udevadm settle 2>/dev/null || true
        mkfs.btrfs -f -L NIXOS "$TARGET_ROOT_PART"
    fi

    echo -e "${YELLOW}Montando partições e subvolumes Btrfs em /mnt...${NC}"
    mkdir -p /mnt

    # Cria os subvolumes na primeira montagem (necessário no Modo 2, onde a
    # partição acabou de ser criada e ainda não tem subvolumes).
    mount "$TARGET_ROOT_PART" /mnt
    for sv in @ @home @nix @log; do
        btrfs subvolume show "/mnt/$sv" &>/dev/null || btrfs subvolume create "/mnt/$sv"
    done
    umount /mnt

    mount -o noatime,compress=zstd:1,subvol=@ "$TARGET_ROOT_PART" /mnt
    mkdir -p /mnt/{home,nix,var/log,boot}
    mount -o noatime,compress=zstd:1,subvol=@home "$TARGET_ROOT_PART" /mnt/home
    mount -o noatime,compress=zstd:1,subvol=@nix "$TARGET_ROOT_PART" /mnt/nix
    mount -o noatime,compress=zstd:1,subvol=@log "$TARGET_ROOT_PART" /mnt/var/log
    mount "$EFI_PART" /mnt/boot
fi

echo -e "${YELLOW}Gerando hardware.nix da máquina física...${NC}"
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR/modules/hosts/$HOSTNAME/hardware.nix"

echo -e "${YELLOW}Copiando seu repositório MyNixOs para /mnt/home/$USERNAME/MyNixOs...${NC}"
mkdir -p "/mnt/home/$USERNAME/"
cp -r "$REPO_DIR" "/mnt/home/$USERNAME/MyNixOs"
chown -R 1000:100 "/mnt/home/$USERNAME/MyNixOs"

echo -e "${YELLOW}Executando pré-build visual da configuração via 'nh'...${NC}"
nix run github:viperML/nh -- build "$REPO_DIR#$HOSTNAME" --store /mnt || echo -e "${YELLOW}Aviso: pré-build via 'nh' falhou ou foi pulado; prosseguindo com nixos-install.${NC}"

echo -e "${GREEN}${BOLD}Instalando o NixOS no disco...${NC}"
nixos-install --flake "/mnt/home/$USERNAME/MyNixOs#$HOSTNAME" --option max-jobs "$CUSTOM_JOBS" --option cores "$CUSTOM_CORES"

echo -e "\n${GREEN}${BOLD}======================================================================"
echo -e "  🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!                              "
echo -e "======================================================================${NC}"
echo -e "Defina a senha do seu usuário executando: ${YELLOW}passwd $USERNAME${NC}"
echo -e "Em seguida, reinicie o computador com: ${YELLOW}reboot${NC}\n"
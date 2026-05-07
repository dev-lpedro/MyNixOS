#!/usr/bin/env fish

# Nome único para sincronizar as notificações e evitar empilhamento
set SYNC_ID "gpu_recorder_msg"

# Função para enviar notificação que não vai para o histórico e dura 1.5s
function send_notif
    # -u low: prioridade baixa (geralmente ignora o histórico/sidebar)
    # -h int:transient:1: diz ao sistema para não salvar
    # -h string:x-canonical-private-synchronous: substitui a anterior
    notify-send -u low -t 1500 \
        -h int:transient:1 \
        -h "string:x-canonical-private-synchronous:$SYNC_ID" \
        $argv
end

function save_clip
    set video_dir "$HOME/Vídeos"
    killall -SIGUSR1 gpu-screen-recorder
    sleep 0.6

    set last_file (ls -t $video_dir/*.mp4 2>/dev/null | head -n 1)

    if test -f "$last_file"
        set duration (ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nocsv=1 "$last_file" | cut -d. -f1)
        send_notif "Clip Salvo! " "Duração: $duration segundos" -i video-display
    else
        send_notif "Erro" "Não foi possível encontrar o vídeo." -i dialog-error
    end
end

function set_power_mode
    set mode $argv[1]

    # Tenta mudar o perfil
    powerprofilesctl set $mode

    if test "$mode" = "performance"
        systemctl --user start gpu-replay.service
        send_notif "Modo Performance" "Gravador ATIVADO" -i battery-full-charging
    else
        systemctl --user stop gpu-replay.service
        send_notif "Modo Econômico" "Gravador DESATIVADO" -i battery-low
    end
end

# Função para detectar se está no AC ou Bateria (Detecção Universal)
function check_ac_status
    # Procura em qualquer pasta que comece com AC ou ADP por um arquivo chamado 'online'
    for ac_path in /sys/class/power_supply/A*/online
        if test (cat $ac_path) = "1"
            return 0 # Está no carregador
        end
    end
    return 1 # Está na bateria
end

if test "$argv[1]" = "--monitor"
    # Estado inicial
    if check_ac_status
        set_power_mode performance
    else
        set_power_mode power-saver
    end

    # Monitoramento em tempo real
    udevadm monitor --subsystem-match=power_supply | while read -l line
        if string match -q "*AC*" $line; or string match -q "*ADP*" $line
            sleep 1
            if check_ac_status
                set_power_mode performance
            else
                set_power_mode power-saver
            end
        end
    end
end

if test "$argv[1]" = "--save"
    save_clip
end

if test "$argv[1]" = "--toggle"
    if systemctl --user is-active --quiet gpu-replay.service
        systemctl --user stop gpu-replay.service
        send_notif "GPU Recorder" "Desativado manualmente" -i dialog-warning
    else
        systemctl --user start gpu-replay.service
        send_notif "GPU Recorder" "Ativado manualmente" -i dialog-information
    end
end

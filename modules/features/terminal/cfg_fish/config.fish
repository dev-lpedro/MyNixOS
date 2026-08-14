# ==============================================================================
# Configuração Pessoal do Fish Shell (MyNixOs)
# ==============================================================================

# Executa apenas em sessões interativas do terminal
if status is-interactive
    # Desativa a mensagem padrão de boas-vindas do Fish
    set -g fish_greeting ""

    # Executa o Fastfetch automaticamente ao abrir uma nova aba/janela do terminal
    fastfetch

    #inicializa o starship
    starship init fish | source
end

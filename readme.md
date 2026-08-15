# MyNixOs

Meu repositório pessoal com a minha configuração do NixOS. Projetado para um notebook com gráficos híbridos (Intel + NVIDIA), utilizando o compositor **Niri** com a **Noctalia v4** configurada, suporte à **Noctalia v5** (para testes/futura migração), terminal **kitty** + **fish** + **starship**, e sistema de arquivos **Btrfs**.

Host atual: `fakeNixOs` · Usuário: `leonardo`

---

# 🚀 Como Usar

Existem três formas de usar este repositório, dependendo de onde você está partindo:

| Sua situação | O que fazer |
|---|---|
| Já tenho o NixOS instalado nesta máquina | [1. Aplicar/atualizar a configuração](#1-já-estou-no-nixos-aplicar-ou-atualizar) |
| Quero instalar o NixOS do zero num disco | [2. Instalação completa](#2-instalação-completa-em-um-disco-novo) |
| Só quero ver o Niri + Noctalia + kitty funcionando, sem instalar nada | [3. Testar em outro sistema (efêmero)](#3-testar-em-outro-sistema-sem-instalar-nada) |

---

## 1. Já estou no NixOS (aplicar ou atualizar)

Se a máquina já está rodando essa configuração (ou uma anterior) e você só quer aplicar mudanças que fez no repositório:

```bash
# Reconstrói e aplica as alterações, define como padrão no boot
sudo nixos-rebuild switch --flake .#fakeNixOs

# Ou testa temporariamente (some no próximo reboot, não mexe no bootloader)
sudo nixos-rebuild test --flake .#fakeNixOs
```

Prefere uma saída mais bonita, com diff das mudanças antes de aplicar?

```bash
nix run nixpkgs#nh -- os build .#fakeNixOs   # só builda e mostra o que vai mudar
nix run nixpkgs#nh -- os switch .#fakeNixOs  # builda, mostra o diff e aplica
```

---

## 2. Instalação completa em um disco novo

Para formatar um disco (interno ou externo) e instalar o NixOS com esta configuração do zero. Funciona tanto de dentro de um **live ISO do NixOS** quanto de **outra distro** (ex.: CachyOS, Arch) — o script detecta o que falta e busca via Nix automaticamente, sem precisar instalar nada permanente no sistema hospedeiro além do próprio Nix (se ainda não existir).

```bash
sudo ./install.sh
```

O instalador é interativo e guia você por três modos:

1. **Formatar um disco inteiro** (via Disko) — apaga tudo no disco escolhido.
2. **Instalar em espaço livre** (dual-boot no mesmo disco, ao lado de outro SO).
3. **Usar partições já criadas** (você já tem uma EFI e uma Btrfs prontas).

> ⚠️ **Confira o disco de destino com atenção antes de confirmar** — o Modo 1 apaga o disco inteiro.

Quer só simular, sem tocar em nada de verdade (útil pra revisar o fluxo antes de rodar por real)?

```bash
./install.sh --test
```

---

## 3. Testar em outro sistema (sem instalar nada)

Quer só ver o Niri + Noctalia + kitty + fish/starship funcionando — numa janela do seu desktop atual, no Linux Mint, Ubuntu, ou qualquer outra distro — sem instalar o NixOS e sem tocar nas suas configs reais?

```bash
git clone <este-repositório> ~/MyNixOs   # se ainda não tiver uma cópia local
cd ~/MyNixOs
./test-niri.sh
```

O Niri abre **dentro de uma janela** no seu desktop atual (não toma conta da tela). Kitty, Noctalia, fish e starship rodam com as mesmas configs deste repositório, mas numa cópia temporária — seu `~/.config` de verdade nunca é tocado. Os binários (niri, kitty, noctalia-shell...) rodam via `nix shell`, ficando só em cache no `/nix/store`.

Pra sair: `Ctrl+Alt+Delete` ou feche a janela — a cópia temporária de configs é apagada automaticamente.

Se o script precisou instalar o Nix nessa máquina só pra esse teste e você quiser reverter tudo depois:

```bash
./test-niri.sh uninstall
```

> Se o Nix já existia por outro motivo, esse comando não mexe nele — só limpa marcas de estado deste script e sugere `nix-collect-garbage -d` pra liberar espaço.
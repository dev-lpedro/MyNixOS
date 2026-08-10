
# MyNixOs

Meu repositório pessoal com a minha configuração do NixOS. Projetado para um notebook com gráficos híbridos (Intel + NVIDIA), utilizando o compositor **Niri** com a **Noctalia v4** configurada, suporte à **Noctalia v5** (para testes/futura migração) e o **KDE Plasma 6** como *fallback*. O sistema foi pensado para rodar sobre o sistema de arquivos **Btrfs**.

Se quiser rodar ou testar no seu computador, basta seguir o passo a passo abaixo:

---

# 🚀 Como Usar

## 1. Testar em Máquina Virtual (Sem Formatar)

Ideal para testar a interface e os atalhos dentro do CachyOS, Arch ou qualquer outra distro sem alterar o seu sistema atual.bash

### 1. Construir a imagem da VM
```
nix build .#nixosConfigurations.myMachine.config.system.build.vm
```
### 2. Executar a VM
```
./result/bin/run-nitro-nixos-vm
```
> *Na tela de login do SDDM dentro da VM, selecione a sessão **Plasma**.* (Niri não funciona atualmente na vm)

---

## 2. Instalar / Aplicar no NixOS Nativo (Hardware Real)
Para quando você estiver rodando o NixOS diretamente na máquina física:

```bash
# Reconstruir e aplicar as alterações no boot
sudo nixos-rebuild switch --flake .#myMachine

# Ou testar temporariamente sem salvar no bootloader
sudo nixos-rebuild test --flake .#myMachine
```

---

### 3. Usar Apenas as Configurações de Usuário (Home Manager Standalone)

Para aplicar as configurações do Niri, Noctalia e aplicativos de usuário no CachyOS, Arch ou Ubuntu sem instalar o NixOS completo:

```bash
nix run github:nix-community/home-manager -- switch --flake .#leonardo

```

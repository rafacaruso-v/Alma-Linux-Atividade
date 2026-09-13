# INSTALL.md — Grupo 3 (AlmaLinux)

Guia de instalação reproduzível: AlmaLinux 10.2 com LVM sobre LUKS, serviço SSH endurecido e ciclo de vida do LVM.

## Sumário

1. [Ambiente e pré-requisitos](#1-ambiente-e-pré-requisitos)
2. [Verificação de integridade da ISO](#2-verificação-de-integridade-da-iso)
3. [Criação da VM](#3-criação-da-vm)
4. [Diagrama de particionamento](#4-diagrama-de-particionamento)
5. [Instalação — particionamento manual (LUKS + LVM)](#5-instalação--particionamento-manual-luks--lvm)
6. [Primeiro acesso e verificação inicial](#6-primeiro-acesso-e-verificação-inicial)
7. [Configuração do SSH endurecido](#7-configuração-do-ssh-endurecido)
8. [Ciclo de vida do LVM — disco secundário](#8-ciclo-de-vida-do-lvm--disco-secundário)
9. [Snapshots da VM](#9-snapshots-da-vm)
10. [Seção de troubleshooting](#10-seção-de-troubleshooting)

---

## 1. Ambiente e pré-requisitos

| Item | Configuração usada |
|---|---|
| Hipervisor | VirtualBox |
| Firmware | UEFI habilitado |
| Disco principal | 60 GB |
| Disco secundário | 20 GB (adicionado após a instalação) |
| Memória / vCPU | 4096 MB / 2 vCPU |
| Rede | NAT (com Port Forwarding para testes de SSH) |
| Instalação | AlmaLinux 10.2 — Minimal Install (Server sem GUI) |
| SELinux | Enforcing |

> *[PRINT: tela "Pré-Visualização" do VirtualBox com Geral/Sistema/Armazenamento/Rede da VM]*

---

## 2. Verificação de integridade da ISO

ISO utilizada: `AlmaLinux-10.2-x86_64-minimal.iso`

Hash SHA-256 oficial (retirado do site almalinux.org):
```
1b532f534231da0d1cd0ccae622bea6cd588d8a0d7b259f1f131501a6eed41a4
```

Verificação no Windows (PowerShell):
```powershell
Get-FileHash .\AlmaLinux-10.2-x86_64-minimal.iso -Algorithm SHA256
```

Resultado obtido: **hash idêntico ao oficial** — integridade confirmada.

> *[PRINT: saída do Get-FileHash comparada ao hash do site oficial]*

> **Nota:** inicialmente foi baixada por engano a ISO **DVD** (~9,4 GB), que inclui pacotes de ambiente gráfico. Como o requisito do trabalho exige *Minimal Install*, foi baixada e validada a ISO **Minimal** (~2 GB) em seu lugar. Ver seção de troubleshooting.

---

## 3. Criação da VM

- Nome: `AlmaLinux`
- Sistema Operacional: Linux / Red Hat (64-bit) — o VirtualBox não possui entrada específica para AlmaLinux, então a família Red Hat foi usada por compatibilidade
- **"Proceed with Unattended Installation" foi mantido desmarcado** — essa opção faz particionamento automático e não permite configurar LUKS/LVM manualmente, o que inviabilizaria o requisito central do trabalho
- Hardware: 4096 MB RAM, 2 vCPUs
- Recursos habilitados: I/O APIC, Hardware Clock in UTC, UEFI
- Secure Boot: desabilitado (evita travas no boot/instalação)
- Armazenamento: `AlmaLinux.vdi` (60 GB, SATA)
- Rede: Adaptador 1, NAT

> *[PRINT: tela de resumo "Pré-Visualização" da VM]*
> *[PRINT: tela de Recursos com I/O APIC, Hardware Clock, UEFI, Secure Boot]*

---

## 4. Diagrama de particionamento

Esquema de referência validado com o professor (marco D-14, **antes** da instalação):

```
sda1   /boot/efi     1 GB    FAT32    fora do LUKS
sda2   /boot         1 GB    xfs      fora do LUKS
sda3   (LUKS2)       ~58 GB  LUKS2    container criptografado
  └── VG almalinux_10 (PV = /dev/sda3)
        lv_root      15 G    /            xfs
        lv_var       8 G     /var         xfs
        lv_varlog    5 G     /var/log     xfs
        lv_vartmp    3 G     /var/tmp     xfs
        lv_home      10 G    /home        xfs
        lv_tmp       3 G     /tmp         xfs
        lv_swap      4 G     swap         swap
        (livre)      ~9-10 G reservado para snapshots
```

Soma dos LVs: 15+8+5+3+10+3+4 = 48 GB, dentro dos ~58 GB do container LUKS, sobrando espaço livre não alocado (requisito do trabalho: espaço livre é necessário para snapshots de LVM).

> *[PRINT ou imagem: diagrama de particionamento submetido para validação]*

---

## 5. Instalação — particionamento manual (LUKS + LVM)

### 5.1 Criação dos pontos de montagem fora do LUKS

No particionamento manual do Anaconda, os dois primeiros pontos de montagem foram criados **sem** marcar "Criptografar", pois o GRUB precisa ler o kernel antes de existir qualquer chave de descriptografia:

- `/boot/efi` — 1 GiB — Partição padrão — EFI System Partition
- `/boot` — 1 GiB — Partição padrão — xfs

> *[PRINT: tela de particionamento manual com /boot/efi e /boot criados]*

### 5.2 Criação do `/` com LVM + LUKS

Ao criar o ponto de montagem `/`, o tipo de dispositivo foi alterado para **LVM**, a caixa **"Criptografar"** foi marcada, e um novo Volume Group (`almalinux_10`) foi criado. Nesse momento o Anaconda solicitou a definição da **passphrase do LUKS**.

> **Atenção crítica:** a passphrase do LUKS foi anotada em local seguro imediatamente. Sem ela e sem backup do header, não existe recuperação possível do disco.

> *[PRINT: tela de configuração do LV root com LVM + Criptografar marcado]*

### 5.3 Criação dos demais LVs

Para cada LV subsequente, o checkbox **"Criptografar" foi marcado individualmente** — no Anaconda, marcar a criptografia em um LV não propaga automaticamente para os demais do mesmo VG.

| Ponto de montagem | Tamanho | Tipo de dispositivo | Criptografar | Sistema de arquivo |
|---|---|---|---|---|
| `/` | 15G | LVM | Sim | xfs |
| `/var` | 8G | LVM | Sim | xfs |
| `/var/log` | 5G | LVM | Sim | xfs |
| `/var/tmp` | 3G | LVM | Sim | xfs |
| `/home` | 10G | LVM | Sim | xfs |
| `/tmp` | 3G | LVM | Sim | xfs |
| `swap` | 4G | LVM | Sim | swap (automático) |

> *[PRINT: lista final de pontos de montagem antes de clicar em "Pronto"]*

### 5.4 Resumo de mudanças

Antes de aplicar, o Anaconda apresentou o resumo de mudanças, confirmando a criação da tabela GPT, das partições `sda1`/`sda2`/`sda3`, do physical volume LVM em `sda3` e do Volume Group `almalinux_10`.

> *[PRINT: tela "RESUMO DE MUDANÇAS"]*

### 5.5 Demais configurações da instalação

- Teclado: Português (Brasil)
- Fuso horário: Américas/São Paulo
- Seleção de programas: Instalação Mínima
- Conta root: senha definida (uso local/emergencial apenas — login remoto via SSH será bloqueado)
- Criação de usuário: usuário comum criado, marcado como administrador (grupo `wheel`)
- KDUMP: mantido com configuração padrão (Ativar kdump / Automático)

---

## 6. Primeiro acesso e verificação inicial

Após o primeiro boot, login realizado com sucesso solicitando a passphrase do LUKS.

Evidências coletadas:

```bash
lsblk -f
sudo cryptsetup luksDump /dev/sda3
sudo pvs
sudo vgs
sudo lvs
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
cat /etc/fstab
cat /etc/crypttab
cat /etc/os-release
uname -r
getenforce
sestatus
```

> *[PRINT: saída de cada comando acima]*

**Observação técnica importante:** ao inspecionar `lsblk -f`, verificou-se que o Anaconda cria **um container LUKS individual por LV** (ex.: `luks-30490e67-...` para o root, `luks-6df17b8a-...` para o home, etc.), em vez de um único container LUKS abrangendo todo o Volume Group. Isso difere do modelo "um único LUKS com o VG inteiro dentro" descrito de forma simplificada no diagrama de referência, mas atinge o mesmo objetivo de segurança: todo dado em repouso dentro do VG está criptografado, cada um com sua própria passphrase compartilhada definida durante a instalação.

---

## 7. Configuração do SSH endurecido

### 7.1 Geração do par de chaves ed25519 (no host, não na VM)

```powershell
ssh-keygen -t ed25519 -C "grupo3-almalinux"
```

Chave protegida por passphrase própria (camada adicional de segurança do lado do cliente).

### 7.2 Cópia da chave pública para a VM

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA... grupo3-almalinux" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Validação por fingerprint (mais confiável que comparação visual):
```bash
ssh-keygen -lf ~/.ssh/authorized_keys        # na VM
ssh-keygen -lf C:\Users\PC\.ssh\id_ed25519.pub  # no host
```
Fingerprint idêntico confirmado em ambos os lados: `SHA256:0GxtMyXKnhD/...`

> *[PRINT: comparação de fingerprints]*

### 7.3 Grupo dedicado para acesso SSH

```bash
sudo groupadd sshusers
sudo usermod -aG sshusers usuario
```

### 7.4 Port forwarding (ambiente de teste local)

Como a VM está em rede NAT, foi configurada uma regra de redirecionamento no VirtualBox para permitir testes a partir do host:

| Nome | Protocolo | Porta Hospedeiro | Porta Convidado |
|---|---|---|---|
| SSH | TCP | 2222 | 2155 |

> Nota: esse redirecionamento existe apenas para viabilizar o teste a partir do computador host durante o desenvolvimento; não representa exposição da VM à rede externa.

### 7.5 Diretivas aplicadas em `/etc/ssh/sshd_config`

Backup do arquivo original realizado antes de qualquer alteração:
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```

```
Port 2155
PermitRootLogin no
PasswordAuthentication no
AllowGroups sshusers
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
Banner /etc/issue.net
```

Validação de sintaxe antes de aplicar:
```bash
sudo sshd -t
```

### 7.6 SELinux — rótulo da porta customizada

```bash
sudo dnf install policycoreutils-python-utils -y
sudo semanage port -a -t ssh_port_t -p tcp 2155
sudo semanage port -l | grep ssh
```
Resultado: `ssh_port_t   tcp   2155, 22`

> *[PRINT: semanage port -l | grep ssh]*

### 7.7 update-crypto-policies

Testada a política `FUTURE` — **quebrou a negociação de chaves** com o cliente OpenSSH do Windows (algoritmos pós-quânticos ainda não suportados pelo cliente). Ver seção de troubleshooting.

Política final aplicada: `DEFAULT:OSPP` (perfil de hardening Common Criteria da Red Hat), validada sem quebrar compatibilidade:

```bash
sudo update-crypto-policies --set DEFAULT:OSPP
sudo systemctl restart sshd
```

Evidência de algoritmos habilitados após a mudança:
```bash
sudo sshd -T | grep -E "ciphers|macs|kexalgorithms"
```

> *[PRINT: saída confirmando ausência de SHA-1 e algoritmos legados nas três categorias]*

### 7.8 firewalld

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="2155" protocol="tcp" accept limit value="10/m"'
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

Resultado: apenas a porta 2155/tcp liberada, com limite de taxa de 10 novas conexões por minuto (proteção complementar contra força bruta).

> *[PRINT: firewall-cmd --list-all]*

### 7.9 Banner de aviso legal

`/etc/issue.net`:
```
Acesso restrito a usuários autorizados. Toda atividade neste sistema é monitorada e registrada. O acesso não autorizado é crime, conforme Art. 154-A do Código Penal (Lei 12.737/2012).
```

Banner confirmado apresentado ao cliente antes da autenticação.

> *[PRINT: conexão SSH mostrando o banner antes do prompt de senha/chave]*

### 7.10 Verificação da configuração efetiva

```bash
sudo sshd -T | grep -E "port|permitrootlogin|passwordauthentication|allowgroups|maxauthtries|logingracetime|clientaliveinterval"
```

> *[PRINT: saída confirmando todas as diretivas aplicadas]*

### 7.11 Evidências finais — acesso e bloqueio

**Acesso por chave funcionando:**
```powershell
ssh -p 2222 usuario@127.0.0.1
```
Conecta com sucesso solicitando apenas a passphrase da chave privada.

**Tentativa corretamente bloqueada:**
```powershell
ssh -p 2222 root@127.0.0.1
```

Log correspondente no journald:
```bash
sudo journalctl -u sshd -n 20 --no-pager
```
```
User root from 10.0.2.2 not allowed because none of user's groups are listed in AllowGroups
Connection reset by invalid user root 10.0.2.2 port 53624 [preauth]
```

Também observado: tentativa de conexão sem a passphrase correta da chave resulta em `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)`, confirmando que não existe fallback para autenticação por senha.

> *[PRINT: journalctl mostrando a tentativa de root bloqueada]*
> *[PRINT: tentativa sem passphrase correta sendo recusada]*

---

## 8. Ciclo de vida do LVM — disco secundário

Disco `AlmaLinux_1.vdi` (20 GB) adicionado à VM via VirtualBox (Configurações → Armazenamento → Controladora SATA → novo Hard Disk).

```bash
lsblk
# /dev/sdb aparece sem partições, 20G

sudo pvcreate /dev/sdb
sudo pvs
# /dev/sdb agora é um Physical Volume válido

sudo vgextend almalinux_10 /dev/sdb
sudo vgs
# VG almalinux_10: VSize 68.11g, VFree 20.00g

sudo lvextend -L +15G /dev/almalinux_10/home
sudo lvs
# home: ~25.02g
```

**Passo adicional necessário por causa do LUKS** (não documentado nos tutoriais genéricos de LVM sem criptografia): o `lvextend` expande o Logical Volume, mas o mapeamento LUKS por cima dele não é redimensionado automaticamente. É necessário:

```bash
sudo cryptsetup resize luks-6df17b8a-3365-4d03-b762-b373a6d87e94
```

Só então o `xfs_growfs` consegue enxergar o espaço extra:

```bash
sudo xfs_growfs /home
df -h /home
# /home: 25G, 522M usado, 25G disponível
```

Resultado: expansão completa realizada **a quente**, sem desmontar `/home`, sem reiniciar o sistema, sem downtime.

Sequência completa do ciclo de vida:
```
disco físico → pvcreate → vgextend → lvextend → cryptsetup resize (LUKS) → xfs_growfs
```

> *[PRINT: lsblk -f mostrando /home expandido com sdb incorporado]*
> *[PRINT: df -h /home antes e depois]*

---

## 9. Snapshots da VM

| Snapshot | Momento | Descrição |
|---|---|---|
| `Instalação Limpa da VM` | Logo após a instalação | AlmaLinux 10.2 com LUKS2+LVM, antes de qualquer configuração de SSH |
| `Configuração SSH Completa` | Após o hardening do SSH | Todas as diretivas de segurança aplicadas e testadas |
| `LVM Expandido` | Após o ciclo de vida do LVM | Disco secundário incorporado, /home expandido para 25G |

> *[PRINT: painel de Snapshots do VirtualBox com os três pontos]*

---

## 10. Seção de troubleshooting

### 10.1 ISO errada baixada inicialmente
**Problema:** a primeira ISO baixada foi a versão DVD (~9,4 GB), que inclui pacotes gráficos e não corresponde ao requisito de Minimal Install.
**Solução:** identificada a seção "Minimal" na página oficial de downloads, baixada a ISO correta (~2 GB) e validado o hash SHA-256 antes de prosseguir.

### 10.2 Ferramentas administrativas ausentes na instalação Minimal
**Problema:** comandos como `nano` e `semanage` não estavam disponíveis por padrão.
**Causa:** instalação Minimal reduz a superfície de pacotes instalados por padrão — isso é esperado e correto, não um erro de instalação.
**Solução:** instalados sob demanda (`dnf install nano`, `dnf install policycoreutils-python-utils`). Importante destacar: o **SELinux em si já estava ativo desde o primeiro boot** (`getenforce` retornando `Enforcing`) — apenas a ferramenta de administração (`semanage`) precisou ser instalada à parte.

### 10.3 Acesso SSH via IP interno não funcionava (Connection timed out)
**Problema:** tentativa de `ssh usuario@10.0.2.15` a partir do host resultava em timeout.
**Causa:** rede em modo NAT isola a VM; o host não consegue iniciar conexões para dentro da VM usando o IP interno.
**Solução:** configurado Port Forwarding no VirtualBox (host:2222 → VM:2155), permitindo teste via `ssh -p 2222 usuario@127.0.0.1`.

### 10.4 Autenticação por chave caindo para senha
**Problema:** mesmo com a chave pública corretamente instalada em `authorized_keys` (confirmado por fingerprint idêntico), o SSH solicitava a senha do usuário.
**Causa:** a passphrase da chave privada estava sendo digitada incorretamente três vezes seguidas; após esgotar as tentativas, o cliente SSH parte automaticamente para o próximo método de autenticação disponível (senha).
**Diagnóstico:** uso de `ssh -v` no cliente revelou claramente a sequência `Server accepts key` seguida de três tentativas de passphrase e posterior fallback para `password`.
**Solução:** confirmação cuidadosa da passphrase correta da chave privada.

### 10.5 LoginGraceTime excedido durante testes
**Problema:** conexão fechada com `kex_exchange_identification: Connection closed by remote host` após múltiplas tentativas seguidas de autenticação.
**Causa:** o servidor aplicou a penalidade de `LoginGraceTime` (tempo máximo para completar a autenticação) após a sessão anterior demorar demais entre tentativas de passphrase.
**Solução:** aguardar a liberação temporária e reconectar — comportamento normal e esperado de segurança do OpenSSH (o mesmo mecanismo que o trabalho pede para configurar explicitamente com `LoginGraceTime 30`).

### 10.6 Política de criptografia FUTURE quebrou a negociação SSH
**Problema:** ao aplicar `update-crypto-policies --set FUTURE`, a conexão SSH passou a falhar com `Unable to negotiate ... no matching key exchange method found`.
**Causa:** a política FUTURE habilita exclusivamente algoritmos de troca de chave pós-quânticos (ex.: `mlkem768x25519-sha256`), que o cliente OpenSSH do Windows utilizado ainda não suporta.
**Decisão do grupo:** revertido para uma política mais equilibrada. Testada a existência do módulo `NO-SHA1` (não disponível nesta versão do AlmaLinux 10 — a estrutura de módulos de política mudou em relação ao RHEL 9). Optado pela política `DEFAULT:OSPP`, perfil de hardening Common Criteria da Red Hat, validada como compatível com o cliente e efetiva na remoção de algoritmos legados (confirmado via `sshd -T`, sem SHA-1 presente nas MACs habilitadas).
**Aprendizado documentado:** segurança máxima teórica (FUTURE) nem sempre é a escolha correta em um ambiente com restrições reais de compatibilidade de cliente — trade-off consciente documentado como decisão de administração.

### 10.7 xfs_growfs não expandiu o filesystem após lvextend
**Problema:** após `lvextend -L +15G`, o `df -h /home` continuava mostrando o tamanho antigo (10G), e `xfs_growfs` retornava `data size unchanged, skipping`.
**Causa:** existe uma camada de criptografia LUKS entre o Logical Volume e o sistema de arquivos XFS. O `lvextend` expandiu apenas o LV; o mapeamento `/dev/mapper/luks-...` permaneceu no tamanho antigo até ser explicitamente redimensionado.
**Solução:** executado `cryptsetup resize luks-<uuid>` antes do `xfs_growfs`, alinhando o tamanho do mapeamento criptografado com o novo tamanho do LV. Após esse passo, o `xfs_growfs` reconheceu corretamente o espaço adicional.
**Observação:** esse passo intermediário não é mencionado em tutoriais genéricos de expansão de LVM (que assumem ausência de criptografia), sendo um ponto de atenção específico para ambientes com LVM sobre LUKS.

### 10.8 Conflitos de opções de montagem (nodev/nosuid/noexec)
*(A preencher pelo grupo conforme testes específicos realizados nas opções restritivas de `/tmp`, `/var/tmp`, `/var`, `/var/log` — documentar qualquer conflito real encontrado, por exemplo com atualizações de pacotes que descompactam em `/var/tmp`, ou serviços que dependam de execução em `/var`.)*

---

## Declaração de uso de IA

Conforme exigido pelo escopo do trabalho, o uso de IA generativa como apoio neste processo está declarado no arquivo `USO-DE-IA.md` do repositório.

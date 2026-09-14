# INSTALL.md — Grupo 3 (AlmaLinux)

Guia de instalação reproduzível: AlmaLinux 10.2 com LVM sobre LUKS, serviço SSH endurecido e ciclo de vida do LVM.

## Sumário

1. [Ambiente e Criação da VM](#1-ambiente-e-criação-da-vm)
2. [Verificação de integridade da ISO](#2-verificação-de-integridade-da-iso)
3. [Diagrama de particionamento](#3-diagrama-de-particionamento)
4. [Instalação — particionamento manual (LUKS + LVM)](#4-instalação--particionamento-manual-luks--lvm)
5. [Primeiro acesso e verificação inicial](#5-primeiro-acesso-e-verificação-inicial)
6. [Configuração do SSH endurecido](#6-configuração-do-ssh-endurecido)
7. [Ciclo de vida do LVM — disco secundário](#7-ciclo-de-vida-do-lvm--disco-secundário)
8. [Snapshots da VM](#8-snapshots-da-vm)
9. [Seção de troubleshooting](#9-seção-de-troubleshooting)

---

## 1. Ambiente e Criação da VM

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

<img width="1091" height="715" alt="image" src="https://github.com/user-attachments/assets/ffae2489-d7ae-4cee-859d-2f61a38cb883" />


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

<img width="988" height="95" alt="image" src="https://github.com/user-attachments/assets/fdc5a6f8-7c15-4555-b2a7-02810d26ffab" />
<img width="793" height="100" alt="image" src="https://github.com/user-attachments/assets/7ab7a121-2d7f-4594-8e3b-b7460b7c8848" />


---

## 3. Diagrama de particionamento

Esquema de referência (**antes** da instalação):

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

<img width="1360" height="1080" alt="image" src="https://github.com/user-attachments/assets/69ace3e7-18fc-45d7-842b-450ae3da6789" />


---

## 4. Instalação — particionamento manual (LUKS + LVM)

### 4.1 Criação dos pontos de montagem fora do LUKS

No particionamento manual do Anaconda, os dois primeiros pontos de montagem foram criados **sem** marcar "Criptografar", pois o GRUB precisa ler o kernel antes de existir qualquer chave de descriptografia:

- `/boot/efi` — 1 GiB — Partição padrão — EFI System Partition
- `/boot` — 1 GiB — Partição padrão — xfs

<img width="1244" height="709" alt="image" src="https://github.com/user-attachments/assets/f867e9d3-c5f4-48bd-b651-2f49fd3d374d" />
<img width="1265" height="782" alt="image" src="https://github.com/user-attachments/assets/d44b463c-4730-49e1-bea8-3b9c032c9244" />


### 4.2 Criação do `/` com LVM + LUKS

Ao criar o ponto de montagem `/`, o tipo de dispositivo foi alterado para **LVM**, a caixa **"Criptografar"** foi marcada, e um novo Volume Group (`almalinux_10`) foi criado. Nesse momento o Anaconda solicitou a definição da **passphrase do LUKS**.


<img width="1256" height="710" alt="image" src="https://github.com/user-attachments/assets/af74613d-372a-47ff-8aa0-feb39e19c4a8" />


### 4.3 Criação dos demais LVs

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


<img width="646" height="514" alt="image" src="https://github.com/user-attachments/assets/395abc17-7371-4456-8edd-4cf8e9acca67" />


### 4.5 Demais configurações da instalação

- Teclado: Português (Brasil)
- Fuso horário: Américas/São Paulo
- Seleção de programas: Instalação Mínima
- Conta root: senha definida (uso local/emergencial apenas — login remoto via SSH será bloqueado)
- Criação de usuário: usuário comum criado, marcado como administrador (grupo `wheel`)
- KDUMP: mantido com configuração padrão (Ativar kdump / Automático)

---

## 5. Primeiro acesso e verificação inicial

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

## 6. Configuração do SSH endurecido

### 6.1 Geração do par de chaves ed25519 (no host, não na VM)

```powershell
ssh-keygen -t ed25519 -C "grupo3-almalinux"
```

Chave protegida por passphrase própria (camada adicional de segurança do lado do cliente).

### 6.2 Cópia da chave pública para a VM

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA... grupo3-almalinux" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 6.3 Grupo dedicado para acesso SSH

```bash
sudo groupadd sshusers
sudo usermod -aG sshusers usuario
```

### 6.4 Port forwarding (ambiente de teste local)

Como a VM está em rede NAT, foi configurada uma regra de redirecionamento no VirtualBox para permitir testes a partir do host:

| Nome | Protocolo | Porta Hospedeiro | Porta Convidado |
|---|---|---|---|
| SSH | TCP | 2222 | 2155 |

> Nota: esse redirecionamento existe apenas para viabilizar o teste a partir do computador host durante o desenvolvimento; não representa exposição da VM à rede externa.

### 6.5 Diretivas aplicadas em `/etc/ssh/sshd_config`

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

### 6.6 SELinux — rótulo da porta customizada

```bash
sudo dnf install policycoreutils-python-utils -y
sudo semanage port -a -t ssh_port_t -p tcp 2155
sudo semanage port -l | grep ssh
```
Resultado: `ssh_port_t   tcp   2155, 22`

<img width="412" height="32" alt="image" src="https://github.com/user-attachments/assets/077b0e94-ac3c-4d86-b176-c0a821a1c770" />


### 6.7 update-crypto-policies

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

<img width="1270" height="142" alt="image" src="https://github.com/user-attachments/assets/83df2740-ca4c-4e37-9f7b-92ad297f4dcb" />


### 6.8 firewalld

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="2155" protocol="tcp" accept limit value="10/m"'
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

Resultado: apenas a porta 2155/tcp liberada, com limite de taxa de 10 novas conexões por minuto (proteção complementar contra força bruta).

<img width="757" height="295" alt="image" src="https://github.com/user-attachments/assets/b58c56f2-41fb-4961-be42-571af9ff2196" />


### 6.9 Banner de aviso legal

`/etc/issue.net`:
```
Acesso restrito a usuários autorizados. Toda atividade neste sistema é monitorada e registrada. O acesso não autorizado é crime, conforme Art. 154-A do Código Penal (Lei 12.737/2012).
```

Banner confirmado apresentado ao cliente antes da autenticação.

<img width="784" height="129" alt="image" src="https://github.com/user-attachments/assets/409085a4-9608-4da4-a288-8c76fe6c9662" />


### 6.10 Verificação da configuração efetiva

```bash
sudo sshd -T | grep -E "port|permitrootlogin|passwordauthentication|allowgroups|maxauthtries|logingracetime|clientaliveinterval"
```

<img width="1247" height="195" alt="image" src="https://github.com/user-attachments/assets/01f5d3d1-4f50-442a-a56c-43374b2a66e4" />


### 6.11 Evidências finais — acesso e bloqueio

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

<img width="1010" height="182" alt="image" src="https://github.com/user-attachments/assets/3a627ec6-f94e-417a-837a-1d772ebc9ad4" />

---

## 7. Ciclo de vida do LVM — disco secundário

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

**Passo adicional necessário por causa do LUKS**: o `lvextend` expande o Logical Volume, mas o mapeamento LUKS por cima dele não é redimensionado automaticamente. É necessário:

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

Sequência completa:
```
disco físico → pvcreate → vgextend → lvextend → cryptsetup resize (LUKS) → xfs_growfs
```

<img width="1185" height="409" alt="image" src="https://github.com/user-attachments/assets/38bb404e-7c1c-4c02-86d7-9feca8d0ef04" />

<img width="813" height="68" alt="image" src="https://github.com/user-attachments/assets/97a61816-7647-491a-9e7b-65c1f1c66099" />


---

## 8. Snapshots da VM

| Snapshot | Momento | Descrição |
|---|---|---|
| `Instalação Limpa da VM` | Logo após a instalação | AlmaLinux 10.2 com LUKS2+LVM, antes de qualquer configuração de SSH |
| `Configuração SSH Completa` | Após o hardening do SSH | Todas as diretivas de segurança aplicadas e testadas |
| `LVM Expandido` | Após o ciclo de vida do LVM | Disco secundário incorporado, /home expandido para 25G |

<img width="1089" height="143" alt="image" src="https://github.com/user-attachments/assets/a25ee07e-11d4-40a6-a4f5-a3c76af77cf7" />


---

## 9. Seção de troubleshooting

### 9.1 ISO errada baixada inicialmente
**Problema:** a primeira ISO baixada foi a versão DVD (~9,4 GB), que inclui pacotes gráficos e não corresponde ao requisito de Minimal Install.
**Solução:** identificada a seção "Minimal" na página oficial de downloads, baixada a ISO correta (~2 GB) e validado o hash SHA-256 antes de prosseguir.

### 9.2 Ferramentas administrativas ausentes na instalação Minimal
**Problema:** comandos como `nano` e `semanage` não estavam disponíveis por padrão.
**Causa:** instalação Minimal reduz a superfície de pacotes instalados por padrão — isso é esperado e correto, não um erro de instalação.
**Solução:** instalados sob demanda (`dnf install nano`, `dnf install policycoreutils-python-utils`). Importante destacar: o **SELinux em si já estava ativo desde o primeiro boot** (`getenforce` retornando `Enforcing`) — apenas a ferramenta de administração (`semanage`) precisou ser instalada à parte.

### 9.3 Acesso SSH via IP interno não funcionava (Connection timed out)
**Problema:** tentativa de `ssh usuario@10.0.2.15` a partir do host resultava em timeout.
**Causa:** rede em modo NAT isola a VM; o host não consegue iniciar conexões para dentro da VM usando o IP interno.
**Solução:** configurado Port Forwarding no VirtualBox (host:2222 → VM:2155), permitindo teste via `ssh -p 2222 usuario@127.0.0.1`.

### 9.4 Autenticação por chave caindo para senha
**Problema:** mesmo com a chave pública corretamente instalada em `authorized_keys` (confirmado por fingerprint idêntico), o SSH solicitava a senha do usuário.
**Causa:** a passphrase da chave privada estava sendo digitada incorretamente três vezes seguidas; após esgotar as tentativas, o cliente SSH parte automaticamente para o próximo método de autenticação disponível (senha).
**Diagnóstico:** uso de `ssh -v` no cliente revelou claramente a sequência `Server accepts key` seguida de três tentativas de passphrase e posterior fallback para `password`.
**Solução:** confirmação cuidadosa da passphrase correta da chave privada.

### 9.5 LoginGraceTime excedido durante testes
**Problema:** conexão fechada com `kex_exchange_identification: Connection closed by remote host` após múltiplas tentativas seguidas de autenticação.
**Causa:** o servidor aplicou a penalidade de `LoginGraceTime` (tempo máximo para completar a autenticação) após a sessão anterior demorar demais entre tentativas de passphrase.
**Solução:** aguardar a liberação temporária e reconectar — comportamento normal e esperado de segurança do OpenSSH (o mesmo mecanismo que o trabalho pede para configurar explicitamente com `LoginGraceTime 30`).

### 9.6 Política de criptografia FUTURE quebrou a negociação SSH
**Problema:** ao aplicar `update-crypto-policies --set FUTURE`, a conexão SSH passou a falhar com `Unable to negotiate ... no matching key exchange method found`.
**Causa:** a política FUTURE habilita exclusivamente algoritmos de troca de chave pós-quânticos (ex.: `mlkem768x25519-sha256`), que o cliente OpenSSH do Windows utilizado ainda não suporta.
**Decisão do grupo:** revertido para uma política mais equilibrada. Testada a existência do módulo `NO-SHA1` (não disponível nesta versão do AlmaLinux 10 — a estrutura de módulos de política mudou em relação ao RHEL 9). Optado pela política `DEFAULT:OSPP`, perfil de hardening Common Criteria da Red Hat, validada como compatível com o cliente e efetiva na remoção de algoritmos legados (confirmado via `sshd -T`, sem SHA-1 presente nas MACs habilitadas).
**Aprendizado documentado:** segurança máxima teórica (FUTURE) nem sempre é a escolha correta em um ambiente com restrições reais de compatibilidade de cliente — trade-off consciente documentado como decisão de administração.

### 9.7 xfs_growfs não expandiu o filesystem após lvextend
**Problema:** após `lvextend -L +15G`, o `df -h /home` continuava mostrando o tamanho antigo (10G), e `xfs_growfs` retornava `data size unchanged, skipping`.
**Causa:** existe uma camada de criptografia LUKS entre o Logical Volume e o sistema de arquivos XFS. O `lvextend` expandiu apenas o LV; o mapeamento `/dev/mapper/luks-...` permaneceu no tamanho antigo até ser explicitamente redimensionado.
**Solução:** executado `cryptsetup resize luks-<uuid>` antes do `xfs_growfs`, alinhando o tamanho do mapeamento criptografado com o novo tamanho do LV. Após esse passo, o `xfs_growfs` reconheceu corretamente o espaço adicional.
**Observação:** esse passo intermediário não é mencionado em tutoriais genéricos de expansão de LVM (que assumem ausência de criptografia), sendo um ponto de atenção específico para ambientes com LVM sobre LUKS.

### 9.8 Conflitos de opções de montagem (nodev/nosuid/noexec)
*(A preencher pelo grupo conforme testes específicos realizados nas opções restritivas de `/tmp`, `/var/tmp`, `/var`, `/var/log` — documentar qualquer conflito real encontrado, por exemplo com atualizações de pacotes que descompactam em `/var/tmp`, ou serviços que dependam de execução em `/var`.)*

---

## Declaração de uso de IA

Conforme exigido pelo escopo do trabalho, o uso de IA generativa como apoio neste processo está declarado no arquivo `USO-DE-IA.md` do repositório.

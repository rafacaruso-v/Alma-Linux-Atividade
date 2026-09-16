# Prompts utilizados para IA

Abaixo vai estar os pedidos feitos para a IA junto com a resposta dela:


## 1) Criação do modelo do INSTALL.md

Pedido: 

Crie um modelo do INSTALL.md de tudo que fizemos e deixe espaço para eu mesmo adicionar prints.

--

Resposta da IA: 

Criei o INSTALL.md completo, documentando tudo que fizemos até agora, seção por seção. Ele já está estruturado exatamente como o trabalho pede: guia reproduzível + diagrama + espaço para prints + seção de troubleshooting robusta.

O que está dentro
Ambiente e pré-requisitos
Verificação de integridade da ISO
Criação da VM
Diagrama de particionamento
Instalação manual (LUKS + LVM) passo a passo
Configuração completa do SSH endurecido (todas as 10 diretivas)
Ciclo de vida do LVM com o disco secundário
Lista dos 3 snapshots
7 casos reais de troubleshooting documentados com problema → causa → solução (ISO errada, ferramentas ausentes, timeout de conexão, chave caindo pra senha, LoginGraceTime, política FUTURE quebrando SSH, e o resize do LUKS)

--

## 2) Criação do layout dos slides

Pedido:

Monte um layout para os slides com o tema do sistema AlmaLinux onde eu consiga colocar as informaçoes.

--

Resposta da IA: 

Montado o Layout dos slides para os seguintes temas

Instalação do AlmaLinux 10.2 (Minimal Install, VirtualBox e SELinux Enforcing).  
Particionamento seguro com LUKS2 e LVM.  
Expansão do volume lógico (/home) integrando LVM e LUKS2.  
Hardening do serviço SSH (alteração para porta 2155, chaves ed25519, bloqueio de root/senha e grupo restrito).  
Regras de firewall e limite de conexões por minuto via firewalld.  
Banner de aviso legal de acesso no /etc/issue.net.  
Ajuste da política de criptografia do sistema para DEFAULT:OSPP.  
Script em Shell de verificação de integridade de arquivos (fim-check.sh) automatizado via timer do systemd. 
Questionário acadêmico interativo.

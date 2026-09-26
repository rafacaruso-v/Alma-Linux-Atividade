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

## 3). Desenvolvimento do script de integridade fim-check.sh

Pedido:

Eu tô adaptando um código para fazer um shell script chamado fim-check.sh de uma atividade que o professor passou sobre o AlmaLinux e queria manter a estrutura que já tô usando e fazer apenas os ajustes necessários para atender aos requisitos da atividade. Pode me ajudar a entender o que ainda precisa ser adaptado?


Resposta da IA:

Foi analisada a estrutura do script e indicados os ajustes necessários para atender aos requisitos, mantendo a ideia principal do código. Entre os pontos trabalhados estavam a organização em funções, o tratamento das opções, a geração do baseline, a comparação dos arquivos e a classificação das alterações.

## 4). Organização das opções com getopts

Pedido:

No código que estou mexendo já tem o getopts. Como que eu posso manter essa estrutura e fazer o tratamento das opções?


Resposta da IA:

Foi explicado como manter o getopts para receber as opções pela linha de comando e organizar o tratamento delas. Também foi mostrado como utilizar as opções de ajuda e execução do script sem precisar modificar toda a estrutura existente.


## 5). Utilização do case no tratamento das opções

Pedido:

No vídeo, a parte onde tá as opções está sendo tratada com case. Como que eu poderia tá organizando essa parte para que cada opção execute corretamente a função correspondente sem deixar necessariamente o código muito complicado? isto é, para poder usar o getopts junto ao case. 


Resposta da IA:

Foi mostrada uma forma de organizar o case junto com o getopts, fazendo cada opção chamar a função correspondente. Dessa forma, o código fica separado em partes e cada opção possui uma responsabilidade específica.


## 6). Utilização do set -euo pipefail

Pedido:

O código que o professor pediu para usar como base precisa ter set -euo pipefail. Isso é só pra parar de executar caso dê algo errado né? existe alguma coisa que preciso tomar cuidado ao rodar o código?


Resposta da IA:

Foi explicado que:

 "-e" faz o script interromper quando um comando retorna erro;
 "-u" trata variáveis não definidas como erro;
 "pipefail" faz um pipeline retornar erro caso algum comando anterior falhe.

Também foram apontados alguns cuidados necessários ao adaptar o código, principalmente com variáveis que podem não existir e comandos que podem retornar códigos diferentes de zero durante as verificações.

## 7). Utilização de mktemp e trap

Pedido:

O script tem que utilizar mktemp e trap para trabalhar com arquivos temporários. Como que eu coloco essa lógica na minha versão e garanto que esses arquivos sejam removidos corretamente depois da execução? passo pra qual função o caminho?

Resposta da IA:

Foi explicado que o mktemp pode ser utilizado para criar arquivos temporários com nomes seguros e que o trap pode executar uma função de limpeza quando o script terminar.

A estrutura foi mantida para evitar que arquivos temporários fiquem no sistema caso o script termine normalmente ou seja interrompido. Também foi explicado onde manter o caminho do arquivo temporário para que ele possa ser utilizado pela função responsável pela limpeza.

## 8). Configuração do serviço fim.service

Pedido:

Criei um service para executar o meu fim-check.sh, mas quando tento iniciar ele não executa o script, creio eu que seja erro de localização. pode me confirmar o que tá errado no ExecStart e como posso corrigir sem ter que mudar algo muito diferente no script?


Resposta da IA:

O erro estava relacionado à forma como o systemd estava tentando executar o script. O ExecStart estava apontando diretamente para o arquivo, então foram verificadas a localização, as permissões de execução e a forma como o script deveria ser chamado. A correção foi chamar o Bash diretamente pelo ExecStart.

Como o script é um Shell Script, uma forma de corrigir foi fazer o ExecStart chamar o Bash diretamente:
ExecStart=/bin/bash /root/Systemd/fim-check.sh

vídeos usados como base/pra entendimento:


https://youtu.be/Kawn6HK47Ag
https://youtu.be/ziw856QiP34
https://youtu.be/hunmD-iWVWA
https://youtu.be/8640OcCL8T8
https://youtu.be/OV3Gc0SISUo
https://youtu.be/hqdN12E5Jk8
https://youtu.be/5O4SLIDSMqg

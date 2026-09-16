#!/bin/bash
#serve para encerrar o script em caso de erro e gera erro em caso de uma variável não definida anteriormente ser usada em uma função. Também detecta os erros em pipelines
set -euo pipefail

#função de log pra adicoinar a data, hora e a mensagem recebida pro arquivo fim-check.log (/var/log/fim-check.log)
log(){
echo "$(date '+%Y-%m-%d %H:%M%:%S') $*" >> /var/log/fim-check.log
}
#executa a função
log

#é a função responsável pelos parâmetros do script, isto é, fazer o script aceitar -h e --help para exibir a descrição, como executar e os comandos
habilitar_getopts(){
#cria variáveis locais para processar as opções e poder evitar interferência no reso do script
local OPTIND opt
#inicia a váriavel help vazio
help=""
#verifica se  o script recebeu um argumento
if [ "$#" -gt 0 ]; then
#guarda o primeiro argumento na variável help
help="$1"
#verifica se o argumento que foi recebido se trata de --help e se sim, exibe as mensagens abaixo
if [ "$help" = "--help" ]; then
echo "Como executar: $0"
echo "Descrição: O arquivo se trata de um verificador de integridade de arquivos"
echo "Comandos: -h --help para exibir a tela de ajuda"
#encerra o script com código 0, que indica que não teve nenhum erro.
exit 0
fi
fi
#se foi passado só o - trata como opção inválida
if [ "$help" = "-" ]; then
echo "Erro: opção inválida '-'"
#registra como [ERROR] no log
log "[ERROR] Opção inválida '-' "
#encerra com código 2 (que é erro de sintaxe/uso incorreto dos parâmetros
exit 2
fi
#analisa qual foi a opção recebida (nesse caso apenas o -h) e exibe como executar, descrição e os comandos do arquivo.
while getopts ":h" opt; do
case $opt in
h)
echo "Como executar: $0"
echo "Descrição: O arquivo se trata de um verificador de integridade de arquivos"
echo "Comandos: -h --help para exibir a tela de ajuda"
exit 0
;;
#caso seja informada uma opção que não existe, gera um erro no log e informa qual função é inválida
\?)
echo "Erro: opção inválida: $OPTARG"
log "[ERROR] Opção inválida: $OPTARG"
exit 2
;;

#no while getopts tem o :h, esses dois pontos são os responsáveis por deixar eu passar os erros a serem exibidos na tela de que a opção precisa de um argumento"
:)
echo "Erro: O $OPTARG precisa receber um argumento"
log "[ERROR] O $OPTARG precisa receber um argumento"
exit 2
;;
esac
done
}
#chama a função para tratar os parametros passando todos os argumentos ($@a que é o -h ou o --help caso digitados corretamente)
habilitar_getopts "$@"
#se trata da função para verificar se o usuário pode ou não executar o código
verificar_privilegio(){
#se o id do usuário for diferente de 0 (que é o número do id do root) exibe a mensagem de que não foi possível executar o arquivo, usuário não é root, do contrário exibe Script executado com sucesso
if [ ! "$EUID" -eq 0 ]; then
echo "Não foi possível executar o arquivo, usuário não é root"
#executa exit 1, que é o erro durante a execução, dizendo que alguma coisa falhou
exit 1
else
echo "Script executado com sucesso"
fi
#da um tempo de 5 segundos até a próxima função
sleep 5
}
#executa a função
verificar_privilegio

#é a função para analisar se os pacotes existem ou não
analisar_dependencias(){

#Percorre uma lista com os comandos sha256 stat find mktemp nano semanage e exibe se eles existem ou nao
for comando in sha256 stat find mktemp nano semanage
do

if command -v "$comando"; then
echo "O programa existe"
else
echo "O programa não existe"
fi
done
sleep 5
}
#executa a função
analisar_dependencias

#se trata da função que cria a primeira baseline para comparativo
calcular_a_hash(){
#informa que começou a calcular a hash
echo "Calculando a hash"
#salva no log
log "[INFO] Calculando a hash dos arquivos"
sleep 5
#aqui o find procura arquivos nas pastas /etc /bin /sbin /boot /etc/ssh limitando somente a arquivos (por conta do type f)
find /etc /bin /sbin /boot /etc/ssh -type f | while read -r arquivo
do
#mostra qual arquivo está sendo analisado
echo "$arquivo"
#da o valor da hash gerada com o sha256sum para a variavel hash
read -r hash _ < <(sha256sum "$arquivo")
#recebe o dono do arquivo
dono=$(stat -c '%U' "$arquivo")
#recebe a permissão do arquivo
permissao=$(stat -c '%a' "$arquivo")
#recebe o contexto de segurança do SElinux
selinux=$(stat -c '%C' "$arquivo")
#salva as informações formatadas da baseline em /tmp/baseline.txt
echo "$hash|$arquivo|$dono|$permissao|$selinux" >> /tmp/baseline.txt

done
sleep 5
echo "O valor da hash foi guardado em /tmp/baseline.txt"
log "[INFO] Baseline foi criada em /tmp/baseline.txt"
}

#é a função que compara os arquivos existentes atuais com os da baseline antiga
baseline(){
#cria uma arquivo temporário
TEMP=$(mktemp)
#quando o script terminar, o trap remove o arquivo temporário
trap 'rm -f "$TEMP"' EXIT
#põe o conteúdo da baseline na  variável baseline
baseline=$(cat /tmp/baseline.txt)
#procura uma outra vez os arquivos nos seguintes diretórios
find /etc /bin /sbin /boot /etc/ssh -type f | while read -r arquivo
do
#faz o cálculo da hash atual do arquivo e coloca no arquivo temporário $TEMP
sha256sum "$arquivo" >"$TEMP"
#L~e o valor da hash que foi gerada
read -r hash_gerada _ < "$TEMP"
#vai percorrendo a lista da baseline e converte o  | em espaços para facilitar a leitura
echo "$baseline" | tr '|' ' ' | while read -r hash_antiga arquivo1 dono_antigo permissao_antiga selinux_antigo
do
#verifica se arquivo atual já existe na baseline
if [ "$arquivo" = "$arquivo1" ]; then
#compara a hash gerada agora com a hash antiga,
if [ "$hash_gerada" = "$hash_antiga" ]; then
#se iguais, exibe que nada foi modificado
echo "Nada foi modificado."
#salva no log
log "[INFO] Nenhuma mudança foi encontrada no $arquivo1"
else
#se está diferente, exibe o arquivo e diz que ele foi modificado
echo "A classificação do arquivo é: Modificado $arquivo1"
#salva o log como [WARN] que reflete que o arquivo sofreu alteração
log "[WARN] O $arquivo1 foi modificado"
fi
#recebe o dono atual do arquivo
dono_atual=$(stat -c '%U' "$arquivo")
#recebe a permissao atual do arquivo
permissao_atual=$(stat -c '%a' "$arquivo")
#recebe o contexto do SELinux atual
selinux_atual=$(stat -c '%C' "$arquivo")

#compara o proprietário atual com o da hash antiga
if [ "$dono_atual" != "$dono_antigo" ]; then
#se o dono do arquivo atual for diferente do antigo, exibe que o arquivo foi modificado, que o dono mudou e salva no log como [WARN]
echo "A classificação do arquivo é: Modificado $arquivo1"
echo "O dono foi alterado"
log "[WARN] O dono do $arquivo1 foi alterado"
fi
#se a permissão do arquivo atual for difernte da antiga, exibe o arquivo sofreu alteração e que a permissão foi alterada, salvando no log como [WARN]
if [ "$permissao_atual" != "$permissao_antiga" ]; then
echo "A classificação do arquivo é: Modificado $arquivo1"
echo "A permissão foi alterada"
log "[WARN] A permissão do $arquivo1 foi alterada"
fi
#se o contexto do selinux atual for diferente do contexto antigo, exibe a classificação de que o arquivo foi modificado, que o contexto foi alterado e salva no log como [WARN]
if [ "$selinux_atual" != "$selinux_antigo" ]; then
echo "A classificação do arquivo é: Modificado $arquivo1"
echo "O contexto SELinux foi alterado"
log "[WARN] O contexto SElinux do $arquivo1 foi alterado"
fi
fi
done
done
#busca novamente os arquivos da baseline
echo "$baseline" | tr '|' ' ' | while read -r hash_antiga arquivo1 dono_antigo permissao_antiga selinux_antigo
do
#faz a verificação de se o arquivo da baseline não existe mais e caso não exista mais, exibe que foi removido
if [ !  -f "$arquivo1" ]; then
echo "O $arquivo1 foi removido"
log "[WARN] O $arquivo1 foi removido"
fi
done
#procura os arquivos atuais nos diretórios /etc /bin /sbin /boot /etc/ssh
find /etc /bin /sbin /boot /etc/ssh -type f | while read -r arquivo
do
#verifica se o arquivo atual não existe na baseline antiga
if ! grep -Fq "|$arquivo|" /tmp/baseline.txt; then
#se ainda não existia, classifica como novo
echo "A classificação do arquivo é: Novo $arquivo"
#salva o log
log "[WARN] O $arquivo é um arquivo novo"
#faz o calculo do hash do novo arquivo
read -r hash_novo _ < <(sha256sum "$arquivo")
#recebe o dono do arquivo novo
dono_novo=$(stat -c '%U' "$arquivo")
#recebe a permissão do arquivo novo
permissao_novo=$(stat -c '%a' "$arquivo")
#recebe o contexto selinux do arquivo novo
selinux_novo=$(stat -c '%C' "$arquivo")
#salva o arquivo na baseline antiga
echo "$hash_novo|$arquivo|$dono_novo|$permissao_novo|$selinux_novo" >> /tmp/baseline.txt
fi
done
}
#verifica se a baseline ainda não existe
if [ ! -f /tmp/baseline.txt ]; then
#caso não existe, executa a função calcular_a_hash (que cria uma baseline)
calcular_a_hash
else
#se existir, pula direto para a função de comparar o sistema atual com a baseline antiga
baseline
fi

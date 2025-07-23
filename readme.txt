top_level deve ser executado como top_level!!

a hierarquia é a seguinte:
1- top_level
  contem o modulo principal, executa o modulo fsm

2- fsm
  contem os modulos driver_lcd e contador_num_time, executa toda a inicialização do lcd e depois envia os dados pra ele.
  utiliza os dados "number" e "tick_segundo" do modulo contador_num_time como dados para impressao ou para execuçao de etapas.

3- driver_lcd
  onde é executada e confirmada a escrita no lcd, os dados são recebidos de fsm.

4- contador_num_time
  conta os ticks de 1segundo e incrementa o number a cada um desses ticks, reseta se number == 99.

ATENÇÃO: reset é utilizado como entrada, um pino deve ser escolhido para ele. o reset não será quem vai voltar os valores
iniciais quando number == 99, ele só irá resetar quando o botão ou o switch for acionado, é considerado uma boa pratica.

Você pode conferir todas as entradas e saídas no top_level.


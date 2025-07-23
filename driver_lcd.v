module driver_lcd (
    input clk,              // Clock de 50 MHz
    input reset_num,          // Reset ativo baixo
    input [7:0] dado_a_enviar, // Dado ou comando a ser escrito no LCD
    input rs_a_enviar,      // Sinal RS para o LCD (0=comando, 1=dado)
    input solicitar_escrita, // Pulso de um ciclo para iniciar uma escrita no LCD

    output reg [7:0] lcd_data_bus, // Barramento de dados para o LCD
    output reg lcd_en,             // Sinal Enable para o LCD
    output reg lcd_rw,             // Sinal Read/Write para o LCD (sempre 0 para escrita)
    output reg lcd_rs,             // Sinal Register Select para o LCD

    output reg escrita_concluida // Sinal de pulso: indica que uma escrita terminou
);

// --- Parâmetros ---
// O LCD precisa de um atraso de ~1ms para processar comandos/dados
// 50 MHz * 0.001s = 50,000 ciclos
parameter VALOR_PULSO_MS = 50_000;

// --- Estados da FSM interna do Driver LCD ---
parameter IDLE = 0, PULSO_WRITE = 1, PULSO_WAIT = 2;
reg [1:0] estado_driver; // 2 bits para 3 estados

// --- Variáveis Internas ---
reg [31:0] contador_pulso_ms; // Contador para o delay de ~1ms

// --- Lógica Principal do Driver (executada a cada pulso de clock) ---
always @(posedge clk) begin
    if (!reset_num) begin // Reset ativo baixo volta para o estado inicial
        // Reseta todos os sinais e estados
        estado_driver <= IDLE;
        lcd_en <= 0;
        lcd_data_bus <= 0;
        lcd_rs <= 0;
        lcd_rw <= 0; // Sempre 0 para escrita
        contador_pulso_ms <= 0;
        escrita_concluida <= 0;
    end else begin // Se não houver reset, executa a lógica do driver
        lcd_rw <= 0; // Garante que RW esteja sempre em 0 (modo de escrita)
        escrita_concluida <= 0; // Reseta o sinal de conclusão a cada ciclo

        case (estado_driver)
            IDLE: begin
                lcd_en <= 0; // EN desabilitado
                lcd_data_bus <= dado_a_enviar; // Coloca o dado/comando no barramento
                lcd_rs <= rs_a_enviar;         // Coloca o RS no pino

                if (solicitar_escrita == 1) begin // Se o módulo principal solicitou uma escrita
                    estado_driver <= PULSO_WRITE;
                    contador_pulso_ms <= 0;
                end
            end

            PULSO_WRITE: begin
                lcd_en <= 1; // Habilita EN (nível alto)
                if (contador_pulso_ms == (VALOR_PULSO_MS - 1)) begin // Se o tempo de EN alto passou
                    estado_driver <= PULSO_WAIT;
                    contador_pulso_ms <= 0;
                end else begin
                    contador_pulso_ms <= contador_pulso_ms + 1;
                end
            end

            PULSO_WAIT: begin
                lcd_en <= 0; // Desabilita EN (borda de descida registra o dado no LCD)
                if (contador_pulso_ms == (VALOR_PULSO_MS - 1)) begin // Se o tempo de EN baixo passou
                    estado_driver <= IDLE;
                    escrita_concluida <= 1; // Sinaliza que a escrita terminou para o módulo principal
                end else begin
                    contador_pulso_ms <= contador_pulso_ms + 1;
                end
            end

            default: estado_driver <= IDLE; // Estado de segurança
        endcase
    end
end

endmodule
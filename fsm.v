module fsm_principal_lcd (
    input clk,               // Clock de 50 MHz da FPGA
    input reset_num,           // Reset ativo baixo
    input enable_switch,     // Sinal do switch para habilitar/travar a contagem

    output [7:0] lcd_data_bus_out, // Saida final do barramento de dados para o LCD
    output lcd_en_out,             // Saida final do EN para o LCD
    output lcd_rw_out,             // Saida final do RW para o LCD
    output lcd_rs_out              // Saida final do RS para o LCD
);

// --- Sinais internos para comunicação entre módulos ---
wire tick_segundo; // Do modulo contador_tempo_e_numero
wire [7:0] number;    // Do modulo contador_tempo_e_numero

wire escrita_driver_lcd_concluida; // Do modulo driver_lcd

reg [7:0] dado_para_driver;     // Dados/Comandos que esta FSM envia para o driver_lcd
reg rs_para_driver;             // RS que esta FSM envia para o driver_lcd
reg solicitar_escrita_driver;   // Pulso que esta FSM envia para o driver_lcd

// --- Instância do Módulo 1: Contador de Tempo e Número ---
contador_num_time contadores (
    .clk(clk),
    .reset_num(reset_num),      // Mapeado corretamente para o input 'reset' do módulo 'contadores'
    .enable_switch(enable_switch),   // Mapeado corretamente para o input 'EN' do módulo 'contadores'
    .tick_segundo(tick_segundo), // Mapeado corretamente para o output 'tick_segundo'
    .number(number)             // Mapeado corretamente para o output 'num'
);

// --- Instância do Módulo 2: Driver do LCD ---
driver_lcd driver_lcd (
    .clk(clk),
    .reset_num(reset_num),  // Mapeado corretamente para o input 'reset_n' do módulo 'driver_lcd'
    .dado_a_enviar(dado_para_driver),
    .rs_a_enviar(rs_para_driver),
    .solicitar_escrita(solicitar_escrita_driver),
    .lcd_data_bus(lcd_data_bus_out),
    .lcd_en(lcd_en_out),
    .lcd_rw(lcd_rw_out),
    .lcd_rs(lcd_rs_out),
    .escrita_concluida(escrita_driver_lcd_concluida)
);

// --- Estados da FSM Principal ---
parameter S_INICIALIZAR_LCD_0 = 0, // Inicia configuracao LCD (0x38)
          S_INICIALIZAR_LCD_1 = 1, // (0x0E)
          S_INICIALIZAR_LCD_2 = 2, // (0x01)
          S_INICIALIZAR_LCD_3 = 3, // (0x02)
          S_INICIALIZAR_LCD_4 = 4, // (0x06)
          S_ESPERAR_ATUALIZACAO = 5, // Espera pelo tick de 1s
          S_ENVIAR_COMANDO_POSICAO = 6, // Posiciona cursor (0x80)
          S_ENVIAR_DIGITO_DEZENA = 7, // Envia digito da dezena
          S_ENVIAR_DIGITO_UNIDADE = 8; // Envia digito da unidade

reg [3:0] estado_principal; // 4 bits para 9 estados

// --- Lógica da FSM Principal (executada a cada pulso de clock) ---
always @(posedge clk) begin
    if (!reset_num) begin // Reset ativo baixo
        estado_principal <= S_INICIALIZAR_LCD_0;
        solicitar_escrita_driver <= 0;
    end else begin
        solicitar_escrita_driver <= 0; // Reseta o pulso de solicitação a cada ciclo

        case (estado_principal)
            S_INICIALIZAR_LCD_0: begin // Comando: Function Set (8-bit, 2 Line, 5x7 Dots)
                dado_para_driver <= 8'h38;
                rs_para_driver <= 0; // Comando
                solicitar_escrita_driver <= 1;
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_INICIALIZAR_LCD_1;
            end
            S_INICIALIZAR_LCD_1: begin // Comando: Display on, Cursor on, Blink off
                dado_para_driver <= 8'h0E;
                rs_para_driver <= 0; // Comando
                solicitar_escrita_driver <= 1;
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_INICIALIZAR_LCD_2;
            end
            S_INICIALIZAR_LCD_2: begin // Comando: Clear Display Screen
                dado_para_driver <= 8'h01;
                rs_para_driver <= 0; // Comando
                solicitar_escrita_driver <= 1;
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_INICIALIZAR_LCD_3;
            end
            S_INICIALIZAR_LCD_3: begin // Comando: Cursor Home
                dado_para_driver <= 8'h02;
                rs_para_driver <= 0; // Comando
                solicitar_escrita_driver <= 1;
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_INICIALIZAR_LCD_4;
            end
            S_INICIALIZAR_LCD_4: begin // Comando: Entry Mode Set (Incrementa cursor, no shift display)
                dado_para_driver <= 8'h06;
                rs_para_driver <= 0; // Comando
                solicitar_escrita_driver <= 1;
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_ESPERAR_ATUALIZACAO;
            end

            S_ESPERAR_ATUALIZACAO: begin
                // Espera pelo tick de 1 segundo (do contador_tempo_e_numero)
                if (tick_segundo == 1) begin
                    estado_principal <= S_ENVIAR_COMANDO_POSICAO;
                end
            end

            S_ENVIAR_COMANDO_POSICAO: begin
                // Comando para forçar o cursor para o início da 1ª linha
                dado_para_driver <= 8'h80;
                rs_para_driver <= 0; // É um comando
                solicitar_escrita_driver <= 1; // Pede para o driver_lcd enviar
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_ENVIAR_DIGITO_DEZENA;
            end

            S_ENVIAR_DIGITO_DEZENA: begin
                // Extrai a dezena e converte para ASCII (ex: '0' é 0x30, '1' é 0x31)
                dado_para_driver <= (number / 10) + 8'h30;
                rs_para_driver <= 1; // É um dado (caractere)
                solicitar_escrita_driver <= 1; // Pede para o driver_lcd enviar
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_ENVIAR_DIGITO_UNIDADE;
            end

            S_ENVIAR_DIGITO_UNIDADE: begin
                // Extrai a unidade e converte para ASCII
                dado_para_driver <= (number % 10) + 8'h30;
                rs_para_driver <= 1; // É um dado (caractere)
                solicitar_escrita_driver <= 1; // Pede para o driver_lcd enviar
                if (escrita_driver_lcd_concluida == 1) estado_principal <= S_ESPERAR_ATUALIZACAO; // Volta a esperar pelo próximo tick
            end

            default: estado_principal <= S_INICIALIZAR_LCD_0; // Estado de segurança
        endcase
    end
end

endmodule
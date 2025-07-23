module top_level (
    input CLOCK_50, // Pino de clock da FPGA (50 MHz)
    input [0:0] KEY,      // Pino para o reset (ex: KEY[0] na Altera)
    input [0:0] SW, // Pino para o switch enable (ex: SW[0] na Altera)

    output [7:0] LCD_DATA, // Pinos de dados do LCD (DB0-DB7)
    output LCD_EN,         // Pino Enable do LCD
    output LCD_RW,         // Pino Read/Write do LCD
    output LCD_RS          // Pino Register Select do LCD
);

// Conectando o reset_n (ativo baixo) do pino KEY (que geralmente é ativo baixo)
// Se o seu botão de reset for ativo alto, use: wire reset_n = !KEY[0];
wire reset_n = !KEY[0]; // Assumindo KEY[0] é o botão de reset (ativo baixo)
wire enable_sw_in = SW[0]; // Assumindo SW[0] é o switch de enable

// Instância do módulo principal que orquestra tudo
fsm_principal_lcd fsm_principal_inst (
    .clk(CLOCK_50),
    .reset_num(reset_n),
    .enable_switch(enable_sw_in),

    .lcd_data_bus_out(LCD_DATA),
    .lcd_en_out(LCD_EN),
    .lcd_rw_out(LCD_RW),
    .lcd_rs_out(LCD_RS)
);

endmodule
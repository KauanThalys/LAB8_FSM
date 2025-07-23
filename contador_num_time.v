module contador_num_time (
    input clk, //clock
    input enable_switch, // switch
    input reset_num, //reset

    output reg tick_segundo, //conta se deu 1 segundo
    output reg [7:0] number //conta de 0 a 99
);

//iniciando variaveis
initial begin
    tick_segundo = 0;
    number = 0;
end

//parametros
parameter S = 50_000_000; // 1 segundo

//incrementa a cada clock
reg [31:0] counter = 0; //quando chegar a 50mi incrementa o segundo

always @(posedge clk) begin
    if (!reset_num) begin
        counter <= 0; // Reseta o contador se reset for ativado
        number <= 0; // Reseta o número se reset for ativado
        tick_segundo <= 0; // Reseta o sinal de tick
    end else begin
        if (enable_switch) begin //se o enable estiver ativo
            if (counter == S - 1) begin //se o contador chegar a 50mi
                counter <= 0; //reseta o contador
                tick_segundo <= 1; //ativa o sinal de tick

                if (number == 99) begin //verifica se o número chegou a 99
                    number <= 0; //se sim, reseta o número
                end else begin
                    number <= number + 1; // se não incrementa o número a cada segundo
                end

            end else begin //se o contador não chegou a 50mi
                counter <= counter + 1; //incrementa o contador
                tick_segundo <= 0; //desativa o sinal de tick
            end
            
        end else begin //se o enable estiver desligado
            counter <= 0; // Reseta o contador se enable_switch for desligado
            tick_segundo <= 0; // Reseta o sinal de tick
        end    
    end
end
endmodule
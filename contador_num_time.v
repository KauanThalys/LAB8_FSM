module contadores (
    input clk, //clock
    input EN, // switch

    output reg tick_segundo, //conta se deu 1 segundo
    output reg [7:0] num, //conta de 0 a 99
);

//iniciando variaveis
initial begin
    num = 0;
end

//parametros
parameter S = 50_000_000; // 1 segundo

//incrementa a cada clock
reg [31:0] counter = 0; //quando chegar a 50mi incrementa o segundo

always @(posedge clk) begin
    if (EN) begin //se o enable estiver ativo
        if (counter == S - 1) begin //se o contador chegar a 50mi
            counter <= 0; //reseta o contador

            if (num == 99) begin //verifica se o número chegou a 99
                num <= 0; //se sim, reseta o número
            end else begin
                num <= num + 1; // se não incrementa o número a cada segundo
            end

        end else begin //se o contador não chegou a 50mi
            counter <= counter + 1; //incrementa o contador
        end
    end else begin //se o enable estiver desligado
        counter <= 0; // Reseta o contador se EN for desligado
    end
end
endmodule
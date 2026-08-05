`timescale 1ns / 1ps
`default_nettype none

module tb_parallel_binary_mult;

    // --- Parâmetros de Teste ---
    parameter WORD_WIDTH_A      = 32;
    parameter WORD_WIDTH_B      = 32;
    parameter INPUT_PIPE_DEPTH  = 1;
    parameter OUTPUT_PIPE_DEPTH = 1;
    
    parameter PRODUCT_WIDTH = WORD_WIDTH_A + WORD_WIDTH_B;
    parameter real CLK_PERIOD = 3.333333; // ~300MHz

    // --- Limites Dinâmicos Automáticos ---
    localparam signed [WORD_WIDTH_A-1:0] MIN_A = (1'sb1 <<< (WORD_WIDTH_A-1));
    localparam signed [WORD_WIDTH_A-1:0] MAX_A = ~MIN_A;

    localparam signed [WORD_WIDTH_B-1:0] MIN_B = (1'sb1 <<< (WORD_WIDTH_B-1));
    localparam signed [WORD_WIDTH_B-1:0] MAX_B = ~MIN_B;

    // --- Sinais do DUT ---
    reg                        clk;
    reg                        rst_n; // Adicionado sinal de reset
    reg  signed [WORD_WIDTH_A-1:0] A_in;
    reg  signed [WORD_WIDTH_B-1:0] B_in;
    wire signed [PRODUCT_WIDTH-1:0] product_out;

    // --- Lógica de Verificação (Modelagem da Latência) ---
    localparam TOTAL_LATENCY = INPUT_PIPE_DEPTH + OUTPUT_PIPE_DEPTH;
    localparam SR_DEPTH = (TOTAL_LATENCY > 0) ? TOTAL_LATENCY : 1;
    
    reg signed [PRODUCT_WIDTH-1:0] expected_sr [SR_DEPTH-1:0];
    reg signed [PRODUCT_WIDTH-1:0] current_expected;
    
    integer i;
    integer errors = 0;
    integer tests_run = 0;
    reg     pipeline_ready = 1'b0;

    // Atalho local para zerar o SR interno do TB
    localparam PRODUCT_ZERO = {PRODUCT_WIDTH{1'b0}};

    // --- Instanciação do DUT ---
    parallel_binary_mult #(
        .WORD_WIDTH_A      (WORD_WIDTH_A),
        .WORD_WIDTH_B      (WORD_WIDTH_B),
        .INPUT_PIPE_DEPTH  (INPUT_PIPE_DEPTH),
        .OUTPUT_PIPE_DEPTH (OUTPUT_PIPE_DEPTH)
    ) dut (
        .i_clk       (clk),
        .i_rst_n     (rst_n), // Conexão do novo pino de reset adicionada
        .A_in        (A_in),
        .B_in        (B_in),
        .product_out (product_out)
    );

    // --- Geração do Clock ---
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2.0);
        clk = 1'b1;
        #(CLK_PERIOD / 2.0);
    end

    // --- Deslocamento do Shift Register (Reset adicionado aqui também) ---
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < SR_DEPTH; i = i + 1) begin
                expected_sr[i] <= PRODUCT_ZERO;
            end
        end else if (TOTAL_LATENCY > 0) begin
            for (i = TOTAL_LATENCY-1; i > 0; i = i - 1) begin
                expected_sr[i] <= expected_sr[i-1];
            end
            expected_sr[0] <= A_in * B_in;
        end
    end

    // --- Bloco de Estímulos Principal ---
    initial begin
        // Inicialização dos sinais
        A_in  = 0;
        B_in  = 0;
        rst_n = 1'b1;
        pipeline_ready = 1'b0;

        for (i = 0; i < SR_DEPTH; i = i + 1) begin
            expected_sr[i] = 0;
        end

        // --- Sequência de Reset Físico ---
        #(CLK_PERIOD * 0.2);
        rst_n = 1'b0;          // Ativa o reset
        #(CLK_PERIOD * 3);     // Segura por 3 ciclos de clock
        rst_n = 1'b1;          // Libera o sistema
        #(CLK_PERIOD * 1);
        
        $display("==========================================================");
        $display("Iniciando Testbench (Verilog-2001) para parallel_binary_mult");
        $display("Configuracao: A=%0dB, B=%0dB | Latencia Total: %0d ciclos", 
                  WORD_WIDTH_A, WORD_WIDTH_B, TOTAL_LATENCY);
        $display("==========================================================");

        pipeline_ready = 1'b1;

        // --- Caso 1: Multiplicações Simples ---
        send_stimulus(10, 5);
        send_stimulus(12, 12);
        send_stimulus(127, 2);
        
        // --- Caso 2: Números Negativos ---
        send_stimulus(-10, 5); 
        send_stimulus(10, -5); 
        send_stimulus(-6, -7); 

        // --- Caso 3: Zero e Um ---
        send_stimulus(0, 0);
        send_stimulus(1, 1);
        send_stimulus(0, 25); 
        send_stimulus(-50, 0);
        send_stimulus(1, -37);

        // --- Caso 4: Valores Limites Parametrizados ---
        send_stimulus(MIN_A, MIN_B);
        send_stimulus(MIN_A, 0);
        send_stimulus(MIN_A, 1);
        send_stimulus(MIN_B, 0);
        send_stimulus(MIN_B, 1);

        // --- Caso 5: Testes Aleatórios Dinâmicos ---
        $display("Iniciando bateria de testes aleatorios...");
        repeat(20) begin
            send_random_stimulus();
        end

        // Flusha o pipeline
        repeat(TOTAL_LATENCY + 1) begin
            send_stimulus(0, 0);
        end

        repeat(2) @(posedge clk);

        $display("==========================================================");
        $display("FIM DOS TESTES");
        $display("Testes executados validados: %0d", tests_run);
        if (errors == 0) begin
            $display("STATUS: PASSED (Nenhum erro encontrado!)");
        end else begin
            $display("STATUS: FAILED (%0d erros encontrados)", errors);
        end
        $display("==========================================================");
        $finish;
    end

    // --- Task Padrão de Estímulos (Sincronismo Corrigido) ---
    task send_stimulus;
        input signed [WORD_WIDTH_A-1:0] a;
        input signed [WORD_WIDTH_B-1:0] b;
        begin
            @(posedge clk); // Espera a borda subir primeiro
            #0.1;           // Pequeno atraso para simular o tempo de hold/setup físico
            A_in = a;
            B_in = b;
        end
    endtask

    // --- Task para Injeção de Dados Aleatórios Automatizados ---
    task send_random_stimulus;
        reg signed [WORD_WIDTH_A-1:0] rand_a;
        reg signed [WORD_WIDTH_B-1:0] rand_b;
        begin
            rand_a = $random;
            rand_b = $random;
            send_stimulus(rand_a, rand_b);
        end
    endtask

    // --- Bloco de Verificação Automática (Checker) ---
    always @(posedge clk) begin
        // O checker só roda se o pipeline estiver ativo E fora do estado de reset
        if (pipeline_ready && rst_n) begin
            if (TOTAL_LATENCY == 0) begin
                current_expected = A_in * B_in;
            end else begin
                current_expected = expected_sr[TOTAL_LATENCY-1];
            end
            
            tests_run = tests_run + 1;

            if (product_out !== current_expected) begin
                $display("[ERRO @ %0t ns] Saida Incorreta!", $time);
                $display("       A_in: %0d | B_in: %0d", A_in, B_in);
                $display("       Esperado: %0d", current_expected);
                $display("       Obtido:   %0d", product_out);
                errors = errors + 1;
            end else begin
                $display("[OK   @ %0t ns] Resultado Obtido: %0d", $time, product_out);
            end
        end
    end

endmodule
`timescale 1ns / 1ps
`default_nettype none

module parallel_binary_mult
#(
    parameter WORD_WIDTH_A      = 32,
    parameter WORD_WIDTH_B      = 32,
    parameter INPUT_PIPE_DEPTH  = 1,
    parameter OUTPUT_PIPE_DEPTH = 1,

    // Não alterar na instanciação, exceto em IPI
    parameter PRODUCT_WIDTH = WORD_WIDTH_A + WORD_WIDTH_B
)
(
    input  wire                             i_clk,
    input  wire                             i_rst_n, // Reset síncrono ativo em baixo (Obrigatório para ASIC)
    input  wire signed [WORD_WIDTH_A-1:0]   A_in,
    input  wire signed [WORD_WIDTH_B-1:0]   B_in,
    output reg  signed [PRODUCT_WIDTH-1:0]  product_out
);

    localparam WORD_ZERO_A  = {WORD_WIDTH_A{1'b0}};
    localparam WORD_ZERO_B  = {WORD_WIDTH_B{1'b0}};
    localparam PRODUCT_ZERO = {PRODUCT_WIDTH{1'b0}};

    generate
        // ----------------------------------------------------
        // Caso 1: Sem pipelines (Multiplicador Combinacional)
        // ----------------------------------------------------
        if ((INPUT_PIPE_DEPTH == 0) && (OUTPUT_PIPE_DEPTH == 0)) begin: no_pipe
            always @(*) begin
                product_out = A_in * B_in;
            end
        end

        // ----------------------------------------------------
        // Caso 2: Apenas pipeline de entrada
        // ----------------------------------------------------
        else if ((INPUT_PIPE_DEPTH > 0) && (OUTPUT_PIPE_DEPTH == 0)) begin: in_pipe
            reg signed [WORD_WIDTH_A-1:0]  input_pipe_A  [INPUT_PIPE_DEPTH-1:0];
            reg signed [WORD_WIDTH_B-1:0]  input_pipe_B  [INPUT_PIPE_DEPTH-1:0];
            integer i; // Escopo local seguro para o compilador

            always @(posedge i_clk) begin
                if (!i_rst_n) begin
                    for (i=0; i < INPUT_PIPE_DEPTH; i=i+1) begin
                        input_pipe_A[i] <= WORD_ZERO_A;
                        input_pipe_B[i] <= WORD_ZERO_B;
                    end
                end else begin
                    input_pipe_A[0] <= A_in;
                    input_pipe_B[0] <= B_in;
                    for (i=1; i < INPUT_PIPE_DEPTH; i=i+1) begin
                        input_pipe_A[i] <= input_pipe_A[i-1];
                        input_pipe_B[i] <= input_pipe_B[i-1];
                    end
                end
            end

            always @(*) begin
                product_out = input_pipe_A[INPUT_PIPE_DEPTH-1] * input_pipe_B[INPUT_PIPE_DEPTH-1];
            end
        end

        // ----------------------------------------------------
        // Caso 3: Apenas pipeline de saída
        // ----------------------------------------------------
        else if ((INPUT_PIPE_DEPTH == 0) && (OUTPUT_PIPE_DEPTH > 0)) begin: out_pipe
            reg signed [PRODUCT_WIDTH-1:0] output_pipe   [OUTPUT_PIPE_DEPTH-1:0];
            integer i;

            always @(posedge i_clk) begin
                if (!i_rst_n) begin
                    for (i=0; i < OUTPUT_PIPE_DEPTH; i=i+1) begin
                        output_pipe[i] <= PRODUCT_ZERO;
                    end
                end else begin
                    output_pipe[0] <= A_in * B_in;
                    for (i=1; i < OUTPUT_PIPE_DEPTH; i=i+1) begin
                        output_pipe[i] <= output_pipe[i-1];
                    end
                end
            end

            always @(*) begin
                product_out = output_pipe[OUTPUT_PIPE_DEPTH-1];
            end
        end

        // ----------------------------------------------------
        // Caso 4: Ambos os pipelines (Entrada e Saída)
        // ----------------------------------------------------
        else if ((INPUT_PIPE_DEPTH > 0) && (OUTPUT_PIPE_DEPTH > 0)) begin: in_out_pipe
            reg signed [WORD_WIDTH_A-1:0]  input_pipe_A  [INPUT_PIPE_DEPTH-1:0];
            reg signed [WORD_WIDTH_B-1:0]  input_pipe_B  [INPUT_PIPE_DEPTH-1:0];
            reg signed [PRODUCT_WIDTH-1:0] output_pipe   [OUTPUT_PIPE_DEPTH-1:0];
            integer i;

            always @(posedge i_clk) begin
                if (!i_rst_n) begin
                    for (i=0; i < INPUT_PIPE_DEPTH; i=i+1) begin
                        input_pipe_A[i] <= WORD_ZERO_A;
                        input_pipe_B[i] <= WORD_ZERO_B;
                    end
                    for (i=0; i < OUTPUT_PIPE_DEPTH; i=i+1) begin
                        output_pipe[i] <= PRODUCT_ZERO;
                    end
                end else begin
                    input_pipe_A[0] <= A_in;
                    input_pipe_B[0] <= B_in;
                    for (i=1; i < INPUT_PIPE_DEPTH; i=i+1) begin
                        input_pipe_A[i] <= input_pipe_A[i-1];
                        input_pipe_B[i] <= input_pipe_B[i-1];
                    end

                    output_pipe[0] <= input_pipe_A[INPUT_PIPE_DEPTH-1] * input_pipe_B[INPUT_PIPE_DEPTH-1];
                    for (i=1; i < OUTPUT_PIPE_DEPTH; i=i+1) begin
                        output_pipe[i] <= output_pipe[i-1];
                    end
                end
            end

            always @(*) begin
                product_out = output_pipe[OUTPUT_PIPE_DEPTH-1];
            end
        end
    endgenerate

endmodule
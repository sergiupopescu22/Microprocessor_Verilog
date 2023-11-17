module RF  #(parameter N = 8, parameter addressBits = 2) ( 
    /* --------------------------------- Inputs --------------------------------- */
    input logic clk,
    input logic rst_n,
    input logic selectDestinationA,
    input logic selectDestinationB,
    
    input logic [1:0] selectSource,             // mux?
    input logic [addressBits-1:0] writeAddress, //2 bit
    input logic write_en,
    input logic [addressBits-1:0] readAddressA,
    input logic [addressBits-1:0] readAddressB,

    input logic [N-1:0] A,                      // input i select
    input logic [N-1:0] B,                      // input i select
    input logic [N-1:0] C,                      // input i select
    /* --------------------------------- Outputs -------------------------------- */
    output logic [N-1:0] destination1A,
    output logic [N-1:0] destination2A,
    output logic [N-1:0] destination1B,
    output logic [N-1:0] destination2B
);
    
    logic [N-1:0] outSelector;
    logic [N-1:0] inSelectorA;
    logic [N-1:0] inSelectorB;
    logic [N-1:0] Q [2 ** addressBits];

        
    always_ff @(posedge clk, negedge rst_n) begin

        if (!rst_n) begin
            for (int i=0; i< 2 ** addressBits; i=i+1 ) begin
                if (i != 1) Q[i] <= 0; // 0'b0
                else Q[i] <= '1;
            end
        end
        else if (write_en) begin
             Q[writeAddress] = outSelector;    
        end            

    end

    always_comb begin 
        case (selectSource)
           2'b00 : outSelector = A;
           2'b01 : outSelector = B;
           2'b10 : outSelector = C;
           default: outSelector = 8'b0;
        endcase
    end

    always_comb begin 
        inSelectorA = Q[readAddressA];
        inSelectorB = Q[readAddressB];

        case(selectDestinationA)
            (1'b0): begin
                destination1A = inSelectorA;
                destination2A = '0;
            end
            (1'b1): begin
                destination1A = '0;
                destination2A = inSelectorA;
            end
        endcase

        case(selectDestinationB)
            (1'b0): begin
                destination1B = inSelectorB;
                destination2B = '0;
            end
            (1'b1): begin
                destination1B = '0;
                destination2B = inSelectorB;
            end
        endcase
    end

    


endmodule
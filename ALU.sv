module ALU #(parameter N = 8) (
    input logic clk,
    input logic rst_n,
    input logic rst_p,
    input logic en,
    input logic [2:0] OP, 
    input logic signed [N-1:0] A, 
    input logic signed [N-1:0] B, 
    /* --------------------------------- Outputs -------------------------------- */
    output logic  [2:0] ONZ,
    output logic signed [N-1:0] Result 
);
  // Add your ALU description here

logic [N-1:0] next_Result;
logic [2:0] next_ONZ;

always_ff @(posedge clk, negedge rst_n) begin

    if (!rst_n) begin
        Result = '0;
        ONZ = '0;
    end
    else begin
        
        Result = next_Result;

        if (rst_p == 1) begin
            ONZ = '0;
        end
        else begin 
            if (en == 1) begin
                ONZ = next_ONZ;
            end
        end
    end
end


always_comb begin

    next_ONZ[2] = 0;

    case (OP)
        3'b000: begin
            next_Result = A + B;

            // here overflow occurs when the 2 operands
            // have the same sign but the result has a different sign
            if (A[N-1] == B[N-1] && A[N-1] != next_Result[N-1]) begin
                next_ONZ[2] = 1'b1;
            end
            else begin
                next_ONZ[2] = 1'b0;
            end
            end
        3'b001: begin
            next_Result = A - B;

            // here overflow occurs when the first and second 
            // opperand have different sign and the result has
            // the sign of the second operand

            // for no overflow:
            // N - P should be N
            // P - N should be P

            if (A[N-1] != B[N-1] && A[N-1] != next_Result[N-1]) begin
                next_ONZ[2] = 1'b1;
            end
            else begin
                next_ONZ[2] = 1'b0;
            end
            end
        3'b010: begin 
            next_Result = A & B;
        end    
        3'b011: begin
            next_Result = A|B;
        end   
        3'b100: begin 
            next_Result = A^B; 
        end    
        3'b101: begin
            next_Result = A+1;  
        // ONZ[2] = 1'b0; 
        // if (A[N-1] == 0 & Result[N-1] == 1) begin
        //   ONZ[2] = 1'b1;
        // end
        // else begin 
        //   ONZ[2] = 1'b0;
        // end
        end   
        3'b110: begin
            next_Result = A;

        end       
        3'b111: begin
            next_Result = B;  
        end      

        default: 
        begin
            next_Result = '0;
            next_ONZ[2] = 0;
        end
    endcase
end

assign next_ONZ[1] = next_Result[N-1] ? 1 : 0;
assign next_ONZ[0] = |next_Result ? 0 : 1;

endmodule
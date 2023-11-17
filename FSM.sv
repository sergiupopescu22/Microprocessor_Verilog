//-------------- Copyright (c) notice -----------------------------------------
//
// The SV code, the logic and concepts described in this file constitute
// the intellectual property of the authors listed below, who are affiliated
// to KTH (Kungliga Tekniska Högskolan), School of EECS, Kista.
// Any unauthorised use, copy or distribution is strictly prohibited.
// Any authorised use, copy or distribution should carry this copyright notice
// unaltered.
//-----------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//                                                                         #
//This file is part of IL1332 and IL2234 course.                           #
//                                                                         #
//    The source code is distributed freely: you can                       #
//    redistribute it and/or modify it under the terms of the GNU          #
//    General Public License as published by the Free Software Foundation, #
//    either version 3 of the License, or (at your option) any             #
//    later version.                                                       #
//                                                                         #
//    It is distributed in the hope that it will be useful,                #
//    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
//    GNU General Public License for more details.                         #
//                                                                         #
//    See <https://www.gnu.org/licenses/>.                                 #
//                                                                         #
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

`include "instructions.sv"


module FSM #(
  parameter M = 4, // size of register address
  parameter N = 4, // size of register data
  parameter P = 6  // PC size and instruction memory address
) (
  input  logic clk,
  input  logic rst_n,
  output logic ov_warning,
  /* ---------------------- signals to/from register file --------------------- */
  output logic [  1:0] select_source,
  output logic [M-1:0] write_address,
  output logic             write_en,
  output logic [M-1:0] read_address_A, read_address_B,
  output logic select_destination_A, select_destination_B,
  output logic [N-1:0] immediate_value,
  /* --------------------------- signals to/from ALU -------------------------- */
  output logic [2:0] OP,
  output logic       s_rst,
  input  logic [2:0] ONZ,
  output logic enable,
  /* --------------------------- signals from instruction memory -------------- */
  input  logic [4+2*M-1:0] instruction_in,
  output logic             en_read_instr,
  output logic [P-1:0] read_address_instr,
  /*---------------------------Signals to the data memory--------------*/
  output logic SRAM_readEnable,
  output logic SRAM_writeEnable
);

enum logic [1:0] { idle = 2'b11, fetch = 2'b00, decode = 2'b01, execute= 2'b10} state, next;
/* ----------------------------- PROGRAM COUNTER ---------------------------- */
logic [  P-1:0] PC     ;
logic [  P-1:0] PC_next;
logic           ov     ;
logic           ov_reg ;
logic [2*M-1:0] offset ;

/*-----------------------------------------------------------------------------*/
// Add signals and logic here

logic [4+2*M-1:0] instruction_reg;
logic [4+2*M-1:0] instruction_reg_next;
logic [2:0] Flags;
logic [2:0] Flags_next;
logic [M-1: 0] DATA;

//used for testing
logic decode_status;
logic execute_status;
/*-----------------------------------------------------------------------------*/

//State register
always @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    state <= idle;
  end else begin
    state <= next;
  end
end


// PC and overflow
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    PC     <= 0;
    ov_reg <= 0;
    instruction_reg <= 0;
    Flags <= 0;
  end else begin
    PC     <= PC_next;
    ov_reg <= ov;
    instruction_reg <= instruction_reg_next;
    Flags <= Flags_next;
  end
end

assign ov_warning = ov_reg;

/*-----------------------------------------------------------------------------*/
// Describe your next state and output logic here

// Next state logic
always_comb begin

  case (state)
    idle: begin

      if (!ov_reg) begin
        next = fetch;
      end
      else begin
        next = idle;
      end

    end
    fetch: begin

      next = decode;

    end
    decode: begin

      next = execute;

    end

    execute: begin

      if(!ov) begin
        next = fetch;
      end
      else begin
        next = idle;
      end

    end

  endcase

end

// Combinational output logic
always_comb begin
  case (state)

    idle: begin
      PC_next = PC;
      ov = ov_reg;
      decode_status = 0;
    end

    fetch: begin
      read_address_instr = PC;
      en_read_instr = 1;
      write_en = 0;
      decode_status = 0;
    end

    decode: begin

      en_read_instr = 0;
      instruction_reg_next = instruction_in;
      Flags_next = ONZ;
      offset = 0;
      s_rst = 0;
      SRAM_readEnable = 0;
      SRAM_writeEnable = 0;
      write_en = 0;
      immediate_value = 0;
      enable = 0;
      decode_status = 1;

      case (instruction_in[4+2*M-1:2*M])
        ADD      : begin 

          read_address_A = instruction_in[2*M-1: M];
          read_address_B = instruction_in[M-1: 0];
          select_destination_A = 0; // first destiantion -> to the ALU
          select_destination_B = 0; // first destination -> to the ALU
          OP = 3'b000;
          enable = 1;

        end
        SUB      : begin 
          read_address_A = instruction_in[2*M-1: M];
          read_address_B = instruction_in[M-1: 0];
          select_destination_A = 0; // first destiantion -> to the ALU
          select_destination_B = 0; // first destination -> to the ALU
          OP = 3'b001;
          enable = 1;

        end
        AND      : begin 
          read_address_A = instruction_in[2*M-1: M];
          read_address_B = instruction_in[M-1: 0];
          select_destination_A = 0; // first destiantion -> to the ALU
          select_destination_B = 0; // first destination -> to the ALU
          OP = 3'b010;
          enable = 1;

        end
        OR       : begin 
          read_address_A = instruction_in[2*M-1: M];
          read_address_B = instruction_in[M-1: 0];
          select_destination_A = 0; // first destiantion -> to the ALU
          select_destination_B = 0; // first destination -> to the ALU
          OP = 3'b011;
          enable = 1;

        end
        XOR      : begin 
          read_address_A = instruction_in[2*M-1: M];
          read_address_B = instruction_in[M-1: 0];
          select_destination_A = 0; // first destiantion -> to the ALU
          select_destination_B = 0; // first destination -> to the ALU
          OP = 3'b100;
          enable = 1;

        end
        INC      : begin 
          read_address_A = instruction_in[2*M-1: M];
          read_address_B = instruction_in[M-1: 0];
          select_destination_A = 0; // first destiantion -> to the ALU
          select_destination_B = 0; // first destination -> to the ALU
          OP = 3'b101;
          enable = 1;

        end
        MOV      : begin 
          read_address_A = instruction_in[2*M-1: M];
          read_address_B = instruction_in[M-1: 0];
          select_destination_A = 0; // first destiantion -> to the ALU
          select_destination_B = 0; // first destination -> to the ALU
          OP = 3'b111;
          enable = 1;

        end
        NOP      : begin 

        end
        LOAD     : begin 

          write_en = 0;
          read_address_A = instruction_in[M-1: 0];
          select_destination_A = 1;
          SRAM_readEnable = 1;
          SRAM_writeEnable = 0;

        end
        STORE    : begin 

          write_en = 0;
          read_address_A = instruction_in[M-1: 0];
          select_destination_A = 1;
          read_address_B = instruction_in[2*M-1: M];
          select_destination_B = 1;
          SRAM_readEnable = 0;
          SRAM_writeEnable = 1;

        end
        LOAD_IM  : begin 

          write_en = 1;
          write_address = instruction_in[2*M-1: M];
          immediate_value[N-1:0] = $signed(instruction_in[M-1: 0]);
          select_source = 2;

        end
        BRN_Z    : begin 
          offset = instruction_in[2*M-1:0];
          s_rst = 1;
        end  
        BRN_N    : begin 
          offset = instruction_in[2*M-1:0];
          s_rst = 1;
        end 
        BRN_O    : begin 
          offset = instruction_in[2*M-1:0];
          s_rst = 1;
        end 
        BRN      : begin 
          offset = instruction_in[2*M-1:0];
          s_rst = 1;
        end    
      endcase

    end

    execute: begin
      
      read_address_A = 0;
      read_address_B = 0;
      s_rst = 0;
      SRAM_readEnable = 0;
      SRAM_writeEnable = 0;
      write_en = 0;
      immediate_value = 0;
      decode_status = 0;
      
      case (instruction_reg[4+2*M-1:2*M])

        ADD      : begin 

          select_source = 0;
          write_address = instruction_reg[2*M-1: M];
          {ov, PC_next} = PC + 1;
          write_en = 1;

        end
        SUB      : begin 
          select_source = 0;
          write_address = instruction_reg[2*M-1: M];
          {ov, PC_next} = PC + 1;
          write_en = 1;

        end
        AND      : begin 
          select_source = 0;
          write_address = instruction_reg[2*M-1: M];
          {ov, PC_next} = PC + 1;
          write_en = 1;

        end
        OR       : begin 
          select_source = 0;
          write_address = instruction_reg[2*M-1: M];
          {ov, PC_next} = PC + 1;
          write_en = 1;

        end
        XOR      : begin 
          select_source = 0;
          write_address = instruction_reg[2*M-1: M];
          {ov, PC_next} = PC + 1;
          write_en = 1;

        end
        INC      : begin 
          select_source = 0;
          write_address = instruction_reg[2*M-1: M];
          {ov, PC_next} = PC + 1;
          write_en = 1;

        end
        MOV      : begin 
          select_source = 0;
          write_address = instruction_reg[2*M-1: M];
          {ov, PC_next} = PC + 1;
          write_en = 1;
        end
        NOP      : begin 
          {ov, PC_next} = PC + 1;
        end
        LOAD     : begin

          write_address = instruction_reg[2*M-1: M];
          select_source = 1;
          write_en = 1;
          {ov, PC_next} = PC + 1;
          SRAM_readEnable = 1;

        end
        STORE    : begin
          //nothing to do here, the RAM will do the work inside
          {ov, PC_next} = PC + 1;
        end
        LOAD_IM  : begin 
          {ov, PC_next} = PC + 1;
        end
        BRN_Z    : begin 

          $display("BRN_Z");

          if (Flags[0] == 1) begin
            $display("Branch true");
            if (offset[2*M-1]==1) begin
              $display("Offset negative");
              {ov,PC_next} = PC - offset[2*M-2:0];
              end  
            else begin
              $display("Offset positive");
              {ov,PC_next} = PC + offset[2*M-2:0];
              end

          end
          else begin
            $display("Branch not true");
            {ov, PC_next} = PC + 1;
          end 

        end  
        BRN_N    : begin 

          if (Flags[1] == 1) begin
            $display("Branch true");
            if (offset[2*M-1]==1) begin
              {ov,PC_next} = PC - offset[2*M-2:0];
              end  
            else begin
              {ov,PC_next} = PC + offset[2*M-2:0];
              end

          end
          else begin
            $display("Branch not true");
            {ov, PC_next} = PC + 1;
          end 

        end 
        BRN_O    : begin 

          if (Flags[2] == 1) begin
            $display("Branch true");
            if (offset[2*M-1]==1) begin
              {ov,PC_next} = PC - offset[2*M-2:0];
              end  
            else begin
              {ov,PC_next} = PC + offset[2*M-2:0];
              end

          end
          else begin
            $display("Branch not true");
            {ov, PC_next} = PC + 1;
          end 

        end 
        BRN      : begin 

            if (offset[2*M-1]==1) begin
              {ov,PC_next} = PC - offset[2*M-2:0];
              end  
            else begin
              {ov,PC_next} = PC + offset[2*M-2:0];
              end

        end

      endcase

      enable = 0;

    end
    
  endcase

end
/*
Example of how to update the PC counter
if (offset[2*M-1]==1) begin
{ov,PC_next} = PC - offset[2*M-2:0];
end  else begin
{ov,PC_next} = PC + offset[2*M-2:0];
end
*/
/*-----------------------------------------------------------------------------*/





// Registered the output of the FSM when required
always_ff @(posedge clk, negedge rst_n) begin

  // fill in here

end



endmodule
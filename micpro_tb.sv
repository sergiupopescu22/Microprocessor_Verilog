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
module micpro_tb ();
`include "instructions.sv"

  logic clk        = 0;
  logic rst_n      = 0;
  logic overflowPC    ;

  parameter N               = 8;
  parameter ROM_addressBits = 6;
  parameter RF_addressBits  = 3;

  logic [3+2*(RF_addressBits):0] ROM_data      ;
  logic                          ROM_readEnable;
  logic [   ROM_addressBits-1:0] ROM_address   ;

  logic [                  N-1:0] SRAM_data;
  logic                           SRAM_readEnable;
  logic                           SRAM_writeEnable;
  logic [(2**RF_addressBits)-1:0] SRAM_address;
  logic [                  N-1:0] SRAM_data_in;
  

  SRAM #(N, ROM_addressBits, RF_addressBits) RAM_1(
    clk,
    SRAM_readEnable,
    SRAM_writeEnable,
    SRAM_address,
    SRAM_data_in,
    SRAM_data);
   /* ---------------------- signals to/from register file --------------------- */
    logic [1:0] select_source;
    logic [RF_addressBits-1:0] write_address;
    logic             write_en;
    logic [RF_addressBits-1:0] read_address_A, read_address_B;
    logic select_destination_A, select_destination_B;
    logic [N-1:0] immediate_value;
    logic [N-1:0] destination1A;
    logic [N-1:0] destination1B;
  /* --------------------------- signals to/from ALU -------------------------- */
    logic [2:0] OP;
    logic       s_rst;
    logic [2:0] ONZ;
    logic enable;
    logic [N-1:0] Result_ALU;
  /* ------------------------------------------------------------------------- */
  
    FSM #(RF_addressBits, N, ROM_addressBits) FSM_1 (
              clk, 
              rst_n, 
              overflowPC,
              select_source,
              write_address,
              write_en,
              read_address_A, read_address_B,
              select_destination_A, select_destination_B,
              immediate_value,
              OP,
              s_rst,
              ONZ,
              enable,
              ROM_data,
              ROM_readEnable,
              ROM_address,
              SRAM_readEnable,
              SRAM_writeEnable);
  
    RF #(N, RF_addressBits) RF_1(
            clk,
            rst_n,
            select_destination_A,
            select_destination_B,
            select_source,
            write_address,
            write_en,
            read_address_A,
            read_address_B,
            Result_ALU, // source A
            SRAM_data,  // source B
            immediate_value,  // source C
            destination1A,
            SRAM_address,
            destination1B,
            SRAM_data_in);
  
    ALU #(N) ALU_1(
              clk,
              rst_n,
              s_rst,
              enable,
              OP,
              destination1A,
              destination1B,
              ONZ,
              Result_ALU);

  logic [6:0] RF_scoreboard;
  // cover groups
  covergroup  instr @(posedge clk);
          fsm_instr: coverpoint FSM_1.instruction_in[4+2*RF_addressBits-1:2*RF_addressBits];
          alu_instr: coverpoint FSM_1.OP;
  endgroup

  covergroup  branch_instr @(posedge clk);
          branch_instr_point: coverpoint (FSM_1.instruction_in[4+2*RF_addressBits-1:2*RF_addressBits] > 10);
  endgroup

  covergroup  offset @(posedge clk);
          offset_point: coverpoint FSM_1.instruction_in[2*RF_addressBits-1:0];
  endgroup

  covergroup crosscov @(posedge clk);
    c: coverpoint (FSM_1.instruction_in[4+2*RF_addressBits-1:2*RF_addressBits] > 10);
    d: coverpoint FSM_1.instruction_in[2*RF_addressBits-1:0];
    cXd : cross c, d;
  endgroup

  instr instr_inst = new();
  branch_instr branch_instr_inst = new();
  offset offset_inst = new();
  crosscov crosscov_inst = new();


  always #5ns clk = ~clk;

  logic [RF_addressBits-1: 0] ra;
  logic [RF_addressBits-1: 0] rb;
  logic [3: 0] tc;
  logic empty_rf_flag = 1;
  logic [N-1:0] Result_ALU_temp;

  class random_instr;
    rand logic [3:0] testcode;
    rand logic [RF_addressBits-1: 0] ra;
    rand logic [RF_addressBits-1: 0] rb;
    logic rf_empty;

    function new(int empty_rf_flag);
            rf_empty = empty_rf_flag;
    endfunction

    constraint test_code_load {rf_empty -> (testcode == 4'b1010);};
    constraint address_limit {ra > 1;};
    constraint testcode_limit {testcode < 15;};
  endclass

  random_instr random_instr_gen = new(empty_rf_flag);
  //for after the first batch of instructions
  random_instr new_random_instr_gen = new(!empty_rf_flag);


  int i = 0;

  initial begin
    // check registers are empty

    rst_n = 0;
    #10;

    for (i=0; i< 2 ** RF_addressBits; i=i+1 ) begin
      if (i != 1) begin
          assert (RF_1.Q[i] == 0) $display("RF is reset correctly");
      end
      else begin
          assert (RF_1.Q[i] == '1) $display("RF is reset correctly");
      end
    end

    assert (ALU_1.ONZ == 0) $display("ALU ONZ is reset correctly"); else $error("Alu reset ONZ false");
    assert (ALU_1.Result == 0) $display("ALU result is reset correctly"); else $error("Alu reset result false");
    
    assert (FSM_1.PC == 0) $display("FSM PC is reset correctly"); else $error("FSM reset PC false");
    assert (FSM_1.state == 2'b11) $display("FSM State is reset correctly"); else $error("FSM reset state false");
    
    rst_n = 1;

    #10ns;
 
    while (empty_rf_flag) begin
      if (random_instr_gen.randomize()) begin
        tc = random_instr_gen.testcode;
        $display("Testcode before RF filled is currently %b", tc);
        ra = random_instr_gen.ra;
        rb = random_instr_gen.rb;
        ROM_data = {tc, ra, rb};

      end
      else $display("Random Failed");
      #20;
      empty_rf_flag = 0;
      for (i =2; i< 2 ** RF_addressBits; i=i+1 ) begin
        // if one of the rows in the register is empty break, else all the register is full i can set empty rf flag to 0
        if (RF_1.Q[i] == 0) empty_rf_flag = 1;
      end
      #20ns;
    end
    $display("Done with filling the RF");
    for (i=0; i< 2 ** RF_addressBits; i=i+1 ) begin
      $display("Value stored at %0d: %b", i, RF_1.Q[i]);
    end

    #20ns;
    for(i=0; i<7; i=i+1 ) begin
      @(posedge clk);
      if (new_random_instr_gen.randomize()) begin
        tc = new_random_instr_gen.testcode;
        $display("-----------------------------------------------------");
        $display("Testcode after RF filled is currently %b", tc);
        ra = new_random_instr_gen.ra;
        rb = new_random_instr_gen.rb;
        ROM_data = {tc, ra, rb};

        @(FSM_1.decode_status==1);
        if ((tc== BRN_Z)||(tc== BRN_O)||(tc== BRN_N)||(tc== BRN)) begin
          // assert s_rst
          assert(s_rst == 1) $display ("s_rst Success"); else $error("s_rst failed!");
          
          #20;
          
          RF_scoreboard[i] = 1;
        end
        else begin
          // ALU ENABLE TEST 
          if (tc == STORE || tc == LOAD
              || tc == LOAD_IM || tc == NOP) begin
            // assert enable in these cases is 0
            assert(enable == 0) $display ("ALU ENABLE Success"); else $error("ALU ENABLE failed!");
          end
          else assert(enable == 1) $display ("ALU ENABLE Success"); else $error("ALU ENABLE failed!");

          // OP TEST 
          if (tc == ADD) begin
            assert(OP == 3'b000) $display ("OP Success"); else $error("OP failed!");
          end
          else if (tc == SUB) assert(OP == 3'b001) $display ("OP Success"); else $error("OP failed!");
          else if (tc == AND) assert(OP == 3'b010) $display ("OP Success"); else $error("OP failed!");
          else if (tc == OR) assert(OP == 3'b011) $display ("OP Success"); else $error("OP failed!");
          else if (tc == XOR) assert(OP == 3'b100) $display ("OP Success"); else $error("OP failed!");
          else if (tc == INC) assert(OP == 3'b101) $display ("OP Success"); else $error("OP failed!");
          else if (tc == MOV) assert(OP == 3'b111) $display ("OP Success"); else $error("OP failed!");

          // SELECT SOURCE TEST
          if (tc == LOAD_IM) begin
            assert(select_source == 2) $display ("Select Source Success"); else $error("Select Source failed!");
          end
          
          // fast forward to execute stage
          #15;
          Result_ALU_temp = Result_ALU;
          
          if (tc == STORE || tc == LOAD_IM || tc == NOP) begin
          // assert write enable in these cases is 0
              assert(write_en == 0) $display ("WRITE ENABLE Success"); else $error("WRITE ENABLE failed!");
          end
          else assert(write_en == 1) $display ("WRITE ENABLE Success"); else $error("WRITE ENABLE failed!");

          // SELECT SOURCE TEST
          if (tc != NOP)begin
            if (tc == LOAD) begin
              assert(select_source == 1) $display ("Select Source Success"); else $error("Select Source failed!");
              end
            else assert(select_source == 0) $display ("Select Source Success"); else $error("Select Source failed!");
          end

          #10ns;

          $display("ra %b", ra);
          $display("rb %b", rb);
          $display("alu result %b", Result_ALU_temp);
          $display("value stored %b", RF_1.Q[ROM_data[2*RF_addressBits-1: RF_addressBits]]);
          // for (i=0; i< 2 ** RF_addressBits; i=i+1 ) begin
          //   $display("Value stored at %0d: %b", i, RF_1.Q[i]);
          // end

          if(RF_1.Q[ROM_data[2*RF_addressBits-1: RF_addressBits]] == Result_ALU_temp) RF_scoreboard[i] = 1;
        end
      end
      else $display("Random Failed");
    end
    #10ns;
    $display("scoreboard = %b", RF_scoreboard);
    
    assert (&RF_scoreboard) $display("Scoreboard passed"); else $error("Scoreboard failed");
    $display("Coverage = %0.2f %%", instr_inst.get_inst_coverage());
    $display("Coverage = %0.2f %%", branch_instr_inst.get_inst_coverage());
    $display("Coverage = %0.2f %%", offset_inst.get_inst_coverage());
    $display("Coverage = %0.2f %%", crosscov_inst.get_inst_coverage());  

  end
endmodule
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
module microprocessor #(parameter N = 8, ROM_addressBits = 6, RF_addressBits = 3) (
  /* --------------------------------- Inputs --------------------------------- */
  input  logic                           clk             ,
  input  logic                           rst_n           ,
  input  logic [ 3+2*(RF_addressBits):0] ROM_data        ,
  input  logic [                  N-1:0] SRAM_data       ,
  /* --------------------------------- Outputs -------------------------------- */
  output logic                           overflowPC      ,
  //Memory
  output logic                           ROM_readEnable  ,
  output logic                           SRAM_readEnable ,
  output logic                           SRAM_writeEnable,
  output logic [    ROM_addressBits-1:0] ROM_address     ,
  output logic [(2**RF_addressBits)-1:0] SRAM_address    ,
  output logic [                  N-1:0] SRAM_data_in
);

  // Connect your components here

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

endmodule
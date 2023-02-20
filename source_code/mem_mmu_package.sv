//////////////////////////////////////////////////////////
// File Name    : mem_mmu_package.sv
// Description  : define package for mem mmu
// Author       : Tony
// Date created : 3/Nov/2022
// Note:
//////////////////////////////////////////////////////////
`ifndef MEM_MMU_PACKAGE
`define MEM_MMU_PACKAGE

`include "uvm_macros.svh"

package mem_mmu_package;

 import uvm_pkg::*;

/*
E_INC: buffer_data = {buffer index, data increment from 0 to buffer size}
E_DEC: buffer_data = {buffer index, data decrement from buffer size to 0}
E_EMPTY: buffer_data is empty
E_LOADFF: buffer_data is load from file
*/
 typedef enum bit [1:0]  {E_INC, E_DEC, E_EMPTY, E_LOADFF}              e_gen_data_type;
 typedef enum bit        {E_GOLEFT=0, E_GORIGHT=1}                      e_direction;
 typedef enum bit        {FALSE, TRUE}                                  bool_t;
 typedef enum bit  [1:0] {OVERLAP_ADDR, OVERLAP_NAME, NO_OVERLAP}       e_overlap_type;

 `include "mem_mmu_node.sv"
 `include "mem_mmu_binary_tree_info.sv"
 `include "mem_mmu.sv"
endpackage: mem_mmu_package

`endif // MEM_MMU_PACKAGE

//////////////////////////////////////////////////////////////////
// File Name    : mem_mmu_binary_tree_info.sv
// Description  : binary tree - store the info of the binary tree
// Author       : Tony
// Date created : 3/Nov/2022
// Note:
//////////////////////////////////////////////////////////////////
`ifndef MEM_MMU_BINARY_TREE_INFO
`define MEM_MMU_BINARY_TREE_INFO

class mem_mmu_binary_tree_info#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32) extends uvm_object;
 typedef logic [DATA_WIDTH-1 : 0]            uint32_data_t;
 typedef logic [ADDR_WIDTH-1 : 0]            uint32_addr_t;
 string                                      region_name;
 uint32_addr_t                               pos_start;
 uint32_addr_t                               pos_end;
 uint32_addr_t                               region_saddr;
 uint32_addr_t                               region_eaddr;
 uint32_data_t                               buffer_size;
 e_gen_data_type                             data_type;
 uint32_data_t                               num_buffer;
 mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) roof;

 `uvm_object_param_utils_begin(mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH))
  `uvm_field_string    (region_name                            , UVM_ALL_ON)
  `uvm_field_int       (pos_start                              , UVM_ALL_ON)
  `uvm_field_int       (pos_end                                , UVM_ALL_ON)
  `uvm_field_int       (region_saddr                           , UVM_ALL_ON)
  `uvm_field_int       (region_eaddr                           , UVM_ALL_ON)
  `uvm_field_int       (buffer_size                            , UVM_ALL_ON)
  `uvm_field_enum      (e_gen_data_type, data_type             , UVM_ALL_ON)
  `uvm_field_int       (num_buffer                             , UVM_ALL_ON)
  `uvm_field_object    (roof                                   , UVM_ALL_ON)
 `uvm_object_utils_end

/*
Function name: new
 + name
Info:
*/
function new(string name="BINARY_TREE_INFO");
  super.new(name);
  this.roof = null;
endfunction: new

/*
Function name: check_overlap_info
 + obj_info
Info: Two type of overlap should be checked
  - can't be the same address range
  - can't be the same region name
*/
virtual function e_overlap_type check_overlap_info(mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) obj_info);
  if(obj_info.region_name == this.region_name)
    return OVERLAP_NAME;
  else
  if((obj_info.region_saddr >= this.region_saddr) && (obj_info.region_saddr < this.region_eaddr ))
    return OVERLAP_ADDR;
  else
    return NO_OVERLAP;
endfunction: check_overlap_info

/*
Function name: check_buffer_size_of_binary_tree_info
Info:
*/
virtual function bool_t check_buffer_size_of_binary_tree_info();
    uint32_addr_t log2size;
    uint32_addr_t log2width;
    uint32_addr_t tmp;

    if(ADDR_WIDTH == 64)
    begin
        log2size = log2_64(this.buffer_size);
        log2width = log2_64(DATA_WIDTH);
    end
    else
    begin
        log2size = log2_32(this.buffer_size);
        log2width = log2_32(DATA_WIDTH);
    end
    `uvm_info(get_full_name(), $psprintf("log2size %0d", log2size), UVM_HIGH)
    `uvm_info(get_full_name(), $psprintf("log2width %0d", log2width), UVM_HIGH)

    tmp = 2 ** log2size;

    if(this.buffer_size < log2width) // buffer size smaller than memory data width (unexpected)
    begin
        `uvm_error(get_full_name(), $psprintf("Buffer size %0d is smaller than memory data width %0d is unexpected", this.buffer_size, DATA_WIDTH))
        return FALSE;
    end
    else
    if(tmp !== this.buffer_size) // buffer size should be 1, 2, 4, 8, ...
    begin
        `uvm_error(get_full_name(), $psprintf("Buffer size %0d should be pow of 2", this.buffer_size))
        return FALSE;
    end
    else
    begin
        return TRUE;
    end
endfunction: check_buffer_size_of_binary_tree_info

/*
Function name: check_align_address_of_binary_tree_info
Info:
*/
virtual function bool_t check_align_address_of_binary_tree_info(bool_t active);
    uint32_addr_t clog2_size;
    if(active == TRUE)
    begin
        clog2_size = $clog2(this.buffer_size);
        for(uint32_addr_t index = 0; index < clog2_size; index++)
        begin
            if(this.region_saddr[index] !== 0)
            begin
                `uvm_error(get_full_name(), "Address of Buffer isn't aligned with Buffer size")
                return FALSE;
            end
        end
        return TRUE;
    end
    else
        return FALSE;
endfunction: check_align_address_of_binary_tree_info

/*
Function name: position_resolution_from_binary_tree_info
 + active
Info:
*/
virtual function bool_t position_resolution_from_binary_tree_info(bool_t active);
    uint32_addr_t log2buffersize;
    uint32_addr_t log2numbuffer;
    uint32_addr_t regioncapacity;
    if(active == TRUE)
    begin
        if(ADDR_WIDTH == 64)
        begin
            log2buffersize  = log2_64(this.buffer_size);
            log2numbuffer   = log2_64(this.num_buffer);
            this.pos_start  = log2buffersize + log2numbuffer;
        end
        else
        begin
            log2buffersize  = log2_32(this.buffer_size);
            log2numbuffer   = log2_32(this.num_buffer);
            this.pos_start  = log2buffersize + log2numbuffer;
        end
        if((log2buffersize + log2numbuffer) >= ADDR_WIDTH)
        begin
            `uvm_error(get_full_name(), $psprintf("Memory region capacity = log2(buffer size) +  log2(number of buffer) = %0d + %0d over ADDR range %0d bits", log2buffersize, log2numbuffer, ADDR_WIDTH))
            return FALSE;
        end
        else
        begin
            regioncapacity = 2 ** this.pos_start;
            /*
              case 1: number buffer isn't power of 2 -> log2(number buffer) is round 
              case 2: number buffer is 1 -> log2(number buffer) is 0
            */
            if((regioncapacity !== (this.buffer_size * this.num_buffer)) || (this.num_buffer == 1))
            begin
                this.pos_start = this.pos_start + 1;
            end
            this.pos_end = $clog2(this.buffer_size);
            return TRUE;
        end
    end
endfunction: position_resolution_from_binary_tree_info

/*
Function name: fetch_binary_tree_info
 + region_name
 + region_saddr
 + num_buffer
 + buffer_size
 + roof
Info:
*/
virtual function bool_t fetch_binary_tree_info(string region_name, uint32_addr_t region_saddr,
                          uint32_addr_t num_buffer, uint32_data_t buffer_size, e_gen_data_type data_type);
  bool_t status       = FALSE;
  this.region_saddr   = region_saddr;
  this.region_eaddr   = (region_saddr+buffer_size*(num_buffer-1'b1)); // number - 1 because start from 0
  this.buffer_size    = buffer_size;
  this.region_name    = region_name;
  this.data_type      = data_type;
  this.num_buffer     = num_buffer;
  status = this.check_buffer_size_of_binary_tree_info();
  status = this.check_align_address_of_binary_tree_info(status);
  status = this.position_resolution_from_binary_tree_info(status);
  if(status == FALSE)
  begin
    `uvm_error(get_full_name(), "FETCH INFO FAILED")
    return status;
  end
  return status;
endfunction: fetch_binary_tree_info

virtual function uint32_addr_t log2_64 (uint32_addr_t value);
int tab64[64] = '{
    63,  0, 58,  1, 59, 47, 53,  2,
    60, 39, 48, 27, 54, 33, 42,  3,
    61, 51, 37, 40, 49, 18, 28, 20,
    55, 30, 34, 11, 43, 14, 22,  4,
    62, 57, 46, 52, 38, 26, 32, 41,
    50, 36, 17, 19, 29, 10, 13, 21,
    56, 45, 25, 31, 35, 16,  9, 12,
    44, 24, 15,  8, 23,  7,  6,  5};

    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    value |= value >> 32;
    return tab64[(uint32_addr_t'((value - (value >> 1))*64'h07EDD5E59A4E28C2)) >> 58];
endfunction: log2_64


virtual function uint32_addr_t log2_32 (uint32_addr_t value);
int tab32[32] = '{
     0,  9,  1, 10, 13, 21,  2, 29,
    11, 14, 16, 18, 22, 25,  3, 30,
     8, 12, 20, 28, 15, 17, 24,  7,
    19, 27, 23,  6, 26,  5,  4, 31};

    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return tab32[uint32_addr_t'(value*32'h07C4ACDD) >> 27];
endfunction: log2_32


endclass: mem_mmu_binary_tree_info

`endif // MEM_MMU_BINARY_TREE_INFO

//////////////////////////////////////////////////////////
// File Name    : mem_mmu_node.sv
// Description  : binary tree - node struct
// Author       : Tony
// Date created : 3/Nov/2022
// Note:
//////////////////////////////////////////////////////////

`ifndef MEM_MMU_NODE
`define MEM_MMU_NODE

class mem_mmu_node#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32) extends uvm_object;
 typedef logic [DATA_WIDTH-1 : 0]       uint32_data_t;
 typedef logic [ADDR_WIDTH-1 : 0]       uint32_addr_t;
 uint32_data_t                          buffer_data[];
 mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH)  left_node;
 mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH)  right_node;

 `uvm_object_param_utils_begin(mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH))
  `uvm_field_array_int  (buffer_data                        , UVM_ALL_ON)
  `uvm_field_object     (left_node                          , UVM_ALL_ON)
  `uvm_field_object     (right_node                         , UVM_ALL_ON)
 `uvm_object_utils_end

/*
Function name: new
 + name
Info:
*/
function new(string name="MMU_NODE");
    super.new(name);
    this.left_node  = null;
    this.right_node = null;
endfunction: new

/*
Function name: generate_buffer_data
 + data_type
 + buffer_size
Info:
*/
virtual function bool_t generate_buffer_data(e_gen_data_type data_type, uint32_data_t buffer_size, uint32_addr_t numbits, uint32_addr_t buffer_index);
    uint32_data_t random_value;
    case(data_type)
    /*
        E_RAND:
        begin
            this.buffer_data = new[buffer_size/(DATA_WIDTH/8)];
            for(uint32_data_t i=0; i<this.buffer_data.size(); i++)
            begin
                assert(std::randomize(random_value));
                this.buffer_data[i] = random_value;
            end
        end
    */
        E_INC:
        begin
            this.buffer_data = new[buffer_size/(DATA_WIDTH/8)];
            for(uint32_data_t i=0; i<this.buffer_data.size(); i++)
            begin
                random_value = i;
                random_value = (random_value << numbits) >> numbits;
                random_value = random_value | (uint32_data_t'(buffer_index) << (DATA_WIDTH - numbits));
                this.buffer_data[i] = random_value;
            end
        end
        E_DEC:
        begin
            this.buffer_data = new[buffer_size/(DATA_WIDTH/8)];
            for(uint32_data_t i=(this.buffer_data.size()-1); i>=0; i--)
            begin
                random_value = i;
                random_value = (random_value << numbits) >> numbits;
                random_value = random_value | (uint32_data_t'(buffer_index) << (DATA_WIDTH - numbits));
                this.buffer_data[i] = random_value;
            end
        end
        E_EMPTY: // buffer data isn't initial
        begin
            //this.buffer_data = new[buffer_size/(DATA_WIDTH/8)];
        end
        default: // buffer data isn't initial
        begin
        end
    endcase
    //this.print();

endfunction: generate_buffer_data

/*
Function name: generate_buffer_data_load_from_file
 + data_type
 + buffer_size
Info:
*/
virtual function bool_t generate_buffer_data_load_from_file(uint32_data_t buffer_size, uint32_addr_t numbits, uint32_addr_t buffer_index, string filename);
    uint32_data_t mem[1024];
    begin
        $readmemh ( filename , mem, 0, 1023);
        this.buffer_data = new[buffer_size/(DATA_WIDTH/8)];
        for(uint32_data_t i=0; i< (this.buffer_data.size()); i++)
        begin
            this.buffer_data[i] = mem[i];
            this.buffer_data[i] = (this.buffer_data[i] << numbits) >> numbits;
            this.buffer_data[i] = this.buffer_data[i] | (uint32_data_t'(buffer_index) << (DATA_WIDTH - numbits));
        end
    end

endfunction: generate_buffer_data_load_from_file

/*
Function name: insert_node
 + direction
Info:
*/
virtual function mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) insert_node(e_direction direction, string name);
    if(direction == E_GOLEFT)
    begin
        if(this.left_node == null)
            begin
                this.left_node = new(name);
                `uvm_info(get_full_name(), $psprintf("Node name: %s -> %s was created", name, direction.name), UVM_HIGH)
                return this.left_node;
            end
        else
            return this.left_node;
    end
    else
    if(direction == E_GORIGHT)
    begin
        if(this.right_node == null)
            begin
                this.right_node = new(name);
                `uvm_info(get_full_name(), $psprintf("Node name: %s -> %s was created", name, direction.name), UVM_HIGH)
                return this.right_node;
            end
        else
            return this.right_node;
    end
    else
    begin
        `uvm_error(get_full_name(), $psprintf("direction = %0d isn't defined", direction))
    end
endfunction: insert_node

/*
Function name: go_to_node
 + direction
Info:
*/
virtual function mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) go_to_node(e_direction direction);
    if(direction == E_GOLEFT)
    begin
        `uvm_info(get_full_name(), $psprintf("Pointer moved to %s", direction.name), UVM_LOW)
        return this.left_node;
    end
    else
    if(direction == E_GORIGHT)
    begin
        `uvm_info(get_full_name(), $psprintf("Pointer moved to %s", direction.name), UVM_LOW)
        return this.right_node;
    end
    else
    begin
        `uvm_error(get_full_name(), $psprintf("direction = %0d isn't defined", direction))
    end
endfunction: go_to_node

endclass: mem_mmu_node
`endif // MEM_MMU_NODE

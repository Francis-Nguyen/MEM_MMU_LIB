/////////////////////////////////////////////////////////////////////////////
// File Name    : mem_mmu.sv
// Description  : Define a method to manage memory in SOC
//                 + support allocate/de-allocate buffer
//                 + support memory address upto 64 bits
//                 + support get buffer by address
//                 + support get buffer number(x) in advanced of memory name
// Limitation   :
//                 + Buffer's address should be aligned with buffer size
//                 + Regions shouldn't be overlapped
//                 + Can't create memory regions has the same name
//                 + Buffer size are power of 2 and should be larger than
//                      data width
//                 + Number buffer shouldn't be 0
// Author       : Tony
// Date created : 3/Nov/2022
// Note:
//////////////////////////////////////////////////////////////////////////////

`ifndef MEM_MMU
`define MEM_MMU

class mem_mmu#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32) extends uvm_object;
    typedef logic [DATA_WIDTH-1 : 0] uint32_data_t;
    typedef logic [ADDR_WIDTH-1 : 0] uint32_addr_t;

    mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) binary_tree_info[$];

    `uvm_object_param_utils_begin(mem_mmu#(DATA_WIDTH, ADDR_WIDTH))
        `uvm_field_queue_object     (binary_tree_info                      , UVM_ALL_ON)
    `uvm_object_utils_end

/*
Function name: new
 + name :
Info:
*/
function new(string name="MEM_MMU");
    super.new(name);
endfunction: new
/*
Function name: create_binary_tree
 + region_name :
 + buffer_size :
 + region_saddr   :
 + num_buffer  :
 + data_type   :
Info:
*/
virtual function create_binary_tree(string region_name, uint32_addr_t buffer_size, uint32_addr_t region_saddr, uint32_addr_t num_buffer, e_gen_data_type data_type);
    bool_t       status = FALSE;
    mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) tree_info;

    tree_info = new("Binary Tree Info");

    // Fetch information for Binary Tree
    status = tree_info.fetch_binary_tree_info(region_name, region_saddr, num_buffer, buffer_size, data_type);

    // binary tree overlap address check
    status = this.check_overlap_info_binary_tree(status, tree_info);

    // insert node
    status = this.insert_node(status, tree_info);

    // Store binary tree information
    this.binary_tree_info.push_back(tree_info);

    if(status !== TRUE)
    begin
        `uvm_fatal(get_full_name(), "Create Binary Tree is FAILED")
    end
endfunction: create_binary_tree

/*
Function name: get_buffer_n_by_name_from_binary_tree
 + region_name :
 + buffer_n    :
Info:
*/
virtual function mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) get_buffer_n_by_name_from_binary_tree(string region_name, uint32_addr_t buffer_n);
    bool_t  status = FALSE;
    mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) node_obj;
    mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) obj_info;

    obj_info = this.get_info_by_name_from_binary_tree(status, region_name);
    node_obj = get_buffer_n_by_name(status, region_name, buffer_n, obj_info);
    if(status == FALSE)
    begin
        `uvm_fatal(get_full_name(), $psprintf("Memory: %s BUFFER number: %0d doesn't exist", region_name, buffer_n))
    end
    else
    begin
        obj_info = null;
        return node_obj;
    end
endfunction: get_buffer_n_by_name_from_binary_tree

/*
Function name: get_buffer_by_address_from_binary_tree
 + buffer_addr :
Info:
*/
virtual function mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) get_buffer_by_address_from_binary_tree(uint32_addr_t buffer_addr);
    bool_t  status = FALSE;
    mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) node_obj;
    mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) obj_info;

    obj_info = this.get_info_by_address_from_binary_tree(status, buffer_addr);
    node_obj = this.get_buffer_by_address(status, buffer_addr, obj_info);
    if(status == FALSE)
    begin
        `uvm_fatal(get_full_name(), $psprintf("BUFFER at address: 0x%x doesn't exist", buffer_addr))
    end
    else
    begin
        obj_info = null;
        return node_obj;
    end
endfunction: get_buffer_by_address_from_binary_tree

/*
Function name: delete_buffer_n_binary_tree
Info:
*/
virtual function delete_buffer_n_binary_tree();
endfunction: delete_buffer_n_binary_tree

/*
Function name: check_overlap_info_binary_tree
 + active
 + obj_info
Info: each binary tree doesn't allocate in the same region or same name
*/
virtual function bool_t check_overlap_info_binary_tree(bool_t active, mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) obj_info);
    e_overlap_type overlap_status;
    if(active == TRUE)
    begin
        if(this.binary_tree_info.size() !== 0)
        begin
            foreach(this.binary_tree_info[i])
            begin
                overlap_status = this.binary_tree_info[i].check_overlap_info(obj_info);
                if(overlap_status == NO_OVERLAP)
                    return TRUE;
                else
                begin
                    `uvm_error(get_full_name(), $psprintf("Memory region is %s", overlap_status.name))
                    return FALSE;
                end
            end
        end
        else
        begin
            // binary tree is empty
            return TRUE;
        end
    end
    else
    begin
        return FALSE;
    end
endfunction: check_overlap_info_binary_tree

/*
Function name: insert_node
 + active
 + obj_info
Info: Insert Node to Binary Tree
*/
virtual function bool_t insert_node(bool_t active, ref mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) obj_info);
    uint32_addr_t                           s_addr;
    mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH)   node_0;
    e_direction                             direction;
    string                                  roof_name;
    uint32_addr_t                           log2numbuffer;
    uint32_addr_t                           tmp;
    if(active == TRUE)
    begin
        // create roof for binary tree
        roof_name = $psprintf("%s Root", obj_info.region_name);
        obj_info.roof = new(roof_name);

        // log2numbuffer is prepared for randomize data purpose
        if(ADDR_WIDTH == 64)
        begin
            log2numbuffer = obj_info.log2_64(obj_info.num_buffer);
            tmp = 2 ** log2numbuffer;
            if(tmp !== obj_info.num_buffer)
                log2numbuffer = log2numbuffer + 1;
        end
        else
        begin
            log2numbuffer = obj_info.log2_32(obj_info.num_buffer);
            tmp = 2 ** log2numbuffer;
            if(tmp !== obj_info.num_buffer)
                log2numbuffer = log2numbuffer + 1;
        end
        // create binary tree
        for(uint32_addr_t buffer_index=0; buffer_index < obj_info.num_buffer; buffer_index++)
        begin
            node_0 = obj_info.roof;
            s_addr = obj_info.region_saddr;
            s_addr = s_addr + buffer_index*obj_info.buffer_size;
            for(uint32_addr_t j = obj_info.pos_start-1; j >= obj_info.pos_end; j--)
            begin
                direction = e_direction'(s_addr[j]); // cast to type enum
                node_0 = node_0.insert_node(direction, $psprintf("%s Node[%0d][%0d]", obj_info.region_name, buffer_index, j));
                if(j == obj_info.pos_end)
                begin
                    if(obj_info.data_type == E_LOADFF)
                        node_0.generate_buffer_data_load_from_file(obj_info.buffer_size, log2numbuffer, buffer_index, "../../../LIB/mem32_4k.dat");
                    else
                        node_0.generate_buffer_data(obj_info.data_type, obj_info.buffer_size, log2numbuffer, buffer_index);
                end
            end
        end
        return TRUE;
    end
    else
    begin
        return FALSE;
    end
endfunction: insert_node

/*
Function name: get_info_by_address_from_binary_tree
 + active
 + buffer_addr
Info: Get Binary Tree Information by address
*/
virtual function mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) get_info_by_address_from_binary_tree(ref bool_t active, uint32_addr_t buffer_addr);
    bool_t info_matched = FALSE;
    mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) obj_info;

    foreach(this.binary_tree_info[i])
    begin
        if((this.binary_tree_info[i].region_saddr <= buffer_addr) && (buffer_addr <= this.binary_tree_info[i].region_eaddr))
        begin
            info_matched    = TRUE;
            obj_info        = this.binary_tree_info[i];
            active          = TRUE;
            return          obj_info;
        end
    end
    `uvm_info(get_full_name(), $psprintf("info_matched %s", info_matched.name), UVM_HIGH)
    // return in-case of info searching isn't matched
    if(info_matched == FALSE)
    begin
        obj_info    = null;
        active      = FALSE;
        return      obj_info;
    end
endfunction: get_info_by_address_from_binary_tree

/*
Function name: get_info_by_name_from_binary_tree
 + active
 + region_name
Info: Get Binary Tree Information by region name
*/
virtual function mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) get_info_by_name_from_binary_tree(ref bool_t active, string region_name);
    bool_t info_matched = FALSE;
    mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) obj_info;

    // Check expectation of memory region name is matched
    foreach(this.binary_tree_info[i])
    begin
        if(this.binary_tree_info[i].region_name == region_name)
        begin
            info_matched = TRUE;
            obj_info = this.binary_tree_info[i];
            active = TRUE;
            return obj_info;
        end
    end
    // return in-case of info searching isn't matched
    if(info_matched == FALSE)
    begin
        obj_info = null;
        active = FALSE;
        return obj_info;
    end
endfunction: get_info_by_name_from_binary_tree

/*
Function name: get_buffer_n_by_name
 + active
 + region_name
 + buffer_n
 + buffer_info
Info: get buffer n'th by region name
*/
virtual function mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) get_buffer_n_by_name(ref bool_t active, string region_name, uint32_addr_t buffer_n, mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) buffer_info);
    uint32_addr_t s_addr;
    e_direction direction;
    mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) node_obj;
    if(active == TRUE)
    begin
        s_addr = buffer_info.region_saddr + buffer_n*buffer_info.buffer_size;
        node_obj = buffer_info.roof;
        for(uint32_addr_t i = buffer_info.pos_start-1; i >= buffer_info.pos_end; i--)
        begin
            direction = e_direction'(s_addr[i]); // cast to type enum
            node_obj = node_obj.go_to_node(direction);
            if(node_obj == null)
            begin
                `uvm_error(get_full_name(), $psprintf("Memory: %s BUFFER number: %0d doesn't exist", region_name, buffer_n))
                active = FALSE;
                return node_obj;
            end
        end
        return node_obj;
    end
    else
    begin
        node_obj = null;
        return node_obj;
    end
endfunction: get_buffer_n_by_name

/*
Function name: get_buffer_by_address
 + active
 + buffer_addr
 + buffer_info
Info: get buffer by address
*/
virtual function mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) get_buffer_by_address(ref bool_t active, uint32_addr_t buffer_addr, mem_mmu_binary_tree_info#(DATA_WIDTH, ADDR_WIDTH) buffer_info);
    e_direction direction;
    mem_mmu_node#(DATA_WIDTH, ADDR_WIDTH) node_obj;
    if(active == TRUE)
    begin
        node_obj = buffer_info.roof;
        for(uint32_addr_t index = buffer_info.pos_start-1; index >= buffer_info.pos_end; index--)
        begin
            direction = e_direction'(buffer_addr[index]);
            node_obj = node_obj.go_to_node(direction);
            if(node_obj == null)
            begin
                `uvm_error(get_full_name(), $psprintf("BUFFER at address: 0x%x doesn't exist", buffer_addr))
                active = FALSE;
                return node_obj;
            end
        end
        return node_obj;
    end
    else
    begin
        node_obj = null;
        return node_obj;
    end
endfunction: get_buffer_by_address

endclass: mem_mmu

`endif // MEM_MMU

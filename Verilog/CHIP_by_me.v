// Your code

module CHIP(clk,
            rst_n,
            // For mem_D
            mem_wen_D,
            mem_addr_D,
            mem_wdata_D,
            mem_rdata_D,
            // For mem_I
            mem_addr_I,
            mem_rdata_I
    );

    input         clk, rst_n ;
    // For mem_D
    output        mem_wen_D  ;
    output [31:0] mem_addr_D ;
    output [31:0] mem_wdata_D;
    input  [31:0] mem_rdata_D;
    // For mem_I
    output [31:0] mem_addr_I ;
    input  [31:0] mem_rdata_I;
    
    //---------------------------------------//
    // Do not modify this part!!!            //
    // Exception: You may change wire to reg //
    reg    [31:0] PC          ;              //
    reg    [31:0] PC_nxt      ;              //
    reg           regWrite    ;              //
    wire   [ 4:0] rs1, rs2, rd;              //
    wire   [31:0] rs1_data    ;              //
    wire   [31:0] rs2_data    ;              //
    wire   [31:0] rd_data     ;              //
    //---------------------------------------//

    // Todo: other wire/reg
    reg 	[31:0] mem_wdata_D	 ;
    reg 	[31:0] register [0:31];
    reg 	[31:0] next_register [0:31];
    reg 		   mem_write 	 ;
    reg 	[31:0] mem_write_addr;            // to memory output
    reg 	[2:0]  ALU_ctrl 	 ;            // ALU contorl
    reg 	[1:0]  ALU_op 		 ;
    reg 		   ALU_src		 ;
    wire 	[6:0]  funct7		 ;
    wire 	[2:0]  funct3 		 ;
    wire 	[6:0]  opcode		 ;
    reg 		   Jal, Jalr	 ;            // to recognize whether it is jal or jalr
    wire 	[31:0] alu_in 		 ;
    wire 	[31:0] alu_out 		 ;
    reg 	[31:0] I_imm		 ;
    reg 		   branch_control;
    wire 		   zero, jump	 ;            // to compute jump or not
    reg 	[2:0]  regWrite_src  ;            // to control register write part
    reg 	[20:0] tmp_Imm		 ;            // to help do sign extension operation

    `define R_type 		7'b0110011
    `define I_type		7'b0010011
    `define AUIPC_type  7'b0010111
    `define SW_type		7'b0100011
    `define LW_type		7'b0000011
    `define BEQ_type	7'b1100011
    `define JAL_type	7'b1101111
    `define JALR_type	7'b1100111

    // ------------------- Output Connection ---------------------
	assign mem_wen_D = mem_write;
    assign mem_addr_D = mem_write_addr[31:0];
    assign mem_addr_I = PC[31:0];

    // ----------------------- Decoding --------------------------
    assign rs1 = mem_rdata_I[19:15];
    assign rs2 = mem_rdata_I[24:20];
    assign rd = mem_rdata_I[11:7];
    assign funct7 = mem_rdata_I[31:25];
    assign funct3 = mem_rdata_I[14:12];
    assign opcode = mem_rdata_I[6:0];
    assign zero = (register[rs1] == register[rs2])? 1 : 0;
    assign jump = (branch_control & zero) | Jal;

    //---------------------------------------//
    // Do not modify this part!!!            //
    reg_file reg0(                           //
        .clk(clk),                           //
        .rst_n(rst_n),                       //
        .wen(regWrite),                      //
        .a1(rs1),                            //
        .a2(rs2),                            //
        .aw(rd),                             //
        .d(rd_data),                         //
        .q1(rs1_data),                       //
        .q2(rs2_data));                      //
    //---------------------------------------//
    
    // Todo: any combinational/sequential circuit
    // --------------------- Sub Modules ----------------------
    MUX32 MUX_ALUsrc(
    	.in1(register[rs2]),
    	.in2(I_imm),
    	.ctrl(ALU_src),
    	.out(alu_in));

    ALU ALU(
    	.in1(register[rs1]),
    	.in2(alu_in),
    	.ctrl(ALU_ctrl),
    	.out(alu_out));

    // ----------------- Instruction Fetching -----------------
    always@(*) begin
    	//$display("0x%8h", mem_rdata_I);
    	ALU_ctrl = 3'b111;
    	ALU_src = 1'b0;
    	mem_write = 1'b0;
    	regWrite = 1'b0;
    	Jal = 1'b0;
    	Jalr = 1'b0;
    	branch_control = 1'b0;
    	I_imm = 32'b0;
    	regWrite_src = 3'b000;

    	if(opcode == `R_type) begin 								// R type
    		regWrite = 1'b1;
    		ALU_src = 1'b0;
    		if (funct3 == 3'b111 && funct7 == 7'b0000000) begin
    			//$display("AND");
    			ALU_ctrl = 3'b000;									// AND operation
    		end 
    		else if (funct3 == 3'b110 && funct7 == 7'b0000000) begin 
    			//$display("OR");
    			ALU_ctrl = 3'b001;									// OR operation
    		end
    		else if (funct3 == 3'b000 && funct7 == 7'b0000000) begin
    			//$display("ADD");
    			ALU_ctrl = 3'b010;									// ADD operation
    		end 
    		else if (funct3 == 3'b000 && funct7 == 7'b0100000) begin
    			//$display("SUB");
    			ALU_ctrl = 3'b110;									// SUB operation
    		end
            else if (funct3 == 3'b000 && funct7 == 7'b0000001) begin    // <- need to change to MULDIV??????????????
                //$display("MUL");
                ALU_ctrl = 3'b101; // MUL operation
            end 
    		else begin
    			//$display("R_type None");
    		end
    	end
    	else if (opcode ==`I_type) begin 							// I type
    		regWrite = 1'b1;
    		ALU_src = 1'b1;
    		if (funct3 == 3'b000) begin 							// ADDI
    			//$display("ADDI");
    			ALU_ctrl = 3'b010; 									// ADD operation
                if (mem_rdata_I[31]) begin
                    I_imm =  {20'b11111111111111111111, mem_rdata_I[31:20]};
                end
                else begin
                    I_imm =  {20'b0, mem_rdata_I[31:20]};
                end
    		end
    		else if(funct3 == 3'b010) begin 						//SLTI
    			//$display("SLTI");
    			regWrite_src = 3'b100;
    			ALU_ctrl = 3'b110; 									// SUB operation
                if (mem_rdata_I[31]) begin
                    I_imm =  {20'b11111111111111111111, mem_rdata_I[31:20]};
                end
                else begin
                    I_imm =  {20'b0, mem_rdata_I[31:20]};
                end     
    		end
    		else begin
    			//$display("I_type None");
    		end
    	end
    	else if (opcode == `AUIPC_type) begin                      // AUIPC
    		//$display("AUIPC");
    		regWrite_src = 3'b011;
    		regWrite = 1'b1;
    		ALU_src = 1'b1;
    		I_imm = {mem_rdata_I[31:12], 12'b0};
    	end
    	else if (opcode == `SW_type) begin                         // SW
    		//$display("SW");
    		regWrite = 1'b0;
    		ALU_ctrl = 3'b010;												 
    		ALU_src = 1'b1;
    		mem_write = 1'b1;
            if (mem_rdata_I[31]) begin
                I_imm = {20'b11111111111111111111, mem_rdata_I[31:25], mem_rdata_I[11:7]};
            end
            else begin
                I_imm = {20'b0, mem_rdata_I[31:25], mem_rdata_I[11:7]};
            end
    	end
    	else if (opcode == `LW_type) begin                         // LW
    		//$display("LW");
    		regWrite_src = 3'b010;
    		regWrite = 1'b1;
    		ALU_ctrl = 3'b010;												  
    		ALU_src = 1'b1;
    		mem_write = 1'b0;
    		if (mem_rdata_I[31]) begin
                I_imm =  {20'b11111111111111111111, mem_rdata_I[31:20]};
            end
            else begin
                I_imm =  {20'b0, mem_rdata_I[31:20]};
            end
        end
    	else if (opcode == `BEQ_type) begin                        // BEQ
    		//$display("BEQ");
    		regWrite = 1'b0;
    		ALU_ctrl = 3'b110;												 
    		ALU_src = 1'b0;
    		branch_control = 1'b1;
            if (mem_rdata_I[31]) begin
                I_imm = {19'b1111111111111111111, mem_rdata_I[31], mem_rdata_I[7], mem_rdata_I[30:25], mem_rdata_I[11:8], 1'b0}; 
            end
            else begin
                I_imm = {19'b0, mem_rdata_I[31], mem_rdata_I[7], mem_rdata_I[30:25], mem_rdata_I[11:8], 1'b0}; 
            end
    	end
    	else if (opcode == `JAL_type) begin                        // JAL
    		//$display("JAL");
    		regWrite = 1'b1;
    		regWrite_src = 3'b001;
    		Jal = 1'b1;
            Jalr = 1'b0;
            if (mem_rdata_I[31]) begin
            	I_imm = {11'b11111111111, mem_rdata_I[31], mem_rdata_I[19:12], mem_rdata_I[20], mem_rdata_I[30:21], 1'b0};
            end
            else begin
            	I_imm = {11'b0, mem_rdata_I[31], mem_rdata_I[19:12], mem_rdata_I[20], mem_rdata_I[30:21], 1'b0};
            end									 
    	end
    	else if (opcode == `JALR_type) begin                       // JALR
    		//$display("JALR");
    		regWrite = 1'b1;
    		regWrite_src = 3'b001;
    		Jal = 1'b0;
            Jalr = 1'b1;											 
    		if (mem_rdata_I[31]) begin
                I_imm =  {20'b11111111111111111111, mem_rdata_I[31:20]};
            end
            else begin
                I_imm =  {20'b0, mem_rdata_I[31:20]};
            end
    	end
    	else begin 				//  None
    		//$display("None");
    	end
    end

    // ------------------- Register Writing ----------------------
    integer j;
    always@(*) begin
        for(j = 0; j < 32; j = j+1) begin                   // to save registers
            next_register[j] = register[j];
        end
        if(regWrite) begin
            if(regWrite_src == 3'b000) begin    			// R type and ADDI
                next_register[rd] = alu_out;
            end
            else if (regWrite_src == 3'b001) begin 			// JAL or JALR
                next_register[rd] = PC + 32'd4;
            end
            else if(regWrite_src == 3'b010) begin  			// LW
                next_register[rd] = mem_rdata_D;
            end
            else if (regWrite_src == 3'b011) begin 			// AUPIC
            	next_register[rd] = PC + I_imm;
            end
            else if (regWrite_src == 3'b100) begin 			// SLTI
            	if (alu_out[31]) begin
                    //$display("less");
            		next_register[rd] = {31'b0, 1'b1};
            	end
            	else begin
                    //$display("larger");
            		next_register[rd] = 32'b0;
            	end
            end
            else begin
            	//$display("There is something wrong with register writing!");
            end
            //$display("write_data   | 0x%32b", next_register[rd]);
        end 
    end

    // --------------------- Handle Memory Access -----------------------
    always@(*) begin
        mem_write_addr = alu_out;
        if(mem_write) begin
        	mem_wdata_D = register[rs2];
        end
        else begin
            mem_wdata_D = 32'b0;
        end
    end 

    // -------------------------- Handle PC -----------------------------
    always@(*) begin
        PC_nxt = PC + 32'd4;
        if(Jalr) begin
            PC_nxt = register[rs1] + I_imm;
        end
        else begin
            if(jump) begin
                PC_nxt = PC + I_imm;
            end
            else begin
            	PC_nxt = PC + 32'd4;
            end
        end
    end

    // ------------------------- PC (Sequential Part)--------------------------------
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
            for(i = 0; i < 32; i = i+1) begin
                register[i] <= 32'd0;
            end
            register[32'b10] <= 32'hbffffff0;
            register[32'b11] <= 32'h10008000;
        end
        else begin
            PC <= PC_nxt;
            register[0] <= 32'd0;
            for(i = 1; i < 32; i = i+1) begin
                register[i] <= next_register[i];
            end
            //$display("x1   | 0x%8h", register[32'b1]);
            //$display("x2   | 0x%8h", register[32'b10]);
            //$display("x5   | 0x%8h", register[32'b101]);
            //$display("x6   | 0x%8h", register[32'b110]);
            //$display("x10  | 0x%8h", register[32'b1010]);
            //$display("--------------------------------------"); 
        end
    end

endmodule

module reg_file(clk, rst_n, wen, a1, a2, aw, d, q1, q2);
  
    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; 					// 2^addr_width >= word_depth
    
    input clk, rst_n, wen; 						// wen: 0:read | 1:write, regWrite
    input [BITS-1:0] d;							// rd_data
    input [addr_width-1:0] a1, a2, aw; 			// for r1, r2, rd

    output [BITS-1:0] q1, q2;					// rs1_data, rs2_data
    //reg [BITS-1:0] q1, q2;	

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign q1 = mem[a1];
    assign q2 = mem[a2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (aw == i)) ? d : mem[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end       
    end
endmodule

module MUX32(in1, in2, ctrl, out);
	input  [31:0] in1, in2;
	input         ctrl;
	output [31:0] out;
	reg [31:0] out;

	always @(*) begin
		if (ctrl == 1'b0) out = in1;
		else out = in2;
	end
endmodule

module ALU(in1, in2, ctrl, out);
	input signed[31:0] in1;
	input signed[31:0] in2;
	input [2:0] ctrl;
	output signed[31:0] out;
	reg signed [32:0] o;

	parameter AND  = 3'b000;
	parameter OR = 3'b001;
	parameter ADD  = 3'b010;
	parameter SUB  = 3'b110;
	parameter MUL  = 3'b101;

	always @(*) begin
		//$display("in1	| 0x%32b", in1);
		//$display("in2	| 0x%32b", in2);
		case (ctrl)
			AND:  o = in1 & in2;
			OR:   o = in1 | in2;
			ADD:  o = in1 + in2;
			SUB:  o = in1 - in2;
            MUL:  o = in1 * in2; 
		    default: begin
		    	o = 33'b0;
			end
		endcase
	end
	assign out = o[31:0];
endmodule

//module mulDiv(clk, rst_n, valid, ready, mode, in_A, in_B, out);
    // Todo: your HW3

//endmodule
import ahb_pkg::*;
module ahb_m 
	#( parameter AHB_DATA_WIDTH = 64,
	    parameter AHB_ADDRESS_WIDTH = 32,
	    parameter Hclock=10,
	    parameter GEN_RATE=50,
	    parameter max_undefined_length = 25)
	(   // Inputs
	    input logic HREADY,
	    input logic HRESP,
	    input logic [AHB_DATA_WIDTH-1:0] HRDATA,
	    // Outputs
	    output logic [AHB_ADDRESS_WIDTH-1:0] HADDR,
	    output logic [AHB_DATA_WIDTH-1:0] HWDATA,
	    output logic HWRITE,
	    output logic [2:0] HSIZE,
	    output logic [2:0] HBURST,
	    output logic [1:0] HTRANS,
	    output logic HCLK=0,
	    output logic HRESETn);

integer data_bus_bytes;
assign data_bus_bytes = AHB_DATA_WIDTH/8;


// 1. 'logic' only (no reg, no wire)
// 2. parameters/I/O @ the interface [done]
// 3. SV tasks
// 4. NO multiple drivers
// 5. AHB package [done]


//hready fix

//////////////////////////////////////////
////// Encoding stuff
//////////////////////////////////////////

// state encoding
state_t state;
assign HTRANS  = state_t'(state);

// burst encoding
burst_t burst_type;
assign HBURST = burst_t'(burst_type);

// size encoding
size_t size;
assign HSIZE = size_t'(size);

// HRESP encoding
response_t response;
assign response = response_t'(HRESP);

///////++++++++++++++++++++++
////// END OF - Encoding stuff
///////++++++++++++++++++++++





logic [8:0] cycle_counter;
logic [63:0] trans_random_var,gen_random_var,size_random_var,write_random_var;
logic [63:0] file,debug_file;
logic [63:0] local_cycle_counter;
logic [63:0] number_bytes,upper_byte_lane,lower_byte_lane;
logic [7:0] tmp0;
logic [AHB_DATA_WIDTH-1:0]data;
logic [63:0] burst_length;
logic [AHB_DATA_WIDTH-1:0]data_buffer;
logic sucess;
initial begin
	
	file = $fopen("C:/Users/haris/Desktop/Verilog/AHB_master_slave/results.txt", "w") ;
	debug_file = $fopen("C:/Users/haris/Desktop/Verilog/AHB_master_slave/debug_file.txt", "w") ;
	HCLK=0;
	HRESETn=1'b1;
	cycle_counter=0;
	local_cycle_counter=0;
	while (1) begin
		gen_random_var = $urandom_range(0,99);
		trans_random_var = $urandom_range(0,4);
		sucess = std::randomize(size_random_var) with { size_random_var inside {1,2,4,8};};
		// size_random_var = $urandom_range(0,3);
		write_random_var = $urandom_range(0,1);
		if (gen_random_var<GEN_RATE && sucess==1'b1) begin
			if (trans_random_var==0) begin // INCR4
				INCR_t(4,$urandom_range(0,10),size_random_var,write_random_var);
			end else if (trans_random_var==1) begin // INCR8
				INCR_t(8,$urandom_range(0,10),size_random_var,write_random_var);
			end else if (trans_random_var==2) begin // INCR16
				INCR_t(16,$urandom_range(0,10),size_random_var,write_random_var);
			end else if (trans_random_var==3) begin // SINGLE
				SINGLE_t($urandom_range(0,10),size_random_var,write_random_var);
			end else if (trans_random_var==4) begin //INCR
				INCR_t($urandom_range(max_undefined_length,17),$urandom_range(0,10),size_random_var,write_random_var);
			end
		end else begin
			IDLE_t;
		end
	end






	//write_random_var = $urandom_range(0,1);
	// IDLE_t;
	//
	// INCR_t(8,'h0,4,write_random_var);
	// INCR_t(4,'h1,4,write_random_var);
	// INCR_t(4,'h2,4,write_random_var);
	// INCR_t(4,'h3,4,write_random_var);
	// INCR_t(4,'h4,4,write_random_var);
	// INCR_t(4,'h0,4,write_random_var);
	// INCR_t(4,'h1,4,0);
	IDLE_t;
end
// clock generator
always #(Hclock/2) HCLK= ~HCLK;

always @(posedge HCLK) begin
	cycle_counter<=cycle_counter+1;
	if (HWRITE==1) begin
		if (state==BUSY) begin
			HWDATA<=data_buffer;
		end else if (HREADY==1'b1) begin
			HWDATA<=data;
		end else begin
			HWDATA<=HWDATA;
		end
	end else begin
		HWDATA<='bx;
	end

	

	if (state==NONSEQ) begin
		$fwrite(file,"\n");
	end
	//$fwrite(file,"@cycle_counter=%0d \tHTRANS=%s \tHADDR=%h \tHWRITE=%h \tHBURST=%s \tHSIZE=%s \tHWDATA=%h data=%h\tHREADY=%b \t@local_cycle_counter=%0d put_write_data=%b\n",cycle_counter,state,HADDR,HWRITE,burst_type,size,HWDATA,data,HREADY,local_cycle_counter,put_write_data);
	$fwrite(file,"@cycle_counter=%0d \tHTRANS=%s \tHTRANS=%b \tHBURST=%s \tHSIZE=%s \tburst_length=%0d \tHWRITE=%h \tHADDR=%h \tHWDATA=%h \tHRDATA=%h \tHREADY=%b \tHRESP=%s \tdata=%h \tdata_buffer=%h \t@local_cycle_counter=%0d \n",cycle_counter,state,HTRANS,burst_type,size,burst_length,HWRITE,HADDR,HWDATA,HRDATA,HREADY,response,data,data_buffer,local_cycle_counter);


end

always @(posedge (HTRANS==2'b00) ) begin
	$fwrite(file,"\n");
end







task INCR_t;
input integer number_of_beats;
input [AHB_ADDRESS_WIDTH-1:0] start_address;
input integer size_in_bytes;
input write_random_var;
reg [7:0] tmp0;
reg  [AHB_ADDRESS_WIDTH-1:0] aligned_address,next_address;
assign number_bytes = size_in_bytes;
assign aligned_address = (start_address/number_bytes)*number_bytes;
//INCR
	
	local_cycle_counter=0;
	tmp0=0;
	
	while (local_cycle_counter<number_of_beats-1) begin
		@(posedge HCLK) begin
			burst_length<=number_of_beats;
			///////////////////////////
			/// Address phase
			///////////////////////////
			// Set burst type
			if (number_of_beats==0) begin
				burst_type<=INCR;
			end else if (number_of_beats==4) begin
				burst_type<=INCR4;
			end else if(number_of_beats==8) begin
				burst_type<=INCR8;
			end else if (number_of_beats==16) begin
				burst_type<=INCR16;
			end else begin
				burst_type<=INCR;
			end

			// Set size
			if (size_in_bytes==1) begin
				size<=Byte;
			end else if (size_in_bytes==2) begin
				size<=Halfword;
			end else if(size_in_bytes==4) begin
				size<=Word;
			end else if (size_in_bytes==8) begin
				size<=Doubleword;
			end
			if (state==BUSY) begin
				if ($urandom_range(0,100)>10) begin
					state<=SEQ;
				end else begin
					state<=BUSY;
				end
			end else if (HREADY==1'b1) begin
				if (local_cycle_counter==0) begin
					state<=NONSEQ;
				end else begin
					if (local_cycle_counter<number_of_beats-2 && $urandom_range(0,100)<10) begin // na min mporei an emfanisei busy ston teleutaio kyklo gt tote paei stin epomeni entoli apo ton counter, kai etsi dn ginetai to teleutaio transfer tou burst
						state<=BUSY;
					end else begin
						state<=SEQ;
					end
				end 
				//size<=Halfword;

				HWRITE<=write_random_var;
				if (local_cycle_counter>0) begin
					next_address = aligned_address+(local_cycle_counter)*number_bytes;
					HADDR<=next_address; 
				end else begin
					HADDR<=start_address;
				end

				local_cycle_counter<=local_cycle_counter+1;
				if (local_cycle_counter==number_of_beats-1) begin
					local_cycle_counter<=0;
				end
				

				
				// if (local_cycle_counter==0) begin //if first transfer
				// 	lower_byte_lane = (start_address-(start_address/data_bus_bytes)*data_bus_bytes);
				// 	upper_byte_lane = ( aligned_address+(number_bytes-1)-(start_address/data_bus_bytes)*data_bus_bytes);
				// end else begin
				// 	lower_byte_lane=next_address-(next_address/data_bus_bytes)*data_bus_bytes;
				// 	upper_byte_lane=lower_byte_lane+number_bytes-1;
				// end
				// $display("@cycle_counter=%0d",cycle_counter);
				// $display("local_cycle_counter=%0d",local_cycle_counter);
				// $display("lower_byte_lane=%0d",lower_byte_lane);
				// $display("upper_byte_lane=%0d",upper_byte_lane);
				// $display("\n");

				// Set data on data bus
				data_buffer<=data;
				for (int i=0;i<AHB_DATA_WIDTH;i=i+8)begin
					if (local_cycle_counter==0) begin //if first transfer
						lower_byte_lane = (start_address-(start_address/data_bus_bytes)*data_bus_bytes);
						upper_byte_lane = ( aligned_address+(number_bytes-1)-(start_address/data_bus_bytes)*data_bus_bytes);
						if ((i>=lower_byte_lane*8) && (i<=upper_byte_lane*8)) begin //if i >= lower_byte_lane && i<=upper_byte_lane //((i>=start_address-(start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8)) && ( i<=(start_address - start_address%(AHB_DATA_WIDTH/8) + (2**HSIZE-1) - (start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8) ) ) )
							data[i+:8]<=tmp0;
						end else begin
							data[i+:8]<='bx;
						end
					end else begin
						lower_byte_lane=next_address-(next_address/data_bus_bytes)*data_bus_bytes;
						upper_byte_lane=lower_byte_lane+number_bytes-1;
						if ((i>=lower_byte_lane*8) && (i<=upper_byte_lane*8)) begin
							data[i+:8]<=tmp0;
						end else begin
							data[i+:8]<='bx;
						end
						
						
					end
					tmp0=tmp0+1;
				end	
				
				
				
			end
		end
	end
endtask

task IDLE_t;
	
	@(posedge HCLK) begin
		state<=IDLE;
		HADDR<='bx;
		HWRITE<='bx;
		burst_type<=SINGLE;
		size<=Byte;
		data<='bx;
		burst_length<=0;
	end


endtask

task SINGLE_t;
input [AHB_ADDRESS_WIDTH-1:0] start_address;
input integer size_in_bytes;
input write_random_var;
reg  [AHB_ADDRESS_WIDTH-1:0] aligned_address;
assign number_bytes = size_in_bytes;
assign aligned_address = (start_address/number_bytes)*number_bytes;
	// while (HREADY==0)begin // an mou leei to spec oti prepei opwsdipote na kanei o slave sample to 1o nonsec tote to afairw auto
	// 	@(posedge HCLK);
	// end
	tmp0=0;//(start_address/number_bytes)*number_bytes+1;
	@(posedge HCLK)begin
		burst_length<=1;
		burst_type<=SINGLE;
		// Set size
		if (size_in_bytes==1) begin
			size<=Byte;
		end else if (size_in_bytes==2) begin
			size<=Halfword;
		end else if(size_in_bytes==4) begin
			size<=Word;
		end else if (size_in_bytes==8) begin
			size<=Doubleword;
		end
		state<=NONSEQ;
		HWRITE<=write_random_var;
		HADDR<=start_address;
		for (int i=0;i<AHB_DATA_WIDTH;i=i+8)begin
			lower_byte_lane = (start_address-(start_address/data_bus_bytes)*data_bus_bytes);
			upper_byte_lane = ( aligned_address+(number_bytes-1)-(start_address/data_bus_bytes)*data_bus_bytes);
			if ((i>=lower_byte_lane*8) && (i<=upper_byte_lane*8)) begin //if i >= lower_byte_lane && i<=upper_byte_lane //((i>=start_address-(start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8)) && ( i<=(start_address - start_address%(AHB_DATA_WIDTH/8) + (2**HSIZE-1) - (start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8) ) ) )
				data[i+:8]<=tmp0;
			end else begin
				data[i+:8]<='bx;
			end
			tmp0=tmp0+1;
		end
	end
endtask


endmodule
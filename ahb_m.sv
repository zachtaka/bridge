module ahb_m (HADDR,HWDATA,HWRITE,HSIZE,HBURST,HTRANS); // HREADY pros to paron vgazw to hready apo porta

// Parameter declarations
parameter AHB_DATA_WIDTH = 64;
reg [63:0] data_bus_bytes;
assign data_bus_bytes = AHB_DATA_WIDTH/8;
parameter AHB_ADDRESS_WIDTH = 32;
parameter Hclock=10;
parameter GEN_RATE=50;
// Port declarations
// input ports
// output ports
output reg [AHB_ADDRESS_WIDTH-1:0] HADDR;
output reg [AHB_DATA_WIDTH-1:0] HWDATA;
output reg HWRITE;
output reg [2:0] HSIZE,HBURST;
output reg [1:0] HTRANS;

reg HREADY;
reg HCLK=0,HRESETn; //tha ginoun portes logika kapoia stigmi

//////////////////////////////////////////
////// Encoding stuff
//////////////////////////////////////////

// state encoding
enum {IDLE,BUSY,NONSEQ,SEQ} state;
always @(*) begin // #ask to htrans prepei na einai register?
	if (state==IDLE) begin
		HTRANS=2'b00;
	end else if(state==BUSY) begin
		HTRANS=2'b01;
	end else if (state==NONSEQ) begin
		HTRANS=2'b10;
	end else if (state==SEQ) begin
		HTRANS=2'b11;
	end else begin
		HTRANS=2'b00; // default state:idle
	end
end
// burst encoding
enum {SINGLE,INCR,INCR4,INCR8,INCR16,WRAP4,WRAP8,WRAP16} burst_type;
always @(*) begin // #ask to htrans prepei na einai register?
	if (burst_type==SINGLE) begin
		HBURST=3'b000;
	end else if(burst_type==INCR) begin
		HBURST=3'b001;
	end else if (burst_type==WRAP4) begin
		HBURST=3'b010;
	end else if (burst_type==INCR4) begin
		HBURST=3'b011;
	end else if (burst_type==WRAP8) begin
		HBURST=3'b100;
	end else if (burst_type==INCR8) begin
		HBURST=3'b101;
	end else if (burst_type==WRAP16) begin
		HBURST=3'b110;
	end else if (burst_type==INCR16) begin
		HBURST=3'b111;
	end 
end
// size encoding
enum {Byte,Halfword,Word,Doubleword,Fourword,Eightword} size;
integer size_in_bits;
always @(*) begin // #ask to htrans prepei na einai register?
	if (size==Byte) begin
		HSIZE=3'b000;
		size_in_bits=8;
	end else if(size==Halfword) begin
		HSIZE=3'b001;
		size_in_bits=16;
	end else if (size==Word) begin
		HSIZE=3'b010;
		size_in_bits=32;
	end else if (size==Doubleword) begin
		HSIZE=3'b011;
		size_in_bits=64;
	end else if (size==Fourword) begin
		HSIZE=3'b100;
		size_in_bits=128;
	end else if (size==Eightword) begin
		HSIZE=3'b101;
		size_in_bits=256;
	end 
end

reg [8:0] cycle_counter;
integer trans_random_var,gen_random_var;
integer file,debug_file;
integer local_cycle_counter;
reg put_write_data;
integer number_bytes,upper_byte_lane,lower_byte_lane;
reg [7:0] tmp0;
reg [AHB_DATA_WIDTH-1:0]data;


initial begin
	file = $fopen("C:/Users/haris/Desktop/bridge/results.txt", "w") ;
	debug_file = $fopen("C:/Users/haris/Desktop/bridge/debug_file.txt", "w") ;
	HCLK=0;
	HRESETn=1'b1;
	cycle_counter=0;
	HREADY=1'b1;
	local_cycle_counter=0;
	// while (1) begin
	// 	gen_random_var = $urandom_range(0,100);
	// 	trans_random_var = $urandom_range(0,3);
	// 	if (gen_random_var<GEN_RATE) begin
	// 		if (trans_random_var==0) begin
	// 			INCR_t(4,$urandom_range(0,10));
	// 		end else if (trans_random_var==1) begin
	// 			INCR_t(8,$urandom_range(0,10));
	// 		end else if (trans_random_var==2) begin
	// 			INCR_t(16,$urandom_range(0,10));
	// 		end else if (trans_random_var==3) begin
	// 			SINGLE_t($urandom_range(0,10));
	// 		end
	// 	end else begin
	// 		IDLE_t;
	// 	end
		
	// end

	IDLE_t;
	INCR_t(4,'h0,4);
	// INCR_t(4,'h1,4);
	// INCR_t(4,'h2,4);
	// INCR_t(4,'h3,4);
	// INCR_t(4,'h4,4);
	// INCR_t(4,'h0,4);
	IDLE_t;
end
// clock generator
always #(Hclock/2) HCLK= ~HCLK;

always @(posedge HCLK) begin
	cycle_counter<=cycle_counter+1;
	HWDATA<=data;
	//it bugs sometimes san na kleidwnei to HREADY sto 0
	// if (local_cycle_counter>0) begin
	// 	if ($urandom_range(0,100)<10) begin
	// 		HREADY<=0;
	// 	end else begin
	// 		HREADY<=1'b1;
	// 	end
	// end
	
	

	// $display(file,"@cycle_counter=%0d \n",cycle_counter);
	// $display(file,"\tHTRANS=%s\n",state);
	// $display(file,"\tHADDR=%h\n",HADDR);
	// $display(file,"\tHWRITE=%h\n",HWRITE);
	// $display(file,"\tHBURST=%s\n",burst_type);
	// $display(file,"\tHSIZE=%0d bytes\n",size_in_bits/8);

	if (state==NONSEQ) begin
		$fwrite(file,"\n");
	end
	$fwrite(file,"@cycle_counter=%0d \tHTRANS=%s \tHADDR=%h \tHWRITE=%h \tHBURST=%s \tHSIZE=%s \tHWDATA=%h data=%h\tHREADY=%b \t@local_cycle_counter=%0d put_write_data=%b\n",cycle_counter,state,HADDR,HWRITE,burst_type,size,HWDATA,data,HREADY,local_cycle_counter,put_write_data);


end


//Data generator
// always @(*) begin
// 	if (put_write_data==1'b1) begin
// 		// $display("@cycle_counter=%0d",cycle_counter);
// 		// $display("local_cycle_counter=%0d",local_cycle_counter);
// 		// $display("lower_byte_lane=%0d",lower_byte_lane);
// 		// $display("upper_byte_lane=%0d",upper_byte_lane);
// 		// $display("\n");
// 		for (int i=0;i<AHB_DATA_WIDTH;i=i+8)begin
// 			if (local_cycle_counter==2) begin //if first transfer
// 				if ((i>=lower_byte_lane*8) && (i<=upper_byte_lane*8)) begin //if i >= lower_byte_lane && i<=upper_byte_lane //((i>=start_address-(start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8)) && ( i<=(start_address - start_address%(AHB_DATA_WIDTH/8) + (2**HSIZE-1) - (start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8) ) ) )
// 					HWDATA[i+:8]=tmp0;
// 				end else begin
// 					HWDATA[i+:8]='bx;
// 				end
// 			end else begin
// 				if ((i>=lower_byte_lane*8) && (i<=upper_byte_lane*8)) begin
// 					HWDATA[i+:8]=tmp0;
// 				end else begin
// 					HWDATA[i+:8]='bx;
// 				end
				
// 			end
// 			tmp0=tmp0+1;
// 		end
// 	end else begin
// 		HWDATA='bx;
// 		tmp0=0;
// 	end
// end




task INCR_t;
input integer number_of_beats;
input [AHB_ADDRESS_WIDTH-1:0] start_address;
input integer size_in_bytes;
reg [7:0] tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
reg  [AHB_ADDRESS_WIDTH-1:0] aligned_address,next_address;
assign number_bytes = size_in_bytes;
assign aligned_address = (start_address/number_bytes)*number_bytes;
//INCR4
	local_cycle_counter=0;
	tmp0<=0;
	
	while (local_cycle_counter<number_of_beats-1) begin
		@(posedge HCLK) begin
			///////////////////////////
			/// Address phase
			///////////////////////////
			if (local_cycle_counter>=1 || HTRANS==SEQ) begin
				put_write_data<=1'b1;
			end else begin
				put_write_data<=0;
			end
			
			// Set burst type
			if (number_of_beats==0) begin
				burst_type<=INCR;
			end else if (number_of_beats==4) begin
				burst_type<=INCR4;
			end else if(number_of_beats==8) begin
				burst_type<=INCR8;
			end else if (number_of_beats==16) begin
				burst_type<=INCR16;
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
					if (local_cycle_counter!==number_of_beats-1 && $urandom_range(0,100)<10) begin // na min mporei an emfanisei busy ston teleutaio kyklo gt tote paei stin epomeni entoli apo ton counter, kai etsi dn ginetai to teleutaio transfer tou burst
						state<=BUSY;
					end else begin
						state<=SEQ;
					end
				end 
				//size<=Halfword;

				HWRITE<=1'b1;
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
		size<=Word;
		data<='bx;

	end


endtask

task SINGLE_t;
input [AHB_ADDRESS_WIDTH-1:0] start_address;
	while (HREADY==0)begin // an mou leei to spec oti prepei opwsdipote na kanei o slave sample to 1o nonsec tote to afairw auto
		@(posedge HCLK);
	end

	@(posedge HCLK)begin
		burst_type<=SINGLE;
		size<=Word;
		state<=NONSEQ;
		HWRITE<=1'b1;
		HADDR<=start_address;
		for (int i=0;i<AHB_DATA_WIDTH;i=i+8)begin
			//tmp0=i+0; tmp1=i+1; tmp2=i+2; tmp3=i+3; tmp4=i+4; tmp5=i+5; tmp6=i+6; tmp7=i+7;
			if (local_cycle_counter==1) begin //if first transfer
				if(i>=(start_address%(AHB_DATA_WIDTH/8))*8)   begin //if i >= lower_byte_lane && i<=upper_byte_lane//////(i>=(start_address%(AHB_DATA_WIDTH/8))*8) ///////////((i>=start_address-(start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8)) && ( i<=(start_address - start_address%(AHB_DATA_WIDTH/8) + (2**HSIZE-1) - (start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8) ) ) )
					HWDATA[i+:8]<=8'hFF;//{tmp7,tmp6,tmp5,tmp4,tmp3,tmp2,tmp1,tmp0};
				end else begin
					HWDATA[i+:8]<=0;
				end
			end else begin
				HWDATA[i+:8]<=8'hFF;
			end

		end
	end



endtask

endmodule
module ahb_s (HCLK,HRESETn,HADDR,HWDATA,HWRITE,HSIZE,HBURST,HTRANS,HREADY,HRDATA,HRESP,HEXOKAY);


// Parameter declarations
parameter AHB_DATA_WIDTH = 64;
parameter AHB_ADDRESS_WIDTH = 32;

// Port declarations
// input ports
input wire HCLK;
input wire [AHB_ADDRESS_WIDTH-1:0] HADDR;
input wire [AHB_DATA_WIDTH-1:0] HWDATA;
input wire HWRITE;
input wire [2:0] HSIZE,HBURST;
input wire [1:0] HTRANS;
input wire HRESETn;

//output ports
output reg HREADY;
output reg [AHB_DATA_WIDTH-1:0] HRDATA;
output reg HRESP;
output reg HEXOKAY;



//////////////////////////////////////////
////// Encoding stuff
//////////////////////////////////////////

// state encoding
enum {IDLE,BUSY,NONSEQ,SEQ} state;
always @(*) begin // #ask to htrans prepei na einai register?
	if (HTRANS==2'b00) begin
		state=IDLE;
	end else if(HTRANS==2'b01) begin
		state=BUSY;
	end else if (HTRANS==2'b10) begin
		state=NONSEQ;
	end else if (HTRANS==2'b11) begin
		state=SEQ;
	end 
end
// burst encoding
enum {SINGLE,INCR,INCR4,INCR8,INCR16,WRAP4,WRAP8,WRAP16} burst_type;
always @(*) begin // #ask to htrans prepei na einai register?
	if (HBURST==3'b000) begin
		burst_type=SINGLE;
	end else if(HBURST==3'b001) begin
		burst_type=INCR;
	end else if (HBURST==3'b010) begin
		burst_type=WRAP4;
	end else if (HBURST==3'b011) begin
		burst_type=INCR4;
	end else if (HBURST==3'b100) begin
		burst_type=WRAP8;
	end else if (HBURST==3'b101) begin
		burst_type=INCR8;
	end else if (HBURST==3'b110) begin
		burst_type=WRAP16;
	end else if (HBURST==3'b111) begin
		burst_type=INCR16;
	end 
end
// size encoding
enum {Byte,Halfword,Word,Doubleword,Fourword,Eightword} size;
always @(*) begin // #ask to htrans prepei na einai register?
	if (HSIZE==3'b000) begin
		size=Byte;
	end else if(HSIZE==3'b001) begin
		size=Halfword;
	end else if (HSIZE==3'b010) begin
		size=Word;
	end else if (HSIZE==3'b011) begin
		size=Doubleword;
	end else if (HSIZE==3'b100) begin
		size=Fourword;
	end else if (HSIZE==3'b101) begin
		size=Eightword;
	end 
end



// HRESP encoding
enum {ERROR,OKAY} response;
always @(*) begin // #ask to htrans prepei na einai register?
	if (response==OKAY) begin
		HRESP=0;
	end else if(response==ERROR) begin
		HRESP=1'b1;
	end 
end

///////++++++++++++++++++++++
////// END OF - Encoding stuff
///////++++++++++++++++++++++
integer slave_debug_file;
integer clock_cycle_counter;
initial begin 
	slave_debug_file = $fopen("C:/Users/haris/Desktop/bridge/slave_debug_file.txt", "w") ;
	clock_cycle_counter = 0;
end

always @(posedge HCLK ) begin
	HREADY<=1'b1;
	if (state==SEQ) begin 
		if ($urandom_range(0,100)<0) begin  // bug otan to hready=0 sto teleutaio transfer tou burst  
			HREADY<=0;  
		end else begin
			HREADY<=1'b1; 
		end
	end
	HRESP<=0; // hresp==OKAY
end





reg [AHB_ADDRESS_WIDTH-1:0] start_address;
reg [AHB_ADDRESS_WIDTH-1:0] aligned_address;
integer number_bytes,upper_byte_lane,lower_byte_lane,data_bus_bytes;
reg [AHB_DATA_WIDTH-1:0] data;
reg [7:0] tmp0;

assign data_bus_bytes = AHB_DATA_WIDTH/8 ;

always @(*)begin 
	number_bytes = 2**HSIZE;
	aligned_address =(HADDR/number_bytes)*number_bytes ;
	if(state==NONSEQ) begin
		lower_byte_lane = (HADDR-(HADDR/data_bus_bytes)*data_bus_bytes);
		upper_byte_lane = ( aligned_address+(number_bytes-1)-(HADDR/data_bus_bytes)*data_bus_bytes);
	end else begin 
		lower_byte_lane=HADDR-(HADDR/data_bus_bytes)*data_bus_bytes;
		upper_byte_lane=lower_byte_lane+number_bytes-1;
	end
end

always @(posedge HCLK ) begin
	clock_cycle_counter<=clock_cycle_counter+1;
	// If READ send DATA
	if(HWRITE==0 && state!==BUSY) begin // if READ
		$fwrite(slave_debug_file,"@clock_cycle_counter=%d \tHADDR=%h \tHSIZE=%0d \taligned_address=%h \tnumber_bytes=%0d \tlower_byte_lane=%0d \tupper_byte_lane=%h \n",clock_cycle_counter,HADDR,HSIZE,aligned_address,number_bytes,lower_byte_lane,upper_byte_lane);
		for (int i=0;i<=AHB_DATA_WIDTH;i=i+8)begin
			if ((i>=lower_byte_lane*8) && (i<=upper_byte_lane*8)) begin //if i >= lower_byte_lane && i<=upper_byte_lane //((i>=start_address-(start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8)) && ( i<=(start_address - start_address%(AHB_DATA_WIDTH/8) + (2**HSIZE-1) - (start_address/(AHB_DATA_WIDTH/8))*(AHB_DATA_WIDTH/8) ) ) )
				HRDATA[i+:8]<=tmp0;
			end else begin
				HRDATA[i+:8]<='bx;
			end

			tmp0=tmp0+1;
		end

	end else begin 
		HRDATA<='bx;
		if(state==BUSY) begin
			tmp0=tmp0;
		end else begin 
			tmp0=0;
		end
	end


	if(state==NONSEQ) begin
		tmp0=0;
	end
end







endmodule
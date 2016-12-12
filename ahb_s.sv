import ahb_pkg::*;
module ahb_s #(
	parameter AHB_DATA_WIDTH,
	parameter AHB_ADDRESS_WIDTH
	)(
	// Inputs
	input logic HCLK,
	input logic [AHB_ADDRESS_WIDTH-1:0] HADDR,
	input logic [AHB_DATA_WIDTH-1:0] HWDATA,
	input logic HWRITE,
	input logic [2:0] HSIZE,HBURST,
	input logic [1:0] HTRANS,
	input logic HRESETn,
	// Outputs
	output logic HREADY,
	output logic [AHB_DATA_WIDTH-1:0] HRDATA,
	output logic HRESP,
	output logic HEXOKAY
	);




// 1. 'logic' only (no reg, no wire) [done]
// 2. parameters/I/O @ the interface [done]
// 3. SV tasks
// 4. NO multiple drivers
// 5. AHB package[done]


//////////////////////////////////////////
////// Encoding stuff
//////////////////////////////////////////

// state encoding
state_t state;
assign state = state_t'(HTRANS);
// burst encoding
burst_t burst_type;
assign burst_type = burst_t'(HBURST);
// size encoding
size_t size;
assign size = size_t'(HSIZE);
// HRESP encoding
response_t response;
assign response = response_t'(HRESP);

///////++++++++++++++++++++++
////// END OF - Encoding stuff
///////++++++++++++++++++++++

logic [63:0] slave_debug_file;
logic [63:0] clock_cycle_counter;
initial begin 
	// slave_debug_file = $fopen("C:/Users/haris/Desktop/bridge/slave_debug_file.txt", "w") ;
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





logic [AHB_ADDRESS_WIDTH-1:0] start_address;
logic [AHB_ADDRESS_WIDTH-1:0] aligned_address;
logic [63:0] number_bytes,upper_byte_lane,lower_byte_lane,data_bus_bytes;
reg [AHB_DATA_WIDTH-1:0] data;
logic [7:0] tmp0;

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
		// $fwrite(slave_debug_file,"@clock_cycle_counter=%d \tHADDR=%h \tHSIZE=%0d \taligned_address=%h \tnumber_bytes=%0d \tlower_byte_lane=%0d \tupper_byte_lane=%h \n",clock_cycle_counter,HADDR,HSIZE,aligned_address,number_bytes,lower_byte_lane,upper_byte_lane);
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
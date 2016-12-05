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



///////++++++++++++++++++++++
////// END OF - Encoding stuff
///////++++++++++++++++++++++






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


// HRESP encoding
enum {ERROR,OKAY} response;
always @(*) begin // #ask to htrans prepei na einai register?
	if (response==OKAY) begin
		HRESP=0;
	end else if(response==ERROR) begin
		HRESP=1'b1;
	end 
end





endmodule
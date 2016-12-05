`include "ahb_m.sv"
`include "ahb_s.sv"

module wrapper;

// Parameter declarations
parameter AHB_DATA_WIDTH = 64;
parameter AHB_ADDRESS_WIDTH = 32;
parameter Hclock = 10;
parameter GEN_RATE=100;
parameter max_undefined_length=25;
// Signal declarations
wire HREADY;
wire [AHB_ADDRESS_WIDTH-1:0] HADDR;
wire [AHB_DATA_WIDTH-1:0] HWDATA,HRDATA;
wire HWRITE;
wire [2:0] HSIZE,HBURST;
wire [1:0] HTRANS;
wire HCLK,HRESETn;


integer debug_file;
integer cycle_counter;



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









initial begin
	debug_file = $fopen("C:/Users/haris/Desktop/bridge/debug_file.txt", "w") ;
	cycle_counter=0;
end


always @(posedge HCLK) begin
	cycle_counter<=cycle_counter+1;
	if (HTRANS==2'b10) begin //htrans == NONSEQ
		$fwrite(debug_file,"\n");
	end
	$fwrite(debug_file,"@cycle_counter=%0d \tHTRANS=%s \tHADDR=%h \tHWRITE=%h \tHBURST=%s \tHSIZE=%s \tHWDATA=%h \tHREADY=%b\n",cycle_counter,state,HADDR,HWRITE,burst_type,size,HWDATA,HREADY);

end
always @(posedge (HTRANS==2'b00) ) begin
	$fwrite(debug_file,"\n");
end



		ahb_m #(
			.AHB_DATA_WIDTH(AHB_DATA_WIDTH),
			.AHB_ADDRESS_WIDTH(AHB_ADDRESS_WIDTH),
			.Hclock(Hclock),
			.GEN_RATE(GEN_RATE),
			.max_undefined_length(max_undefined_length)
		) inst_ahb_m (
			.HCLK    (HCLK),
			.HRESETn (HRESETn),
			.HADDR   (HADDR),
			.HWDATA  (HWDATA),
			.HWRITE  (HWRITE),
			.HSIZE   (HSIZE),
			.HBURST  (HBURST),
			.HTRANS  (HTRANS),
			.HREADY  (HREADY),
			.HRESP   (HRESP)
		);











			ahb_s #(
			.AHB_DATA_WIDTH(AHB_DATA_WIDTH),
			.AHB_ADDRESS_WIDTH(AHB_ADDRESS_WIDTH)
		) inst_ahb_s (
			.HCLK    (HCLK),
			.HRESETn (HRESETn),
			.HADDR   (HADDR),
			.HWDATA  (HWDATA),
			.HWRITE  (HWRITE),
			.HSIZE   (HSIZE),
			.HBURST  (HBURST),
			.HTRANS  (HTRANS),
			.HREADY  (HREADY),
			.HRDATA  (HRDATA),
			.HRESP   (HRESP),
			.HEXOKAY (HEXOKAY)
		);



endmodule
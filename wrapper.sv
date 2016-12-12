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
logic HREADY;
logic [AHB_ADDRESS_WIDTH-1:0] HADDR;
logic [AHB_DATA_WIDTH-1:0] HWDATA,HRDATA;
logic HWRITE;
logic [2:0] HSIZE,HBURST;
logic [1:0] HTRANS;
logic HCLK,HRESETn;
logic [63:0] debug_file;
logic [63:0] cycle_counter;

// 1. 'logic' only (no reg, no wire)[done]
// 2. parameters/I/O @ the interface [done]
// 3. SV tasks
// 4. NO multiple drivers
// 5. AHB package [done]




initial begin
	//debug_file = $fopen("C:/Users/haris/Desktop/bridge/debug_file.txt", "w") ;
	cycle_counter=0;
end


always @(posedge HCLK) begin
	cycle_counter<=cycle_counter+1;
	// if (HTRANS==2'b10) begin //htrans == NONSEQ
	// 	$fwrite(debug_file,"\n");
	// end
	// $fwrite(debug_file,"@cycle_counter=%0d \tHTRANS=%s \tHADDR=%h \tHWRITE=%h \tHBURST=%s \tHSIZE=%s \tHWDATA=%h \tHREADY=%b\n",cycle_counter,state,HADDR,HWRITE,burst_type,size,HWDATA,HREADY);

end
always @(posedge (HTRANS==2'b00) ) begin
	// $fwrite(debug_file,"\n");
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
			.HRDATA  (HRDATA),
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

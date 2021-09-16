module async_fifo
#(
	parameter data_width = 16,
	parameter data_depth = 1024,
	parameter addr_width = 10
)
(
	input  	                    rst,
	input 			    wr_clk,
	input 			    wr_en,
	input 	   [data_width-1:0] din,
	input 			    rd_clk,
	input                       rd_en,
	output reg                  vaild,
	output reg [data_width-1:0] dout,
	//output     [addr_width:0]   room_avail;
	//output     [addr_width:0]   data_avail;
	output                      empty,
	output                      full
);

	reg  [addr_width:0]   wr_addr_ptr; //write address pointer  add one bit
	reg  [addr_width:0]   rd_addr_ptr; //read address pointer  add one bit
	wire [addr_width-1:0] wr_addr;   //RAM address
	wire [addr_width-1:0] rd_addr;
	
	wire [addr_width:0]   wr_addr_gray;  //write address pointer gray code
	reg  [addr_width:0]   wr_addr_gray_d1;
	reg  [addr_width:0]   wr_addr_gray_d2;
	
	wire [addr_width:0]   rd_addr_gray;  //read address pointer gray code
	reg  [addr_width:0]   rd_addr_gray_d1;
	reg  [addr_width:0]   rd_addr_gray_d2;

	reg  [data_width-1:0] fifo_ram [data_depth-1:0];

	//write fifo
	genvar i;
	generate 
	for(i=0;i<data_depth;i=i+1)
	begin: fifo_init
	always@(posedge wr_clk or negedge rst) begin
		if(!rst)
			fifo_ram[i] <= 16'h0;
		else if(wr_en && (!full))
			fifo_ram[wr_addr] <= din;
		else
			fifo_ram[wr_addr] <= fifo_ram[wr_addr];
	end
	end
	endgenerate
	
	//read fifo
	always@(posedge rd_clk or negedge rst) begin
	if(!rst) begin
		dout  <= 16'h0; 
		vaild <= 1'b0;
	end
	else if(rd_en && (!empty)) begin
		dout <= fifo_ram[rd_addr];
		vaild <= 1'b1;
	end
	else begin
		dout <= dout;
		vaild <= 1'b0;
	end
	end

	assign wr_addr = wr_addr_ptr[addr_width-1-:addr_width];
	assign rd_addr = rd_addr_ptr[addr_width-1-:addr_width];
	
	//binary translation gray code
	assign wr_addr_gray = (wr_addr_ptr >>1) ^ wr_addr_ptr;
	assign rd_addr_gray = (rd_addr_ptr >>1) ^ rd_addr_ptr;
	
	//gray code sync  read->write
	always@(posedge wr_clk) begin
		rd_addr_gray_d1 <= rd_addr_gray;
		rd_addr_gray_d2 <= rd_addr_gray_d1;
	end
	
	always@(posedge wr_clk or negedge rst) begin
	if(!rst)
		wr_addr_ptr <= 'b0;
	else if(wr_en && (!full))
		wr_addr_ptr <= wr_addr_ptr + 1'b1;
	else
		wr_addr_ptr <= wr_addr_ptr;
	end

	//gray code sync write->read
	always@(posedge rd_clk) begin
		wr_addr_gray_d1 <= wr_addr_gray;
		wr_addr_gray_d2 <= wr_addr_gray_d1;
	end
	
	always@(posedge rd_clk or negedge rst) begin
	if(!rst)
		rd_addr_ptr <= 'b0;
	else if(rd_en && (!empty))
		rd_addr_ptr <= rd_addr_ptr + 1'b1;
	else
		rd_addr_ptr <= rd_addr_ptr;
	end
	
	//write clock domain detece full
	assign full  = (wr_addr_gray== {~(rd_addr_gray_d2[addr_width-:2]),rd_addr_gray_d2[addr_width-2:0]}) ? 1'b1:1'b0;
	
	//read clock domain detect empty
	assign empty = (rd_addr_gray==wr_addr_gray_d2) ? 1'b1:1'b0;
	


endmodule


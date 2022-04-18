`timescale 1ns/1ps
`define HALF_CLOCK_PERIOD #20 //design uses 50MHz clock

module testbench();
	reg clk;
	reg rst;
	reg [7:0] writedata;
	reg write;
	reg chipselect;
	reg [2:0] address;
	wire [7:0] VGA_R, VGA_G, VGA_B;
	reg [7:0] writedata_address;
	reg [3:0] color_counter;

	integer i, j;

   vga_ball vga_ball0 ( .clk(clk), .reset(rst), .writedata(writedata), .write(write), .chipselect(chipselect), .address(address), 
		.VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_CLK(), .VGA_HS(), .VGA_VS(), .VGA_BLANK_n(), .VGA_SYNC_n());

	always begin
		`HALF_CLOCK_PERIOD;
		clk = ~clk;
	end

	initial begin
		// register setup
		clk = 0;
		rst = 1;
		chipselect=0;
		write=0;
		writedata_address=0;
		color_counter=0;
		@(posedge clk);

		@(negedge clk);   // release rst
		rst = 0;      

		@(posedge clk);   // start the first cycle
		
		//start TB
		//write sprite attribute table
		chipselect=1;
		write=1;
		address=3'b0;
		writedata=8'b1100_0000; //vertical position (192)
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		address=3'b0;
		writedata=8'b1111_0001; //horizontal position (240)
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		address=3'b0; //~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!test later
		writedata=8'b0000_0010; //sprite gen table base address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//write sprite generator table
		for (j=0 ; j<16; j=j+1) begin 
			for (i=0 ; i<8; i=i+1) begin 
				address=3'b1;
				writedata=writedata_address; //sprite address
				@(posedge clk); 
				@(posedge clk); 
				address=3'b10;
				if (j%3) begin
					if (i<4) writedata=8'b0011_0011; //orange sprite pixel data
					else if (i>3 && i <6) writedata=8'b0000_0000; //transparent
					else writedata=8'b0101_0101; //pink sprite pixel data
				end else
					if (i<4) writedata=8'b0000_0000; //transparent
					else if (i>3 && i <6) writedata=8'b0001_0001; //yellow
					else writedata=8'b0010_0010; //red
				@(posedge clk); 
				@(posedge clk); 
				writedata_address=writedata_address+1;
			end
		end
		
/* 		//row1 l
		address=3'b1;
		writedata=8'b0000_0000; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'b1111_1111; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row1 r
		address=3'b1;
		writedata=8'b0000_0001; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'b1111_1111; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row2 l
		address=3'b1;
		writedata=8'h2; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'hf0; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row2 r
		address=3'b1;
		writedata=8'h3; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'h00; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row3 l
		address=3'b1;
		writedata=8'h4; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'hf0; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row3 r
		address=3'b1;
		writedata=8'h5; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'h00; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row4 l
		address=3'b1;
		writedata=8'h6; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'hff; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row4 r
		address=3'b1;
		writedata=8'h7; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'h00; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		
		//row5 l
		address=3'b1;
		writedata=8'h8; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'hf0; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row5 r
		address=3'b1;
		writedata=8'h9; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'h00; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row6 l
		address=3'b1;
		writedata=8'ha; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'hf0; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row6 r
		address=3'b1;
		writedata=8'hb; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'h00; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row7 l
		address=3'b1;
		writedata=8'hc; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'hf0; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row7 r
		address=3'b1;
		writedata=8'hd; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'h0f; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row8 l
		address=3'b1;
		writedata=8'he; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'hf0; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		//row8 r
		address=3'b1;
		writedata=8'hf; //sprite address
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		address=3'b10;
		writedata=8'h0f; //sprite pixel data
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk);  */
		
		
		for (i=0 ; i<500000; i=i+1) begin 
			@(posedge clk);  // next cycle
		end
		$finish;
	end 
endmodule // testbench


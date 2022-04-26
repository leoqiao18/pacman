`timescale 1ns/1ps
`define HALF_CLOCK_PERIOD #20 //design uses 50MHz clock

module testbench();
	reg clk;
	reg rst;
	reg [31:0] writedata;
	reg write;
	reg chipselect;
	reg [3:0] address;
	wire [7:0] VGA_R, VGA_G, VGA_B;
	reg [15:0] writedata_address;
	reg [6:0] name_writedata_address;
	reg name_value;
	reg [3:0] color_counter;
	
	reg [1:0] table_select;
	reg [7:0] gen_table_base_addr;
	reg [7:0] v_pos;
	reg [7:0] h_pos; 
	reg [15:0] j_counter1;
	reg [15:0] i_counter1;
	reg [7:0] table_data;
	
	

	integer i, j, k;

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
		name_writedata_address=0;
		color_counter=0;
		name_value=1;
		
		table_select=0;
		gen_table_base_addr=0;
		v_pos=0;
		h_pos=0;
		j_counter1=0;
		i_counter1=0;
		table_data=0;
		@(posedge clk);

		@(negedge clk);   // release rst
		rst = 0;      

		@(posedge clk);   // start the first cycle
		
		//start TB
/* 		//Pattern TB
		//write sprite attribute table for 1st sprite
		chipselect=1;
		write=1;
		address=3'b0;
		
		//Load pattern name table
		for (j=0 ; j<4; j=j+1) begin 
			for (i=0 ; i<32; i=i+1) begin 
				writedata={name_value, name_writedata_address}; //address of pixel address
				name_value=~name_value;
				@(posedge clk); 
				@(posedge clk); 
				name_writedata_address=name_writedata_address+1;
			end
			name_value=~name_value; //extra toggle so each adjacent row has different patterns
		end
		
		
		//write pattern generator table values
		for (j=0 ; j<2; j=j+1) begin //one of two patterns
			for (i=0 ; i<32; i=i+1) begin 
				address=3'b1;
				writedata=writedata_address; //sprite address
				@(posedge clk); 
				@(posedge clk); 
				address=3'b10;
				if (j==0) begin
					if (i<7) writedata=8'b0011_0011; //orange sprite pixel data
					else if (i>15) writedata=8'b0101_0101; //pink sprite pixel data
					else writedata=8'b0000_0000; //transparent
				end else
					if (i%3) writedata=8'b0000_0000; //transparent
					else writedata= 8'b0001_0001; //yellow
				@(posedge clk); 
				@(posedge clk); 
				writedata_address=writedata_address+1;
			end
		end */

		//full 5 sprites tb
		chipselect=1;
		write=1;
		
		//write to sprite attribute table
		table_select=2'b10;
		for (j=0 ; j<5; j=j+1) begin  
			i_counter1=0;
			for (i=0 ; i<4; i=i+1) begin  
				case (i)
					0 : begin //sprite vertical position
						writedata={v_pos, 6'b0, (j_counter1<<2) + i_counter1,  table_select};
					end
					1 : begin //sprite horizontal position
						writedata={h_pos, 6'b0, (j_counter1<<2) + i_counter1,  table_select};
					end
					2 : begin //gen table base addr
						writedata={gen_table_base_addr, 6'b0, (j_counter1<<2) + i_counter1,  table_select};
					end
					3 : begin //unused
						writedata={8'b0, 6'b0, (j_counter1<<2) + i_counter1,  table_select};
					end
				endcase
				@(posedge clk); //wait 1 cycle
				i_counter1=i_counter1+1;
			end	
			if (j==3) begin //one more increment to get to edge (630, 460)
				v_pos=v_pos+8'd46; 
				h_pos=h_pos+8'd50;
			end
			gen_table_base_addr=gen_table_base_addr+1;
			j_counter1=j_counter1+1;
			v_pos=v_pos+8'd46; 
			h_pos=h_pos+8'd50;
		end
		
		
		//write to sprite generator table
		table_select=2'b11;
		for (k=0 ; k<5; k=k+1) begin 
			for (j=0 ; j<16; j=j+1) begin 
				for (i=0 ; i<8; i=i+1) begin 
					@(posedge clk); //wait 1 cycle
					if (k%2) begin
						if (i<4) table_data=8'b0011_0011; //orange sprite pixel data
						else if (i>3 && i <6) table_data=8'b0000_0000; //transparent
						else table_data=8'b0101_0101; //pink sprite pixel data
					end else
						if (i<4) table_data=8'b0000_0000; //transparent
						else if (i>3 && i <6) table_data=8'b0001_0001; //yellow
						else table_data=8'b0010_0010; //red
					writedata={table_data, 6'b0, writedata_address, table_select};
					writedata_address=writedata_address+1;
				end
			end
		end
		
/* 		//write sprite attribute table for 1st sprite
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
		
		//write sprite generator table values for 1st sprite
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
		
		//write sprite attribute table for 1st sprite
		address=3'h0;
		writedata=8'b1100_0100; //vertical position (192), address==4
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		address=3'b0;
		writedata=8'b1111_1101; //horizontal position (248) address==5
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		address=3'b0; //~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!test later
		writedata=8'b1000_0110; //sprite gen table base address, val=128, address==6
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk); 
		
		for (j=0 ; j<16; j=j+1) begin 
			for (i=0 ; i<8; i=i+1) begin 
				address=3'b1;
				writedata=writedata_address; //sprite address
				@(posedge clk); 
				@(posedge clk); 
				address=3'b10;
				if (j%3) begin
					if (i<4) writedata=8'b0000_0000; //transparent
					else if (i>6) writedata=8'b0001_0001; //yellow
					else writedata=8'b0111_0111; //blue
				end else
					if (i<4) writedata=8'b0100_0100; //cyan (whitish blue)
					else if (i>6) writedata=8'b0001_0001; //yellow
					else writedata=8'b0000_0000; //transparent
				@(posedge clk); 
				@(posedge clk); 
				writedata_address=writedata_address+1;
			end
		end */
		
		
		
		for (i=0 ; i<850000; i=i+1) begin 
			@(posedge clk);  // next cycle
		end
		$finish;
	end 
endmodule // testbench


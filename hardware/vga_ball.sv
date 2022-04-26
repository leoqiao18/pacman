/*
 * Avalon memory-mapped peripheral that generates VGA
 *
 * Stephen A. Edwards
 * Columbia University
 */

module vga_ball(input logic        clk,
	        input logic 	   reset,
		input logic [31:0]  writedata,
		input logic 	   write,
		input 		   chipselect,
		input logic [3:0]  address,

		output logic [7:0] VGA_R, VGA_G, VGA_B,
		output logic 	   VGA_CLK, VGA_HS, VGA_VS,
		                   VGA_BLANK_n,
		output logic 	   VGA_SYNC_n);

	logic [10:0]	   hcount;
	logic [9:0]     vcount;

	logic [3:0] out_pixel[5:0]; //output pixels values from each of 5 sprites + 1 pattern
	logic [3:0] final_out_pixel; //actual output pixel to display
	logic [7:0] 	   background_r, background_g, background_b;
	logic [23:0] rgb_val; //final RGB value to display
   
   
   	//for pattern name table 
   	logic [11:0] ra_n, wa_n; //12 bits
	logic we_n;
	logic [7:0] din_n;
	logic [7:0] dout_n;
	
	//for pattern generator table 
   	logic [10:0] ra_pg, wa_pg; //change later
	logic we_pg;
	logic [7:0] din_pg;
	logic [7:0] dout_pg;
   
	//for sprite attribute table 
   	logic [4:0] ra_a, wa_a; //5  simultaneous sprites
	logic we_a;
	logic [7:0] din_a;
	logic [7:0] dout_a;
	
	//for sprite generator table 
   	logic [10:0] ra_g, wa_g; //10*128 sprite -> 11 bit addr
	logic we_g;
	logic [7:0] din_g;
	logic [7:0] dout_g;
	
	logic [4:0] sprite_base_addr[4:0]; //sprite attr table base address 
	logic [10:0] h_start[4:0]; //hcount at which sprite_prep n starts
	logic [4:0] sprite_ra_a[4:0]; //requested read address for sprite attr table from sprite prep modules
	logic [10:0] sprite_ra_g[4:0]; //requested read address for sprite gen table from sprite prep modules
	
	//determines where each sprite prep instance will start reading the attr table from
	assign sprite_base_addr[0]=5'h0;
	assign sprite_base_addr[1]=5'h4;
	assign sprite_base_addr[2]=5'h8;
	assign sprite_base_addr[3]=5'hc;
	assign sprite_base_addr[4]=5'h10;
	
	//determines when each sprite prep instance will start processing sprites
	assign h_start[0]=11'b10100100000; //1312
	assign h_start[1]=11'b10100111010; //1338
	assign h_start[2]=11'b10101010100; //1364
	assign h_start[3]=11'b10101101110; //1390
	assign h_start[4]=11'b10110001000; //1416
	
	
	
	vga_counters counters(.clk50(clk), .*);
	patt_name_table pn1(.clk(clk), .ra(ra_n), .wa(wa_n), .we(we_n), .din(din_n), .dout(dout_n));
	patt_gen_table pg1(.clk(clk), .ra(ra_pg), .wa(wa_pg), .we(we_pg), .din(din_pg), .dout(dout_pg));
	
	sprite_attr_table sat1(.clk(clk), .ra(ra_a), .wa(wa_a), .we(we_a), .din(din_a), .dout(dout_a));
	sprite_gen_table sgt1(.clk(clk), .ra(ra_g), .wa(wa_g), .we(we_g), .din(din_g), .dout(dout_g));
	color_lut cl1(.color_code(final_out_pixel), .rgb_val(rgb_val));
	
	pattern_prep pp0(.clk(clk), .reset(reset), .hcount(hcount), .vcount(vcount), .VGA_BLANK_n(VGA_BLANK_n), 
	.dout_n (dout_n), .dout_g (dout_pg), .ra_n (ra_n), .ra_g(ra_pg), .out_pixel(out_pixel[5]));
	
	sprite_prep sp0(.clk(clk), .reset(reset), .h_start(h_start[0]), .hcount(hcount), .vcount(vcount), .VGA_BLANK_n(VGA_BLANK_n), .base_addr(sprite_base_addr[0]),
	.dout_a (dout_a), .dout_g (dout_g), .ra_a (sprite_ra_a[0]), .ra_g(sprite_ra_g[0]), .out_pixel(out_pixel[0]));
	
	sprite_prep sp1(.clk(clk), .reset(reset), .h_start(h_start[1]), .hcount(hcount), .vcount(vcount), .VGA_BLANK_n(VGA_BLANK_n), .base_addr(sprite_base_addr[1]),
	.dout_a (dout_a), .dout_g (dout_g), .ra_a (sprite_ra_a[1]), .ra_g(sprite_ra_g[1]), .out_pixel(out_pixel[1]));
	
	sprite_prep sp2(.clk(clk), .reset(reset), .h_start(h_start[2]), .hcount(hcount), .vcount(vcount), .VGA_BLANK_n(VGA_BLANK_n), .base_addr(sprite_base_addr[2]),
	.dout_a (dout_a), .dout_g (dout_g), .ra_a (sprite_ra_a[2]), .ra_g(sprite_ra_g[2]), .out_pixel(out_pixel[2]));
	
	sprite_prep sp3(.clk(clk), .reset(reset), .h_start(h_start[3]), .hcount(hcount), .vcount(vcount), .VGA_BLANK_n(VGA_BLANK_n), .base_addr(sprite_base_addr[3]),
	.dout_a (dout_a), .dout_g (dout_g), .ra_a (sprite_ra_a[3]), .ra_g(sprite_ra_g[3]), .out_pixel(out_pixel[3]));
	
	sprite_prep sp4(.clk(clk), .reset(reset), .h_start(h_start[4]), .hcount(hcount), .vcount(vcount), .VGA_BLANK_n(VGA_BLANK_n), .base_addr(sprite_base_addr[4]),
	.dout_a (dout_a), .dout_g (dout_g), .ra_a (sprite_ra_a[4]), .ra_g(sprite_ra_g[4]), .out_pixel(out_pixel[4]));

    always_ff @(posedge clk) begin //Writing to VRAM
		 if (reset) begin
			background_r <= 8'h0;
			background_g <= 8'h0;
			background_b <= 8'h20;
		 end else if (chipselect && write) begin
			case (writedata[1:0])
				2'b0 : begin //pattern name table
						we_n<=1; 
						we_pg<=0;
						we_a<=0;
						we_g<=0;
						din_n<=writedata[31:24];
						wa_n<=writedata[13:2];
					end
				2'b1 : begin //pattern gen table
						we_n<=0; 
						we_pg<=1;
						we_a<=0;
						we_g<=0;
						din_pg<=writedata[31:24];
						wa_pg<=writedata[12:2];
					end
				2'b10 : begin //sprite attr table
						we_n<=0; 
						we_pg<=0;
						we_a<=1;
						we_g<=0;
						din_a<=writedata[31:24];
						wa_a<=writedata[6:2];
					end
				2'b11 : begin //sprite gen table
						we_n<=0; 
						we_pg<=0;
						we_a<=0;
						we_g<=1;
						din_g<=writedata[31:24];
						wa_g<=writedata[12:2];
					end
			endcase
		 end
	end
	
	always_comb begin //Display logic
		{VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};
		if (VGA_BLANK_n ) begin
			if (final_out_pixel!=4'b0) {VGA_R, VGA_G, VGA_B} = {rgb_val[23:16], rgb_val[15:8], rgb_val[7:0]};
			else  {VGA_R, VGA_G, VGA_B} = {background_r, background_g, background_b};
		end
	end
	
	always_comb begin //color prioirity multiplexer (i.e. sprite 1 pixels precedes sprite 2, sprite 2 > sprite 3...)
		if (out_pixel[0]!=4'b0) final_out_pixel=out_pixel[0];
		else if (out_pixel[1]!=4'b0) final_out_pixel=out_pixel[1];
		else if (out_pixel[2]!=4'b0) final_out_pixel=out_pixel[2];
		else if (out_pixel[3]!=4'b0) final_out_pixel=out_pixel[3];
		else if (out_pixel[4]!=4'b0) final_out_pixel=out_pixel[4];
		else if (out_pixel[5]!=4'b0) final_out_pixel=out_pixel[5]; //pattern has lowest pixel priority
		else final_out_pixel=4'b0;
	end
	
	
	
	always_comb begin //VRAM read multiplexer
		//multiplex sprite attribute table reads
		if ((hcount>=h_start[0]) && (hcount<h_start[1])) begin
			ra_a=sprite_ra_a[0]; 
			ra_g=sprite_ra_g[0]; 
		end else if ((hcount>=h_start[1]) && (hcount<h_start[2])) begin
			ra_a=sprite_ra_a[1]; 
			ra_g=sprite_ra_g[1]; 
		end else if ((hcount>=h_start[2]) && (hcount<h_start[3])) begin
			ra_a=sprite_ra_a[2]; 
			ra_g=sprite_ra_g[2]; 
		end else if ((hcount>=h_start[3]) && (hcount<h_start[4])) begin
			ra_a=sprite_ra_a[3]; 
			ra_g=sprite_ra_g[3]; 
		end else if (hcount>=h_start[4]) begin
			ra_a=sprite_ra_a[4]; 
			ra_g=sprite_ra_g[4]; 
		end else begin //below should never run here
			ra_a=5'b0; 
			ra_g=11'b0; 
		end
	end
	 
endmodule

module sprite_prep (input logic clk, reset,
	input logic [10:0] h_start,
	input logic [10:0] hcount,
	input logic [9:0] vcount,
	input logic VGA_BLANK_n,
	input logic [4:0] base_addr, //base address in sprite attr table
	input logic [7:0] dout_a,
	input logic [7:0] dout_g,
	output logic [4:0] ra_a,
	output logic [10:0] ra_g,
	output logic [3:0] out_pixel);
	
	logic [8:0] down_counter; //8 bit wide down counter
	logic [63:0] shift_reg; //64 bit wide shift register
	logic [7:0] shift_pos; //position in shift reg to read pixel value from
	logic [10:0] sprite_offset; //which row of a given sprite to display
	logic [63:0] display_pixel;// determines whether sprite or background pixel is shown
	logic [7:0] shift_reg_shift; //bit position in shift reg to write to (0-63, steps of 8)
	assign out_pixel=display_pixel[3:0];
	
	enum {IDLE, READ_VERT_POS,READ_VERT_POS_WAIT, READ_VERT_POS_WAIT2, READ_HORT_POS, READ_HORT_POS_WAIT, 
	READ_SPRITE_ADDR, READ_SPRITE_ADDR_WAIT, READ_SPRITE_PIXELS_BASE, READ_SPRITE_PIXELS_BASE_WAIT, 
	LOAD_SHIFT_REG, LOAD_SHIFT_REG_WAIT, SPRITES_LOADED, COUNT_DOWN, PREPARE_PIXELS } 
	state, state_next;
	
	
	always_ff @(posedge clk) begin
		state<=state_next;
		if (reset) begin
			state<=IDLE;
			ra_g<=0;
			ra_a<=0;
		end
		
		case (state)
			IDLE: begin
				display_pixel<=64'b0;
				shift_reg<=64'b0;
				shift_reg_shift<=8'h40; //dec=64 (actual value used is 8 less)
				shift_pos<=8'h40; //dec=64 set shift position to start of shift regs (MSB) (actual value used is 4 less)
			end
			READ_VERT_POS: begin
				ra_a<=base_addr; //address of (starting) vertical position of sprite
			end
			READ_HORT_POS: begin
				ra_a<=base_addr+5'b1; //address of horizontal position of sprite
				sprite_offset<={2'b0, vcount[8:0]-{dout_a, 1'b0}}; //which of 16 rows of sprite to display //e.g. vcount=11, v_pos=5 -> 11-5=6th row
			end
			READ_SPRITE_ADDR: begin //base address need right shift of 3 bits 
				ra_a<=base_addr+5'b10; //address of base address of sprite pixels in the generator table //test using 0
				down_counter<={dout_a, 1'b0}; //copy horizontal position into down counter
			end
			READ_SPRITE_PIXELS_BASE: begin //!!note: address no longer >> shifted by 3!!
				ra_g<={dout_a[3:0], 7'b0} + (sprite_offset<<3); //read left-most 8 pixels in gen table, 8x offset since 8 table rows needed per pixel line 
			end
			LOAD_SHIFT_REG: begin
				shift_reg<= ({56'b0, dout_g}<<(shift_reg_shift-8'h8)) | shift_reg; //store left-most 8 pixels of sprite line
				shift_reg_shift<=shift_reg_shift-8'h8; //minus 8
				ra_g<=ra_g+1; //increment gen table address by one to read upcoming pixels
			end
			COUNT_DOWN: begin
				//only down count every 2 hcounts
				if (down_counter>9'b0 && VGA_BLANK_n && !hcount[0]) down_counter<=down_counter-1;
			end
			PREPARE_PIXELS: begin
				if (VGA_BLANK_n && !hcount[0]) begin
					display_pixel<=(shift_reg>>(shift_pos-8'h4)); //Only 4 LSB of display_pixel matter
					shift_pos<=shift_pos-8'h4; //minus 4
				end
			end
		endcase
		
	end
	
	always_comb begin
        case (state)
            IDLE:       state_next = (hcount==h_start) ? READ_VERT_POS: IDLE; 
            READ_VERT_POS:      state_next = READ_VERT_POS_WAIT; //extra cycle for reading vertical position in attr table
			READ_VERT_POS_WAIT:   state_next = READ_VERT_POS_WAIT2; //ra_a update needs 2 cycles for some reason
			READ_VERT_POS_WAIT2: state_next = ((vcount [8:0]>={dout_a, 1'b0}) && (vcount[8:0]<({dout_a, 1'b0}+8'b10000)))? READ_HORT_POS: IDLE;  //check if any part of sprite is showing (don't need last 4 LSB)
			READ_HORT_POS:       state_next = READ_HORT_POS_WAIT;  //extra cycle for mem read
			READ_HORT_POS_WAIT:  state_next = READ_SPRITE_ADDR;
			READ_SPRITE_ADDR:    state_next = READ_SPRITE_ADDR_WAIT; //extra cycle for mem read
			READ_SPRITE_ADDR_WAIT:    state_next = READ_SPRITE_PIXELS_BASE;
			READ_SPRITE_PIXELS_BASE: state_next= READ_SPRITE_PIXELS_BASE_WAIT; //extra cycle for mem read
			READ_SPRITE_PIXELS_BASE_WAIT: state_next= LOAD_SHIFT_REG; 
			LOAD_SHIFT_REG: state_next= LOAD_SHIFT_REG_WAIT; 
			LOAD_SHIFT_REG_WAIT: state_next= (shift_reg_shift==8'b0) ? SPRITES_LOADED: LOAD_SHIFT_REG; 
			
			//if new vertical line started, begin down counting
			SPRITES_LOADED: state_next= (hcount==11'b1111111) ? COUNT_DOWN : SPRITES_LOADED; //start at 127
			COUNT_DOWN: state_next= (down_counter==9'b0) ? PREPARE_PIXELS: COUNT_DOWN;
			PREPARE_PIXELS: state_next= (shift_pos==8'b0) ? IDLE : PREPARE_PIXELS;
            default:    state_next = IDLE;
        endcase
    end
endmodule

module pattern_prep (input logic clk, reset,
	input logic [10:0] hcount,
	input logic [9:0] vcount,
	input logic VGA_BLANK_n,
	input logic [7:0] dout_n,
	input logic [7:0] dout_g,
	output logic [11:0] ra_n,
	output logic [10:0] ra_g,
	output logic [3:0] out_pixel);
	
	logic [2047:0] shift_reg; //8*64*4 bit wide shift register
	logic [11:0] shift_pos; //position in shift reg to read pixel value from
	logic [10:0] pattern_row_offset; //which of 8 of a given pattern to display
	logic [2047:0] display_pixel;// determines whether sprite or background pixel is shown
	logic [11:0] shift_reg_shift; //bit position in shift reg to write to (0-63, steps of 8)
	logic [7:0] tile_total_counter; //counts the total number of tiles that has been loaded into shift reg
	logic [7:0] tile_pixel_counter; //counts the number of tile pixel rows that has been loaded 
	assign out_pixel=display_pixel[3:0];
	
	parameter [11:0] v_start=12'h0; //vertical position where first pattern begins
	parameter [7:0] tiles_per_row=8'd64; //number of tiles per row
	//parameter [7:0] tiles_per_col=8'h18; //number of tiles per column
	parameter [11:0] name_table_addr_mask={6'b111111, 6'b0}; 
	
	enum {IDLE, READ_TILE_ADDR_BASE, READ_TILE_ADDR_BASE_WAIT, READ_PATT_PIXELS_BASE, READ_PATT_PIXELS_BASE_WAIT,
	LOAD_SHIFT_REG, LOAD_SHIFT_REG_WAIT, READ_TILE_NEXT, READ_TILE_NEXT_WAIT, PATT_LOADED, PREPARE_PIXELS } 
	state, state_next;
	
	
	always_ff @(posedge clk) begin
		state<=state_next;
		if (reset) begin
			state<=IDLE;
			ra_n<=0;
			ra_g<=0;
		end
		
		case (state)
			IDLE: begin
				tile_total_counter<=8'b0;
				tile_pixel_counter<=8'b0;
				display_pixel<=2048'b0;
				shift_reg<=2048'b0;
				shift_reg_shift<=12'b100000000000; //dec=2048 (actual value used is 8 less)
				shift_pos<=12'b100000000000; // dec=2048 set shift position to start of shift regs (MSB) (actual value used is 4 less)

			end
			READ_TILE_ADDR_BASE: begin
				ra_n<=(({2'b0, vcount}-v_start)<<3) & name_table_addr_mask; //get address of (starting) tile pixel address in name table
				pattern_row_offset<={8'b0, vcount[2:0]-v_start[2:0]}; //which of 8 pixel rows to access
			end

			READ_PATT_PIXELS_BASE: begin //!!note: address no longer >> shifted by 3!!
				ra_g<={dout_n[5:0], 5'b0} + (pattern_row_offset<<2); //read base 8 pixels in gen table,4x offset since 4 table rows needed per pixel line 
			end
			
			READ_PATT_PIXELS_BASE_WAIT: begin //!!note: address no longer >> shifted by 3!!
				ra_g<=ra_g+1;
			end
			
			LOAD_SHIFT_REG: begin //first time: gets ra_g pixels_base stage and not base_wait stage
				shift_reg<= ({2040'b0, dout_g}<<(shift_reg_shift-12'h8)) | shift_reg; //store left-most 8 pixels of sprite line
				shift_reg_shift<=shift_reg_shift-12'h8; //minus 8
				ra_g<=ra_g+1; //increment gen table address by one to read upcoming pixels
				tile_pixel_counter<=tile_pixel_counter+8'b1;
			end
			READ_TILE_NEXT: begin 
				ra_n<=ra_n+1; //increment name table address
				tile_pixel_counter<=8'b0;
				tile_total_counter<=tile_total_counter+8'b1;
			end
			
			PREPARE_PIXELS: begin
				if (VGA_BLANK_n && !hcount[0]) begin
					display_pixel<=(shift_reg>>(shift_pos-12'h4)); //Only 4 LSB of display_pixel matter
					shift_pos<=shift_pos-12'h4; //minus 4
				end
			end
		endcase
		
	end

	always_comb begin
        case (state)
            IDLE:       state_next = ((hcount==11'd1152) && (vcount>=v_start[9:0]) && (vcount<10'd480)) ? READ_TILE_ADDR_BASE: IDLE; //start at h=1152 and vcount=0
            READ_TILE_ADDR_BASE:      state_next = READ_TILE_ADDR_BASE_WAIT; //extra cycle for reading vertical position in attr table
			READ_TILE_ADDR_BASE_WAIT:   state_next = READ_PATT_PIXELS_BASE; //check if true: ra_a update needs 2 cycles for some reason
			READ_PATT_PIXELS_BASE:  	state_next = READ_PATT_PIXELS_BASE_WAIT;
			READ_PATT_PIXELS_BASE_WAIT: state_next= LOAD_SHIFT_REG; 
			LOAD_SHIFT_REG: state_next= (tile_pixel_counter==8'h3) ? READ_TILE_NEXT: LOAD_SHIFT_REG; 
			READ_TILE_NEXT: state_next=READ_TILE_NEXT_WAIT;
			READ_TILE_NEXT_WAIT: state_next=(tile_total_counter==tiles_per_row)? PATT_LOADED: READ_PATT_PIXELS_BASE;
			
			//if new vertical line started, begin down counting
			PATT_LOADED: state_next= (hcount==11'd127) ? PREPARE_PIXELS : PATT_LOADED;
			PREPARE_PIXELS: state_next= (shift_pos==12'b0 || vcount>10'd480) ? IDLE : PREPARE_PIXELS;
            default:    state_next = IDLE;
        endcase
    end
endmodule

module sprite_attr_table( //stores sprite information (x, y, name, color)
	//x and y position has to be a multiple (2x) of hcount/vcount since only 8 bits
	input logic clk,
	input logic [4:0] ra, wa, //change later
	input logic we,
	input logic [7:0] din, 
	output logic [7:0] dout);
	
	logic[7:0] mem[31:0];
	
	always_ff @(posedge clk) begin
      if (we) mem[wa] <= din;
      dout <= mem[ra];      
	end
endmodule

module sprite_gen_table( //stores 16x 16x16 sprites (only 10 needed)
	input logic clk,
	input logic [10:0] ra, wa, //change later
	input logic we,
	input logic [7:0] din,
	output logic [7:0] dout);
	
	logic[7:0] mem[2047:0]; //128 8 bit words need per sprite: 64 bits per pixel row
	 
	always_ff @(posedge clk) begin
      if (we) mem[wa] <= din;
      dout <= mem[ra];      
	end
endmodule

module patt_name_table( //stores 8 bit address of tiles on each row
	input logic clk,
	input logic [11:0] ra, wa, //12 bit addr
	input logic we,
	input logic [7:0] din, 
	output logic [7:0] dout);
	
	logic[7:0] mem[4095:0];
	
	always_ff @(posedge clk) begin
      if (we) mem[wa] <= din;
      dout <= mem[ra];      
	end
endmodule

module patt_gen_table( //stores 8x8 patterns
	input logic clk,
	input logic [10:0] ra, wa, 
	input logic we,
	input logic [7:0] din,
	output logic [7:0] dout);
	
	logic[7:0] mem[2047:0]; //32 8 bit words need per pattern: 4 table rows (32 bits) per pixel row
	 
	always_ff @(posedge clk) begin
      if (we) mem[wa] <= din;
      dout <= mem[ra];      
	end
endmodule

module color_lut(input logic  [3:0] color_code,
	       output logic [23:0] rgb_val);
   always_comb
		case(color_code)
			4'h1: rgb_val=24'hfef104; //yellow pac-man 
			4'h2: rgb_val=24'hfe0e03; //red ghost 
			4'h3: rgb_val=24'hfeb846; //orange ghost
			4'h4: rgb_val=24'h00ecfe; //cyan ghost
			4'h5: rgb_val=24'hfdbff9; //pink ghost
			4'h6: rgb_val=24'he5dfee; //ghost eyes (whites)
			4'h7: rgb_val=24'h1e26b8; //blue: ghost eye iris, maze walls, blue ghosts
			4'h8: rgb_val=24'hffc0b7; //salmon food pellets
			4'h9: rgb_val=24'hffffff; //white text
			default: rgb_val=24'hffffff; //if something goes wrong, use white to make it obvious
		endcase
   
endmodule
	
	

module vga_counters(
 input logic 	     clk50, reset,
 output logic [10:0] hcount,  // hcount[10:1] is pixel column
 output logic [9:0]  vcount,  // vcount[9:0] is pixel row
 output logic 	     VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 * HCOUNT 1599 0             1279       1599 0
 *             _______________              ________
 * ___________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */
   // Parameters for hcount
   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 32,
             HSYNC        = 11'd 192,
             HBACK_PORCH  = 11'd 96,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC +
                            HBACK_PORCH; // 1600
   
   // Parameters for vcount
   parameter VACTIVE      = 10'd 480,
             VFRONT_PORCH = 10'd 10,
             VSYNC        = 10'd 2,
             VBACK_PORCH  = 10'd 33,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC +
                            VBACK_PORCH; // 525

   logic endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;
       
   logic endOfField;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 10'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x5DF (0x57F)
   // 101 0010 0000 to 101 1101 1111 (active LOW during 1312-1503) (192 cycles)
   assign VGA_HS = !( (hcount[10:8] == 3'b101) & !(hcount[7:5] == 3'b111));
   assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 1'b0; // For putting sync on the green signal; unused
   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480
   // 110 0011 1111  1599	       10 0000 1100  524
   assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
			!( vcount[9] | (vcount[8:5] == 4'b1111) );

   /* VGA_CLK is 25 MHz
    *             __    __    __
    * clk50    __|  |__|  |__|
    *        
    *             _____       __
    * hcount[0]__|     |_____|
    */
   assign VGA_CLK = hcount[0]; // 25 MHz clock: rising edge sensitive
   
endmodule

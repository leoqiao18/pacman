/*
 * Avalon memory-mapped peripheral that generates VGA
 *
 * Stephen A. Edwards
 * Columbia University
 *///

module vga_ball(input logic        clk,
	        input logic 	   reset,
		input logic [7:0]  writedata,
		input logic 	   write,
		input 		   chipselect,
		input logic [2:0]  address,

		output logic [7:0] VGA_R, VGA_G, VGA_B,
		output logic 	   VGA_CLK, VGA_HS, VGA_VS,
		                   VGA_BLANK_n,
		output logic 	   VGA_SYNC_n);

	logic [10:0]	   hcount;
	logic [9:0]     vcount;

	logic [3:0] out_pixel[36:0]; //output pixels values from each sprite
	logic [7:0] 	   background_r, background_g, background_b;
	logic [23:0] rgb_val; //final RGB value to display
   
   
	//for sprite attribute table 
   	logic [2:0] ra_a, wa_a; //change later
	logic we_a;
	logic [7:0] din_a;
	logic [7:0] dout_a;
	
	//for sprite generator table 
   	logic [7:0] ra_g, wa_g; //change later
	logic we_g;
	logic [7:0] din_g;
	logic [7:0] dout_g;
	
	logic [7:0] sprite_base_addr[36:0]; //36 sprites
	assign sprite_base_addr[0]=8'b0;
	
	vga_counters counters(.clk50(clk), .*);
	sprite_attr_table sat1(.clk(clk), .ra(ra_a), .wa(wa_a), .we(we_a), .din(din_a), .dout(dout_a));
	sprite_gen_table sgt1(.clk(clk), .ra(ra_g), .wa(wa_g), .we(we_g), .din(din_g), .dout(dout_g));
	color_lut cl1(.color_code(out_pixel[0]), .rgb_val(rgb_val));
	sprite_prep sp0(.clk(clk), .reset(reset), .hcount(hcount), .vcount(vcount), .VGA_BLANK_n(VGA_BLANK_n), .base_addr(sprite_base_addr[0][2:0]),
	.dout_a (dout_a), .dout_g (dout_g), .ra_a (ra_a), .ra_g(ra_g), .out_pixel(out_pixel[0]));

    always_ff @(posedge clk) begin
		 if (reset) begin
			background_r <= 8'h0;
			background_g <= 8'h0;
			background_b <= 8'h20;
		 end else if (chipselect && write) begin
		 //need to wait for values to be loaded
		   case (address)
			 3'h0 : begin //write to attr table
						we_g<=0;
						we_a<=1;
						din_a<={writedata[7:3], 3'b0}; //5 MSB bits is data in
						wa_a<=writedata[2:0]; //3 LSB is addr for data
					end
			 3'h1 : begin
						we_a<=0;
						we_g<=1;
						wa_g <= writedata ; //sprite addr. for the 8 sprite pixels
					end
			 3'h2 : begin
						we_a<=0;
						we_g<=1;
						din_g <= writedata; //8 sprite pixels
					end
		   endcase
		 end
	end
	
	always_comb begin
		{VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};
		if (VGA_BLANK_n ) begin
			if (out_pixel[0]!=4'b0) {VGA_R, VGA_G, VGA_B} = {rgb_val[23:16], rgb_val[15:8], rgb_val[7:0]};
			else  {VGA_R, VGA_G, VGA_B} = {background_r, background_g, background_b};
		end
	end
	 
endmodule

module sprite_prep (input logic clk, reset,
	input logic [10:0] hcount,
	input logic [9:0] vcount,
	input logic VGA_BLANK_n,
	input logic [2:0] base_addr, //base address in sprite attr table
	input logic [7:0] dout_a,
	input logic [7:0] dout_g,
	output logic [2:0] ra_a,
	output logic [7:0] ra_g,
	output logic [3:0] out_pixel);
	
	logic [7:0] down_counter; //8 bit wide down counter
	logic [63:0] shift_reg; //64 bit wide shift register
	logic [7:0] shift_pos; //position in shift reg to read pixel value from
	logic [7:0] sprite_offset; //which row of a given sprite to display
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
				ra_a<=base_addr+3'b1; //address of horizontal position of 1st sprite
				sprite_offset<=vcount[7:0]-dout_a; //which of 16 rows of sprite to display //e.g. vcount=11, v_pos=5 -> 11-5=6th row
			end
			READ_SPRITE_ADDR: begin //base address need right shift of 3 bits 
				ra_a<=base_addr+3'b10; //address of base address of sprite pixels in the generator table //test using 0
				down_counter<=dout_a; //copy horizontal position into down counter
			end
			READ_SPRITE_PIXELS_BASE: begin
				ra_g<={3'b0, dout_a[7:3]} + (sprite_offset<<3); //read left-most 8 pixels in gen table, 8x offset since 8 table rows needed per pixel line 
			end
			LOAD_SHIFT_REG: begin
				shift_reg<= ({56'b0, dout_g}<<(shift_reg_shift-8'h8)) | shift_reg; //store left-most 8 pixels of sprite line
				shift_reg_shift<=shift_reg_shift-8'h8; //minus 8
				ra_g<=ra_g+1; //increment gen table address by one to read upcoming pixels
			end
			COUNT_DOWN: begin
				//only down count every 2 hcounts
				if (down_counter>8'b0 && VGA_BLANK_n && !hcount[0]) down_counter<=down_counter-1;
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
            IDLE:       state_next = (hcount==11'b10100100000) ? READ_VERT_POS: IDLE; //start at 1312
            READ_VERT_POS:      state_next = READ_VERT_POS_WAIT; //extra cycle for reading vertical position in attr table
			READ_VERT_POS_WAIT:   state_next = READ_VERT_POS_WAIT2; //ra_a update needs 2 cycles for some reason
			READ_VERT_POS_WAIT2: state_next = ((vcount [7:0]>=dout_a) && (vcount[7:0]<(dout_a+8'b10000)))? READ_HORT_POS: IDLE;  //check if any part of sprite is showing (don't need last 4 LSB)
			READ_HORT_POS:       state_next = READ_HORT_POS_WAIT;  //extra cycle for mem read
			READ_HORT_POS_WAIT:  state_next = READ_SPRITE_ADDR;
			READ_SPRITE_ADDR:    state_next = READ_SPRITE_ADDR_WAIT; //extra cycle for mem read
			READ_SPRITE_ADDR_WAIT:    state_next = READ_SPRITE_PIXELS_BASE;
			READ_SPRITE_PIXELS_BASE: state_next= READ_SPRITE_PIXELS_BASE_WAIT; //extra cycle for mem read
			READ_SPRITE_PIXELS_BASE_WAIT: state_next= LOAD_SHIFT_REG; 
			LOAD_SHIFT_REG: state_next= LOAD_SHIFT_REG_WAIT; 
			LOAD_SHIFT_REG_WAIT: state_next= (shift_reg_shift==8'b0) ? SPRITES_LOADED: LOAD_SHIFT_REG; 
			
			//if new vertical line started, begin down counting
			SPRITES_LOADED: state_next= (hcount==11'b0) ? COUNT_DOWN : SPRITES_LOADED;
			COUNT_DOWN: state_next= (down_counter==8'b0) ? PREPARE_PIXELS: COUNT_DOWN;
			PREPARE_PIXELS: state_next= (shift_pos==8'b0) ? IDLE : PREPARE_PIXELS;
            default:    state_next = IDLE;
        endcase
    end
endmodule

module sprite_attr_table( //stores sprite information (x, y, name, color)
	//x and y position has to be a multiple of hcount/vcount since only 8 bits
	input logic clk,
	input logic [2:0] ra, wa, //change later
	input logic we,
	input logic [7:0] din, 
	output logic [7:0] dout);
	
	logic[7:0] mem[7:0];
	
	always_ff @(posedge clk) begin
      if (we) mem[wa] <= din;
      dout <= mem[ra];      
	end
endmodule

module sprite_gen_table( //stores 2x 16x16 sprites
	input logic clk,
	input logic [7:0] ra, wa, //change later
	input logic we,
	input logic [7:0] din,
	output logic [7:0] dout);
	
	logic[7:0] mem[255:0]; //128 8 bit words need per sprite: 64 bits per pixel row
	 
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

//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (“LICENCE”) IS A LEGAL AGREEMENT BETWEEN      //
//YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  //
//THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   //
//CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  //
//OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   //
//TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   //
//TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    //
//YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                //
//                                                                              //
//ARM hereby grants to you, subject to the terms and conditions of this Licence,//
//a non-exclusive, worldwide, non-transferable, copyright licence only to       //
//redistribute and use in source and binary forms, with or without modification,//
//for academic purposes provided the following conditions are met:              //
//a) Redistributions of source code must retain the above copyright notice, this//
//list of conditions and the following disclaimer.                              //
//b) Redistributions in binary form must reproduce the above copyright notice,  //
//this list of conditions and the following disclaimer in the documentation     //
//and/or other materials provided with the distribution.                        //
//                                                                              //
//THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     //
//EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     //
//WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR //
//PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE/
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY/
//KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE //
//FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, //
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    //
//EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE/
// OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.//
//////////////////////////////////////////////////////////////////////////////////


//module AHBGPIO(
//  input wire HCLK,
//  input wire HRESETn,
//  input wire [31:0] HADDR,
//  input wire [1:0] HTRANS,
//  input wire [31:0] HWDATA,
//  input wire HWRITE,
//  input wire HSEL,
//  input wire HREADY,
//  input wire [15:0] GPIOIN,
  
	
//	//Output
//  output wire HREADYOUT,
//  output wire [31:0] HRDATA,
//  output wire [15:0] GPIOOUT,
  
//  output wire gpio_irq
  
  
//  );
  
//  localparam [7:0] gpio_data_addr = 8'h00;
//  localparam [7:0] gpio_dir_addr = 8'h04;
//  localparam [7:0] gpio_irq_en_addr = 8'h08;
//  localparam [7:0] gpio_irq_flag_addr = 8'h0C;
  
//  reg [15:0] gpio_dataout;
//  reg [15:0] gpio_datain;
//  reg [15:0] gpio_dir;
//  reg [15:0] gpio_data_next;
//  reg [31:0] last_HADDR;
//  reg [1:0] last_HTRANS;
//  reg last_HWRITE;
//  reg last_HSEL;
//  reg [7:0] gpio_irq_en;
//  reg [7:0] gpio_irq_flag;
  
//  integer i;
  
//  assign HREADYOUT = 1'b1;
  
//  reg  [15:0] prev_pins;

//  always @(posedge HCLK) begin
//      prev_pins <= GPIOIN;    // store all 15 previous values
//  end
  
//  // Rising edge detected when pin was LOW and is now HIGH
//  wire [15:0] rising_edge  = GPIOIN & ~prev_pins;
//  // Falling edge detected when pin was HIGH and is now LOW  
//  wire [15:0] falling_edge = ~GPIOIN & prev_pins;
  
//// Set Registers from address phase  
//  always @(posedge HCLK)
//  begin
//    if(HREADY)
//    begin
//      last_HADDR <= HADDR;
//      last_HTRANS <= HTRANS;
//      last_HWRITE <= HWRITE;
//      last_HSEL <= HSEL;
//    end
//  end

//  // Update in/out switch
//  always @(posedge HCLK, negedge HRESETn)
//  begin
//    if(!HRESETn)
//    begin
//      gpio_dir <= 16'h0000;
//      gpio_irq_flag <= 1'b0;
//    end
//    else begin
//        // Set flag on rising edge if pin is input and interrupt enabled
//        if (rising_edge & ~gpio_dir_addr & gpio_irq_en)
//            gpio_irq_flag <= gpio_irq_flag | (rising_edge & ~gpio_dir_addr & gpio_irq_en);
        
//        // CPU clears flag by writing 1 to the flag register (write 1 to clear)    
//        if ((last_HADDR[7:0] == gpio_dir_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
//            gpio_dir <= HWDATA[15:0];
//            gpio_irq_flag <= gpio_irq_flag & ~HWDATA[7:0];
//    end
//  end
  
//  // Update output value
//  always @(posedge HCLK, negedge HRESETn)
//  begin
//    if(!HRESETn)
//    begin
//      gpio_dataout <= 16'h0000;
//    end
//    else if ((gpio_dir == 16'h0001) & (last_HADDR[7:0] == gpio_data_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
//      gpio_dataout <= HWDATA[15:0];
//  end
  
//  // Update input value
//  always @(posedge HCLK, negedge HRESETn)
//  begin
//    if(!HRESETn)
//    begin
//      gpio_datain <= 16'h0000;
//    end
//    else if (gpio_dir == 16'h0000)
//      gpio_datain <= GPIOIN;
//    else if (gpio_dir == 16'h0001)
//      gpio_datain <= GPIOOUT;
//  end
  
//  // Interrupt fires if any enabled flag is set
//  assign gpio_irq = |gpio_irq_flag;       
//  assign HRDATA[15:0] = gpio_datain;  
//  assign GPIOOUT = gpio_dataout;
   

//endmodule

//LED works, but not VGA
//module AHBGPIO(
//  input wire HCLK,
//  input wire HRESETn,
//  input wire [31:0] HADDR,
//  input wire [1:0] HTRANS,
//  input wire [31:0] HWDATA,
//  input wire HWRITE,
//  input wire HSEL,
//  input wire HREADY,
//  input wire [15:0] GPIOIN,
  
//  output wire HREADYOUT,
//  output wire [31:0] HRDATA,
//  output wire [15:0] GPIOOUT,
//  output wire GPIO_IRQ          // Added IRQ Output
//);
  
//  localparam [7:0] gpio_data_addr = 8'h00;
//  localparam [7:0] gpio_dir_addr  = 8'h04;
//  localparam [7:0] gpio_ie_addr   = 8'h08; // Interrupt Enable Address
//  localparam [7:0] gpio_is_addr   = 8'h0C; // Interrupt Status (Clear) Address
  
//  reg [15:0] gpio_dataout;
//  reg [15:0] gpio_dir;
//  reg [15:0] gpio_ie;           // Interrupt Enable Register
//  reg [15:0] gpio_is;           // Interrupt Status Register
  
//  reg [31:0] last_HADDR;
//  reg [1:0] last_HTRANS;
//  reg last_HWRITE;
//  reg last_HSEL;
  
//  // Edge Detection registers
//  reg [15:0] gpio_in_sync;
//  reg [15:0] gpio_in_last;
  
//  // 1. Force the Handshake to be ALWAYS ready
//  assign HREADYOUT = 1'b1;
  
//  // 2. Simplify the Write Logic
//  // Instead of using 'last_HADDR', use 'HADDR' directly for a 'Zero-Wait' write
//  //wire fast_write = HSEL && HWRITE && HTRANS[1] && HREADY;
  
  
////  always @(posedge HCLK or negedge HRESETn) begin
////    if(!HRESETn) begin
////        gpio_dataout <= 16'h0000;
////        gpio_dir     <= 16'h0000;
////    end else if (fast_write) begin
////        if (HADDR[7:0] == gpio_data_addr) gpio_dataout <= HWDATA[15:0];
////        if (HADDR[7:0] == gpio_dir_addr)  gpio_dir     <= HWDATA[15:0];
////    end
////  end
  
//  // AHB Address Phase Latch
//  always @(posedge HCLK) begin
//    if(HREADY) begin
//      last_HADDR  <= HADDR;
//      last_HTRANS <= HTRANS;
//      last_HWRITE <= HWRITE;
//      last_HSEL   <= HSEL;
//    end
//  end

//  // Register Write Logic
//  wire is_write = last_HSEL & last_HWRITE & last_HTRANS[1];
  
//  always @(posedge HCLK, negedge HRESETn) begin
//    if(!HRESETn) begin
//      gpio_dir     <= 16'h0000;
//      gpio_dataout <= 16'h0000;
//      gpio_ie      <= 16'h0000;
//    end else if (is_write) begin
//      case (last_HADDR[7:0])
//        gpio_dir_addr:  gpio_dir     <= HWDATA[15:0];
//        gpio_data_addr: gpio_dataout <= HWDATA[15:0];
//        gpio_ie_addr:   gpio_ie      <= HWDATA[15:0];
//      endcase
//    end
//  end

//  // Interrupt Status Logic (Edge Detection + W1C)
//  // 1. Synchronize input to prevent metastability
//  // 2. Detect rising edge (button press)
//  always @(posedge HCLK, negedge HRESETn) begin
//    if(!HRESETn) begin
//      gpio_in_sync <= 16'h0000;
//      gpio_in_last <= 16'h0000;
//      gpio_is      <= 16'h0000;
//    end else begin
//      gpio_in_sync <= GPIOIN;      // Simple sync
//      gpio_in_last <= gpio_in_sync;
      
//      // Edge Detection: if bit was 0 and is now 1
//      // W1C: If CPU writes a 1 to a bit in gpio_is_addr, clear that bit
//      if (is_write && (last_HADDR[7:0] == gpio_is_addr))
//        gpio_is <= (gpio_is | (gpio_in_sync & ~gpio_in_last)) & ~HWDATA[15:0];
//      else
//        gpio_is <= gpio_is | (gpio_in_sync & ~gpio_in_last);
//    end
//  end
  
//  // Read Logic
////  assign HRDATA = (last_HADDR[7:0] == gpio_is_addr)   ? {16'b0, gpio_is} :
////                  (last_HADDR[7:0] == gpio_ie_addr)   ? {16'b0, gpio_ie} :
////                  (last_HADDR[7:0] == gpio_dir_addr)  ? {16'b0, gpio_dir} :
////                  {16'b0, (GPIOIN & ~gpio_dir) | (gpio_dataout & gpio_dir)};

//// Ensure HRDATA is a combinational mux, not a registered one
//// This ensures the CPU gets data in exactly one clock cycle
//  assign HRDATA = (last_HADDR[7:0] == gpio_is_addr)  ? {16'b0, gpio_is} :
//                  (last_HADDR[7:0] == gpio_ie_addr)  ? {16'b0, gpio_ie} :
//                  (last_HADDR[7:0] == gpio_dir_addr) ? {16'b0, gpio_dir} :
//                  {16'b0, GPIOIN};

//  assign GPIOOUT = gpio_dataout;
  
//  // The Interrupt Signal
//  // High if any bit is set in status AND enabled in IE
//  assign GPIO_IRQ = |(gpio_is & gpio_ie);

//endmodule

//Commented April 23, 2026 
//module AHBGPIO(
//    input wire HCLK,
//    input wire HRESETn,
//    input wire [31:0] HADDR,
//    input wire [1:0] HTRANS,
//    input wire [31:0] HWDATA,
//    input wire HWRITE,
//    input wire HSEL,
//    input wire HREADY,
//    input wire [15:0] GPIOIN,
    
//    output wire HREADYOUT,
//    output wire [31:0] HRDATA,
//    output wire [15:0] GPIOOUT,
//    output wire GPIO_IRQ
//);
  
//    // Addresses
//    localparam [7:0] gpio_data_addr = 8'h00;
//    localparam [7:0] gpio_dir_addr  = 8'h04;
//    localparam [7:0] gpio_ie_addr   = 8'h08;
//    localparam [7:0] gpio_is_addr   = 8'h0C;
  
//    reg [15:0] gpio_dataout, gpio_dir, gpio_ie, gpio_is;
//    reg [7:0]  last_HADDR;
//    reg        last_HSEL, last_HWRITE;
//    reg [1:0]  last_HTRANS;

//    // 1. Bus Handshake (Zero Wait State for VGA stability)
//    assign HREADYOUT = 1'b1;

//    // 2. Address Phase Capture
//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn) begin
//            last_HADDR  <= 8'h0;
//            last_HSEL   <= 1'b0;
//            last_HWRITE <= 1'b0;
//            last_HTRANS <= 2'b0;
//        end else if (HREADY) begin
//            last_HADDR  <= HADDR[7:0];
//            last_HSEL   <= HSEL;
//            last_HWRITE <= HWRITE;
//            last_HTRANS <= HTRANS;
//        end
//    end

//    // 3. Write Logic (Data Phase)
//    wire write_en = last_HSEL & last_HWRITE & last_HTRANS[1];
//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn) begin
//            gpio_dataout <= 16'h0;
//            gpio_dir     <= 16'h0;
//            gpio_ie      <= 16'h0;
//        end else if (write_en) begin
//            case (last_HADDR)
//                gpio_data_addr: gpio_dataout <= HWDATA[15:0];
//                gpio_dir_addr:  gpio_dir     <= HWDATA[15:0];
//                gpio_ie_addr:   gpio_ie      <= HWDATA[15:0];
//            endcase
//        end
//    end

//    // 4. Interrupt Logic (Edge Detection + W1C)
//    reg [15:0] gpio_in_sync, gpio_in_last;
//    wire [15:0] edge_detected = (gpio_in_sync & ~gpio_in_last);

//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn) begin
//            gpio_in_sync <= 16'h0;
//            gpio_in_last <= 16'h0;
//            gpio_is      <= 16'h0;
//        end else begin
//            gpio_in_sync <= GPIOIN;
//            gpio_in_last <= gpio_in_sync;
            
//            if (write_en && (last_HADDR == gpio_is_addr))
//                gpio_is <= (gpio_is | edge_detected) & ~HWDATA[15:0]; // Clear bits written with 1
//            else
//                //gpio_is <= gpio_is | edge_detected;
//                gpio_is <= gpio_is | GPIOIN[7:0];
//        end
//    end

//    // 5. Read Logic (Combinational for Zero Latency)
//    assign HRDATA = (last_HADDR == gpio_data_addr) ? {16'b0, (GPIOIN & ~gpio_dir) | (gpio_dataout & gpio_dir)} :
//                    (last_HADDR == gpio_dir_addr)  ? {16'b0, gpio_dir} :
//                    (last_HADDR == gpio_ie_addr)   ? {16'b0, gpio_ie} :
//                    (last_HADDR == gpio_is_addr)   ? {16'b0, gpio_is} : 32'h0;

//    assign GPIOOUT  = gpio_dataout;
//    assign GPIO_IRQ = |(gpio_is & gpio_ie);

//endmodule

//Cannot connect gpio to output
//module AHBGPIO(
//    input wire HCLK,
//    input wire HRESETn,
//    input wire [31:0] HADDR,
//    input wire [1:0] HTRANS,
//    input wire [31:0] HWDATA,
//    input wire HWRITE,
//    input wire HSEL,
//    input wire HREADY,
//    input wire [15:0] GPIOIN,
    
//    output wire HREADYOUT,
//    output wire [31:0] HRDATA,
//    output wire [15:0] GPIOOUT,
    
//    output wire GPIO_IRQ
//);
  
//    // Addresses
//    localparam [7:0] gpio_data_addr = 8'h00;
//    localparam [7:0] gpio_dir_addr  = 8'h04;
//    localparam [3:0] CLRADDR = 4'hc;
  
//    reg [15:0] gpio_dataout;
//    reg [15:0] gpio_datain;
//    reg [15:0] gpio_dir;
//    reg [15:0] gpio_data_next;
//    reg [31:0] last_HADDR;
//    reg [1:0] last_HTRANS;
//    reg last_HWRITE;
//    reg last_HSEL;
    
//    //added
//    reg gpio_irq;
//    reg previous_switch;   //stores last switch value
//    reg clear;             //clear signal from software
//    reg gpio_irq_next;     //next interrupt value
    
//    integer i;
    


//    // 1. Bus Handshake (Zero Wait State for VGA stability)
//    assign HREADYOUT = 1'b1;

//    // Set Registers from address phase  
//    always @(posedge HCLK)
//    begin
//      if(HREADY)
//      begin
//        last_HADDR <= HADDR;
//        last_HTRANS <= HTRANS;
//        last_HWRITE <= HWRITE;
//        last_HSEL <= HSEL;
//      end
//    end

//    // Update in/out switch
//    always @(posedge HCLK, negedge HRESETn)
//    begin
//      if(!HRESETn)
//      begin
//        gpio_dir <= 16'h0000;
//      end
//      else if ((last_HADDR[7:0] == gpio_dir_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
//        gpio_dir <= HWDATA[15:0];
//    end
    
//    // Update output value
//    always @(posedge HCLK, negedge HRESETn)
//    begin
//      if(!HRESETn)
//      begin
//        gpio_dataout <= 16'h0000;
//      end
//      else if ((gpio_dir == 16'h0001) & (last_HADDR[7:0] == gpio_data_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
//        gpio_dataout <= HWDATA[15:0];
//    end
      
//      // Update input value
//    always @(posedge HCLK, negedge HRESETn)
//    begin
//      if(!HRESETn)
//      begin
//        gpio_datain <= 16'h0000;
//      end
//      else if (gpio_dir == 16'h0000)
//        gpio_datain <= GPIOIN;
//      else if (gpio_dir == 16'h0001)
//        gpio_datain <= GPIOOUT;
//    end

//        //added
//        //stores interrupt and previous switch value each clock
//     always @(posedge HCLK or negedge HRESETn) begin
//         if (!HRESETn) begin
//             previous_switch <= 1'b0;   //reset previous switch
//             gpio_irq        <= 1'b0;   //reset interrupt
//         end
//         else begin
//             previous_switch <= gpio_datain[0]; //track switch each cycle
//             gpio_irq        <= gpio_irq_next;  //update interrupt
//         end
//     end

//     always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn) begin
//            previous_switch <= 1'b0;
//            gpio_irq        <= 1'b0;
//        end else begin
//            previous_switch <= gpio_datain[0];
            
//            if (clear)
//                gpio_irq <= 1'b0;                                    // CPU cleared it
//            else if (gpio_datain[0] & ~previous_switch & ~gpio_dir[0])  // rising edge on input pin
//                gpio_irq <= 1'b1;                                    // set interrupt
//        end
//    end

//     //added
//     //clear interrupt register (written by software)
//     always @(posedge HCLK or negedge HRESETn)
//     begin
//         if(!HRESETn)
//             clear <= 1'b0;
//         else if (last_HWRITE & last_HSEL & last_HTRANS[1] & (last_HADDR[3:0] == CLRADDR))
//            clear <= HWDATA[0];
//        else
//            clear <= 1'b0;   // auto clear after one cycle
//     end

//     assign HRDATA[15:0] = gpio_datain;  
//     assign GPIOOUT = gpio_dataout;
//     assign GPIO_IRQ = gpio_irq_next;

//endmodule

//Commented on April 28_2026
//Made with some help from people
//module AHBGPIO(
//    input wire         HCLK,
//    input wire         HRESETn,
//    input wire  [31:0] HADDR,
//    input wire  [1:0]  HTRANS,
//    input wire  [31:0] HWDATA,
//    input wire         HWRITE,
//    input wire         HSEL,
//    input wire         HREADY,
//    input wire  [15:0] GPIOIN,
    
//    output wire        HREADYOUT,
//    output wire [31:0] HRDATA,
//    output wire [15:0] GPIOOUT,
//    output wire        GPIO_IRQ
//);
  
//    // Addresses
//    localparam [7:0] gpio_data_addr = 8'h00;
//    localparam [7:0] gpio_dir_addr  = 8'h04;
//    localparam [3:0] CLRADDR        = 4'hc;
  
//    reg [15:0] gpio_dataout;
//    reg [15:0] gpio_datain;
//    reg [15:0] gpio_dir;
//    reg [31:0] last_HADDR;
//    reg [1:0]  last_HTRANS;
//    reg        last_HWRITE;
//    reg        last_HSEL;
    
//    // Interrupt signals
//    reg        gpio_irq;          // interrupt flag
//    reg        previous_switch;   // stores last switch value
//    reg        clear;             // clear signal from software

//    // -------------------------------------------------------
//    // Bus handshake - zero wait state
//    // -------------------------------------------------------
//    assign HREADYOUT = 1'b1;

//    // -------------------------------------------------------
//    // Latch AHB address phase signals
//    // -------------------------------------------------------
//    always @(posedge HCLK) begin
//        if (HREADY) begin
//            last_HADDR  <= HADDR;
//            last_HTRANS <= HTRANS;
//            last_HWRITE <= HWRITE;
//            last_HSEL   <= HSEL;
//        end
//    end

//    // -------------------------------------------------------
//    // Direction register
//    // -------------------------------------------------------
//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            gpio_dir <= 16'h0000;
//        else if ((last_HADDR[7:0] == gpio_dir_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
//            gpio_dir <= HWDATA[15:0];
//    end

//    // -------------------------------------------------------
//    // Output data register - only written when pin is output
//    // -------------------------------------------------------
//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            gpio_dataout <= 16'h0000;
//        else if ((gpio_dir == 16'h0001) & (last_HADDR[7:0] == gpio_data_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
//            gpio_dataout <= HWDATA[15:0];
//    end

//    // -------------------------------------------------------
//    // Input data register
//    // -------------------------------------------------------
//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            gpio_datain <= 16'h0000;
//        else if (gpio_dir == 16'h0000)
//            gpio_datain <= GPIOIN;
//        else if (gpio_dir == 16'h0001)
//            gpio_datain <= GPIOOUT;
//    end

//    // -------------------------------------------------------
//    // Clear register - auto resets after one cycle so the
//    // interrupt can fire again after being cleared
//    // -------------------------------------------------------
//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            clear <= 1'b0;
//        else if (last_HWRITE & last_HSEL & last_HTRANS[1] & (last_HADDR[3:0] == CLRADDR))
//            clear <= HWDATA[0];
//        else
//            clear <= 1'b0;   // auto clear after one cycle
//    end

//    // -------------------------------------------------------
//    // Interrupt flag register
//    // Fires on rising edge of switch when pin is input
//    // Cleared by CPU writing 1 to CLRADDR
//    // -------------------------------------------------------
//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn) begin
//            previous_switch <= 1'b0;
//            gpio_irq        <= 1'b0;
//        end else begin
//            // Always track previous switch state
//            previous_switch <= gpio_datain[0];

//            if (clear)
//                // CPU cleared the interrupt
//                gpio_irq <= 1'b0;
//            else if (gpio_datain[0] & ~previous_switch & ~gpio_dir[0])
//                // Rising edge on pin 0 while configured as input
//                gpio_irq <= 1'b1;
//        end
//    end

//    // -------------------------------------------------------
//    // AHB read
//    // -------------------------------------------------------
//    assign HRDATA[15:0]  = gpio_datain;
//    assign HRDATA[31:16] = 16'h0000;

//    // -------------------------------------------------------
//    // Outputs
//    // -------------------------------------------------------
//    assign GPIOOUT  = gpio_dataout;
//    assign GPIO_IRQ = gpio_irq;     // fixed case to match port declaration

//endmodule

//works, but can only stop counter
//module AHBGPIO(
//    input wire         HCLK,
//    input wire         HRESETn,
//    input wire  [31:0] HADDR,
//    input wire  [1:0]  HTRANS,
//    input wire  [31:0] HWDATA,
//    input wire         HWRITE,
//    input wire         HSEL,
//    input wire         HREADY,
//    input wire  [15:0] GPIOIN,

//    output wire        HREADYOUT,
//    output wire [31:0] HRDATA,
//    output wire [15:0] GPIOOUT,
//    output wire        GPIO_IRQ
//);

//    localparam [7:0] gpio_data_addr = 8'h00;
//    localparam [7:0] gpio_dir_addr  = 8'h04;
//    localparam [3:0] CLRADDR        = 4'hc;

//    reg [15:0] gpio_dataout;
//    reg [15:0] gpio_datain;
//    reg [15:0] gpio_dir;
//    reg [31:0] last_HADDR;
//    reg [1:0]  last_HTRANS;
//    reg        last_HWRITE;
//    reg        last_HSEL;

//    reg        gpio_irq;
//    reg        previous_switch;
//    reg        clear;

//    assign HREADYOUT = 1'b1;

//    always @(posedge HCLK) begin
//        if (HREADY) begin
//            last_HADDR  <= HADDR;
//            last_HTRANS <= HTRANS;
//            last_HWRITE <= HWRITE;
//            last_HSEL   <= HSEL;
//        end
//    end

//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            gpio_dir <= 16'h0000;
//        else if ((last_HADDR[7:0] == gpio_dir_addr) && last_HSEL && last_HWRITE && last_HTRANS[1])
//            gpio_dir <= HWDATA[15:0];
//    end

//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            gpio_dataout <= 16'h0000;
//        else if (gpio_dir[0] && (last_HADDR[7:0] == gpio_data_addr) && last_HSEL && last_HWRITE && last_HTRANS[1])
//            gpio_dataout <= HWDATA[15:0];
//    end

//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            gpio_datain <= 16'h0000;
//        else if (gpio_dir[0] == 1'b0)
//            gpio_datain <= GPIOIN;
//        else
//            gpio_datain <= GPIOOUT;
//    end

//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn)
//            clear <= 1'b0;
//        else if (last_HWRITE && last_HSEL && last_HTRANS[1] && (last_HADDR[3:0] == CLRADDR))
//            clear <= HWDATA[0];
//        else
//            clear <= 1'b0;
//    end

//    always @(posedge HCLK or negedge HRESETn) begin
//        if (!HRESETn) begin
//            previous_switch <= 1'b0;
//            gpio_irq        <= 1'b0;
//        end else begin
//            previous_switch <= gpio_datain[0];

//            if (clear)
//                gpio_irq <= 1'b0;
//            else if (gpio_datain[0] && !previous_switch && !gpio_dir[0])
//                gpio_irq <= 1'b1;
//        end
//    end

//    assign HRDATA[15:0]  = gpio_datain;
//    assign HRDATA[31:16] = 16'h0000;

//    assign GPIOOUT  = gpio_dataout;
//    assign GPIO_IRQ = gpio_irq;

//endmodule

//resume counter after stopped
module AHBGPIO(
    input wire         HCLK,
    input wire         HRESETn,
    input wire  [31:0] HADDR,
    input wire  [1:0]  HTRANS,
    input wire  [31:0] HWDATA,
    input wire         HWRITE,
    input wire         HSEL,
    input wire         HREADY,
    input wire  [15:0] GPIOIN,

    output wire        HREADYOUT,
    output wire [31:0] HRDATA,
    output wire [15:0] GPIOOUT,
    output wire        GPIO_IRQ
);

    // Addresses
    localparam [7:0] GPIO_DATA_ADDR = 8'h00;
    localparam [7:0] GPIO_DIR_ADDR  = 8'h04;
    localparam [3:0] CLRADDR        = 4'hC;

    reg [15:0] gpio_dataout;
    reg [15:0] gpio_datain;
    reg [15:0] gpio_dir;

    reg [31:0] last_HADDR;
    reg [1:0]  last_HTRANS;
    reg        last_HWRITE;
    reg        last_HSEL;

    // Interrupt signals
    reg gpio_irq;
    reg previous_switch;
    reg clear;

    // -------------------------------------------------------
    // Bus handshake - zero wait state
    // -------------------------------------------------------
    assign HREADYOUT = 1'b1;

    // -------------------------------------------------------
    // Latch AHB address phase signals
    // -------------------------------------------------------
    always @(posedge HCLK) begin
        if (HREADY) begin
            last_HADDR  <= HADDR;
            last_HTRANS <= HTRANS;
            last_HWRITE <= HWRITE;
            last_HSEL   <= HSEL;
        end
    end

    // -------------------------------------------------------
    // Direction register
    // 0 = input, 1 = output
    // -------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            gpio_dir <= 16'h0000;
        else if ((last_HADDR[7:0] == GPIO_DIR_ADDR) && last_HSEL && last_HWRITE && last_HTRANS[1])
            gpio_dir <= HWDATA[15:0];
    end

    // -------------------------------------------------------
    // Output data register
    // -------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            gpio_dataout <= 16'h0000;
        else if ((last_HADDR[7:0] == GPIO_DATA_ADDR) && last_HSEL && last_HWRITE && last_HTRANS[1] && gpio_dir[0])
            gpio_dataout <= HWDATA[15:0];
    end

    // -------------------------------------------------------
    // Input data register
    // -------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            gpio_datain <= 16'h0000;
        else if (!gpio_dir[0])
            gpio_datain <= GPIOIN;
        else
            gpio_datain <= GPIOOUT;
    end

    // -------------------------------------------------------
    // Clear register
    // CPU writes 1 to clear interrupt
    // -------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            clear <= 1'b0;
        else if (last_HWRITE && last_HSEL && last_HTRANS[1] && (last_HADDR[3:0] == CLRADDR))
            clear <= HWDATA[0];
        else
            clear <= 1'b0;
    end

    // -------------------------------------------------------
    // Interrupt flag register
    // Trigger on either edge of GPIOIN[0] when pin 0 is input
    // -------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            previous_switch <= 1'b0;
            gpio_irq        <= 1'b0;
        end
        else begin
            previous_switch <= gpio_datain[0];

            if (clear)
                gpio_irq <= 1'b0;
            else if ((gpio_datain[0] ^ previous_switch) && !gpio_dir[0])
                gpio_irq <= 1'b1;
        end
    end

    // -------------------------------------------------------
    // AHB read
    // -------------------------------------------------------
    assign HRDATA[15:0]  = gpio_datain;
    assign HRDATA[31:16] = 16'h0000;

    // -------------------------------------------------------
    // Outputs
    // -------------------------------------------------------
    assign GPIOOUT  = gpio_dataout;
    assign GPIO_IRQ = gpio_irq;

endmodule

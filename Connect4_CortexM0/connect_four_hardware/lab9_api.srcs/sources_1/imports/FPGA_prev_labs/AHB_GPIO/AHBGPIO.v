//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (�LICENCE�) IS A LEGAL AGREEMENT BETWEEN      //
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

    reg        gpio_irq;
    reg [15:0] previous_switch;
    reg        clear;

    assign HREADYOUT = 1'b1;

    // Latch AHB address phase signals
    always @(posedge HCLK) begin
        if (HREADY) begin
            last_HADDR  <= HADDR;
            last_HTRANS <= HTRANS;
            last_HWRITE <= HWRITE;
            last_HSEL   <= HSEL;
        end
    end

    // Direction register
    // 0 = input, 1 = output
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            gpio_dir <= 16'h0000;
        else if ((last_HADDR[7:0] == GPIO_DIR_ADDR) &&
                 last_HSEL && last_HWRITE && last_HTRANS[1])
            gpio_dir <= HWDATA[15:0];
    end

    // Output data register
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            gpio_dataout <= 16'h0000;
        else if ((last_HADDR[7:0] == GPIO_DATA_ADDR) &&
                 last_HSEL && last_HWRITE && last_HTRANS[1])
            gpio_dataout <= HWDATA[15:0];
    end

    // Input data register
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            gpio_datain <= 16'h0000;
        else
            gpio_datain <= (GPIOIN & ~gpio_dir) | (gpio_dataout & gpio_dir);
    end

    // Clear register
    // CPU writes 1 to offset 0x0C to clear GPIO interrupt
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            clear <= 1'b0;
        else if (last_HWRITE && last_HSEL && last_HTRANS[1] &&
                 (last_HADDR[3:0] == CLRADDR))
            clear <= HWDATA[0];
        else
            clear <= 1'b0;
    end

    // -------------------------------------------------------
    // GPIO interrupt logic
    //
    // previous_switch stores the previous GPIO input value.
    // The expression:
    //
    //   gpio_datain[7:0] & ~previous_switch[7:0]
    //
    // detects rising edges on SW0-SW7. This means an interrupt
    // is generated only when a switch changes from 0 to 1.
    //
    // gpio_dir[7:0] == 0 ensures the pins are configured as inputs.
    // The interrupt remains asserted until software clears it by
    // writing 1 to the clear register at offset 0x0C.
    // -------------------------------------------------------
    // Interrupt flag register
    // Generates interrupt on rising edge of GPIOIN[7:0]
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            previous_switch <= 16'h0000;
            gpio_irq        <= 1'b0;
        end
        else begin
            previous_switch <= gpio_datain;

            if (clear)
                gpio_irq <= 1'b0;
           else if (((gpio_datain[7:0] & ~previous_switch[7:0]) != 8'b00000000) &&
                     (gpio_dir[7:0] == 8'b00000000))
                gpio_irq <= 1'b1;
        end
    end

    // AHB read
    assign HRDATA = (last_HADDR[7:0] == GPIO_DIR_ADDR)  ? {16'h0000, gpio_dir} :
                    (last_HADDR[7:0] == GPIO_DATA_ADDR) ? {16'h0000, gpio_datain} :
                    32'h00000000;

    assign GPIOOUT  = gpio_dataout & gpio_dir;
    assign GPIO_IRQ = gpio_irq;

endmodule





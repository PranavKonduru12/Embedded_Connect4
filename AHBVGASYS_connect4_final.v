module AHBVGA(
  input  wire        HCLK,
  input  wire        HRESETn,
  input  wire [31:0] HADDR,
  input  wire [31:0] HWDATA,
  input  wire        HREADY,
  input  wire        HWRITE,
  input  wire [1:0]  HTRANS,
  input  wire        HSEL,

  output wire [31:0] HRDATA,
  output wire        HREADYOUT,

  output wire        hsync,
  output wire        vsync,
  output wire [7:0]  rgb
);

  reg        last_HWRITE;
  reg        last_HSEL;
  reg [1:0]  last_HTRANS;
  reg [31:0] last_HADDR;

  wire [7:0] console_rgb;
  wire [7:0] image_rgb;
  wire [9:0] pixel_x;
  wire [9:0] pixel_y;
  wire       scroll;

  reg        console_write;
  reg [7:0]  console_wdata;
  reg        image_write;
  reg [7:0]  image_wdata;
  reg [7:0]  cin;

  // address == 0 goes to text console, everything else to Connect Four renderer
  wire sel_console;
  wire sel_image;

  always @(posedge HCLK) begin
    if (HREADY) begin
      last_HADDR  <= HADDR;
      last_HWRITE <= HWRITE;
      last_HSEL   <= HSEL;
      last_HTRANS <= HTRANS;
    end
  end

  assign sel_console = (last_HADDR[15:2] == 16'h0000);
  assign sel_image   = ~sel_console;

  assign HREADYOUT = ~scroll;
  assign HRDATA    = 32'h0000_0000;

  VGAInterface uVGAInterface (
    .CLK(HCLK),
    .COLOUR_IN(cin),
    .cout(rgb),
    .hs(hsync),
    .vs(vsync),
    .addrh(pixel_x),
    .addrv(pixel_y)
  );

  vga_console uvga_console(
    .clk(HCLK),
    .resetn(HRESETn),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .font_we(console_write),
    .font_data(console_wdata),
    .text_rgb(console_rgb),
    .scroll(scroll)
  );

  vga_image uvga_image(
    .clk(HCLK),
    .resetn(HRESETn),
    .address(last_HADDR[15:2]),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .image_we(image_write),
    .image_data(image_wdata),
    .image_rgb(image_rgb)
  );

  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      console_write <= 1'b0;
      console_wdata <= 8'h00;
      image_write   <= 1'b0;
      image_wdata   <= 8'h00;
    end else begin
      console_write <= 1'b0;
      image_write   <= 1'b0;
      console_wdata <= 8'h00;
      image_wdata   <= 8'h00;

      if (last_HWRITE && last_HSEL && last_HTRANS[1] && HREADYOUT) begin
        if (sel_console) begin
          console_write <= 1'b1;
          console_wdata <= HWDATA[7:0];
        end else begin
          image_write <= 1'b1;
          image_wdata <= HWDATA[7:0];
        end
      end
    end
  end

  always @(*) begin
    if (!HRESETn)
      cin = 8'h00;
    else if (pixel_x < 10'd240)
      cin = console_rgb;
    else
      cin = image_rgb;
  end

endmodule

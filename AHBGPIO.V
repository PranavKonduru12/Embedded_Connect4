module AHBGPIO(
  input  wire        HCLK,
  input  wire        HRESETn,
  input  wire [31:0] HADDR,
  input  wire [1:0]  HTRANS,
  input  wire [31:0] HWDATA,
  input  wire        HWRITE,
  input  wire        HSEL,
  input  wire        HREADY,
  input  wire [15:0] GPIOIN,

  output wire        HREADYOUT,
  output wire [31:0] HRDATA,
  output wire [15:0] GPIOOUT
);

  localparam [7:0] GPIO_DATA_ADDR = 8'h00;
  localparam [7:0] GPIO_DIR_ADDR  = 8'h04;

  reg [15:0] gpio_dataout;
  reg [15:0] gpio_dir;

  reg [31:0] last_HADDR;
  reg [1:0]  last_HTRANS;
  reg        last_HWRITE;
  reg        last_HSEL;

  wire write_en;
  wire read_en;
  wire [15:0] gpio_read_data;

  always @(posedge HCLK) begin
    if (HREADY) begin
      last_HADDR  <= HADDR;
      last_HTRANS <= HTRANS;
      last_HWRITE <= HWRITE;
      last_HSEL   <= HSEL;
    end
  end

  assign write_en = last_HSEL && last_HWRITE && last_HTRANS[1];
  assign read_en  = last_HSEL && !last_HWRITE && last_HTRANS[1];

  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      gpio_dir     <= 16'h0000;
      gpio_dataout <= 16'h0000;
    end else if (write_en) begin
      case (last_HADDR[7:0])
        GPIO_DIR_ADDR:  gpio_dir     <= HWDATA[15:0];
        GPIO_DATA_ADDR: gpio_dataout <= HWDATA[15:0];
        default: begin end
      endcase
    end
  end

  assign GPIOOUT = gpio_dataout & gpio_dir;
  assign gpio_read_data = (GPIOIN & ~gpio_dir) | (gpio_dataout & gpio_dir);

  assign HRDATA    = (read_en && (last_HADDR[7:0] == GPIO_DIR_ADDR))  ? {16'h0000, gpio_dir} :
                     (read_en && (last_HADDR[7:0] == GPIO_DATA_ADDR)) ? {16'h0000, gpio_read_data} :
                     32'h0000_0000;
  assign HREADYOUT = 1'b1;

endmodule

module vga_image(
  input  wire        clk,
  input  wire        resetn,
  input  wire [9:0]  pixel_x,
  input  wire [9:0]  pixel_y,
  input  wire        image_we,
  input  wire [7:0]  image_data,
  input  wire [15:0] address,
  output reg  [7:0]  image_rgb
);

  // --------------------------------------------------------------------------
  // Connect Four renderer register map (byte writes, address = HADDR[15:2])
  // 0x000C..0x0016 : 11 bytes, board cells packed 4 cells/byte, 2 bits/cell
  // 0x0017         : control
  //                  [2:0] selected column
  //                  [4:3] current player (1=red, 2=yellow)
  //                  [5]   game_over
  //                  [7:6] winner (0 none, 1 red, 2 yellow)
  // 0x0018         : color/theme
  //                  [2:0] board color
  //                  [5:3] background color
  // --------------------------------------------------------------------------

  localparam [15:0] BOARD_BASE_ADDR = 16'h000C;
  localparam [15:0] CTRL_ADDR       = 16'h0017;
  localparam [15:0] THEME_ADDR      = 16'h0018;

  localparam integer BOARD_COLS = 7;
  localparam integer BOARD_ROWS = 6;
  localparam integer CELL_W     = 56;
  localparam integer CELL_H     = 56;
  localparam integer BOARD_W    = BOARD_COLS * CELL_W;
  localparam integer BOARD_H    = BOARD_ROWS * CELL_H;
  localparam integer BOARD_X    = 4;
  localparam integer BOARD_Y    = 60;
  localparam integer DISC_R     = 20;
  localparam integer CURSOR_Y   = 24;
  localparam integer CURSOR_R   = 14;

  reg [1:0] board [0:BOARD_ROWS-1][0:BOARD_COLS-1];
  reg [2:0] selected_col;
  reg [1:0] current_player;
  reg       game_over;
  reg [1:0] winner;
  reg [2:0] board_color_sel;
  reg [2:0] bg_color_sel;

  integer r;
  integer c;
  integer packed_index;
  integer cell_index;
  integer row_idx;
  integer col_idx;

  reg [9:0] local_x;
  reg [9:0] local_y;
  reg [9:0] cell_x;
  reg [9:0] cell_y;
  reg [9:0] disc_cx;
  reg [9:0] disc_cy;
  reg signed [11:0] dx;
  reg signed [11:0] dy;
  reg [23:0] dist2;
  reg inside_disc;
  reg inside_cursor_disc;
  reg inside_board_rect;
  reg on_grid_line;
  reg [2:0] pix_col;
  reg [2:0] pix_row;
  reg [1:0] cell_state;
  reg [7:0] bg_rgb;
  reg [7:0] board_rgb;
  reg [7:0] piece_rgb;
  reg [7:0] cursor_rgb;
  reg [7:0] grid_rgb;
  reg [7:0] empty_hole_rgb;

  function [7:0] color_lut;
    input [2:0] idx;
    begin
      case (idx)
        3'd0: color_lut = 8'h00; // black
        3'd1: color_lut = 8'h03; // blue
        3'd2: color_lut = 8'h1C; // green
        3'd3: color_lut = 8'hE0; // red
        3'd4: color_lut = 8'hFC; // yellow
        3'd5: color_lut = 8'h1F; // cyan
        3'd6: color_lut = 8'hE3; // magenta
        default: color_lut = 8'hFF; // white
      endcase
    end
  endfunction

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      for (r = 0; r < BOARD_ROWS; r = r + 1) begin
        for (c = 0; c < BOARD_COLS; c = c + 1) begin
          board[r][c] <= 2'b00;
        end
      end
      selected_col    <= 3'd0;
      current_player  <= 2'd1;
      game_over       <= 1'b0;
      winner          <= 2'd0;
      board_color_sel <= 3'd1;
      bg_color_sel    <= 3'd0;
    end else if (image_we) begin
      if ((address >= BOARD_BASE_ADDR) && (address < BOARD_BASE_ADDR + 16'd11)) begin
        packed_index = address - BOARD_BASE_ADDR;
        for (c = 0; c < 4; c = c + 1) begin
          cell_index = packed_index * 4 + c;
          if (cell_index < (BOARD_ROWS * BOARD_COLS)) begin
            row_idx = cell_index / BOARD_COLS;
            col_idx = cell_index % BOARD_COLS;
            board[row_idx][col_idx] <= image_data[c*2 +: 2];
          end
        end
      end else if (address == CTRL_ADDR) begin
        selected_col   <= (image_data[2:0] < BOARD_COLS) ? image_data[2:0] : 3'd0;
        current_player <= image_data[4:3];
        game_over      <= image_data[5];
        winner         <= image_data[7:6];
      end else if (address == THEME_ADDR) begin
        board_color_sel <= image_data[2:0];
        bg_color_sel    <= image_data[5:3];
      end
    end
  end

  always @(*) begin
    bg_rgb         = color_lut(bg_color_sel);
    board_rgb      = color_lut(board_color_sel);
    grid_rgb       = 8'hFF;
    empty_hole_rgb = 8'h00;
    cursor_rgb     = (current_player == 2'd2) ? 8'hFC : 8'hE0;

    image_rgb          = bg_rgb;
    inside_board_rect  = (pixel_x >= BOARD_X) && (pixel_x < BOARD_X + BOARD_W) &&
                         (pixel_y >= BOARD_Y) && (pixel_y < BOARD_Y + BOARD_H);
    inside_cursor_disc = 1'b0;
    inside_disc        = 1'b0;
    on_grid_line       = 1'b0;
    pix_col            = 3'd0;
    pix_row            = 3'd0;
    cell_state         = 2'b00;

    // Cursor disc above the selected column
    if ((pixel_y >= (CURSOR_Y - CURSOR_R)) && (pixel_y <= (CURSOR_Y + CURSOR_R))) begin
      disc_cx = BOARD_X + (selected_col * CELL_W) + (CELL_W >> 1);
      disc_cy = CURSOR_Y;
      dx = $signed({1'b0, pixel_x}) - $signed({1'b0, disc_cx});
      dy = $signed({1'b0, pixel_y}) - $signed({1'b0, disc_cy});
      dist2 = (dx * dx) + (dy * dy);
      inside_cursor_disc = (dist2 <= (CURSOR_R * CURSOR_R));
    end

    if (inside_cursor_disc)
      image_rgb = cursor_rgb;

    if (inside_board_rect) begin
      local_x = pixel_x - BOARD_X;
      local_y = pixel_y - BOARD_Y;
      pix_col = local_x / CELL_W;
      pix_row = local_y / CELL_H;
      cell_x  = BOARD_X + pix_col * CELL_W;
      cell_y  = BOARD_Y + pix_row * CELL_H;
      disc_cx = cell_x + (CELL_W >> 1);
      disc_cy = cell_y + (CELL_H >> 1);

      dx = $signed({1'b0, pixel_x}) - $signed({1'b0, disc_cx});
      dy = $signed({1'b0, pixel_y}) - $signed({1'b0, disc_cy});
      dist2 = (dx * dx) + (dy * dy);
      inside_disc = (dist2 <= (DISC_R * DISC_R));

      on_grid_line = (local_x % CELL_W == 0) || (local_y % CELL_H == 0) ||
                     (local_x % CELL_W == 1) || (local_y % CELL_H == 1);

      cell_state = board[pix_row][pix_col];

      if (cell_state == 2'd1)
        piece_rgb = 8'hE0;
      else if (cell_state == 2'd2)
        piece_rgb = 8'hFC;
      else
        piece_rgb = empty_hole_rgb;

      image_rgb = board_rgb;
      if (on_grid_line)
        image_rgb = grid_rgb;
      if (inside_disc)
        image_rgb = (cell_state == 2'd0) ? empty_hole_rgb : piece_rgb;
    end

    // Simple winner bar near the bottom of the image region
    if (game_over && pixel_y >= 430 && pixel_y < 460) begin
      if (winner == 2'd1)
        image_rgb = 8'hE0;
      else if (winner == 2'd2)
        image_rgb = 8'hFC;
      else
        image_rgb = 8'hFF;
    end
  end

endmodule

module vga_image(
    input  wire        clk,
    input  wire        resetn,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        image_we,
    input  wire [7:0]  image_data,
    input  wire [15:0] address,
    output wire [7:0]  image_rgb
);

    localparam integer ROWS   = 6;
    localparam integer COLS   = 7;

    localparam integer BOARD_X = 280;
    localparam integer BOARD_Y = 40;
    localparam integer CELL_W  = 40;
    localparam integer CELL_H  = 40;
    localparam integer DISC_R  = 14;

    localparam integer BOARD_W = COLS * CELL_W;
    localparam integer BOARD_H = ROWS * CELL_H;

    reg [7:0] board_bytes [0:10];
    reg [7:0] ctrl_reg;
    reg [7:0] theme_reg;

    integer i;

    wire [2:0] sel_col      = ctrl_reg[2:0];
    wire [1:0] current_player = ctrl_reg[4:3];
    wire       game_over    = ctrl_reg[5];
    wire [1:0] winner       = ctrl_reg[7:6];

    wire [2:0] board_color_sel = theme_reg[2:0];
    wire [2:0] bg_color_sel    = theme_reg[5:3];

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < 11; i = i + 1)
                board_bytes[i] <= 8'h00;
            ctrl_reg  <= 8'h00;
            theme_reg <= 8'h01;
        end else if (image_we) begin
            case (address)
                16'd12: board_bytes[0]  <= image_data;
                16'd13: board_bytes[1]  <= image_data;
                16'd14: board_bytes[2]  <= image_data;
                16'd15: board_bytes[3]  <= image_data;
                16'd16: board_bytes[4]  <= image_data;
                16'd17: board_bytes[5]  <= image_data;
                16'd18: board_bytes[6]  <= image_data;
                16'd19: board_bytes[7]  <= image_data;
                16'd20: board_bytes[8]  <= image_data;
                16'd21: board_bytes[9]  <= image_data;
                16'd22: board_bytes[10] <= image_data;
                16'd23: ctrl_reg        <= image_data;
                16'd24: theme_reg       <= image_data;
                default: ;
            endcase
        end
    end

    function [1:0] get_cell;
        input integer row;
        input integer col;
        integer idx;
        integer byte_idx;
        integer bit_idx;
        reg [7:0] b;
        begin
            idx      = row * COLS + col;
            byte_idx = idx >> 2;
            bit_idx  = (idx & 3) * 2;
            b        = board_bytes[byte_idx];
            get_cell = (b >> bit_idx) & 2'b11;
        end
    endfunction

    function [7:0] rgb332;
        input [2:0] csel;
        begin
            case (csel)
                3'd0: rgb332 = 8'b000_000_00;
                3'd1: rgb332 = 8'b000_000_11;
                3'd2: rgb332 = 8'b111_000_00;
                3'd3: rgb332 = 8'b111_111_00;
                3'd4: rgb332 = 8'b000_111_00;
                3'd5: rgb332 = 8'b000_111_11;
                3'd6: rgb332 = 8'b111_111_11;
                3'd7: rgb332 = 8'b100_100_10;
                default: rgb332 = 8'b000_000_00;
            endcase
        end
    endfunction

    reg [7:0] rgb_r;

    integer rel_x;
    integer rel_y;
    integer col;
    integer row;
    integer local_x;
    integer local_y;
    integer dx;
    integer dy;
    integer dx2dy2;
    integer cursor_center_x;
    integer cursor_center_y;
    integer cdx;
    integer cdy;
    integer cdist2;
    reg [1:0] cell_state;
    reg inside_board;
    reg inside_disc;
    reg inside_cursor;

    reg [7:0] bg_rgb;
    reg [7:0] board_rgb;
    reg [7:0] hole_rgb;
    reg [7:0] p1_rgb;
    reg [7:0] p2_rgb;
    reg [7:0] cursor_rgb;
    reg [7:0] win_rgb;

    always @(*) begin
        bg_rgb     = rgb332(bg_color_sel);
        board_rgb  = rgb332(board_color_sel);
        hole_rgb   = 8'b000_000_01;
        p1_rgb     = 8'b111_000_00;
        p2_rgb     = 8'b111_111_00;
        cursor_rgb = (current_player == 2'b10) ? p2_rgb : p1_rgb;
        win_rgb    = 8'b111_111_11;

        rgb_r = bg_rgb;

        rel_x = pixel_x - BOARD_X;
        rel_y = pixel_y - BOARD_Y;

        inside_board = (pixel_x >= BOARD_X) && (pixel_x < (BOARD_X + BOARD_W)) &&
                       (pixel_y >= BOARD_Y) && (pixel_y < (BOARD_Y + BOARD_H));

        inside_disc   = 1'b0;
        inside_cursor = 1'b0;
        cell_state    = 2'b00;

        if (inside_board) begin
            col = rel_x / CELL_W;
            row = rel_y / CELL_H;

            if ((col >= 0) && (col < COLS) && (row >= 0) && (row < ROWS)) begin
                local_x = rel_x % CELL_W;
                local_y = rel_y % CELL_H;

                dx = local_x - (CELL_W/2);
                dy = local_y - (CELL_H/2);
                dx2dy2 = dx*dx + dy*dy;
                inside_disc = (dx2dy2 <= (DISC_R*DISC_R));

                cell_state = get_cell(row, col);

                rgb_r = board_rgb;

                if (inside_disc) begin
                    case (cell_state)
                        2'b00: rgb_r = hole_rgb;
                        2'b01: rgb_r = p1_rgb;
                        2'b10: rgb_r = p2_rgb;
                        default: rgb_r = hole_rgb;
                    endcase
                end

                if ((local_x == 0) || (local_y == 0))
                    rgb_r = 8'b111_111_11;
            end
        end

        if ((pixel_y >= (BOARD_Y - 24)) && (pixel_y < (BOARD_Y - 4))) begin
            if ((pixel_x >= BOARD_X) && (pixel_x < (BOARD_X + BOARD_W))) begin
                cursor_center_x = BOARD_X + sel_col*CELL_W + (CELL_W/2);
                cursor_center_y = BOARD_Y - 14;
                cdx = pixel_x - cursor_center_x;
                cdy = pixel_y - cursor_center_y;
                cdist2 = cdx*cdx + cdy*cdy;
                inside_cursor = (cdist2 <= (DISC_R*DISC_R));
                if (inside_cursor)
                    rgb_r = cursor_rgb;
            end
        end

        if (game_over) begin
            if ((pixel_y >= (BOARD_Y + BOARD_H + 8)) && (pixel_y < (BOARD_Y + BOARD_H + 16))) begin
                if (winner != 2'b00)
                    rgb_r = win_rgb;
            end
        end
    end

    assign image_rgb = rgb_r;

endmodule

`timescale 1ns / 1ps

module axi4_lite_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter ARRAY_ROWS = 20
) (
    input  wire                    aclk,
    input  wire                    aresetn,

    input  wire [ADDR_WIDTH-1:0]   s_awaddr,
    input  wire [2:0]              s_awprot,
    input  wire                    s_awvalid,
    output wire                    s_awready,
    input  wire [DATA_WIDTH-1:0]   s_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_wstrb,
    input  wire                    s_wvalid,
    output wire                    s_wready,
    output wire [1:0]              s_bresp,
    output wire                    s_bvalid,
    input  wire                    s_bready,

    input  wire [ADDR_WIDTH-1:0]   s_araddr,
    input  wire [2:0]              s_arprot,
    input  wire                    s_arvalid,
    output wire                    s_arready,
    output reg  [DATA_WIDTH-1:0]   s_rdata,
    output wire [1:0]              s_rresp,
    output reg                     s_rvalid,
    input  wire                    s_rready,

    // Control Outputs
    output wire                    csr_start,
    output wire                    csr_soft_reset,
    output wire                    csr_layer_type,
    output wire                    csr_cosine_sim_mode,
    output wire                    csr_wgt_bank_sel,
    output wire [31:0]             csr_weight_base,
    output wire [31:0]             csr_act_base,
    output wire [31:0]             csr_out_base,
    output wire [7:0]              csr_kernel_size,
    output wire [7:0]              csr_stride,
    output wire [7:0]              csr_padding,
    output wire [1:0]              csr_act_sel,
    output wire [15:0]             csr_in_channels,
    output wire [15:0]             csr_out_channels,
    output wire [15:0]             csr_input_width,
    output wire [15:0]             csr_input_height,
    output wire                    csr_irq_en,
    output wire [31:0]             csr_m0,
    output wire [31:0]             csr_n_shift,
    output wire [31:0]             csr_bias,
    output wire [7:0]              csr_conf_threshold,
    output wire [15:0]             csr_crop_x,
    output wire [15:0]             csr_crop_y,
    output wire [15:0]             csr_crop_w,
    output wire [15:0]             csr_crop_h,
    output wire [1:0]              csr_stride_sel,
    output wire [2:0]              csr_act_ext,
    output wire [1:0]              csr_pool_mode,
    output wire [4:0]              csr_array_rows,
    output wire [1:0]              csr_input_fmt,
    output wire [15:0]             csr_frame_w,
    output wire [15:0]             csr_frame_h,
    output wire [15:0]             csr_num_tiles_x,
    output wire [15:0]             csr_num_tiles_y,

    // Status / Profiling Inputs
    input  wire                    status_idle,
    input  wire                    status_busy,
    input  wire                    status_done,
    input  wire                    status_error,
    input  wire [63:0]             perf_cycle_count,
    input  wire [63:0]             perf_compute_count,
    input  wire [31:0]             perf_dma_stall_count,
    input  wire [31:0]             perf_out_stall_count,
    input  wire                    vid_locked,
    input  wire [31:0]             tile_count
);

    // Memory-Mapped Register Addresses
    localparam ADDR_CTRL            = 8'h00;
    localparam ADDR_STATUS          = 8'h04;
    localparam ADDR_WEIGHT_BASE     = 8'h08;
    localparam ADDR_ACT_BASE        = 8'h0C;
    localparam ADDR_OUT_BASE        = 8'h10;
    localparam ADDR_LAYER_CFG_0     = 8'h14;
    localparam ADDR_LAYER_CFG_1     = 8'h18;
    localparam ADDR_LAYER_CFG_2     = 8'h1C;
    localparam ADDR_PERF_CYCLE_LO   = 8'h20;
    localparam ADDR_PERF_CYCLE_HI   = 8'h24;
    localparam ADDR_IRQ_CTRL        = 8'h28;
    localparam ADDR_M0_CFG          = 8'h2C;
    localparam ADDR_SHIFT_CFG       = 8'h30;
    localparam ADDR_BIAS_CFG        = 8'h34;
    localparam ADDR_PERF_COMPUTE_LO = 8'h38;
    localparam ADDR_PERF_COMPUTE_HI = 8'h3C;
    localparam ADDR_PERF_DMA_STALL  = 8'h40;
    localparam ADDR_PERF_OUT_STALL  = 8'h44;
    localparam ADDR_CONF_THRESHOLD  = 8'h48;
    localparam ADDR_CROP_XY         = 8'h4C;
    localparam ADDR_CROP_WH         = 8'h50;

    localparam ADDR_STRIDE_SEL      = 8'h54;
    localparam ADDR_ACT_EXT         = 8'h58;
    localparam ADDR_POOL_MODE       = 8'h5C;
    localparam ADDR_ARRAY_ROWS      = 8'h60;
    localparam ADDR_INPUT_FMT       = 8'h64;
    localparam ADDR_FRAME_W         = 8'h68;
    localparam ADDR_FRAME_H         = 8'h6C;
    localparam ADDR_NUM_TILES       = 8'h70;
    localparam ADDR_VID_LOCKED      = 8'h74;
    localparam ADDR_TILE_COUNT      = 8'h78;
    localparam ADDR_VERSION         = 8'hF8;
    localparam ADDR_FEATURE_FLAGS   = 8'hFC;

    // Registers
    reg [31:0] reg_ctrl;
    reg [31:0] reg_weight_base;
    reg [31:0] reg_act_base;
    reg [31:0] reg_out_base;
    reg [31:0] reg_layer_cfg0;
    reg [31:0] reg_layer_cfg1;
    reg [31:0] reg_layer_cfg2;
    reg [31:0] reg_irq_ctrl;
    reg [31:0] reg_m0;
    reg [31:0] reg_n_shift;
    reg [31:0] reg_bias;
    reg [31:0] reg_conf_threshold;
    reg [31:0] reg_crop_xy;
    reg [31:0] reg_crop_wh;
    reg [31:0] reg_stride_sel;
    reg [31:0] reg_act_ext;
    reg [31:0] reg_pool_mode;
    reg [31:0] reg_input_fmt;
    reg [31:0] reg_frame_w;
    reg [31:0] reg_frame_h;
    reg [31:0] reg_num_tiles;

    // =========================================================================
    // AXI4-Lite Handshake Registers
    // =========================================================================
    reg [ADDR_WIDTH-1:0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg [ADDR_WIDTH-1:0] axi_araddr;
    reg axi_arready;
    reg [1:0] axi_rresp;

    assign s_awready = axi_awready;
    assign s_wready  = axi_wready;
    assign s_bresp   = axi_bresp;
    assign s_bvalid  = axi_bvalid;
    assign s_arready = axi_arready;
    assign s_rresp   = axi_rresp;

    // AWREADY and AWADDR
    always @(posedge aclk) begin
        if (!aresetn) begin
            axi_awready <= 1'b0;
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && s_awvalid && s_wvalid) begin
                axi_awready <= 1'b1;
                axi_awaddr  <= s_awaddr;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // WREADY
    always @(posedge aclk) begin
        if (!aresetn) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && s_wvalid && s_awvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // BVALID and BRESP
    always @(posedge aclk) begin
        if (!aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;
        end else begin
            if (axi_awready && s_awvalid && ~axi_bvalid && axi_wready && s_wvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00;
            end else if (s_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // ARREADY and ARADDR
    always @(posedge aclk) begin
        if (!aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else begin
            if (~axi_arready && s_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr  <= s_araddr;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    wire slv_reg_wren = axi_wready && s_wvalid && axi_awready && s_awvalid;
    wire slv_reg_rden = axi_arready & s_arvalid & ~s_rvalid;
    
    wire [ADDR_WIDTH-1:0] wr_addr = axi_awaddr;

    integer b;

    // =========================================================================
    // CSR Write Logic
    // =========================================================================
    always @(posedge aclk) begin
        if (!aresetn) begin
            reg_ctrl           <= 32'd0;
            reg_weight_base    <= 32'd0;
            reg_act_base       <= 32'd0;
            reg_out_base       <= 32'd0;
            reg_layer_cfg0     <= 32'd0;
            reg_layer_cfg1     <= 32'd0;
            reg_layer_cfg2     <= 32'd0;
            reg_irq_ctrl       <= 32'd0;
            reg_m0             <= 32'd0;
            reg_n_shift        <= 32'd0;
            reg_bias           <= 32'd0;
            reg_conf_threshold <= 32'd0;
            reg_crop_xy        <= 32'd0;
            reg_crop_wh        <= 32'd0;
            reg_stride_sel     <= 32'd0;
            reg_act_ext        <= 32'd0;
            reg_pool_mode      <= 32'd0;
            reg_input_fmt      <= 32'd0;
            reg_frame_w        <= 16'd1280;
            reg_frame_h        <= 16'd720;
            reg_num_tiles      <= 32'd0;
        end else begin
            reg_ctrl[0] <= 1'b0;
            reg_ctrl[1] <= 1'b0;

            if (slv_reg_wren) begin
                for (b = 0; b < DATA_WIDTH/8; b = b + 1) begin
                    if (s_wstrb[b]) begin
                        case (wr_addr[7:0])
                            ADDR_CTRL:           reg_ctrl[b*8 +: 8]           <= s_wdata[b*8 +: 8];
                            ADDR_WEIGHT_BASE:    reg_weight_base[b*8 +: 8]    <= s_wdata[b*8 +: 8];
                            ADDR_ACT_BASE:       reg_act_base[b*8 +: 8]       <= s_wdata[b*8 +: 8];
                            ADDR_OUT_BASE:       reg_out_base[b*8 +: 8]       <= s_wdata[b*8 +: 8];
                            ADDR_LAYER_CFG_0:    reg_layer_cfg0[b*8 +: 8]     <= s_wdata[b*8 +: 8];
                            ADDR_LAYER_CFG_1:    reg_layer_cfg1[b*8 +: 8]     <= s_wdata[b*8 +: 8];
                            ADDR_LAYER_CFG_2:    reg_layer_cfg2[b*8 +: 8]     <= s_wdata[b*8 +: 8];
                            ADDR_IRQ_CTRL:       reg_irq_ctrl[b*8 +: 8]       <= s_wdata[b*8 +: 8];
                            ADDR_M0_CFG:         reg_m0[b*8 +: 8]             <= s_wdata[b*8 +: 8];
                            ADDR_SHIFT_CFG:      reg_n_shift[b*8 +: 8]        <= s_wdata[b*8 +: 8];
                            ADDR_BIAS_CFG:       reg_bias[b*8 +: 8]           <= s_wdata[b*8 +: 8];
                            ADDR_CONF_THRESHOLD: reg_conf_threshold[b*8 +: 8] <= s_wdata[b*8 +: 8];
                            ADDR_CROP_XY:        reg_crop_xy[b*8 +: 8]        <= s_wdata[b*8 +: 8];
                            ADDR_CROP_WH:        reg_crop_wh[b*8 +: 8]        <= s_wdata[b*8 +: 8];
                            ADDR_STRIDE_SEL:     reg_stride_sel[b*8 +: 8]     <= s_wdata[b*8 +: 8];
                            ADDR_ACT_EXT:        reg_act_ext[b*8 +: 8]        <= s_wdata[b*8 +: 8];
                            ADDR_POOL_MODE:      reg_pool_mode[b*8 +: 8]      <= s_wdata[b*8 +: 8];
                            // ADDR_ARRAY_ROWS is read-only
                            ADDR_INPUT_FMT:      reg_input_fmt[b*8 +: 8]      <= s_wdata[b*8 +: 8];
                            ADDR_FRAME_W:        reg_frame_w[b*8 +: 8]        <= s_wdata[b*8 +: 8];
                            ADDR_FRAME_H:        reg_frame_h[b*8 +: 8]        <= s_wdata[b*8 +: 8];
                            ADDR_NUM_TILES:      reg_num_tiles[b*8 +: 8]      <= s_wdata[b*8 +: 8];
                            default: ;
                        endcase
                    end
                end
            end
        end
    end

    // =========================================================================
    // CSR Read Logic
    // =========================================================================
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_rvalid <= 1'b0;
            axi_rresp <= 2'b00;
        end else begin
            if (slv_reg_rden) begin
                s_rvalid <= 1'b1;
                axi_rresp <= 2'b00;
            end else if (s_rvalid && s_rready) begin
                s_rvalid <= 1'b0;
            end
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            s_rdata <= 0;
        end else begin
            if (slv_reg_rden) begin
                case (axi_araddr[7:0])
                    ADDR_CTRL:            s_rdata <= reg_ctrl;
                    ADDR_STATUS:          s_rdata <= {28'b0, status_error, status_done, status_busy, status_idle};
                    ADDR_WEIGHT_BASE:     s_rdata <= reg_weight_base;
                    ADDR_ACT_BASE:        s_rdata <= reg_act_base;
                    ADDR_OUT_BASE:        s_rdata <= reg_out_base;
                    ADDR_LAYER_CFG_0:     s_rdata <= reg_layer_cfg0;
                    ADDR_LAYER_CFG_1:     s_rdata <= reg_layer_cfg1;
                    ADDR_LAYER_CFG_2:     s_rdata <= reg_layer_cfg2;
                    ADDR_PERF_CYCLE_LO:   s_rdata <= perf_cycle_count[31:0];
                    ADDR_PERF_CYCLE_HI:   s_rdata <= perf_cycle_count[63:32];
                    ADDR_IRQ_CTRL:        s_rdata <= reg_irq_ctrl;
                    ADDR_M0_CFG:          s_rdata <= reg_m0;
                    ADDR_SHIFT_CFG:       s_rdata <= reg_n_shift;
                    ADDR_BIAS_CFG:        s_rdata <= reg_bias;
                    ADDR_PERF_COMPUTE_LO: s_rdata <= perf_compute_count[31:0];
                    ADDR_PERF_COMPUTE_HI: s_rdata <= perf_compute_count[63:32];
                    ADDR_PERF_DMA_STALL:  s_rdata <= perf_dma_stall_count;
                    ADDR_PERF_OUT_STALL:  s_rdata <= perf_out_stall_count;
                    ADDR_CONF_THRESHOLD:  s_rdata <= reg_conf_threshold;
                    ADDR_CROP_XY:         s_rdata <= reg_crop_xy;
                    ADDR_CROP_WH:         s_rdata <= reg_crop_wh;
                    ADDR_STRIDE_SEL:      s_rdata <= reg_stride_sel;
                    ADDR_ACT_EXT:         s_rdata <= reg_act_ext;
                    ADDR_POOL_MODE:       s_rdata <= reg_pool_mode;
                    ADDR_ARRAY_ROWS:      s_rdata <= ARRAY_ROWS;
                    ADDR_INPUT_FMT:       s_rdata <= reg_input_fmt;
                    ADDR_FRAME_W:         s_rdata <= reg_frame_w;
                    ADDR_FRAME_H:         s_rdata <= reg_frame_h;
                    ADDR_NUM_TILES:       s_rdata <= reg_num_tiles;
                    ADDR_VID_LOCKED:      s_rdata <= {31'b0, vid_locked};
                    ADDR_TILE_COUNT:      s_rdata <= tile_count;
                    ADDR_VERSION:         s_rdata <= 32'h02000001; // TinyNPU v2.0.1
                    ADDR_FEATURE_FLAGS:   s_rdata <= 32'h0000007F; // capability bitmask
                    default:              s_rdata <= 32'hDEADBEEF;
                endcase
            end
        end
    end

    // =========================================================================
    // Output Mapping
    // =========================================================================
    assign csr_start           = reg_ctrl[0];
    assign csr_soft_reset      = reg_ctrl[1];
    assign csr_layer_type      = reg_ctrl[2];
    assign csr_cosine_sim_mode = reg_ctrl[3];
    assign csr_wgt_bank_sel    = reg_ctrl[4];

    assign csr_weight_base     = reg_weight_base;
    assign csr_act_base        = reg_act_base;
    assign csr_out_base        = reg_out_base;

    assign csr_kernel_size     = reg_layer_cfg0[7:0];
    assign csr_stride          = reg_layer_cfg0[15:8];
    assign csr_padding         = reg_layer_cfg0[23:16];
    assign csr_act_sel         = reg_layer_cfg0[25:24];

    assign csr_in_channels     = reg_layer_cfg1[15:0];
    assign csr_out_channels    = reg_layer_cfg1[31:16];

    assign csr_input_width     = reg_layer_cfg2[15:0];
    assign csr_input_height    = reg_layer_cfg2[31:16];

    assign csr_irq_en          = reg_irq_ctrl[0];
    assign csr_m0              = reg_m0;
    assign csr_n_shift         = reg_n_shift;
    assign csr_bias            = reg_bias;

    assign csr_conf_threshold  = reg_conf_threshold[7:0];
    assign csr_crop_x          = reg_crop_xy[15:0];
    assign csr_crop_y          = reg_crop_xy[31:16];
    assign csr_crop_w          = reg_crop_wh[15:0];
    assign csr_crop_h          = reg_crop_wh[31:16];

    assign csr_stride_sel      = reg_stride_sel[1:0];
    assign csr_act_ext         = reg_act_ext[2:0];
    assign csr_pool_mode       = reg_pool_mode[1:0];
    assign csr_array_rows      = ARRAY_ROWS[4:0];
    assign csr_input_fmt       = reg_input_fmt[1:0];
    assign csr_frame_w         = reg_frame_w[15:0];
    assign csr_frame_h         = reg_frame_h[15:0];
    assign csr_num_tiles_x     = reg_num_tiles[15:0];
    assign csr_num_tiles_y     = reg_num_tiles[31:16];

endmodule

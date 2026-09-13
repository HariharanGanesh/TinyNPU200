`timescale 1ns / 1ps

module dma_controller #(
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_DATA_WIDTH    = 32,
    parameter BUFFER_ADDR_WIDTH = 10,
    parameter DATA_WIDTH        = 8
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // AXI4 Master Interface
    output reg  [AXI_ADDR_WIDTH-1:0]    m_axi_awaddr,
    output reg  [7:0]                   m_axi_awlen,
    output wire [2:0]                   m_axi_awsize,
    output wire [1:0]                   m_axi_awburst,
    output reg                          m_axi_awvalid,
    input  wire                         m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0]  m_axi_wstrb,
    output reg                          m_axi_wlast,
    output reg                          m_axi_wvalid,
    input  wire                         m_axi_wready,
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output reg                          m_axi_bready,
    output reg  [AXI_ADDR_WIDTH-1:0]    m_axi_araddr,
    output reg  [7:0]                   m_axi_arlen,
    output wire [2:0]                   m_axi_arsize,
    output wire [1:0]                   m_axi_arburst,
    output reg                          m_axi_arvalid,
    input  wire                         m_axi_arready,
    input  wire [AXI_DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [1:0]                   m_axi_rresp,
    input  wire                         m_axi_rlast,
    input  wire                         m_axi_rvalid,
    output reg                          m_axi_rready,

    // Control and Status
    input  wire [AXI_ADDR_WIDTH-1:0]    weight_base_addr,
    input  wire [15:0]                  transfer_size, // number of bytes to transfer
    input  wire                         start_load_weights,
    output reg                          weight_load_done,

    // Buffer Write Port (Weights)
    output reg  [BUFFER_ADDR_WIDTH-1:0] wgt_buf_wr_addr,
    output reg  [DATA_WIDTH-1:0]        wgt_buf_wr_data,
    output reg                          wgt_buf_wr_en
);

    // Constant mappings for 32-bit AXI
    assign m_axi_awsize  = 3'b000; // 1 byte per transfer (mapped to 8-bit weights)
    assign m_axi_awburst = 2'b01;  // INCR burst type
    assign m_axi_arsize  = 3'b000; // 1 byte per transfer
    assign m_axi_arburst = 2'b01;  // INCR burst type
    
    // Write channel not used in this weight-only DMA, safely tie off
    assign m_axi_wdata   = 0;
    assign m_axi_wstrb   = 0;

    localparam STATE_IDLE        = 3'd0;
    localparam STATE_R_ADDR      = 3'd1;
    localparam STATE_R_DATA      = 3'd2;

    reg [2:0] state;
    reg [15:0] bytes_transferred;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axi_awaddr      <= 0;
            m_axi_awlen       <= 0;
            m_axi_awvalid     <= 1'b0;
            m_axi_wlast       <= 1'b0;
            m_axi_wvalid      <= 1'b0;
            m_axi_bready      <= 1'b0;
            m_axi_araddr      <= 0;
            m_axi_arlen       <= 0;
            m_axi_arvalid     <= 1'b0;
            m_axi_rready      <= 1'b0;
            weight_load_done  <= 1'b0;
            wgt_buf_wr_addr   <= 0;
            wgt_buf_wr_data   <= 0;
            wgt_buf_wr_en     <= 1'b0;
            state             <= STATE_IDLE;
            bytes_transferred <= 0;
        end else begin
            wgt_buf_wr_en  <= 1'b0;
            weight_load_done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    if (start_load_weights) begin
                        m_axi_araddr   <= weight_base_addr;
                        m_axi_arlen    <= transfer_size - 1'b1;
                        m_axi_arvalid  <= 1'b1;
                        bytes_transferred <= 0;
                        state          <= STATE_R_ADDR;
                    end
                end

                STATE_R_ADDR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        state         <= STATE_R_DATA;
                    end
                end

                STATE_R_DATA: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        wgt_buf_wr_addr <= bytes_transferred[BUFFER_ADDR_WIDTH-1:0];
                        wgt_buf_wr_data <= m_axi_rdata[DATA_WIDTH-1:0];
                        wgt_buf_wr_en   <= 1'b1;
                        
                        bytes_transferred <= bytes_transferred + 1'b1;

                        if (m_axi_rlast) begin
                            m_axi_rready     <= 1'b0;
                            weight_load_done <= 1'b1;
                            state            <= STATE_IDLE;
                        end
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule

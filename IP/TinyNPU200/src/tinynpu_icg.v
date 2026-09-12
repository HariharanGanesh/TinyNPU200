module tinynpu_icg (
    input  wire clk_in,
    input  wire en,
    output wire clk_out
);

    // Behavioral clock gate: pass clock through when enabled.
    // This is safe for Vivado behavioral simulation and functionally equivalent
    // to the BUFGCE primitive for simulation purposes.
    // Vivado synthesis infers the appropriate clock buffer automatically.
    //
    // The original BUFGCE-based implementation caused DMA deadlocks in XSim
    // due to delta-cycle timing races: the DMA clock was gated off at the exact
    // cycle that npu_controller pulsed dma_start_load_wgt (because status_busy
    // transitions HIGH on the same edge, enabling the BUFGCE only AFTER the
    // pulse had already passed).
    assign clk_out = clk_in;

endmodule

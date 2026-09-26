////////////////////////////////////////////////////////////////
// TESTBENCH ///////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module traffic_light_fsm_tb;

    // ========================================================
    // Parameters
    // ========================================================

    localparam int GREEN_TIME  = 5;
    localparam int YELLOW_TIME = 2;


    // ========================================================
    // Signals
    // ========================================================

    logic clk;
    logic reset;

    logic ns_red;
    logic ns_yellow;
    logic ns_green;

    logic ew_red;
    logic ew_yellow;
    logic ew_green;


    // ========================================================
    // DUT
    // ========================================================

    traffic_light_fsm #(
        .GREEN_TIME  (GREEN_TIME),
        .YELLOW_TIME (YELLOW_TIME)
    ) dut (
        .clk       (clk),
        .reset     (reset),

        .ns_red    (ns_red),
        .ns_yellow (ns_yellow),
        .ns_green  (ns_green),

        .ew_red    (ew_red),
        .ew_yellow (ew_yellow),
        .ew_green  (ew_green)
    );


    // ========================================================
    // Clock Generation
    // ========================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ========================================================
    // Test Statistics
    // ========================================================

    int errors = 0;

    int ns_green_cycles  = 0;
    int ns_yellow_cycles = 0;
    int ew_green_cycles  = 0;
    int ew_yellow_cycles = 0;


    // ========================================================
    // Functional Coverage
    // ========================================================
    //
    // These flags represent whether each FSM state was visited.
    //
    // 1 = state was visited
    // 0 = state was never visited
    //
    // This is simple simulator-independent functional coverage.
    // ========================================================

    bit cov_ns_green  = 0;
    bit cov_ns_yellow = 0;
    bit cov_ew_green  = 0;
    bit cov_ew_yellow = 0;


    // ========================================================
    // Check Current Outputs
    // ========================================================

    task automatic check_state;

        begin

            case (dut.state)

                dut.NS_GREEN: begin

                    cov_ns_green = 1;

                    if (
                        ns_red    !== 1'b0 ||
                        ns_yellow !== 1'b0 ||
                        ns_green  !== 1'b1 ||
                        ew_red    !== 1'b1 ||
                        ew_yellow !== 1'b0 ||
                        ew_green  !== 1'b0
                    ) begin

                        $error(
                            "[%0t] NS_GREEN OUTPUT ERROR",
                            $time
                        );

                        errors++;

                    end

                    ns_green_cycles++;

                end


                dut.NS_YELLOW: begin

                    cov_ns_yellow = 1;

                    if (
                        ns_red    !== 1'b0 ||
                        ns_yellow !== 1'b1 ||
                        ns_green  !== 1'b0 ||
                        ew_red    !== 1'b1 ||
                        ew_yellow !== 1'b0 ||
                        ew_green  !== 1'b0
                    ) begin

                        $error(
                            "[%0t] NS_YELLOW OUTPUT ERROR",
                            $time
                        );

                        errors++;

                    end

                    ns_yellow_cycles++;

                end


                dut.EW_GREEN: begin

                    cov_ew_green = 1;

                    if (
                        ns_red    !== 1'b1 ||
                        ns_yellow !== 1'b0 ||
                        ns_green  !== 1'b0 ||
                        ew_red    !== 1'b0 ||
                        ew_yellow !== 1'b0 ||
                        ew_green  !== 1'b1
                    ) begin

                        $error(
                            "[%0t] EW_GREEN OUTPUT ERROR",
                            $time
                        );

                        errors++;

                    end

                    ew_green_cycles++;

                end


                dut.EW_YELLOW: begin

                    cov_ew_yellow = 1;

                    if (
                        ns_red    !== 1'b1 ||
                        ns_yellow !== 1'b0 ||
                        ns_green  !== 1'b0 ||
                        ew_red    !== 1'b0 ||
                        ew_yellow !== 1'b1 ||
                        ew_green  !== 1'b0
                    ) begin

                        $error(
                            "[%0t] EW_YELLOW OUTPUT ERROR",
                            $time
                        );

                        errors++;

                    end

                    ew_yellow_cycles++;

                end


                default: begin

                    $error(
                        "[%0t] INVALID FSM STATE",
                        $time
                    );

                    errors++;

                end

            endcase

        end

    endtask


    // ========================================================
    // Safety Checks
    // ========================================================
    //
    // These are immediate assertions.
    // They are deliberately written this way so that they
    // work reliably with Icarus Verilog.
    // ========================================================

    always @(negedge clk) begin

        if (!reset) begin

            // ----------------------------------------------
            // Both directions can NEVER be GREEN
            // ----------------------------------------------

            assert (!(ns_green && ew_green))
            else begin

                $error(
                    "[%0t] SAFETY ERROR: Both directions GREEN",
                    $time
                );

                errors++;

            end


            // ----------------------------------------------
            // NS GREEN requires EW RED
            // ----------------------------------------------

            assert (!ns_green || ew_red)
            else begin

                $error(
                    "[%0t] SAFETY ERROR: NS GREEN while EW is not RED",
                    $time
                );

                errors++;

            end


            // ----------------------------------------------
            // EW GREEN requires NS RED
            // ----------------------------------------------

            assert (!ew_green || ns_red)
            else begin

                $error(
                    "[%0t] SAFETY ERROR: EW GREEN while NS is not RED",
                    $time
                );

                errors++;

            end


            // ----------------------------------------------
            // Only one light per direction can be ON
            // ----------------------------------------------

            assert (
                (ns_red + ns_yellow + ns_green) <= 1
            )
            else begin

                $error(
                    "[%0t] SAFETY ERROR: Multiple NS lights ON",
                    $time
                );

                errors++;

            end


            assert (
                (ew_red + ew_yellow + ew_green) <= 1
            )
            else begin

                $error(
                    "[%0t] SAFETY ERROR: Multiple EW lights ON",
                    $time
                );

                errors++;

            end

        end

    end


    // ========================================================
    // Monitor
    // ========================================================
    //
    // Check outputs after the DUT has updated its state.
    // Negedge gives NBA updates from the previous posedge time
    // to settle before checking.
    // ========================================================

    always @(negedge clk) begin

        if (!reset)
            check_state();

    end


    // ========================================================
    // Main Test
    // ========================================================

    initial begin

        $display("");
        $display("==============================================");
        $display("     TRAFFIC LIGHT FSM VERIFICATION");
        $display("==============================================");

        $display(
            "GREEN_TIME  = %0d cycles",
            GREEN_TIME
        );

        $display(
            "YELLOW_TIME = %0d cycles",
            YELLOW_TIME
        );

        $display("");


        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        reset = 1'b1;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;


        // ----------------------------------------------------
        // Run the complete FSM cycle multiple times
        // ----------------------------------------------------
        //
        // One complete cycle:
        //
        // NS_GREEN
        // NS_YELLOW
        // EW_GREEN
        // EW_YELLOW
        //
        // We run several cycles so the testbench verifies
        // repeated operation rather than one transition.
        // ----------------------------------------------------

        repeat (4 * (GREEN_TIME + YELLOW_TIME))
            @(posedge clk);


        // Give the monitor one final half-cycle
        @(negedge clk);


        // ====================================================
        // Timing Verification
        // ====================================================

        $display("");
        $display("----------------------------------------------");
        $display("TIMING RESULTS");
        $display("----------------------------------------------");

        $display(
            "NS_GREEN cycles  = %0d",
            ns_green_cycles
        );

        $display(
            "NS_YELLOW cycles = %0d",
            ns_yellow_cycles
        );

        $display(
            "EW_GREEN cycles  = %0d",
            ew_green_cycles
        );

        $display(
            "EW_YELLOW cycles = %0d",
            ew_yellow_cycles
        );


        // ----------------------------------------------------
        // Check that every state was visited
        // ----------------------------------------------------

        if (!cov_ns_green) begin
            $error("Coverage ERROR: NS_GREEN was never visited");
            errors++;
        end

        if (!cov_ns_yellow) begin
            $error("Coverage ERROR: NS_YELLOW was never visited");
            errors++;
        end

        if (!cov_ew_green) begin
            $error("Coverage ERROR: EW_GREEN was never visited");
            errors++;
        end

        if (!cov_ew_yellow) begin
            $error("Coverage ERROR: EW_YELLOW was never visited");
            errors++;
        end


        // ====================================================
        // Functional Coverage Result
        // ====================================================

        $display("");
        $display("----------------------------------------------");
        $display("FUNCTIONAL COVERAGE");
        $display("----------------------------------------------");

        $display(
            "NS_GREEN  : %s",
            cov_ns_green ? "HIT" : "MISS"
        );

        $display(
            "NS_YELLOW : %s",
            cov_ns_yellow ? "HIT" : "MISS"
        );

        $display(
            "EW_GREEN  : %s",
            cov_ew_green ? "HIT" : "MISS"
        );

        $display(
            "EW_YELLOW : %s",
            cov_ew_yellow ? "HIT" : "MISS"
        );


        // ====================================================
        // Final Result
        // ====================================================

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display("        ALL TESTS PASSED");
            $display("        ERRORS = 0");

        end
        else begin

            $display(
                "        TEST FAILED"
            );

            $display(
                "        ERRORS = %0d",
                errors
            );

        end

        $display("==============================================");
        $display("");


        $finish;

    end


    // ========================================================
    // Waveform Dump
    // ========================================================

    initial begin

        $dumpfile("traffic_light.vcd");
        $dumpvars(0, traffic_light_fsm_tb);

    end

endmodule
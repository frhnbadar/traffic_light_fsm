////////////////////////////////////////////////////////////////
// DESIGN //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
module traffic_light_fsm #(
    parameter int GREEN_TIME  = 10,
    parameter int YELLOW_TIME = 3
)(
    input  logic clk,
    input  logic reset,

    output logic ns_red,
    output logic ns_yellow,
    output logic ns_green,

    output logic ew_red,
    output logic ew_yellow,
    output logic ew_green
);

    typedef enum logic [1:0] {
        NS_GREEN,
        NS_YELLOW,
        EW_GREEN,
        EW_YELLOW
    } state_t;

    state_t state, next_state;

    logic [$clog2(GREEN_TIME+1)-1:0] counter;

    // State register + counter
    always_ff @(posedge clk) begin
        if (reset) begin
            state   <= NS_GREEN;
            counter <= '0;
        end
        else begin
            state <= next_state;

            if (state != next_state)
                counter <= '0;
            else
                counter <= counter + 1'b1;
        end
    end


    // Next-state logic
    always_comb begin

        next_state = state;

        case (state)

            NS_GREEN: begin
                if (counter == GREEN_TIME-1)
                    next_state = NS_YELLOW;
            end

            NS_YELLOW: begin
                if (counter == YELLOW_TIME-1)
                    next_state = EW_GREEN;
            end

            EW_GREEN: begin
                if (counter == GREEN_TIME-1)
                    next_state = EW_YELLOW;
            end

            EW_YELLOW: begin
                if (counter == YELLOW_TIME-1)
                    next_state = NS_GREEN;
            end

            default:
                next_state = NS_GREEN;

        endcase
    end


    // Output logic
    always_comb begin

        // Default: everything RED
        ns_red    = 1'b1;
        ns_yellow = 1'b0;
        ns_green  = 1'b0;

        ew_red    = 1'b1;
        ew_yellow = 1'b0;
        ew_green  = 1'b0;

        case (state)

            NS_GREEN: begin
                ns_red   = 1'b0;
                ns_green = 1'b1;
            end

            NS_YELLOW: begin
                ns_red    = 1'b0;
                ns_yellow = 1'b1;
            end

            EW_GREEN: begin
                ew_red   = 1'b0;
                ew_green = 1'b1;
            end

            EW_YELLOW: begin
                ew_red    = 1'b0;
                ew_yellow = 1'b1;
            end

            default: begin
                // Safe state: everything RED
            end

        endcase

    end

endmodule
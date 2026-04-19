module WASHING_MACHINE_CONTROLLER (
    input wire clk,           // clock 
    input wire rst_n,         // reset 
    input wire door_closed,   // Door closed SW0
    input wire water_level,   // Water level SW1
    input wire motor_fault,   // Motor fault or imbalance detection SW2 
    input wire fault_clear,   // clear fault state
    input wire override,      // New override input

    output reg [5:0] state_led, // State indicator LEDs 
    output reg [6:0] seg0,      // 7-segment display (units digit)
    output reg [6:0] seg1       // 7-segment display (tens digit)
);

    // FSM state definitions
    parameter S_READY      = 3'b000;
    parameter S_FILL_WATER = 3'b001;
    parameter S_WASH       = 3'b010;
    parameter S_RINSE      = 3'b011;
    parameter S_SPIN       = 3'b100;
    parameter S_FAULT      = 3'b101;
    parameter S_DRAIN      = 3'b110;  // New DRAIN state

    // Time constants
    parameter ONE_SECOND_CYCLES   = 27'd49999999; // 1 second at 50 MHz
    parameter WATER_FILL_TIMEOUT  = 8'd10;        // 10-second timeout for filling water

    // Internal signals
    reg [2:0] current_state, next_state, prev_state;
    reg [26:0] cycle_timer;        // Timer for 1-second intervals
    reg [7:0] water_fill_counter;  // Timeout counter during water fill
    reg [3:0] remaining_time;      // Countdown for timed operations (WASH, RINSE, SPIN, DRAIN)

    wire function_complete;

    // FSM state transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= S_READY;
        else
            current_state <= next_state;
    end
   
    // FSM next state logic with override priority
    always @(*) begin
        if (override)
            next_state = S_DRAIN;
        else begin
            next_state = current_state;
            case (current_state)
                S_READY:
                    if (door_closed && !fault_clear)
                        next_state = S_FILL_WATER;

                S_FILL_WATER:
                    if (water_level)
                        next_state = S_WASH;
                    else if (water_fill_counter >= WATER_FILL_TIMEOUT)
                        next_state = S_FAULT;

                S_WASH:
                    if (motor_fault)
                        next_state = S_FAULT;
                    else if (function_complete)
                        next_state = S_RINSE;

                S_RINSE:
                    if (motor_fault)
                        next_state = S_FAULT;
                    else if (function_complete)
                        next_state = S_DRAIN;

                S_DRAIN:
                    if (motor_fault)
                        next_state = S_FAULT;
                    else if (function_complete)
                        next_state = S_SPIN;

                S_SPIN:
                    if (motor_fault)
                        next_state = S_FAULT;
                    else if (function_complete)
                        next_state = S_READY;

                S_FAULT:
                    if (fault_clear && !motor_fault && !door_closed && !water_level)
                        next_state = S_READY;

                default:
                    next_state = S_READY;
            endcase
        end
    end

    // Timer and remaining time control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_timer        <= 27'd0;
            water_fill_counter <= 8'd0;
            remaining_time     <= 4'd0;
            prev_state         <= S_READY;
        end else begin
            // Reset water_fill_counter and remaining_time if exiting FAULT state to READY
            if (current_state == S_FAULT && next_state == S_READY) begin
                water_fill_counter <= 8'd0; // Reset water fill counter
                remaining_time     <= 4'd0; // Reset remaining time
            end else begin
                // Update 1-second timer
                if (cycle_timer >= ONE_SECOND_CYCLES - 1)
                    cycle_timer <= 27'd0;
                else
                    cycle_timer <= cycle_timer + 27'd1;

                // Water fill timeout logic
                if (current_state == S_FILL_WATER) begin
                    if (cycle_timer == ONE_SECOND_CYCLES - 1)
                        water_fill_counter <= water_fill_counter + 8'd1;
                end else begin
                    water_fill_counter <= 8'd0;
                end

                // Reset remaining_time on entering timed states or override asserted
                if ((current_state != prev_state) || override) begin
                    if (current_state == S_WASH)
                        remaining_time <= 4'd10;
                    else if (current_state == S_RINSE)
                        remaining_time <= 4'd10;
                    else if (current_state == S_SPIN)
                        remaining_time <= 4'd5;
                    else if (current_state == S_DRAIN)
                        remaining_time <= 4'd5;
                end

                // Countdown remaining_time once per second for timed states
                if (cycle_timer == ONE_SECOND_CYCLES - 1) begin
                    if ((current_state == S_WASH || current_state == S_RINSE || current_state == S_SPIN || current_state == S_DRAIN) && remaining_time > 0)
                        remaining_time <= remaining_time - 1;
                end
            end

            // Update previous state
            prev_state <= current_state;
        end
    end

    assign function_complete = (remaining_time == 0) &&
        (current_state == S_WASH || current_state == S_RINSE || current_state == S_SPIN || current_state == S_DRAIN);

    // State LED output
    always @(*) begin
        case (current_state) 
            S_READY:      state_led = 6'b000001;
            S_FILL_WATER: state_led = 6'b000010;
            S_WASH:       state_led = 6'b000100;
            S_RINSE:      state_led = 6'b001000;
            S_SPIN:       state_led = 6'b010000;
            S_FAULT:      state_led = 6'b100000;
            S_DRAIN:      state_led = 6'b000100;  // You can assign a unique LED pattern for DRAIN if you want
            default:      state_led = 6'b000000;
        endcase
    end

    // 7-segment decoder (active low: 0 = on)
    function [6:0] hex_to_7seg;
        input [3:0] hex_digit;
        begin
            case (hex_digit)
                4'h0: hex_to_7seg = 7'b1000000;
                4'h1: hex_to_7seg = 7'b1111001;
                4'h2: hex_to_7seg = 7'b0100100;
                4'h3: hex_to_7seg = 7'b0110000;
                4'h4: hex_to_7seg = 7'b0011001;
                4'h5: hex_to_7seg = 7'b0010010;
                4'h6: hex_to_7seg = 7'b0000010;
                4'h7: hex_to_7seg = 7'b1111000;
                4'h8: hex_to_7seg = 7'b0000000;
                4'h9: hex_to_7seg = 7'b0010000;
                default: hex_to_7seg = 7'b1111111;
            endcase
        end
    endfunction

    // 7-segment display logic
    always @(*) begin
        if (current_state == S_WASH || current_state == S_RINSE || current_state == S_SPIN || current_state == S_DRAIN) begin
            seg1 = hex_to_7seg(remaining_time / 10);
            seg0 = hex_to_7seg(remaining_time % 10);
        end else if (current_state == S_FAULT) begin
            seg1 = 7'b0001110; // 'F'
            seg0 = 7'b0000110; // 'E'
        end else begin
            seg1 = 7'b1111111; // Blank  - All off
            seg0 = 7'b1111111; // Blank  - All off
        end
    end

endmodule

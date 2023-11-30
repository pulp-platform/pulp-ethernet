/*

Copyright (c) 2016-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

/*
 * Generic ODDR module (ouput double data rate)
 */
module oddr #(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC",
    // IODDR style ("IODDR", "IODDR2")
    // Use IODDR for Virtex-4, Virtex-5, Virtex-6, 7 Series, Ultrascale
    // Use IODDR2 for Spartan-6
    parameter IODDR_STYLE = "IODDR2",
    // Width of register in bits
    parameter WIDTH = 1
) (
    input  wire             clk_i,
    input  wire             rst_ni,

    input  wire [WIDTH-1:0] d1,
    input  wire [WIDTH-1:0] d2,

    output wire [WIDTH-1:0] q
);

/*

Provides a consistent output DDR flip flop across multiple FPGA families
              _____       _____       _____       _____
    clk  ____/     \_____/     \_____/     \_____/     \_____
         _ ___________ ___________ ___________ ___________ __
    d1   _X____D0_____X____D2_____X____D4_____X____D6_____X__
         _ ___________ ___________ ___________ ___________ __
    d2   _X____D1_____X____D3_____X____D5_____X____D7_____X__
         _____ _____ _____ _____ _____ _____ _____ _____ ____
    d    _____X_D0__X_D1__X_D2__X_D3__X_D4__X_D5__X_D6__X_D7_

*/

genvar n;

generate

if (TARGET == "XILINX") begin
    for (n = 0; n < WIDTH; n = n + 1) begin : oddr
        if (IODDR_STYLE == "IODDR") begin
            ODDR #(
                .DDR_CLK_EDGE("SAME_EDGE"),
                .SRTYPE("ASYNC")
            )
            oddr_inst (
                .Q(q[n]),
                .C(clk_i),
                .CE(1'b1),
                .D1(d1[n]),
                .D2(d2[n]),
                .R(1'b0),
                .S(1'b0)
            );
        end else if (IODDR_STYLE == "IODDR2") begin
            ODDR2 #(
                .DDR_ALIGNMENT("C0"),
                .SRTYPE("ASYNC")
            )
            oddr_inst (
                .Q(q[n]),
                .C0(clk_i),
                .C1(~clk_i),
                .CE(1'b1),
                .D0(d1[n]),
                .D1(d2[n]),
                .R(1'b0),
                .S(1'b0)
            );
        end
    end
end else if (TARGET == "ALTERA") begin
    altddio_out #(
        .WIDTH(WIDTH),
        .POWER_UP_HIGH("OFF"),
        .OE_REG("UNUSED")
    )
    altddio_out_inst (
        .aset(1'b0),
        .datain_h(d1),
        .datain_l(d2),
        .outclocken(1'b1),
        .outclock(clk_i),
        .aclr(1'b0),
        .dataout(q)
    );
end else begin
    for (n = 0; n < WIDTH; n = n + 1) begin : oddr
        logic q1, q2;

        tc_clk_mux2 i_ddrmux (
            .clk_o     ( q[n] ),
            .clk0_i    ( q1  ),
            .clk1_i    ( q2  ),
            .clk_sel_i ( clk_i )
        );

        always_ff @(posedge clk_i or negedge rst_ni) begin
            if (~rst_ni) begin
                q1 <= 1'b0;
                q2 <= 1'b0;
            end else begin
                q1 <= d1[n];
                q2 <= d2[n];
            end
        end
    end  // oddr
end

endgenerate

endmodule

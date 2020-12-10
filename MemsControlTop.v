/*
 author  :       Wenky Jong
 Date    :       2020.09.24
 Address :       MianYang SWSUT
 Revision:       1st
 Description:    control the mems with spi protocol
 Contact:        wenkyjong1996@gmail.com
 */

 module MemsContolTop (
   input   wire    sclk,    //system clock 50Mhz
   input   wire    rst_n,
   input   wire    spi_miso,
   input   wire    signal_angle,  // the impulse of deflecting angle
   input   wire    signal_mid,    //the impulse of midle deflecting
   output    wire   spi_mosi,
   output    wire   spi_clk,
   output    wire   tx,
   output    wire   spi_cs
   );


wire [15:0]receive_data_H;
wire [15:0]receive_data_L;
reg config_mems_r;
   spiCommunicate U0 (
     .sclk (sclk),
     .rst_n (rst_n),
     .spi_miso (spi_miso),
     .config_mems (1'b1),
     .spi_mosi (spi_mosi),
     .spi_clk (spi_clk),
     .receive_done (receive_done),
     .receive_data_L (receive_data_L),
     .receive_data_H (receive_data_H),
     .spi_cs (spi_cs)
     );


reg   receive_done1;
reg   receive_done2;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    receive_done1<=1'b0;
    receive_done2<=1'b0;
  end else begin
    receive_done1<=receive_done;
    receive_done2<=receive_done1;
  end
end

reg start_r;
reg [15:0]data_r;
reg [2:0]state;
reg [34:0]cnt_delay;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    start_r<=1'b0;
    state <= 1'b0;
    cnt_delay<=1'b0;
    data_r<=1'b0;
  end else begin
    case (state)
      0: begin
        if (~receive_done1&&receive_done2) begin
          start_r<=1'b1;
          state<=state+1'b1;
          data_r<=receive_data_L;
        end else begin
          state<=state;
        end
      end
      1:begin
        if (cnt_delay==14'd6000) begin
          start_r<=1'b0;
          cnt_delay<=1'b0;
          state<=2;
        end else begin
          cnt_delay<=cnt_delay+1'b1;
          state<=state;
        end
      end
      2:begin
        if (cnt_delay==34'd1000_000_000) begin
            cnt_delay<=1'b0;
            start_r<=1'b1;
            data_r<=receive_data_H;
            state<=0;
        end else begin
            cnt_delay<=cnt_delay+1'b1;
            state<=state;
        end
      end
      default: state<=state;
    endcase
  end
end

wire [15:0]data;
wire start;
assign start=start_r;
assign data=data_r;
     UartSend U1 (
       .sclk (sclk),
       .rst_n (rst_n),
       .data (data),
       .start (start),
       .tx (tx)
       );


 endmodule // MemsContolTop

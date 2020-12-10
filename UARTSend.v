/*
 author  :       Wenky Jong
 Date    :       2020.09.22
 Address :       MianYang SWSUT
 Revision:       1st
 Description:    UART to send config of mems data
 Contact:        wenkyjong1996@gmail.com
 */

module UartSend (
  input   wire    sclk,
  input   wire    rst_n,
  input   wire    [15:0]data,
  input   wire    start,
  output    reg   tx
  );

  reg [7:0]data_send;
  always @ (posedge sclk or negedge rst_n) begin
      if (!rst_n) begin
        data_send<=data[15:8];
      end else begin
        if(cnt_uart==0)
			data_send<=data[15:8];
		 else
			data_send<=data[7:0];
      end
  end

/************uart CLK 9600hz*****************/
  reg   [11:0]cnt_div;
  reg clk_uart;
  always @ (posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_div<=1'b0;
      clk_uart<=1'b0;
    end else begin
      if (cnt_div==12'd2603) begin
        cnt_div<=1'b0;
        clk_uart<=~clk_uart;
      end else begin
        cnt_div<=cnt_div+1'b1;
      end
    end
  end

     /******using state machine********/
     parameter  PARITYMODE = 1'b0;//even parity
     reg   presult;
     reg [3:0]state;
     reg [4:0]cnt_uart;
     always @ (posedge clk_uart or negedge rst_n) begin
       if (!rst_n) begin
         state<=1'b0;
         tx<=1'b1;
     	   cnt_uart<=1'b0;
       end else begin
           case (state)           //data is ready
             0: begin
                if (start) begin
                  state<=state+1'b1;
                end else begin
                  state<=state;
              end
               end
             1:begin
               tx<=1'b0;
               state<=state+1'b1;
               end
             2:begin
               tx<=data_send[0];
               presult<=data_send[0]^PARITYMODE;//even parity
               state<=state+1'b1;
               end
             3:begin
               tx<=data_send[1];
               presult<=data_send[1]^presult;
               state<=state+1'b1;
               end
             4:begin
               tx<=data_send[2];
               presult<=data_send[2]^presult;
               state<=state+1'b1;
               end
             5: begin
               tx<=data_send[3];
               presult<=data_send[3]^presult;
               state<=state+1'b1;
             end
             6:begin
               tx<=data_send[4];
               presult<=data_send[4]^presult;//even parity
               state<=state+1'b1;
               end
             7:begin
               tx<=data_send[5];
               presult<=data_send[5]^presult;
               state<=state+1'b1;
               end
             8:begin
               tx<=data_send[6];
               presult<=data_send[6]^presult;
               state<=state+1'b1;
               end
             9:begin
               tx<=data_send[7];
               presult<=data_send[7]^presult;//even parity
               state<=state+1'b1;
               end
             10:begin                     //send parity
               tx<=presult;
               presult<=data_send[0]^presult;
               state<=state+1'b1;
               end
             11:begin                   //send stop bit
               tx<=1'b1;
               presult<=data_send[0]^presult;
               if (cnt_uart==5'd1) begin
                  cnt_uart<=1'b0;
                  state<=4'd12;
               end else begin
                  cnt_uart<=cnt_uart+1'b1;
                  state<=1'b0;
               end
               end
            12:begin
              if (start) begin
                state<=1'b1;
              end else begin
                state<=state;
              end
            end
             default:begin
                 tx<=1'b1;
                 state<=1'b0;
              end
           endcase
       end
     end


endmodule // UartSend

/*
 author  :       Wenky Jong
 Date    :       2020.11.06
 Address :       MianYang SWSUT
 Revision:       1st
 Description:    spi communication
 Contact:        wenkyjong1996@gmail.com
 */

module spiCommunicate (
  input   wire    sclk,
  input   wire    rst_n,
  input   wire    spi_miso,
  input   wire    config_mems,
  output    reg   spi_mosi,
  output    reg   spi_clk,
  output    reg   receive_done,
  output    reg   [15:0]receive_data_L,
  output    reg   [15:0]receive_data_H,
  output    reg   spi_cs
  );



  /**********spi clk = 100k******/
  localparam  FLAG100K = 249;
  reg [7:0]cnt;
  always @ (posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
      spi_clk<=1'b0;
      cnt<=1'B0;
    end else begin
      if (cnt>=FLAG100K) begin
        spi_clk<=~spi_clk;
        cnt<=1'b0;
      end else begin
        cnt<=cnt+1'b1;
      end
    end
  end
/*********send the data ************/
reg [15:0]angle_scan;
reg [15:0]angle_plus;
reg [15:0]angle_scope;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    angle_scan<=1'b0;
    angle_plus<=1'b0;
    angle_scope<=1'b0;
  end else begin
    angle_scan<=16'h0BB8;
    angle_plus<=16'h8005;
    angle_scope<=16'h05DC;
  end
end

reg [15:0]data[0:3];
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
   data[0]<=1'b0;
	 data[1]<=1'b0;
	 data[2]<=1'b0;
	 data[3]<=1'b0;
  end else begin
		data[0]<=angle_scan;
		data[1]<=angle_plus;
		data[2]<=angle_scope;
		data[3]<=16'hc000;
  end
end

reg [5:0]state_c;
reg [5:0]state_n;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    state_c<=1'b0;
  end else begin
    state_c<=state_n;
  end
end

localparam  IDLE = 6'b0,START=6'd1,  SEND = 6'd2,
            WAIT =6'd3, END=6'd4 ,RECEIVE=6'd5 ;

assign start_spi=config_mems;

always @ (*) begin
  if (!rst_n) begin
    state_n<=1'b0;
  end else begin
    case (state_c)
      IDLE:begin
          if (start_spi) begin
            state_n<=START;
          end else begin
            state_n<=IDLE;
          end
      end
      START:begin
        if (spi_cs==0) begin
            state_n<=SEND;
          end else begin
            state_n<=state_n;
          end
      end
      SEND:begin
        if (cnt_bit==4'd15&&(cnt==FLAG100K-1)&&spi_clk==1) begin
            state_n<=WAIT;
        end else begin
            state_n<=SEND;
        end
      end
      WAIT:begin
          if (cnt_wait>=24'd1_000_000) begin
              state_n<=END;
          end else begin
              state_n<=WAIT;
          end
      end
      END:begin
        if (cnt_data==3) begin
            state_n<=RECEIVE;
        end else begin
            state_n<=START;
        end
      end
      RECEIVE:begin
        if (receive_done) begin
          state_n<=IDLE;
        end else begin
          state_n<=RECEIVE;
        end
      end
      default:state_n<=IDLE ;
    endcase
  end
end
/********************receive done*****************/

always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    receive_done<=1'b0;
  end else begin
    if (state_c==RECEIVE) begin
      if (cnt==FLAG100K-1&&spi_clk) begin
        if (cnt_bit_r==4'd15&&cnt_data_r==2'd1) begin
            receive_done<=1'b1;
        end else begin
            receive_done<=1'b0;
        end
      end else begin
        receive_done<=receive_done;
      end
    end else begin
      receive_done<=1'b0;
    end
  end
end


/***delay 20ms send 16bit***/
reg [23:0]cnt_wait;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_wait<=1'b0;
  end else begin
    if (state_c==WAIT) begin
      if (cnt_wait>=24'd1_000_000) begin//delay 20ms
        cnt_wait<=1'b0;
      end else begin
        cnt_wait<=cnt_wait+1'b1;
      end
    end else begin
      cnt_wait<=1'b0;
    end
  end
end

/****************update the output config data************/
reg [15:0]r_data[0:1];
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    spi_mosi<=1'b0;
    spi_cs<=1;
    r_data[0]<=1'b0;
	 r_data[1]<=1'b0;
  end else begin
    case (state_c)
      IDLE:begin
        spi_mosi<=1'b0;
        spi_cs<=1;
      end
      START:begin
        if (cnt==1&&spi_clk==0) begin
            spi_cs<=0;
          end else begin
            spi_cs<=spi_cs;
          end
        end
      SEND:begin
        spi_mosi<=data[cnt_data][4'd15-cnt_bit];
      end
      WAIT:begin
        spi_cs<=1;
        end
      END:begin
          if (cnt_data==3) begin
            spi_cs<=0;
          end
      end
      RECEIVE:begin
        r_data[cnt_data_r][4'd15-cnt_bit_r]<=spi_miso;
      end
      default: ;
    endcase
  end
end


reg [1:0]cnt_data;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_data<=1'b0;
  end else begin
    if (state_c!=IDLE) begin
      if ((cnt_bit>=4'd15)&&(cnt==FLAG100K-1)&&spi_clk==1) begin
        if (cnt_data>=3) begin//total send 4 data
          cnt_data<=1'b0;
        end else begin
          cnt_data<=cnt_data+1'b1;
        end
      end else begin
        cnt_data<=cnt_data;
      end
    end else begin
      cnt_data<=1'b0;
    end
  end
end

reg [1:0]cnt_data_r;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_data_r<=1'b0;
  end else begin
    if (state_c==RECEIVE) begin
      if ((cnt_bit_r>=4'd15)&&(cnt==FLAG100K-1)&&spi_clk==0) begin
        if (cnt_data_r>=3) begin//total send 4 data
          cnt_data_r<=1'b0;
        end else begin
          cnt_data_r<=cnt_data_r+1'b1;
        end
      end else begin
        cnt_data_r<=cnt_data_r;
      end
    end else begin
      cnt_data_r<=1'b0;
    end
  end
end

reg [3:0]cnt_bit;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_bit<=1'b0;
  end else begin
      if (state_c==SEND) begin
        if ((cnt==FLAG100K-1)&&spi_clk==1) begin//negedge of spi_clk
            if (cnt_bit>=4'd15) begin
              cnt_bit<=1'b0;
            end else begin
              cnt_bit<=cnt_bit+1'b1;
            end
        end else begin
          cnt_bit<=cnt_bit;
        end
      end else begin
        cnt_bit<=1'b0;
      end
  end
end

reg [3:0]cnt_bit_r;//read count that change in posedge spi_clk
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_bit_r<=1'b0;
  end else begin
      if (state_c==RECEIVE) begin
        if ((cnt==FLAG100K-1)&&spi_clk==0) begin//negedge of spi_clk
            if (cnt_bit_r>=4'd15) begin
              cnt_bit_r<=1'b0;
            end else begin
              cnt_bit_r<=cnt_bit_r+1'b1;
            end
        end else begin
          cnt_bit_r<=cnt_bit_r;
        end
      end else begin
        cnt_bit_r<=1'b0;
      end
  end
end


reg done1;
reg done2;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    done1<=1'b0;
    done2<=1'b0;
  end else begin
    done1<=receive_done;
    done2<=done1;
  end
end

always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    receive_data_L<=1'b0;
    receive_data_H<=1'b0;
  end else begin
    if (done1==0&&done2==1) begin
      receive_data_L<=r_data[0];
      receive_data_H<=r_data[1];
    end else begin
      receive_data_L<=receive_data_L[0];
      receive_data_H<=receive_data_H[1];
    end
  end
end

endmodule // spiCommunicate

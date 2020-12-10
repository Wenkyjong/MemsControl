/*
 author  :       Wenky Jong
 Date    :       2020.12.5
 Address :       MianYang SWSUT
 Revision:       1st
 Description:    control the laser on or off
 Contact:        wenkyjong1996@gmail.com
 */

module laserControl (
  input   wire    clk_50,//the clk is 
  input   wire    rst_n,
  input   wire    signal_angle,//½Ç±êÖ¾Âö³å
  input   wire    signal_mid,//Êä³öÁãÂö³å
  output    reg   laser
  );

/*****model_change ******/

wire model_change;
assign model_change=0; //fixed the model 


  pll U0
   (// Clock in ports
    .CLK_IN1(clk_50),      // IN
    // Clock out ports
    .CLK_OUT1(sclk));    // OUT
/*****detect the zero flag plus signal******/

reg zeroFlag_1;
reg zeroFlag_2;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    zeroFlag_1<=1'b0;
    zeroFlag_2<=1'b0;
  end else begin
    zeroFlag_1<=signal_mid;
    zeroFlag_2<=zeroFlag_1;
  end
end

/*********detect the angle flag plus signal*********/

reg angleFlag_1;
reg angleFlag_2;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    angleFlag_1<=1'b0;
    angleFlag_2<=1'b0;
  end else begin
    angleFlag_1<=signal_angle;
    angleFlag_2<=angleFlag_1;
  end
end

/***********the count of angle flag plus signal******/
reg [11:0]cnt_angle_plus;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_angle_plus<=1'b1;
  end else begin
    if ((zeroFlag_1&&~zeroFlag_2)||model_change) begin//zero flag plus or model is changed cnt turn 1
      cnt_angle_plus<=1'b1;
    end else begin
      if (angleFlag_1&&~angleFlag_2) begin
        cnt_angle_plus<=cnt_angle_plus+1'b1;
      end else begin
        cnt_angle_plus<=cnt_angle_plus;
      end
    end
  end
end

/************the control of laser using angle_plus******/
parameter IDLE  = 2'b00, CONTROL=2'b01;

reg [2:0]state_c;
reg [2:0]state_n;
always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
     state_c<=1'b0;
  end else begin
    state_c<=state_n;
  end
end

always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    state_n<=IDLE;
  end else begin
    case (state_c)
      IDLE:begin
        if (cnt_angle_plus==601) begin //the mems is in right
          state_n<=CONTROL;
        end else begin
          state_n<=state_n;
        end
      end
      CONTROL:begin
        if (model_change) begin
            state_n<=IDLE;
        end else begin
            state_n<=CONTROL;
        end
      end
      default: state_n<=state_n;
    endcase
  end
end

always @ (posedge sclk or negedge rst_n) begin
  if (!rst_n) begin
    laser<=1'b0;
  end else begin
    case (state_c)
      IDLE:laser<=1'b0;
      CONTROL:begin
        if (cnt_angle_plus==601) begin
          laser<=1'b1;
        end else begin
          if (cnt_angle_plus==879) begin
              laser<=1'b0;
          end else begin
            if (cnt_angle_plus==1202) begin
              laser<=1'b1;
            end else begin
              if (cnt_angle_plus==1524) begin
                laser<=1'b0;
              end else begin
                if (cnt_angle_plus==2081) begin
                  laser<=1'b1;
                end else begin
                  if (cnt_angle_plus==2402) begin
                    laser<=1'b0;
                  end else begin
                    if (cnt_angle_plus==323) begin
                      laser<=1'b1;
                    end else begin
                      laser<=laser;
                    end
                  end
                end
              end
            end
          end
        end
      end
      default:laser<=laser ;
    endcase
  end
end

endmodule // laserControl

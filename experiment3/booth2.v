module booth2 (
    input  wire        clk  ,
	input  wire        rst_n,
	input  wire [15:0] x    ,
	input  wire [15:0] y    ,
	input  wire        start,
	output reg  [31:0] z    ,
	output wire        busy 
);

reg [16:0] mul_x; //带双符号位的乘数x
reg [16:0] neg_x; //带双符号位的-x
reg [16:0] mul_y; //带n+1位的乘数y
reg [3:0] cnt; //计数，判断算法是否结束
reg busy_reg;
assign busy = busy_reg;

//复位及求-x补
always @(posedge clk or negedge rst_n)  begin
    if(!rst_n) begin
        mul_x <= 0;
        neg_x <= 0;
    end
    else if(start) begin
        mul_x <= {x[15], x}; //增加双符号位
        neg_x <= ~{x[15], x} + 1; //求-x补码
    end
end

//控制busy信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) busy_reg <= 0;
    else if(start) busy_reg <= 1;
    else if(busy && cnt==4'd7) begin
        busy_reg <= 0;
    end
end

//booth算法
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 0;
        mul_y <= 0;
        z <= 0;
    end
    else if(start) begin
        mul_y <= {y, 1'b0}; 
        z <= 0;
    end
    else if(busy) begin
        if(cnt < 4'd7) begin
            case (mul_y[2:0])
                3'b001: z <= ($signed(z + {mul_x, 15'b0})) >>> 2;
                3'b010: z <= ($signed(z + {mul_x, 15'b0})) >>> 2;
                3'b011: z <= ($signed(z + {mul_x, 15'b0} + {mul_x, 15'b0})) >>> 2;
                3'b100: z <= ($signed(z + {neg_x, 15'b0} + {neg_x, 15'b0})) >>> 2;
                3'b101: z <= ($signed(z + {neg_x, 15'b0})) >>> 2;
                3'b110: z <= ($signed(z + {neg_x, 15'b0})) >>> 2;
                default: z <= ($signed(z)) >>> 2;
            endcase
            mul_y <= mul_y >> 2;
            cnt <= cnt+1;
        end
        //最后一步不移位
        else if(cnt == 4'd7) begin
            case (mul_y[2:0])
                3'b001: z <= ($signed(z + {mul_x, 15'b0})) >>> 1;
                3'b010: z <= ($signed(z + {mul_x, 15'b0})) >>> 1;
                3'b011: z <= ($signed(z + {mul_x, 15'b0} + {mul_x, 15'b0})) >>> 1;
                3'b100: z <= ($signed(z + {neg_x, 15'b0} + {neg_x, 15'b0})) >>> 1;
                3'b101: z <= ($signed(z + {neg_x, 15'b0})) >>> 1;
                3'b110: z <= ($signed(z + {neg_x, 15'b0})) >>> 1;
                default: z <= ($signed(z)) >>> 1;
            endcase
            cnt <= 0;
        end
    end
end

endmodule
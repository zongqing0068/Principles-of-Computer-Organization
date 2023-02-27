`timescale 1ns / 1ps

module cache (
    // 全局信号
    input             clk,
    input             reset,
    // 从CPU来的访问信号
    input wire [12:0] addr_from_cpu,    // CPU來的地址
    input wire        rreq_from_cpu,    // CPU来的读请求
    input wire        wreq_from_cpu,    // CPU来的写请求
    input wire [ 7:0] wdata_from_cpu,   // CPU来的写数据
    // 从下层内存模块来的信号
    input wire [31:0] rdata_from_mem,   // 内存读取的数据
    input wire        rvalid_from_mem,  // 内存读取数据可用标志
    // 输出给CPU的信号
    output wire [7:0] rdata_to_cpu,     // 输出给CPU的数据
    output wire       hit_to_cpu,       // 输出给CPU的命中标志
    // 输出给下层内存模块的信号
    output reg        rreq_to_mem,      // 输出给下层内存模块的读请求
    output reg [12:0] raddr_to_mem,     // 输出给下层模块的突发传输首地址
    output reg        wreq_to_mem,      // 输出给下层内存模块的写请求
    output reg [12:0] waddr_to_mem,     // 输出给下层内存模块的写地址
    output reg [ 7:0] wdata_to_mem      // 输出给下层内存模块的写数据
);

reg [3:0] current_state, next_state;
localparam READY     = 4'b0000,
           TAG_CHECK = 4'b0010,
           REFILL    = 4'b0001;     //读时序的REDILL状态以及写时序的WR_DATA状态共用

wire        wea;                        // Cache写使能信号
wire [31:0] wdata_to_cache;              // 在写操作时需写入cache的数据
wire [37:0] cache_line_r = rreq_from_cpu ? {1'b1, addr_from_cpu[12:8], rdata_from_mem} : {1'b1, addr_from_cpu[12:8], wdata_to_cache};  // 待写入Cache的Cache行数据。判断是读缺失还是写操作
wire [37:0] cache_line;                 // 从Cache中读出的Cache行数据

wire [ 5:0] cache_index    = addr_from_cpu[7:2];         // 主存地址中的Cache索引/Cache地址
wire [ 4:0] tag_from_cpu   = addr_from_cpu[12:8];        // 主存地址的Tag
wire [ 1:0] offset         = addr_from_cpu[1:0];         // Cache行内的字节偏移
wire        valid_bit      = cache_line[37];             // Cache行的有效位
wire [ 4:0] tag_from_cache = cache_line[36:32];          // Cache行的Tag

// 当处于TAG_CHECK阶段，且cache中对应行的tag与主存中的tag相等，且数据有效时，视为命中
wire hit  = (current_state == TAG_CHECK) && (tag_from_cpu == tag_from_cache) && valid_bit; 
wire miss = (tag_from_cache != tag_from_cpu) | (~valid_bit);

// 根据Cache行的字节偏移，从Cache块中选取CPU所需的字节数据
assign rdata_to_cpu = (offset == 2'b00) ? cache_line[7:0] :
                      (offset == 2'b01) ? cache_line[15:8] :
                      (offset == 2'b10) ? cache_line[23:16] : cache_line[31:24];

assign hit_to_cpu = hit;
// 根据Cache行的字节偏移，替换cache中的相应字段
assign wdata_to_cache = (offset == 2'b00) ? {cache_line[31:8], wdata_from_cpu} :
                        (offset == 2'b01) ? {cache_line[31:16], wdata_from_cpu, cache_line[7:0]} :
                        (offset == 2'b10) ? {cache_line[31:24], wdata_from_cpu, cache_line[15:0]} : 
                                            {wdata_from_cpu, cache_line[23:0]};

// 使用Block RAM IP核作为Cache的物理存储体
blk_mem_gen_0 u_cache (
    .clka   (clk         ),
    .wea    (wea         ),
    .addra  (cache_index ),
    .dina   (cache_line_r),
    .douta  (cache_line  )
);


always @(posedge clk) begin
    if (reset) begin
        current_state <= READY;
    end else begin
        current_state <= next_state;
    end
end

// 根据指导书/PPT的状态转换图，实现控制Cache读取的状态转移
always @(*) begin
    case(current_state)
        READY: begin
            if (rreq_from_cpu || wreq_from_cpu) begin
                next_state = TAG_CHECK;
            end else begin
                next_state = READY;
            end
        end
        TAG_CHECK: begin
            if ((rreq_from_cpu && hit) || (wreq_from_cpu && !hit)) begin //读命中或写缺失
                next_state = READY;
            end else begin
                next_state = REFILL;
            end
        end
        REFILL: begin
            if (rvalid_from_mem) begin
                next_state = TAG_CHECK;
            end else begin 
                next_state = REFILL;
            end
        end
        default: begin
            next_state = READY;
        end
    endcase
end

// 生成Block RAM的写使能信号。读缺失或是写命中时，该使能有效
assign wea = (rreq_from_cpu && current_state == REFILL && rvalid_from_mem) || (wreq_from_cpu && current_state == TAG_CHECK && hit);

// 生成读取主存所需的信号，即读请求信号rreq_to_mem和读地址信号raddr_to_mem
always @(posedge clk) begin
    if (reset) begin
        raddr_to_mem <= 0;
        rreq_to_mem <= 0;
    end else if(rreq_from_cpu) begin
        case (next_state)
            READY: begin
                raddr_to_mem <= 0;
                rreq_to_mem  <= 0;
            end
            TAG_CHECK: begin
                raddr_to_mem <= 0;
                rreq_to_mem  <= 0;
            end
            REFILL: begin
                raddr_to_mem <= addr_from_cpu;
                rreq_to_mem  <= 1;
            end
            default: begin
                raddr_to_mem <= 0;
                rreq_to_mem  <= 0;
            end
        endcase
    end
    else begin
        raddr_to_mem <= 0;
        rreq_to_mem <= 0;
    end
end

// 写命中处理（写直达法）
// 生成写主存所需的信号，即写请求信号wreq_to_mem、写地址信号waddr_to_mem和写数据信号wdata_to_mem
always @(posedge clk) begin
    if (reset) begin
        waddr_to_mem <= 0;
        wreq_to_mem <= 0;
        wdata_to_mem <= 0;
    end else if(wreq_from_cpu) begin
         case (next_state)
            READY: begin
                waddr_to_mem <= 0;
                wreq_to_mem <= 0;
                wdata_to_mem <= 0;
            end
            TAG_CHECK: begin
                waddr_to_mem <= 0;
                wreq_to_mem <= 0;
                wdata_to_mem <= 0;
            end
            REFILL: begin
                waddr_to_mem <= addr_from_cpu;
                wreq_to_mem  <= 1;
                wdata_to_mem <= wdata_from_cpu;
            end
            default: begin
                waddr_to_mem <= 0;
                wreq_to_mem <= 0;
                wdata_to_mem <= 0;
            end
        endcase
    end
    else begin
        waddr_to_mem <= 0;
        wreq_to_mem <= 0;
        wdata_to_mem <= 0;
    end
end



endmodule

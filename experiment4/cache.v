`timescale 1ns / 1ps

module cache (
    // ȫ���ź�
    input             clk,
    input             reset,
    // ��CPU���ķ����ź�
    input wire [12:0] addr_from_cpu,    // CPU��ĵ�ַ
    input wire        rreq_from_cpu,    // CPU���Ķ�����
    input wire        wreq_from_cpu,    // CPU����д����
    input wire [ 7:0] wdata_from_cpu,   // CPU����д����
    // ���²��ڴ�ģ�������ź�
    input wire [31:0] rdata_from_mem,   // �ڴ��ȡ������
    input wire        rvalid_from_mem,  // �ڴ��ȡ���ݿ��ñ�־
    // �����CPU���ź�
    output wire [7:0] rdata_to_cpu,     // �����CPU������
    output wire       hit_to_cpu,       // �����CPU�����б�־
    // ������²��ڴ�ģ����ź�
    output reg        rreq_to_mem,      // ������²��ڴ�ģ��Ķ�����
    output reg [12:0] raddr_to_mem,     // ������²�ģ���ͻ�������׵�ַ
    output reg        wreq_to_mem,      // ������²��ڴ�ģ���д����
    output reg [12:0] waddr_to_mem,     // ������²��ڴ�ģ���д��ַ
    output reg [ 7:0] wdata_to_mem      // ������²��ڴ�ģ���д����
);

reg [3:0] current_state, next_state;
localparam READY     = 4'b0000,
           TAG_CHECK = 4'b0010,
           REFILL    = 4'b0001;     //��ʱ���REDILL״̬�Լ�дʱ���WR_DATA״̬����

wire        wea;                        // Cacheдʹ���ź�
wire [31:0] wdata_to_cache;              // ��д����ʱ��д��cache������
wire [37:0] cache_line_r = rreq_from_cpu ? {1'b1, addr_from_cpu[12:8], rdata_from_mem} : {1'b1, addr_from_cpu[12:8], wdata_to_cache};  // ��д��Cache��Cache�����ݡ��ж��Ƕ�ȱʧ����д����
wire [37:0] cache_line;                 // ��Cache�ж�����Cache������

wire [ 5:0] cache_index    = addr_from_cpu[7:2];         // �����ַ�е�Cache����/Cache��ַ
wire [ 4:0] tag_from_cpu   = addr_from_cpu[12:8];        // �����ַ��Tag
wire [ 1:0] offset         = addr_from_cpu[1:0];         // Cache���ڵ��ֽ�ƫ��
wire        valid_bit      = cache_line[37];             // Cache�е���Чλ
wire [ 4:0] tag_from_cache = cache_line[36:32];          // Cache�е�Tag

// ������TAG_CHECK�׶Σ���cache�ж�Ӧ�е�tag�������е�tag��ȣ���������Чʱ����Ϊ����
wire hit  = (current_state == TAG_CHECK) && (tag_from_cpu == tag_from_cache) && valid_bit; 
wire miss = (tag_from_cache != tag_from_cpu) | (~valid_bit);

// ����Cache�е��ֽ�ƫ�ƣ���Cache����ѡȡCPU������ֽ�����
assign rdata_to_cpu = (offset == 2'b00) ? cache_line[7:0] :
                      (offset == 2'b01) ? cache_line[15:8] :
                      (offset == 2'b10) ? cache_line[23:16] : cache_line[31:24];

assign hit_to_cpu = hit;
// ����Cache�е��ֽ�ƫ�ƣ��滻cache�е���Ӧ�ֶ�
assign wdata_to_cache = (offset == 2'b00) ? {cache_line[31:8], wdata_from_cpu} :
                        (offset == 2'b01) ? {cache_line[31:16], wdata_from_cpu, cache_line[7:0]} :
                        (offset == 2'b10) ? {cache_line[31:24], wdata_from_cpu, cache_line[15:0]} : 
                                            {wdata_from_cpu, cache_line[23:0]};

// ʹ��Block RAM IP����ΪCache������洢��
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

// ����ָ����/PPT��״̬ת��ͼ��ʵ�ֿ���Cache��ȡ��״̬ת��
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
            if ((rreq_from_cpu && hit) || (wreq_from_cpu && !hit)) begin //�����л�дȱʧ
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

// ����Block RAM��дʹ���źš���ȱʧ����д����ʱ����ʹ����Ч
assign wea = (rreq_from_cpu && current_state == REFILL && rvalid_from_mem) || (wreq_from_cpu && current_state == TAG_CHECK && hit);

// ���ɶ�ȡ����������źţ����������ź�rreq_to_mem�Ͷ���ַ�ź�raddr_to_mem
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

// д���д���дֱ�﷨��
// ����д����������źţ���д�����ź�wreq_to_mem��д��ַ�ź�waddr_to_mem��д�����ź�wdata_to_mem
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

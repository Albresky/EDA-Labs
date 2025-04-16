`timescale 1ns/1ps

module TopFunc_tb;
    // 参数定义
    parameter CLK_PERIOD = 10;  // 100MHz时钟
    parameter SIM_TIME = 5000000; // 5ms仿真时间
    parameter NUM_TEST_CASES = 2; // 与C++代码保持一致
    
    // 信号声明
    reg clk;
    reg reset;
    reg [14:0] test_data;
    reg [4:0] tx_m_state;
    reg [4:0] rx_m_state;
    wire sync_flag;
    
    integer i, seed, success_count;
    reg [4:0] base_state;
    
    // 实例化DUT
    TopFunc top_func_inst (
        .clk(clk),
        .reset(reset),
        .test_data(test_data),
        .tx_m_state(tx_m_state),
        .rx_m_state(rx_m_state),
        .sync_flag(sync_flag)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // 生成测试数据
    function [14:0] generate_test_data;
        input integer seed_val;
        integer i;
        reg [14:0] data;
    begin
        // 使用种子值初始化随机数发生器
        data = 0;
        for (i = 0; i < 15; i = i + 1) begin
            data[i] = ($random(seed_val) % 2);
        end
        generate_test_data = data;
    end
    endfunction
    
    // 生成M码初始状态
    function [4:0] generate_m_state;
        input integer state_idx;
        reg [4:0] state;
    begin
        if (state_idx == 0) begin
            generate_m_state = 5'b10101; // 基准状态
        end else begin
            // 循环右移基准状态
            state = 5'b10101;
            repeat (state_idx) begin
                state = {state[0], state[4:1]};
            end
            generate_m_state = state;
        end
    end
    endfunction
    
    // 测试过程
    initial begin
        // 初始化
        reset = 1;
        success_count = 0;
        base_state = 5'b10101;
        
        // 重置信号
        #(CLK_PERIOD*10) reset = 0;
        
        // 运行测试用例
        for (i = 0; i < NUM_TEST_CASES; i = i + 1) begin
            // 设置随机种子
            seed = i + 100;
            
            // 生成测试数据
            test_data = generate_test_data(seed);
            
            // 生成TX和RX的M码初始状态
            tx_m_state = generate_m_state(i);
            
            // RX状态是TX状态循环右移一位
            rx_m_state = {tx_m_state[0], tx_m_state[4:1]};
            
            // 重置系统开始新的测试
            reset = 1;
            #(CLK_PERIOD*5) reset = 0;
            
            // 等待同步或超时
            fork
                begin
                    // 等待同步信号
                    wait (sync_flag == 1);
                    $display("Test Case %0d: Sync achieved!", i);
                    success_count = success_count + 1;
                end
                begin
                    // 超时检测
                    #SIM_TIME
                    if (!sync_flag) begin
                        $display("Test Case %0d: Failed to achieve sync within timeout", i);
                    end
                end
            join_any
            disable fork;
            
            // 如果使用了随机种子，每次测试后更新
            seed = $time;
        end
        
        // 显示测试结果
        $display("Tests completed. Success rate: %0d/%0d", success_count, NUM_TEST_CASES);
        
        // 结束仿真
        #100 $finish;
    end
    
    // 生成波形文件
    initial begin
        $dumpfile("TopFunc_tb.vcd");
        $dumpvars(0, TopFunc_tb);
    end
endmodule

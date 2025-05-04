# 实验二：简单处理器（CPU）的逻辑综合实验

## 一、源码结构

 - `cpu`
    - 简单 CPU 的 RTL 代码
 - `syn`
    - 逻辑综合的工程目录
 - `sim`
    - 仿真工程目录（逻辑综合后，通过 `make sim_all` 生成）

## 二、实验要求及报告

### 2.1 CPU RTL 验证

利用 VCS 和已有的 test 文件，对 CPU 进行测试，验证 RTL 级 CPU 的正确性，并解决验证过程中遇到的问题。

> 注：在cpu工作目录下使用make命令对CPU进行验证，并根据提示执行相应的命令运行test文件对CPU进行测试。

- **修改参考示例存在的 bug**

   - 主要涉及 .tcl 脚本中大量的语法错误
   - filelist 中 RTL 代码声明缺失
   - `cpu.v` 中 *halt* 信号未拉出，将导致 pad 后的 CPU 无法在仿真时中断

- **RTL 级 CPU 验证结果**
  - 测试 1
    - ![CPU_test_1](./images/cpu_1.png)
  - 测试 2
    - ![CPU_test_1](./images/cpu_2.png)
  - 测试 3
    - ![CPU_test_1](./images/cpu_3.png)

### 2.2 CPU PAD 逻辑综合结果时序验证

2. 对 CPU 添加输入输出 PAD，编写脚本，利用 EDA 逻辑工具和工艺库文件对生成的顶层文件进行逻辑综合，生成门级网表和 SDF 文件。分别设置时钟频率 150MHz、50MHz、20MHz，分析逻辑综合结果是否满足时序要求。

 - **在根目录下执行 `make syn_all` 创建各时钟频率下的逻辑综合工程**

 - 门级网表 和 SDF 文件
   - ![netlists](./images/netlists_all.png)

 - 各频率下的时序指标均满足要求
   - **20 MHz** (Slack=19.60 > 0)
     - ![](./images/timing_20mhz.png)
   - **50 MHz** (Slack=4.58 > 0)
     - ![](./images/timing_50mhz.png)
   - **150 MHz** (Slack=0.02 > 0)
     - ![](./images/timing_150mhz.png)

### 2.3 反标 SDF 后的 CPU 功能验证

利用之前的test文件，反标SDF后，对逻辑综合生成的门级网表（150MHz、50MHz、20MHz）进行功能验证，并对门级验证的结果进行分析。

 - 将逻辑综合后的 SDF 反标至 仿真工程目录
 - 执行 `make sim_all` 生成完成仿真工程文件

> 每个频率的仿真工程创建完毕后，会自动进入 `ucli` 环境，这里需要手动执行 `exit` 以进行其他频率的仿真工程创建。
> 所有仿真工程创建完毕后，手动进入到该仿真工程目录（比如 `sim/20MHz`），执行 `./sim_20MHz` 进行仿真。

 - 结果验证
   - **20 MHz**
      - 测试 1 
        - ![20mhz_test1](./images/sim_20_1.png)
      - 测试 2 
        - ![20mhz_test2](./images/sim_20_2.png)
      - 测试 3 
        - ![20mhz_test3](./images/sim_20_3.png)
   - **50 MHz**
      - 测试 1 
        - ![50mhz_test1](./images/sim_50_1.png)
      - 测试 2 
        - ![50mhz_test2](./images/sim_50_2.png)
      - 测试 3 
        - ![50mhz_test3](./images/sim_50_3.png)
   - **150 MHz**
      - 测试 1 
        - ![150mhz_test1](./images/sim_150_1.png)
      - 测试 2 
        - ![150mhz_test2](./images/sim_150_2.png)
      - 测试 3 
        - ![150mhz_test3](./images/sim_150_3.png)        


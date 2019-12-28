`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module minisys(rst,clk,led2N4,switch2N4
);//instruction,branch,nbranch,jmp,jal,jrn,zero
    input rst;               //板上的Reset信号，低电平复位
    input clk;               //板上的100MHz时钟信号
    input[23:0] switch2N4;    //拨码开关输入
    output[23:0] led2N4;      //led结果输出到板子

    wire branch;
    wire nbranch;
    wire jmp;
    wire jal;
    wire jrn;
    wire zero;    
    wire[31:0] instruction;
    
    wire clock;              //clock: 分频后时钟供给系统
    wire iowrite,ioread;     //I/O读写信号
    wire[31:0] write_data;   //写RAM或IO的数据
    wire[31:0] rdata;        //读RAM或IO的数据
    wire[15:0] ioread_data;  //读IO的数据
    wire[31:0] pc_plus_4;    //PC+4
    wire[31:0] read_data_1;  //
    wire[31:0] read_data_2;  //
    wire[31:0] sign_extend;  //符号扩展
    wire[31:0] add_result;   //
    wire[31:0] alu_result;   //
    wire[31:0] read_data;    //RAM中读取的数据
    wire[31:0] address;
    wire alusrc;

    wire i_format;
    wire regdst;
    wire regwrite;
    wire memwrite;
    wire memread;
    wire memoriotoreg;
    wire memreg;
    wire sftmd;
    wire[1:0] aluop;

    wire[31:0] opcplus4;
    wire ledctrl,switchctrl,jianpanctrl;
    wire[15:0] ioread_data_switch;
    wire[15:0] yy;
    
    
    // multi process begin
    
    wire[1:0] wpc;
    wire wir;
    wire Waluresult;
    
    // multi process end
    
    cpuclk cpuclk(
        .clk_in1(clk),    //100MHz
        .clk_out1(clock)    //cpuclock
    );

    Ifetc32 ifetch(
        //input
        .clock(clock), //时钟信号
        .reset(rst),   //复位信号
        .Add_result(add_result),    // 来自执行单元,算出的跳转地址
        .Read_data_1(read_data_1),  // 来自译码单元，jr指令用的地址
        //.Branch(branch),        // 来自控制单元
        //.nBranch(nbranch),      // 来自控制单元
        .Jmp(jmp),              // 来自控制单元
        .Jal(jal),              // 来自控制单元
        //.Jrn(jrn),              // 来自控制单元
        //.Zero(zero),            //来自执行单元
        //output
        .Instruction(instruction),  // 输出指令到其他模块
        .PC_plus_4_out(pc_plus_4),  // (pc+4)送执行单元        
        .opcplus4(opcplus4),         // JAL指令专用的PC+4
        .Wpc(wpc),
        .Wir(wir)
    );

    Idecode32 idecode(
        //input
        .clock(clock),              // 时钟信号
        .reset(rst),                //复位信号        
        .Instruction(instruction),// 取指单元来的指令
        .read_data(rdata),          //  从DATA RAM or I/O port取出的数据
        .ALU_result(alu_result),    // 从执行单元来的运算的结果，需要扩展立即数到32位
        .Jal(jal),                  //  来自控制单元，说明是JAL指令 
        .RegWrite(regwrite),        // 来自控制单元
        .MemorIOtoReg(memoriotoreg),  // 来自控制单元
        .RegDst(regdst),            //  来自控制单元
        .opcplus4(opcplus4),       // 来自取指单元，JAL中用
        //output
        .read_data_1(read_data_1), // 输出的第一操作数
        .read_data_2(read_data_2), // 输出的第二操作数     
        .Sign_extend(sign_extend)// 扩展后的32位立即数          
    );

    control32 control(
        //input
        .Opcode(instruction[31:26]),        // 来自取指单元instruction[31..26]
        .Function_opcode(instruction[5:0]),// 来自取指单元r-类型 instructions[5..0]
        .Alu_resultHigh(alu_result[31:10]),//读操作需要从端口或存储器读数据到寄存器 ?
        //output
        .Jrn(jrn),          // 为1表明当前指令是jr
        .RegDST(regdst),    // 为1表明目的寄存器是rd，否则目的寄存器是rt
        .ALUSrc(alusrc),    // 为1表明第二个操作数是立即数（beq，bne除外）
        .MemorIOtoReg(memoriotoreg),//  为1表明需要从存储器读数据到寄存器   ?
        .RegWrite(regwrite),    //  为1表明该指令需要写寄存器
        .MemRead(memread),      // 为1表示存储器读  ?
        .MemWrite(memwrite),        //  为1表明该指令需要写存储器
        .IORead(ioread),        //  为1表明是I/O读   ?
        .IOWrite(iowrite),      //  为1表明是I/O写  ?
        .Branch(branch),        //  为1表明是Beq指令
        .nBranch(nbranch),      //  为1表明是Bne指令
        .Jmp(jmp),              //  为1表明是J指令
        .Jal(jal),              //  为1表明是Jal指令
        .I_format(i_format),    //  为1表明该指令是除beq，bne，LW，SW之外的其他I-类型指令
        .Sftmd(sftmd),          //  为1表明是移位指令
        .ALUOp(aluop),           //  是R-类型或I_format=1时位1为1, beq、bne指令则位0为1
        .clock(clock),
        .reset(rst),
        .zero(zero),
        .Wpc(wpc),
        .Wir(wir),
        .Waluresult(Waluresult)
    );

    Executs32 execute(
        //input
        .Read_data_1(read_data_1),// 从译码单元的Read_data_1中来
        .Read_data_2(read_data_2),// 从译码单元的Read_data_2中来
        .Sign_extend(sign_extend),// 从译码单元来的扩展后的立即数
        .Function_opcode(instruction[5:0]),// 取指单元来的r-类型指令功能码,r-form instructions[5:0]
        .Exe_opcode(instruction[31:26]),// 取指单元来的操作码
        .ALUOp(aluop),                  // 来自控制单元的运算指令控制编码
        .Shamt(instruction[10:6]),      // 来自取指单元的instruction[10:6]，指定移位次数
        .Sftmd(sftmd),                  // 来自控制单元的，表明是移位指令
        .ALUSrc(alusrc),                 // 来自控制单元，表明第二个操作数是立即数（beq，bne除外）
        .I_format(i_format),            // 来自控制单元，表明是除beq, bne, LW, SW之外的I-类型指令
        .Jrn(jrn),                      // 来自控制单元，书名是JR指令    
        .PC_plus_4(pc_plus_4),           // 来自取指单元的PC+4
        //output
        .Zero(zero),            // 为1表明计算值为0         
        .ALU_Result(alu_result), // 计算的数据结果
        .Add_Result(add_result),// 计算的地址结果      
        .clock(clock),
        .reset(rst),
        .Waluresult(Waluresult)      
     );

    dmemory32 memory(
        //input
        .clock(clock),              //时钟信号，16.67MHz
        .address(address),          //来自memorio模块，源头是来自执行单元算出的alu_result
        .write_data(write_data),    //来自译码单元的read_data2
        .Memwrite(memwrite),        //来自控制单元
        //output
        .read_data(read_data)// 从存储器中获得的数据        
    );
    memorio memio(
        //input
        .caddress(alu_result),     
        .memread(memread),       
        .memwrite(memwrite),        
        .ioread(ioread),       
        .iowrite(iowrite),         
        .mread_data(read_data),    
        .ioread_data(ioread_data),   
        .wdata(read_data_2),        
        //output
        .address(address),           
        .rdata(rdata),          
        .write_data(write_data),  
        .LEDCtrl(ledctrl),        
        .SwitchCtrl(switchctrl) ,   
        .JianpanCtrl(jianpanctrl)
    );
    ioread multiioread(
        .reset(rst),                // 复位信号 
        .ior(ioread),               //  从控制器来的I/O读，
        .switchctrl(switchctrl),    //  从memorio经过地址高端线获得的拨码开关模块片选
        .ioread_data_switch(ioread_data_switch) ,//从外设来的读数据，此处来自拨码开关        
        .ioread_data(ioread_data),  // 将外设来的数据送给memorio
        .jianpanctrl(jianpanctrl),
        .ioread_data_jianpan(yy)
    );
    leds led24(
        //input
        .led_clk(clock),     // 时钟信号
        .ledrst(rst),        // 复位信号
        .ledwrite(iowrite),  // 写信号
        .ledcs(ledctrl),     // 从memorio来的，由低至高位形成的LED片选信号   !!!!!!!!!!!!!!!!!
        .ledaddr(address[1:0]),          //  到LED模块的地址低端  !!!!!!!!!!!!!!!!!!!!
        .ledwdata(write_data[15:0]),     //  写到LED模块的数据，注意数据线只有16根
        //output
        .ledout(led2N4)                  //  向板子上输出的24位LED信号
    );
    switchs switch24(
        //input
        .switclk(clock),            //  时钟信号
        .switrst(rst),              //  复位信号
        .switchread(ioread),             //  读信号
        .switchcs(switchctrl),           //从memorio来的，由低至高位形成的switch片选信号  !!!!!!!!!!!!!!!!!
        .switchaddr(address[1:0]),          //  到switch模块的地址低端  !!!!!!!!!!!!!!!
        .switch_i(switch2N4),               //  从板上读的24位开关数据
        //output
        .switchrdata(ioread_data_switch)   //  送到CPU的拨码开关值注意数据总线只有16根
    );
endmodule
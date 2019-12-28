`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Ifetc32(Instruction,PC_plus_4_out,Add_result,Read_data_1,Jmp,Jal,clock,reset,opcplus4, Wpc, Wir);
    output[31:0] Instruction;			// 输出指令到其他模块
    output[31:0] PC_plus_4_out;         // (pc+4)送执行单元
    input[31:0]  Add_result;            // 来自执行单元,算出的跳转地址
    input[31:0]  Read_data_1;           // 来自译码单元，jr指令用的地址
    //input        Branch;                // 来自控制单元
    //input        nBranch;               // 来自控制单元
    input        Jmp;                   // 来自控制单元
    input        Jal;                   // 来自控制单元
    //input        Jrn;                   // 来自控制单元
    //input        Zero;                  //来自执行单元
    input        clock,reset;           //时钟与复位
    output[31:0] opcplus4;              // JAL指令专用的PC+4
    
    
    wire[31:0]   PC_plus_4;
    reg[31:0]	  PC;
    reg[31:0]    next_PC;               // 下条指令的PC（不一定是PC+4)
    reg[31:0]    opcplus4;
    
    // multi process begin
    input[1:0] Wpc;
    input Wir;
    wire[31:0] ins;
    
    always@(negedge clock) begin 
        if(reset)begin 
            IR<=0;
        end else if(Wir) begin 
            IR<=ins;
        end else begin 
            IR<=IR;
        end 
    end
    
    assign Instruction=IR;
    
    // multi process end
    
    
    
   //分配64KB ROM，编译器实际只用 64KB ROM
    prgrom instmem(
        .clka(clock),         // input wire clka
        .addra(PC[15:2]),     // input wire [13 : 0] addra
        .douta(ins)         // output wire [31 : 0] douta
    );

    assign PC_plus_4[31:2] = PC[31:2]+1'b1;     //  此处＋1实际上是＋4，因为这里低2位始终为00，＋1加在D2位上
    assign PC_plus_4[1:0] = 2'b00;
    assign PC_plus_4_out = IR;  //  PC＋4送到执行单元，以便执行单元在必要的时候算出ADDRESULT

//    always @* begin                          // beq $n ,$m if $n=$m branch   bne if $n /=$m branch
//        if(((Branch == 1) && (Zero == 1 )) || ((nBranch == 1) && (Zero == 0)))
//            next_PC = Add_result;           //  计算出的新PC地址
//        else if(Jrn == 1)
//            next_PC = Read_data_1[31:0];
//        else  next_PC = {2'b00,PC_plus_4[31:2]};// 其他时候都是PC<-PC+4
//    end
    
   always @(negedge clock) begin
     if(reset == 1) begin
         PC <= 32'b00000000000000000000000000000000;
     end else begin
       if((Jmp == 1) || (Jal == 1)) begin   // 这里利用进程内语句的串行关系，在JAL指令执行时，提前保存PC+4到$31
            if(Jal==1) opcplus4 = {2'b00,PC_plus_4[31:2]} ;
                PC[31:0] <= {4'b0000,Instruction[25:0],2'b00};
       end else PC[31:0] <= {next_PC[29:0],2'b00};
     end
   end
   
    always@(negedge clock) begin 
        if(reset)begin 
            next_PC<=32'b0;
        end else begin 
            case(Wpc)
                2'b01: next_PC<={2'b00,PC_plus_4[31:2]};
                2'b10: next_PC<=Read_data_1[31:0];
                2'b11: next_PC = Add_result;
            endcase
        end 
    end
   
endmodule
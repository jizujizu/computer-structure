`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,
                 Shamt,ALUSrc,I_format,Zero,Jrn,Sftmd,ALU_Result,Add_Result,PC_plus_4,
                 clock, reset, Waluresult);
    input[31:0]  Read_data_1;		// 从译码单元的Read_data_1中来
    input[31:0]  Read_data_2;		// 从译码单元的Read_data_2中来
    input[31:0]  Sign_extend;		// 从译码单元来的扩展后的立即数
    input[5:0]   Function_opcode;  	// 取指单元来的r-类型指令功能码,r-form instructions[5:0]
    input[5:0]   Exe_opcode;  		// 取指单元来的操作码
    input[1:0]   ALUOp;             // 来自控制单元的运算指令控制编码
    input[4:0]   Shamt;             // 来自取指单元的instruction[10:6]，指定移位次数
    input  		 Sftmd;            // 来自控制单元的，表明是移位指令
    input        ALUSrc;            // 来自控制单元，表明第二个操作数是立即数（beq，bne除外）
    input        I_format;          // 来自控制单元，表明是除beq, bne, LW, SW之外的I-类型指令
    input        Jrn;               // 来自控制单元，书名是JR指令
    output       Zero;              // 为1表明计算值为0 
    output[31:0] ALU_Result;        // 计算的数据结果
    output[31:0] Add_Result;		// 计算的地址结果        
    input[31:0]  PC_plus_4;         // 来自取指单元的PC+4
    
    reg[31:0] ALU_Result;
    wire[31:0] Ainput,Binput;
    reg[31:0] Cinput,Dinput;
    reg[31:0] Einput,Finput;
    reg[31:0] Ginput,Hinput;
    reg[31:0] Sinput;
    reg[31:0] ALU_output_mux;
    wire[32:0] Branch_Add;
    wire[2:0] ALU_ctl;
    wire[5:0] Exe_code;
    wire[2:0] Sftm;
    wire Sftmd;
    reg s;
    
    // multi process begin
    
    
    input clock,reset;
    input Waluresult; //写 Aluresult 的信号
    
    always@(negedge clock or posedge reset) begin 
        if(reset) begin 
            ALU_Result=32'h0;
        end else if(Waluresult) begin 
            if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slti(sub)  处理所有SLT类的问题
                ALU_Result = {30'b000000000000000000000000000000,ALU_output_mux[31]};//D31=1 IS neg (LESS)
            else if((ALU_ctl==3'b101) && (I_format==1)) ALU_Result[31:0] = {Binput[15:0],16'b0000000000000000};//lui data
            else if(Sftmd==1) ALU_Result = Sinput; 
            else  ALU_Result = ALU_output_mux[31:0]; //otherwise
        end 
    end
    
    
    // multi process end
    
    
    
    
    assign Sftm = Function_opcode[2:0];   // 实际有用的只有低三位(移位指令）
    assign Exe_code = (I_format==0) ? Function_opcode : {3'b000,Exe_opcode[2:0]};
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0]; //R/LW,SW  sft  else的时候含LW和SW
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];      //24H AND 
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;

    always @* begin  // 6种移位指令
       if(Sftmd)
        case(Sftm[2:0])
            3'b000:Sinput = Binput << Shamt;                    //Sll rd,rt,shamt  00000
            3'b010:Sinput = Binput >> Shamt;                    //Srl rd,rt,shamt  00010
            3'b100:Sinput = Binput << Ainput;                   //Sllv rd,rt,rs 000100
            3'b110:Sinput = Binput >> Ainput;                   //Srlv rd,rt,rs 000110
            3'b011:Sinput = $signed(Binput) >>> Shamt;         //Sra rd,rt,shamt 00011
            3'b111:Sinput = $signed(Binput) >>> Ainput;        //Srav rd,rt,rs 00111
            default:Sinput = Binput;
        endcase
       else Sinput = Binput;
    end
 
//    always @* begin
//        if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slti(sub)  处理所有SLT类的问题
//            ALU_Result = {30'b000000000000000000000000000000,ALU_output_mux[31]};//D31=1 IS neg (LESS)
//        else if((ALU_ctl==3'b101) && (I_format==1)) ALU_Result[31:0] = {Binput[15:0],16'b0000000000000000};//lui data
//        else if(Sftmd==1) ALU_Result = Sinput; 
//        else  ALU_Result = ALU_output_mux[31:0]; //otherwise
//    end
 
    assign Branch_Add = PC_plus_4[31:2] + Sign_extend[31:0];
    assign Add_Result = Branch_Add[31:0];   //算出的下一个PC值已经做了除4处理，所以不需左移16位
 
    always @(ALU_ctl or Ainput or Binput) begin
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput & Binput; //36=24h=>0100(P2=1,OP1=1)
                                                     //CT0=(P0 OR P3) AND OP1=0,CT1=!P2 OR !OP1=0,CT2=(P1 AND OP1)OR OP0=0
            3'b001:ALU_output_mux = Ainput | Binput; //37=25h=>0101(P2=1,P0=1,OP1=1)
                                                     //CT0=(P0 OR P3) AND OP1=[1],CT1=!P2 OR !OP1=0,CT2=(P1 AND OP1)OR OP0=0
            3'b010:ALU_output_mux = Ainput +  Binput;//32=20h=>0000(OP1=1) ADD
                                                     //35=23h=>0011(LW) ct0=0,ct1=1,ct2=0,43=2bh=>1011(SW),ct0=0,ct1=1,ct2=0 
                                                     //CT0=(P0 OR P3) AND OP1=0,CT1=!P2 OR !OP1=[1],CT2=(P1 AND OP1)OR OP0=0
            3'b011:ALU_output_mux = Ainput +  Binput;//33=21h=>0001(P0=1,OP1=1)ADDU
                                                     //CT0=(P0 OR P3) AND OP1=1,CT1=!P2 OR !OP1=[1],CT2=(P1 AND OP1)OR OP0=0
            3'b100:ALU_output_mux = Ainput ^ Binput; //38=26H=10 0110(P1,P2=1,OP1=1)XOR
                                                     //CT0=(P0 OR P3) AND OP1=0,CT1=!P2 OR !OP1=[0],CT2=(P1 AND OP1)OR OP0=1
            3'b101:ALU_output_mux = ~(Ainput | Binput);//39=27H=10 0111(P0-P2=1 OP1=1)NOR
                                                     //CT0=(P0 OR P3) AND OP1=1,CT1=!P2 OR !OP1=[0],CT2=(P1 AND OP1)OR OP0=1
            3'b110:ALU_output_mux = Ainput -  Binput;//34=22H=>0010(P1=1,OP1=1)SUB,BEQ
                                                     //CT0=(P0 OR P3) AND OP1=0,CT1=!P2 OR !OP1=[1],CT2=(P1 AND OP1)OR OP0(BEQ)=1
            3'b111:ALU_output_mux = Ainput -  Binput;//42=2AH=>1010(p3,p1,op1) SLT
                                                     //CT0=(P0 OR P3) AND OP1=1,CT1=!P2 OR !OP1=[1],CT2=(P1 AND OP1)OR OP0=1 [SLT]
            default:ALU_output_mux = 32'h00000000;
        endcase
    end
endmodule

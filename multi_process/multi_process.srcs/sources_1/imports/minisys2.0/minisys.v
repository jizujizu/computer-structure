`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module minisys(rst,clk,led2N4,switch2N4
);//instruction,branch,nbranch,jmp,jal,jrn,zero
    input rst;               //���ϵ�Reset�źţ��͵�ƽ��λ
    input clk;               //���ϵ�100MHzʱ���ź�
    input[23:0] switch2N4;    //���뿪������
    output[23:0] led2N4;      //led������������

    wire branch;
    wire nbranch;
    wire jmp;
    wire jal;
    wire jrn;
    wire zero;    
    wire[31:0] instruction;
    
    wire clock;              //clock: ��Ƶ��ʱ�ӹ���ϵͳ
    wire iowrite,ioread;     //I/O��д�ź�
    wire[31:0] write_data;   //дRAM��IO������
    wire[31:0] rdata;        //��RAM��IO������
    wire[15:0] ioread_data;  //��IO������
    wire[31:0] pc_plus_4;    //PC+4
    wire[31:0] read_data_1;  //
    wire[31:0] read_data_2;  //
    wire[31:0] sign_extend;  //������չ
    wire[31:0] add_result;   //
    wire[31:0] alu_result;   //
    wire[31:0] read_data;    //RAM�ж�ȡ������
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
        .clock(clock), //ʱ���ź�
        .reset(rst),   //��λ�ź�
        .Add_result(add_result),    // ����ִ�е�Ԫ,�������ת��ַ
        .Read_data_1(read_data_1),  // �������뵥Ԫ��jrָ���õĵ�ַ
        //.Branch(branch),        // ���Կ��Ƶ�Ԫ
        //.nBranch(nbranch),      // ���Կ��Ƶ�Ԫ
        .Jmp(jmp),              // ���Կ��Ƶ�Ԫ
        .Jal(jal),              // ���Կ��Ƶ�Ԫ
        //.Jrn(jrn),              // ���Կ��Ƶ�Ԫ
        //.Zero(zero),            //����ִ�е�Ԫ
        //output
        .Instruction(instruction),  // ���ָ�����ģ��
        .PC_plus_4_out(pc_plus_4),  // (pc+4)��ִ�е�Ԫ        
        .opcplus4(opcplus4),         // JALָ��ר�õ�PC+4
        .Wpc(wpc),
        .Wir(wir)
    );

    Idecode32 idecode(
        //input
        .clock(clock),              // ʱ���ź�
        .reset(rst),                //��λ�ź�        
        .Instruction(instruction),// ȡָ��Ԫ����ָ��
        .read_data(rdata),          //  ��DATA RAM or I/O portȡ��������
        .ALU_result(alu_result),    // ��ִ�е�Ԫ��������Ľ������Ҫ��չ��������32λ
        .Jal(jal),                  //  ���Կ��Ƶ�Ԫ��˵����JALָ�� 
        .RegWrite(regwrite),        // ���Կ��Ƶ�Ԫ
        .MemorIOtoReg(memoriotoreg),  // ���Կ��Ƶ�Ԫ
        .RegDst(regdst),            //  ���Կ��Ƶ�Ԫ
        .opcplus4(opcplus4),       // ����ȡָ��Ԫ��JAL����
        //output
        .read_data_1(read_data_1), // ����ĵ�һ������
        .read_data_2(read_data_2), // ����ĵڶ�������     
        .Sign_extend(sign_extend)// ��չ���32λ������          
    );

    control32 control(
        //input
        .Opcode(instruction[31:26]),        // ����ȡָ��Ԫinstruction[31..26]
        .Function_opcode(instruction[5:0]),// ����ȡָ��Ԫr-���� instructions[5..0]
        .Alu_resultHigh(alu_result[31:10]),//��������Ҫ�Ӷ˿ڻ�洢�������ݵ��Ĵ��� ?
        //output
        .Jrn(jrn),          // Ϊ1������ǰָ����jr
        .RegDST(regdst),    // Ϊ1����Ŀ�ļĴ�����rd������Ŀ�ļĴ�����rt
        .ALUSrc(alusrc),    // Ϊ1�����ڶ�������������������beq��bne���⣩
        .MemorIOtoReg(memoriotoreg),//  Ϊ1������Ҫ�Ӵ洢�������ݵ��Ĵ���   ?
        .RegWrite(regwrite),    //  Ϊ1������ָ����Ҫд�Ĵ���
        .MemRead(memread),      // Ϊ1��ʾ�洢����  ?
        .MemWrite(memwrite),        //  Ϊ1������ָ����Ҫд�洢��
        .IORead(ioread),        //  Ϊ1������I/O��   ?
        .IOWrite(iowrite),      //  Ϊ1������I/Oд  ?
        .Branch(branch),        //  Ϊ1������Beqָ��
        .nBranch(nbranch),      //  Ϊ1������Bneָ��
        .Jmp(jmp),              //  Ϊ1������Jָ��
        .Jal(jal),              //  Ϊ1������Jalָ��
        .I_format(i_format),    //  Ϊ1������ָ���ǳ�beq��bne��LW��SW֮�������I-����ָ��
        .Sftmd(sftmd),          //  Ϊ1��������λָ��
        .ALUOp(aluop),           //  ��R-���ͻ�I_format=1ʱλ1Ϊ1, beq��bneָ����λ0Ϊ1
        .clock(clock),
        .reset(rst),
        .zero(zero),
        .Wpc(wpc),
        .Wir(wir),
        .Waluresult(Waluresult)
    );

    Executs32 execute(
        //input
        .Read_data_1(read_data_1),// �����뵥Ԫ��Read_data_1����
        .Read_data_2(read_data_2),// �����뵥Ԫ��Read_data_2����
        .Sign_extend(sign_extend),// �����뵥Ԫ������չ���������
        .Function_opcode(instruction[5:0]),// ȡָ��Ԫ����r-����ָ�����,r-form instructions[5:0]
        .Exe_opcode(instruction[31:26]),// ȡָ��Ԫ���Ĳ�����
        .ALUOp(aluop),                  // ���Կ��Ƶ�Ԫ������ָ����Ʊ���
        .Shamt(instruction[10:6]),      // ����ȡָ��Ԫ��instruction[10:6]��ָ����λ����
        .Sftmd(sftmd),                  // ���Կ��Ƶ�Ԫ�ģ���������λָ��
        .ALUSrc(alusrc),                 // ���Կ��Ƶ�Ԫ�������ڶ�������������������beq��bne���⣩
        .I_format(i_format),            // ���Կ��Ƶ�Ԫ�������ǳ�beq, bne, LW, SW֮���I-����ָ��
        .Jrn(jrn),                      // ���Կ��Ƶ�Ԫ��������JRָ��    
        .PC_plus_4(pc_plus_4),           // ����ȡָ��Ԫ��PC+4
        //output
        .Zero(zero),            // Ϊ1��������ֵΪ0         
        .ALU_Result(alu_result), // ��������ݽ��
        .Add_Result(add_result),// ����ĵ�ַ���      
        .clock(clock),
        .reset(rst),
        .Waluresult(Waluresult)      
     );

    dmemory32 memory(
        //input
        .clock(clock),              //ʱ���źţ�16.67MHz
        .address(address),          //����memorioģ�飬Դͷ������ִ�е�Ԫ�����alu_result
        .write_data(write_data),    //�������뵥Ԫ��read_data2
        .Memwrite(memwrite),        //���Կ��Ƶ�Ԫ
        //output
        .read_data(read_data)// �Ӵ洢���л�õ�����        
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
        .reset(rst),                // ��λ�ź� 
        .ior(ioread),               //  �ӿ���������I/O����
        .switchctrl(switchctrl),    //  ��memorio������ַ�߶��߻�õĲ��뿪��ģ��Ƭѡ
        .ioread_data_switch(ioread_data_switch) ,//���������Ķ����ݣ��˴����Բ��뿪��        
        .ioread_data(ioread_data),  // ���������������͸�memorio
        .jianpanctrl(jianpanctrl),
        .ioread_data_jianpan(yy)
    );
    leds led24(
        //input
        .led_clk(clock),     // ʱ���ź�
        .ledrst(rst),        // ��λ�ź�
        .ledwrite(iowrite),  // д�ź�
        .ledcs(ledctrl),     // ��memorio���ģ��ɵ�����λ�γɵ�LEDƬѡ�ź�   !!!!!!!!!!!!!!!!!
        .ledaddr(address[1:0]),          //  ��LEDģ��ĵ�ַ�Ͷ�  !!!!!!!!!!!!!!!!!!!!
        .ledwdata(write_data[15:0]),     //  д��LEDģ������ݣ�ע��������ֻ��16��
        //output
        .ledout(led2N4)                  //  ������������24λLED�ź�
    );
    switchs switch24(
        //input
        .switclk(clock),            //  ʱ���ź�
        .switrst(rst),              //  ��λ�ź�
        .switchread(ioread),             //  ���ź�
        .switchcs(switchctrl),           //��memorio���ģ��ɵ�����λ�γɵ�switchƬѡ�ź�  !!!!!!!!!!!!!!!!!
        .switchaddr(address[1:0]),          //  ��switchģ��ĵ�ַ�Ͷ�  !!!!!!!!!!!!!!!
        .switch_i(switch2N4),               //  �Ӱ��϶���24λ��������
        //output
        .switchrdata(ioread_data_switch)   //  �͵�CPU�Ĳ��뿪��ֵע����������ֻ��16��
    );
endmodule
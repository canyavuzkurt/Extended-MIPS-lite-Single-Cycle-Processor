module processor;
///Comments that I added starts with /// or /*
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
out2,		//Output of mux with ALUSrc control-mult2
out3,		//Output of mux with MemToReg control-mult3
out4,		//Output of mux with (Branch&ALUZero) control-mult4
out5,		///Output of mux with JCntrl-mult5
out6,		///Output of mux with JRCntrl-mult6
out7,		///Output of mux with JALCntrl-mult7
out9,		///Output of mux with ALUSrcZ-mult9
sum,		//ALU result
extad,	//Output of sign-extend unit
adder1out,	//Output of adder which adds PC and 4-add1
adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
sextad;	//Output of shift left 2 unit

wire [5:0] inst31_26;	//31-26 bits of instruction
wire [4:0] 
inst25_21,	//25-21 bits of instruction
inst20_16,	//20-16 bits of instruction
inst15_11,	//15-11 bits of instruction
out1,		//Write data input of Register File
out8;		///Output of mux with JALCntrl-mult8


wire [15:0] inst15_0;	//15-0 bits of instruction

wire [25:0] inst25_0;	///25-0 bits of instruction

wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [2:0] gout,	//Output of ALU control unit
branch;				///Output of CONTROL unit, now a 3 bit wire.

wire [27:0] jumpaddr;	///jump addr
wire [31:0] finaljumpaddr;	///final jump instruction

wire zout,	//Zero output of ALU
pcsrc,	//Output of AND gate with Branch and ZeroOut inputs
//Control signals ///New signals are aluop3, aluop2, jcntrl, jrcntrl, jalcntrl, alusrcz.
regdest,alusrc,memtoreg,regwrite,memread,memwrite,aluop3,aluop2,aluop1,aluop0,jcntrl,jrcntrl,jalcntrl,alusrcz;

//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

integer i;

// datamemory connections

always @(posedge clk)
//write data to memory
if (memwrite)
begin 
//sum stores address,datab stores the value to be written
datmem[sum[4:0]+3]=datab[7:0];
datmem[sum[4:0]+2]=datab[15:8];
datmem[sum[4:0]+1]=datab[23:16];
datmem[sum[4:0]]=datab[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
 assign inst31_26=instruc[31:26];
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];
 assign inst25_0=instruc[25:0];


// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
always @(posedge clk)///Here, I changed out1 to out8 and out3 to out7
 registerfile[out8]= regwrite ? out7:registerfile[out8];//Write data to register

//read data from memory, sum stores address
assign dpack={datmem[sum[5:0]],datmem[sum[5:0]+1],datmem[sum[5:0]+2],datmem[sum[5:0]+3]};

//multiplexers
//mux with RegDst control
mult2_to_1_5  mult1(out1, instruc[20:16],instruc[15:11],regdest);

//mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab,extad,alusrc);

//mux with MemToReg control
mult2_to_1_32 mult3(out3, sum,dpack,memtoreg);

//mux with (Branch&ALUZero) control
mult2_to_1_32 mult4(out4, adder1out,adder2out,pcsrc);

///mux with JRCntrl for jump instruction
mult2_to_1_32 mult5(out5, out4,finaljumpaddr,jcntrl);

///mux with JRCntrl for jump register instruction
mult2_to_1_32 mult6(out6, out5,dataa,jrcntrl);

///mux with JALCntrl for jal write data
mult2_to_1_32 mult7(out7, out3,adder1out,jalcntrl);

///mux with JALCntrl for jal write reg
mult2_to_1_5 mult8(out8, out1,5'h1f,jalcntrl);

///mux with  ALUSrcZero control
mult2_to_1_32 mult9(out9, out2,32'h0,alusrcz);

// load pc
always @(negedge clk)
pc=out6;

// alu, adder and control logic connections

//ALU unit
alu32 alu1(sum,dataa,out9,zout,gout);

//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);

//Control unit
control cont(instruc[31:26],instruc[5:0],instruc[20:16],regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,
aluop0,aluop1,aluop2,aluop3,jcntrl,jrcntrl,jalcntrl,alusrcz);

//Sign extend unit
signext sext(instruc[15:0],extad);

//ALU control unit
alucont acont(aluop3,aluop2,aluop1,aluop0,instruc[3],instruc[2], instruc[1], instruc[0] ,gout);

//Shift-left 2 unit
shift shift2(sextad,extad);

///shift-left 2 unit for jumpaddress
///This new shift module shifts 26 bit wire to 28bit wire.
shift_26 shiftJump(jumpaddr,inst25_0);

///Pcsrc logical
/*PSRC is a bit complex, but what it does is it gets the branch signal, 
zout from alu and sum’s most significant(sign) bit from alu. 
Than through logical calculations, determines whether it satisfies branch
equations and if it does, allows the branch offset added pc value
to pass through and change programming counter according to it.*/
assign pcsrc=(branch==3'b001 && zout) ||					//BEQ
			 (branch==3'b010 && ~zout) || 					//BNE
			 (branch==3'b011 && (zout || (sum[31]==0))) ||	//BGEZ
			 (branch==3'b100 && ~zout && (sum[31]==0))  ||	//BGTZ
			 (branch==3'b101 && (zout||| (sum[31]==1))) ||	//BLEZ
			 (branch==3'b110 && ~zout && (sum[31]==1));		//BLTZ

///concatanetion for jump instruction
assign finaljumpaddr={adder1out[31:28],jumpaddr[27:0]};	///concatanete jump addr to make it 32 bits.

//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("initDm.dat",datmem); //read Data Memory
$readmemh("initIM.dat",mem);//read Instruction Memory
$readmemh("initReg.dat",registerfile);//read Register File

	for(i=0; i<32; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
pc=0;
#400 $finish;
	
end
initial
begin
clk=0;
//40 time unit for each cycle
forever #20  clk=~clk;
end
initial 
begin
  $monitor($time,"PC %h",pc,"  SUM %h",sum,"   INST %h",instruc[31:0],
"   REGISTER R4:%h R5:%h R6:%h R1:%h R31:%h",registerfile[4],registerfile[5], registerfile[6],registerfile[1],registerfile[31]);
end
endmodule


module control(in,func,branchf,regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop0,aluop1,aluop2,aluop3,jcntrl,jrcntrl,jalcntrl,alusrcz);
input [5:0] 
in,
func;	///For RType inputs, func is necessary to differantiate between jr and others.
input [4:0]
branchf;///bgez and bltz has the same opcode, their branch func is different.
output [2:0] branch;
output regdest,alusrc,memtoreg,regwrite,memread,memwrite,aluop0,aluop1,aluop2,aluop3,jcntrl,jrcntrl,jalcntrl,alusrcz;
wire rformat,lw,sw,beq,bneq,bgez,bgtz,blez,bltz,andi,ori,jump,jr;	
		
//Signal table is given in the report.
assign jr=~|in & 												//000000 and func code is 001000
		  ((~func[5])& (~func[4])&func[3]&(~func[2])&(~func[1])&(~func[0]));
assign rformat=~|in & ~jr;										//000000 and not jr
assign lw=in[5]& (~in[4])&(~in[3])&(~in[2])&in[1]&in[0];		//100011
assign sw=in[5]& (~in[4])&in[3]&(~in[2])&in[1]&in[0];			//101011
assign beq=~in[5]& (~in[4])&(~in[3])&in[2]&(~in[1])&(~in[0]);	//000100
assign bneq=~in[5]& (~in[4])&(~in[3])&in[2]&(~in[1])&in[0];		//000101
assign bgez=~in[5]& (~in[4])&(~in[3])&(~in[2])&(~in[1])&in[0]&	//000001 16th bit 1
			branchf[0];	
assign bgtz=~in[5]& (~in[4])&(~in[3])&in[2]&in[1]&in[0];		//000111
assign blez=~in[5]& (~in[4])&(~in[3])&in[2]&in[1]&(~in[0]);		//000110
assign bltz=~in[5]& (~in[4])&(~in[3])&(~in[2])&(~in[1])&in[0]&	//000001 16th bit 0
			(~branchf[0]);
assign addi=~in[5]& (~in[4])&in[3]&(~in[2])&(~in[1])&(~in[0]); 	//001000
assign andi=~in[5]& (~in[4])&in[3]&in[2]&(~in[1])&(~in[0]);		//001100
assign ori=~in[5]& (~in[4])&in[3]&in[2]&(~in[1])&in[0];			//001101
assign jump=~in[5]& (~in[4])&(~in[3])&(~in[2])&in[1]&(~in[0]);	//000010
assign jal=~in[5]& (~in[4])&(~in[3])&(~in[2])&in[1]&in[0];		//000011

assign regdest=rformat;
assign alusrc=lw|sw|addi|andi|ori;
assign memtoreg=lw;
assign regwrite=rformat|lw|addi|andi|ori|jal;
assign memread=lw;
assign memwrite=sw;
//			beq	bne	bgez bgtz blez bltz
//branch	001	010	 011  100  101  110
assign branch[2]=bgtz|blez|bltz;
assign branch[1]=bneq|bgez|bltz;
assign branch[0]=beq|bgez|blez;
assign aluop0=rformat;
assign aluop1=beq|bneq|bgez|bgtz|blez|bltz;
assign aluop2=andi;
assign aluop3=ori;
assign jcntrl=jump|jal;
assign jrcntrl=jr;
assign jalcntrl=jal;
assign alusrcz=bgez|bgtz|bltz;
endmodule

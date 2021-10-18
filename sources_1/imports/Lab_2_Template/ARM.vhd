----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: ARM
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: ARM Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: The interface (entity) SHOULD NOT be modified. The implementation (architecture) can be modified
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v)	acknowledge that the program was written based on the microarchitecture described in the book Digital Design and Computer Architecture, ARM Edition by Harris and Harris;
--		(vi) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vii) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------

-- R15 is not stored
-- Save waveform file and add it to the project
-- Reset and launch simulation if you add interal signals to the waveform window

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_unsigned.all;

entity ARM is port(
			CLK			: in 	std_logic;
			RESET		: in 	std_logic;
			--Interrupt	: in	std_logic;  -- for optional future use
			Instr		: in 	std_logic_vector(31 downto 0);
			ReadData	: in 	std_logic_vector(31 downto 0);
			MemWrite	: out	std_logic;
			PC			: out	std_logic_vector(31 downto 0);
			ALUResult	: out 	std_logic_vector(31 downto 0);
			WriteData	: out 	std_logic_vector(31 downto 0)
			);
end ARM;

architecture ARM_arch of ARM is

component RegFile is port(
			CLK			: in	std_logic;
			WE3			: in	std_logic;
			A1			: in	std_logic_vector(3 downto 0);
			A2			: in	std_logic_vector(3 downto 0);
			A3			: in	std_logic_vector(3 downto 0);
			WD3			: in	std_logic_vector(31 downto 0);
			R15			: in 	std_logic_vector(31 downto 0);
			RD1			: out	std_logic_vector(31 downto 0);
			RD2			: out	std_logic_vector(31 downto 0)
			);
end component RegFile;			

component Extend is port(
			ImmSrc		: in	std_logic_vector(1 downto 0);
			InstrImm		: in	std_logic_vector(23 downto 0);
			ExtImm		: out	std_logic_vector(31 downto 0)
			);
end component Extend;

component Decoder is port(
			Rd			: in 	std_logic_vector(3 downto 0);
			Op			: in 	std_logic_vector(1 downto 0);
			Funct		: in 	std_logic_vector(5 downto 0);
			extspace    : in    std_logic_vector(3 downto 0);
			PCS			: out	std_logic;
			RegW		: out	std_logic;
			MemW		: out	std_logic;
			MemtoReg	: out	std_logic;
			ALUSrc		: out	std_logic;
			ImmSrc		: out	std_logic_vector(1 downto 0);
			RegSrc		: out	std_logic_vector(1 downto 0);
			NoWrite		: out	std_logic;
			ALUControl	: out	std_logic_vector(1 downto 0);
			FlagW		: out	std_logic_vector(1 downto 0);
			start       : out std_logic; 
			MCycleOp    : out std_logic_vector(1 downto 0)
			);
end component Decoder;

component CondLogic is port(
			CLK			: in	std_logic;
			PCS			: in	std_logic;
			RegW		: in	std_logic;
			NoWrite		: in	std_logic;
			MemW		: in	std_logic;
			FlagW		: in	std_logic_vector(1 downto 0);
			Cond		: in	std_logic_vector(3 downto 0);
			ALUFlags	: in	std_logic_vector(3 downto 0);
			PCSrc		: out	std_logic;
			RegWrite	: out	std_logic;
			MemWrite	: out	std_logic
			);
end component CondLogic;

component Shifter is port(
			Sh			: in	std_logic_vector(1 downto 0); 
			Shamt5		: in	std_logic_vector(4 downto 0);
			ShIn		: in	std_logic_vector(31 downto 0);
			ShOut		: out	std_logic_vector(31 downto 0)		
			);
end component Shifter;
								
component ALU is port(
			Src_A		: in 	std_logic_vector(31 downto 0);
			Src_B		: in 	std_logic_vector(31 downto 0);
			ALUControl	: in	std_logic_vector(1 downto 0);
			ALUResult	: out 	std_logic_vector(31 downto 0);
			ALUFlags	: out 	std_logic_vector(3 downto 0)
			);
end component ALU;
			
component ProgramCounter is port(
			CLK			: in	std_logic;
			RESET		: in 	std_logic;
			WE_PC		: in	std_logic; -- write enable
			PC_IN		: in	std_logic_vector(31 downto 0);
			PC			: out	std_logic_vector(31 downto 0)
			);
end component ProgramCounter;

--MCycle signals
signal Mcycle_wire :std_logic; 
signal extspace :std_logic_vector(3 downto 0); --:=instr(7 downto 4); 
signal Start	: STD_LOGIC;-- Multi-cycle Enable. The control unit should assert this when an instruction with a multi-cycle operation is detected.
signal MCycleOp	: 	STD_LOGIC_VECTOR (1 downto 0); -- Multi-cycle Operation. "00" for signed multiplication, "01" for unsigned multiplication, "10" for signed division, "11" for unsigned division.
signal Operand1	: 	STD_LOGIC_VECTOR (32-1 downto 0); -- Multiplicand / Dividend
signal Operand2	: 	STD_LOGIC_VECTOR (32-1 downto 0); -- Multiplier / Divisor
signal Result1	: 	STD_LOGIC_VECTOR (32-1 downto 0); -- LSW of Product / Quotient
signal Result2	: 	STD_LOGIC_VECTOR (32-1 downto 0); -- MSW of Product / Remainder
signal Busy		: 	STD_LOGIC;  -- Set immediately when Start is set. Cleare


-- RegFile signals
-- signal CLK		: 	std_logic; 
signal WE3			: 	std_logic; 
signal A1			: 	std_logic_vector(3 downto 0); 
signal A2			: 	std_logic_vector(3 downto 0); 
signal A3			: 	std_logic_vector(3 downto 0); 
signal WD3			: 	std_logic_vector(31 downto 0); 
signal R15			: 	std_logic_vector(31 downto 0); 
signal RD1			: 	std_logic_vector(31 downto 0); 
signal RD2			: 	std_logic_vector(31 downto 0);
           
-- Extend signals
signal ImmSrc		:	std_logic_vector(1 downto 0);
signal InstrImm		:	std_logic_vector(23 downto 0);
signal ExtImm		:	std_logic_vector(31 downto 0);

-- Decoder signals
signal Rd			:	std_logic_vector(3 downto 0);
signal Op			:	std_logic_vector(1 downto 0);
signal Funct		:	std_logic_vector(5 downto 0);
-- signal PCS			:	std_logic;
-- signal RegW			:	std_logic;
-- signal MemW		:	std_logic;
signal MemtoReg		:	std_logic;
signal ALUSrc		:	std_logic;
-- signal ImmSrc	:	std_logic_vector(1 downto 0);
signal RegSrc		:	std_logic_vector(1 downto 0);

-- signal NoWrite	:	std_logic;
-- signal ALUControl:	std_logic_vector(1 downto 0);
-- signal FlagW		:	std_logic_vector(1 downto 0);

-- CondLogic signals
-- signal CLK		: 	std_logic;
signal PCS			: 	std_logic;
signal RegW			: 	std_logic;
signal NoWrite		: 	std_logic;
signal MemW			: 	std_logic;
signal FlagW		: 	std_logic_vector(1 downto 0);
signal Cond			: 	std_logic_vector(3 downto 0);
-- signal ALUFlags	: 	std_logic_vector(3 downto 0);
signal PCSrc		: 	std_logic;
signal RegWrite		: 	std_logic;
-- signal MemWrite	: 	std_logic;

-- Shifter signals
signal Sh			: 	std_logic_vector(1 downto 0); 
signal Shamt5		: 	std_logic_vector(4 downto 0);
signal ShIn			: 	std_logic_vector(31 downto 0);
signal ShOut		: 	std_logic_vector(31 downto 0);	
								
-- ALU signals
signal ALUModuleRes : std_logic_vector(31 downto 0); 
signal Src_A		: 	std_logic_vector(31 downto 0);
signal Src_B		: 	std_logic_vector(31 downto 0);
signal ALUControl	: 	std_logic_vector(1 downto 0);
signal ALUResult_sig	: 	std_logic_vector(31 downto 0); -- name for internal signal -> output can't be read
signal ALUFlags		: 	std_logic_vector(3 downto 0);

--ProgramCounter signals
-- signal CLK		:	std_logic;			
signal WE_PC		:	std_logic; -- write enable	
-- signal RESET		: 	std_logic;		
signal PC_IN		:	std_logic_vector(31 downto 0);			
signal PC_sig		:	std_logic_vector(31 downto 0);  -- name for internal signal -> output can't be read

-- Other internal signals
signal PCPlus4		: 	std_logic_vector(31 downto 0);
signal PCPlus8		: 	std_logic_vector(31 downto 0);
signal Result		: 	std_logic_vector(31 downto 0);	

begin

--<Datapath connections here>
--Mcycle signal 
--Operand1<=RD1;
--Operand2<=RD2; 
--Mcycle_wire <='1' when (Instr(27 downto 24)="0000" and Instr(7 downto 4)="1001") else '0'; 
--extspace <=Instr(7 downto 4); 

--Shifter Logic 
ShIn<=RD2; 
Shamt5<=Instr(11 downto 7);
Sh<= Instr(6 downto 5); 

--RegFile Logic
A1 <= Instr(19 downto 16) when RegSrc(0)='0' else "1111"; 
A2 <= Instr(3 downto 0) when RegSrc(1)='0' else Instr(15 downto 12);
A3 <= Instr(15 downto 12); 

WriteData<=RD2; 
WD3<=Result;
WE3 <=RegWrite; 
--rf_block: RegFile port map(CLK,WE3,A1,A2,A3,WD3,R15,RD1,RD2);

--Extend Logic
InstrImm<= Instr(23 downto 0); 
--extend_block: Extend port map (ImmSrc,InstrImm,ExtImm);

--ALU Logic
Src_B <= ShOut when ALUSrc='0' else ExtImm;
Src_A<=RD1; 
--alu_block: ALU port map(Src_A,Src_B,ALUControl,ALUResult,ALUFlags); 
--ALUModuleRes <= ALUResult_sig; 
--ALUResult <= Result1 when Mcycle_wire='1' else ALUModuleRes;
 
Result <= ALUResult_sig when MemtoReg='0' else ReadData;
WE_PC  <= '1'; -- Will need to control it for multi-cycle operations (Multiplication, Division) and/or Pipelining with hazard hardware.


--Decoder Logic 
Cond<= Instr(31 downto 28);
Op <= Instr(27 downto 26);
Funct <= Instr(25 downto 20);
Rd <= Instr(15 downto 12);

-- Port maps 
RegFile1 :RegFile port map(
CLK			=>  	CLK  	,
WE3			=>  	WE3  	,
A1			=>  	A1	 	,
A2			=>  	A2	 	,
A3			=>  	A3	 	,
WD3			=>  	WD3  	,
R15			=>  	R15  	,
RD1			=>  	RD1  	,
RD2			=>  	RD2	
			);
		
Extend1 :Extend port map(
ImmSrc		=>	ImmSrc		,
InstrImm	=>  InstrImm	,
ExtImm		=>  ExtImm
			);
			
Decoder1 : Decoder port map(
Rd			=>	Rd			,
Op			=>	Op			,
Funct		=>	Funct		,
PCS			=>	PCS			,
extspace    =>  extspace    , 
RegW		=>	RegW		,
MemW		=>	MemW		,
MemtoReg	=>	MemtoReg	,
ALUSrc		=>	ALUSrc		,
ImmSrc		=>	ImmSrc		,
RegSrc		=>	RegSrc		,
NoWrite		=>	NoWrite		,
ALUControl	=>	ALUControl	,
FlagW		=>	FlagW       ,
Start       =>  start 
			);
			
CondLogic1: CondLogic port map (
CLK			=>	CLK			,	
PCS		    =>  PCS		    ,
RegW		=>  RegW	    ,
NoWrite	    =>  NoWrite	    ,
MemW		=>  MemW	    ,
FlagW	    =>  FlagW	    ,
Cond		=>  Cond	    ,
ALUFlags	=>  ALUFlags    ,
PCSrc	    =>  PCSrc	    ,
RegWrite	=>  RegWrite    ,
MemWrite	=>  MemWrite
			);

Shifter1 : Shifter port map (
Sh			=>	Sh			,
Shamt5		=>	Shamt5		,	
ShIn		=>	ShIn		,	
ShOut		=>	ShOut
			);
			
ALU1 : ALU port map(
Src_A		=>	Src_A		,	
Src_B		=>	Src_B		,
ALUControl	=>	ALUControl	,
ALUResult	=>	ALUResult_sig	,
ALUFlags	=>	ALUFlags
			);

ProgramCounter1 : ProgramCounter port map(			
CLK			=>	CLK			,
RESET		=>	RESET		,
WE_PC		=>	WE_PC	    ,
PC_IN   	=>	PC_IN       ,
PC			=>	PC_sig
			);

-- Next PC Logic 
R15<=PCPlus8; 
PCPlus4 <= PC_sig+X"00000004";
PCPlus8 <= PCPlus4+X"00000004";
PC<=PC_sig; 
PC_IN <= PCPlus4 when PCSrc='0' else Result;
--pc_block : ProgramCounter port map(CLK,RESET,WE_PC,PC_IN,PC_sig);

end ARM_arch;
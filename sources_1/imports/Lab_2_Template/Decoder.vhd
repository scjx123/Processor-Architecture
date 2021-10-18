----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Decoder Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Decoder is port(
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
end Decoder;

architecture Decoder_arch of Decoder is
	signal ALUOp 			: std_logic_vector(1 downto 0);
	signal Branch 			: std_logic;
	signal internal_regw    : std_logic; 
	--<extra signals, if any>
begin
-- Main purpose of decode is part of the control unit 
--Decoder Logic can be split into 3 parts 
-- PC LOGIC --
process(Rd,internal_regw, Branch)
 begin 
  if Rd = b"1111" then 
   if ('1' and internal_regw)='1' or Branch ='1' then 
    PCS <= '1' ; 
   end if;
  else
   PCS<='0';
  end if; 
 end process; 

-- MAIN DECODER -- 
 process(op,Funct(5),Funct(0))
	begin
	    Branch <= '0'; 
	    MemW <= '0'; 
	    MemtoReg <='0'; 
	    ALUSrc<= '1';
	    ALUOp<="00";
		case op is
			when "00" => ----------------------DP INSTRUCTION---------------------
			 IMMSrc <=b"00"; 
              RegW <= '1';
              internal_regw <='1'; 
              RegSrc<=b"00";  
              ALUOp <= "01"; 						
			 if Funct(5) = '0' then 
			  --DP IMM instruction 
			  ALUSrc<='0'; 
			 end if;
			when "01" =>----------------------MEMORY INSTRUCTION---------------------
			  ALUOp <= "10"; 
			  IMMSrc<=b"01"; 
			  Branch <='0';
			  if Funct(0) = '0' then --STR Instruciton 
			   MemW<='1';
			   RegW<='0';
			   RegSrc<="10";
			  else -- LDR instruction 
			    RegW <= '1'; 
			    internal_regw <='1'; 
			    RegSrc<=b"00";
			    MemtoReg<='1'; 
			 end if; 
			when "10" =>---------------------BRANCH INSTRUCTION------------------------
			 Branch <='1'; 
			 MemW<='0';
			 IMMSrc <= b"10"; 
			 RegW <='0'; 
			 internal_regw <='0'; 
			 RegSrc <=b"01"; 
			when others =>
			
		end case;
	end process;
	
Start <= '1' when extspace="1001" and Op="00" and Funct(5 downto 4)="00" else '0'; 

-- ALU DECODER -- 
 process(ALUOp, Funct(4 downto 1),Funct(0))
	begin
	 if ALUOp = "01" then 
	      NoWrite<='0'; 
        case Funct(4 downto 1) is
                when "0100" =>  -- ADD 
                 ALUControl <= b"00";  
                 if Funct(0) = '0' then 
                  FlagW <= b"00"; 
                 else
                  FlagW<= b"11"; 
                 end if; 
                when "0010" =>  --SUB
                 ALUControl <= b"01";  
                 if Funct(0) = '0' then 
                  FlagW <= b"00"; 
                 else
                  FlagW<= b"11"; 
                 end if; 
                when "0000" =>  --AND
                 ALUControl <= b"10";  
                 if Funct(0) = '0' then 
                  FlagW <= b"00"; 
                 else
                  FlagW<= b"10"; 
                 end if; 
                when "1100" =>  --ORR
                 ALUControl <= b"11";  
                 if Funct(0) = '0' then 
                  FlagW <= b"00"; 
                 else
                  FlagW<= b"10"; 
                 end if; 
                when "1010" =>  --CMP
                  NoWrite <= '1'; 
                  ALUControl <= b"01";  
                  FlagW <= "11";
                when "1011" =>  --CMN
                  NoWrite <= '1'; 
                  ALUControl <= b"00";  
                  FlagW <= b"11"; 
                when "1101" =>  --MOV
                 NoWrite <= '0'; 
                  ALUControl <= b"00";  
                 if Funct(0) = '0' then 
                  FlagW <= b"00"; 
                 else
                  FlagW<= b"11";  
                 end if; 
                when others =>
            end case;
	  
	 elsif ALUOp = "10" then 
	  if Funct(3) = '0' then 
	  ALUControl <= b"01";  
	  else ALUControl <= b"00"; 
	   end if;
      FlagW<= b"11"; 
	 else 
	  ALUControl<= "00";
	 end if; 
	end process;

end Decoder_arch;
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/17/2021 03:46:51 PM
-- Design Name: 
-- Module Name: test_decoder - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_decoder is
--  Port ( );
end test_decoder;

architecture Behavioral of test_decoder is
component decoder is 
 Port (Rd			: in 	std_logic_vector(3 downto 0);
			Op			: in 	std_logic_vector(1 downto 0);
			Funct		: in 	std_logic_vector(5 downto 0);
			PCS			: out	std_logic;
			RegW		: out	std_logic;
			MemW		: out	std_logic;
			MemtoReg	: out	std_logic;
			ALUSrc		: out	std_logic;
			ImmSrc		: out	std_logic_vector(1 downto 0);
			RegSrc		: out	std_logic_vector(1 downto 0);
			NoWrite		: out	std_logic;
			ALUControl	: out	std_logic_vector(1 downto 0);
			FlagW		: out	std_logic_vector(1 downto 0)); 
end component; 
signal op:STD_LOGIC_VECTOR(1 downto 0); 
signal funct:std_logic_vector(5 downto 0);
signal rd:	std_logic_vector(3 downto 0);
signal	PCS,RegW,MemW,MemtoReg,ALUSrc,NoWrite:std_logic; 
signal ImmSrc,RegSrc,ALUControl,FlagW: std_logic_vector(1 downto 0);
begin

dut : decoder port map(rd,op,funct,PCS,RegW,MemW,MemtoReg,ALUSrc,ImmSrc,RegSrc,NoWrite,ALUControl,FlagW); 

--Stimuli 
process 
 begin 
  wait for 10ns; rd<=b"0000"; op<=b"00";  funct<=b"000000";
   wait for 20ns; rd<=b"1111"; op<=b"00";  funct<=b"100000";
    wait for 50ns; rd<=b"0000"; op<=b"01";  funct<=b"000000";
     wait for 80ns; rd<=b"0000"; op<=b"01";  funct<=b"010000";
     wait for 80ns; rd<=b"0000"; op<=b"10";  funct<=b"000000";
     wait for 500ns; 
  
 end process; 
  

end Behavioral;

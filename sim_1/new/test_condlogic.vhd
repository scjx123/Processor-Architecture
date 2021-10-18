----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2021 02:39:55 PM
-- Design Name: 
-- Module Name: test_condlogic - Behavioral
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

entity test_condlogic is
--  Port ( );
end test_condlogic;

architecture Behavioral of test_condlogic is
component CondLogic is 
 Port (	CLK			: in	std_logic;
			PCS			: in	std_logic;
			RegW		: in	std_logic;
			NoWrite		: in	std_logic;
			MemW		: in	std_logic;
			FlagW		: in	std_logic_vector(1 downto 0);
			Cond		: in	std_logic_vector(3 downto 0);
			ALUFlags	: in	std_logic_vector(3 downto 0);
			PCSrc		: out	std_logic;
			RegWrite	: out	std_logic;
			MemWrite	: out	std_logic);
end component; 
signal CLK,PCS,RegW, NoWrite,MemW,PCSrc,RegWrite,MemWrite:std_logic; 
signal FlagW :std_logic_vector (1 downto 0) ; 
signal Cond: std_logic_vector(3 downto 0); 
signal ALUFlags: std_logic_vector(3 downto 0); 

constant CLK_PERIOD: time := 10ns;

begin
dut : CondLogic port map(CLK,PCS,RegW,NoWrite,MemW,FlagW,Cond,ALUFlags,PCSrc,RegWrite,MemWrite); 

PCS<='1' ;
RegW<='1';
MemW<='1'; 
NoWrite<='1';
FlagW<=b"11"; 

--Stimuli 
process
 begin 
  Cond<=b"1110"; ALUFlags<=b"1111"; wait for 10*CLK_PERIOD;--Start with ADDEQ 
  Cond<=b"0000"; ALUFlags<=b"0000"; wait for 2*CLK_PERIOD;
  wait; 
 end process; 

-- Generate Clock 
process 
 begin
  clk<='0'; 
  wait for CLK_PERIOD/2; 
  clk<='1'; 
  wait for CLK_PERIOD/2; 
 end process; 
end Behavioral;

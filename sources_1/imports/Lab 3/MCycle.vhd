----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: Rajesh Panicker
-- 
-- Create Date: 10/13/2015 06:49:10 PM
-- Module Name: ALU
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Multicycle Operations Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	(c) Rajesh Panicker
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------

-- Assume that Operand1, Operand 2, MCycleOp will not change after Start is asserted until the next clock edge after Busy goes to '0'.
-- Start to be asserted by the control unit should assert this when an instruction with a multi-cycle operation is detected. 
-- Start should be deasserted within 1 clock cycle after Busy goes low. Else, the MCycle unit will treat it as another operation.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.ALL;


entity MCycle is
generic (width 	: integer := 32); -- Keep this at 4 to verify your algorithms with 4 bit numbers (easier). When using MCycle as a component in ARM, generic map it to 32.
Port (CLK		: in	STD_LOGIC;
		RESET		: in 	STD_LOGIC;  -- Connect this to the reset of the ARM processor.
		Start		: in 	STD_LOGIC;  -- Multi-cycle Enable. The control unit should assert this when an instruction with a multi-cycle operation is detected.
		MCycleOp	: in	STD_LOGIC_VECTOR (1 downto 0); -- Multi-cycle Operation. "00" for signed multiplication, "01" for unsigned multiplication, "10" for signed division, "11" for unsigned division.
		Operand1	: in	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplicand / Dividend
		Operand2	: in	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplier / Divisor
		Result1	: out	STD_LOGIC_VECTOR (width-1 downto 0); -- LSW of Product / Quotient
		Result2	: out	STD_LOGIC_VECTOR (width-1 downto 0); -- MSW of Product / Remainder
		Busy		: out	STD_LOGIC);  -- Set immediately when Start is set. Cleared when the Results become ready. This bit can be used to stall the processor while multi-cycle operations are on.
end MCycle;


architecture Arch_MCycle of MCycle is

type states is (IDLE, COMPUTING); 
signal state, n_state 	: states := IDLE;
signal done 	: std_logic;

begin

IDLE_PROCESS : process (state, done, Start, RESET)
begin

-- <default outputs>
Busy <= '0';
n_state <= IDLE;

--reset
if RESET = '1' then
	n_state <= IDLE;
	--Busy <= '0';	--implicit
else
	case state is
		when IDLE =>
			if Start = '1' then
				n_state <= COMPUTING;
				Busy <= '1';
			end if;
		when COMPUTING => 
			if done = '1' then
				n_state <= IDLE;
				--Busy <= '0'; --implicit
			else
				n_state <= COMPUTING;
				Busy <= '1';
			end if;
	end case;
end if;	
end process;

COMPUTING_PROCESS : process (CLK) -- process which does the actual computation
variable count : std_logic_vector(7 downto 0) := (others => '0'); -- assuming no computation takes more than 256 cycles.
variable temp_sum : std_logic_vector(2*width-1 downto 0) := (others => '0');
variable shifted_op1 : std_logic_vector(2*width-1 downto 0) := (others => '0');
variable shifted_op2 : std_logic_vector(2*width-1 downto 0) := (others => '0');
variable quotient: std_logic_vector(width-1 downto 0):= (others =>'0'); 
variable NOT_m,m,r:std_logic_vector(width-1 downto 0):=(others=>'0'); 
variable A :std_logic_vector(2*width+1 downto 0):=(others=>'0');
variable S :std_logic_vector(2*width+1 downto 0):= (others =>'0');
variable P :std_logic_vector(2*width+1 downto 0):= (others =>'0');
begin  
   if (CLK'event and CLK = '1') then 
   			-- n_state = COMPUTING and state = IDLE implies we are just transitioning into COMPUTING
		if RESET = '1' or (n_state = COMPUTING and state = IDLE) then
			count := (others => '0');
			temp_sum := (others => '0');
			quotient := (others=>'0');
			shifted_op1 := (2*width-1 downto width => not(MCycleOp(0)) and Operand1(width-1)) & Operand1;					
			shifted_op2 := (2*width-1 downto width => not(MCycleOp(0)) and Operand2(width-1)) & Operand2;
			  if MCycleOp="00" then 
                    m := Operand1;
                    NOT_m:=(not m) +1; 
                    r := Operand2; 
                    A := m(width-1)& m & (width downto 0=>'0');
                    S := not(m(width-1))& NOT_m &(width downto 0=>'0');
                    P := (2*width+1 downto width+1=>'0') & r &"0";
                end if; 
		    if MCycleOp="10" then
             if Operand1(3) ='0' and Operand2(3) = '0' then
              shifted_op1 := (2*width-1 downto 32 =>'0') & Operand1;
		      shifted_op2 := Operand2 & (2*width-1 downto 32 =>'0');
             elsif Operand1(3) ='0' and Operand2(3) = '1' then
              shifted_op1 := (2*width-1 downto 32 =>'0') & Operand1;
              shifted_op2 := (NOT Operand2 +1) & (2*width-1 downto 32 =>'0');     
             elsif Operand1(3) ='1' and Operand2(3) = '0' then
              shifted_op1 := (2*width-1 downto 32 =>'0') & (NOT Operand1 +1);
              shifted_op2 :=  Operand2 & (2*width-1 downto 32 =>'0');  
		     elsif Operand1(3) ='1' and Operand2(3) = '1' then
		      shifted_op1 := (2*width-1 downto 32 =>'0') & (NOT Operand1 +1);
              shifted_op2 :=  (NOT Operand2 +1) &(2*width-1 downto 32 =>'0');       
		     end if; 
		    elsif MCycleOp="11" then 
		      shifted_op1 := (2*width-1 downto 32 =>'0')& Operand1;
		      shifted_op2 := Operand2 & (2*width-1 downto 32 =>'0');
		    end if; 
		end if;
		done <= '0';			

		if MCycleOp(1)='0' then -- Multiply
		-- MCycleOp(0) = '0' takes 2*'width' cycles to execute, returns signed(Operand1)*signed(Operand2)
		-- MCycleOp(0) = '1' takes 'width' cycles to execute, returns unsigned(Operand1)*unsigned(Operand2)		
			if MCycleOp(0) ='1' then --UNSIGNED MULTIPLICATION 
                if shifted_op2(0)= '1' then -- add only if b0 = 1
                    temp_sum := temp_sum + shifted_op1;
                end if;
                shifted_op2 := '0'& shifted_op2(2*width-1 downto 1); --B 
                shifted_op1 := shifted_op1(2*width-2 downto 0)&'0';	--A
                
                if (MCycleOp(0)='1' and count=width-1) then	 -- last cycle?
                    done <= '1';	
                end if;				
                count := count+1;
            elsif MCycleOp(0) ='0' then 
                case P(1 downto 0) is
                 when "10" =>
                  P:=P+S;
                  P:=P(2*width+1)&P(2*width+1 downto 1); 
                 when "01" =>
                  P:=P+A;
                  P:=P(2*width+1)&P(2*width+1 downto 1); 
                 when others =>
                  P:=P(2*width+1)&P(2*width+1 downto 1); 
                end case; 
                count := count+1;
                if count = 5 then 
                    done<='1'; 
                end if; 
                
			end if; 
		else -- Supposed to be Divide. The dummy code below takes 1 cycle to execute, just returns the operands. Change this to signed [MCycleOp(0) = '0'] and unsigned [MCycleOp(0) = '1'] division.
			--temp_sum(2*width-1 downto width) := Operand1;  -- dividend/remainder 
			--temp_sum(width-1 downto 0) := Operand2;         -- divisor 
		    
		    --DIVISION ALGORITHM 
		    temp_sum := shifted_op1 - shifted_op2; 
		    if (signed(temp_sum) >=0 and MCycleOp(0)='0') or (unsigned(shifted_op2)<=unsigned(shifted_op1) and MCycleOp(0)='1')then 
		     shifted_op1 := temp_sum;
		     quotient := quotient(2 downto 0) & '1';
		    else
		    quotient := quotient(2 downto 0) & '0';
		    end if;      
		     shifted_op2:= '0' & shifted_op2(2*width-1 downto 1); 
           
           --TERMINATING CONDITION 
            if count=5 then 
             done<='1';
            end if; 
--			if (MCycleOp(0)='1' and count=width-1) or (MCycleOp(0)='0' and count=2*width-1) then	 -- last cycle?
--				done <= '1';	
--			end if;				
			count := count+1;
		end if;
		
		if McycleOp(1) = '0' then 
		    if MCycleOp(0)='0' then 
		        Result1 <= P(2*width downto width+1);
		        Result2 <=P(width downto 1);  
		        --Result2 <= temp_sum(2*width-1 downto width);
                --Result1 <= temp_sum(width-1 downto 0);
		    else
                Result2 <= temp_sum(2*width-1 downto width);
                Result1 <= temp_sum(width-1 downto 0);
		    end if; 
		else 
            if MCycleOp(0)='0' then	--CORRECTING SIGNS FOR SIGNED DIVISION 
               --FOR QUOTIENT (RESULT1)  --DIFFERENT OPERAND SIGN 
               if Operand1(3)/= Operand2(3) then  
                 Result1<=not quotient+1; 
                 --Result1<= (width-1 =>not quotient(3)) & quotient(2 downto 0);  
               else 
                Result1<= quotient;
               end if;
               
               if Operand1(3) /= shifted_op1(width-1) then 
                Result2 <= not shifted_op1(width-1 downto 0) + 1;  
               else
                Result2 <= shifted_op1(width-1 downto 0);  
               end if; 
            else
             --Result1 <= temp_sum(2*width-1 downto width); 
             Result1 <= quotient; 
             Result2 <= shifted_op1(width-1 downto 0);  
	        end if; 
	     end if; 
	end if;
end process;

STATE_UPDATE_PROCESS : process (CLK) -- state updating
begin  
   if (CLK'event and CLK = '1') then
		state <= n_state;
   end if;
end process;

end Arch_MCycle;
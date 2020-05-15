library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all; 
entity DEC_EX_buffer is port(
buffer_output :out std_logic_vector(102 downto 0);
Readdata1:in std_logic_vector(31 downto 0);
Readdata:in  std_logic_vector(31 downto 0);
EA: in  std_logic_vector(19 downto 0);
IMM:in std_logic_vector(15 downto 0);
TWO_FETCHES:in std_logic_vector(1 downto 0);
PREDICTION_SIGNAL:in std_logic;
PC:in  std_logic_vector(31 downto 0);
WRITE_REG1:in std_logic_vector(2 downto 0);
WRITE_REG2:in std_logic_vector(2 downto 0);
clk:in std_logic
);
end DEC_EX_buffer;
architecture Behavioral of DEC_EX_buffer is
signal Readdata2:std_logic_vector(31 downto 0);
begin

Readdata2 <= Readdata when TWO_FETCHES ="00"
else "000000000000" &EA when TWO_FETCHES ="01"
else std_logic_vector(resize(signed(IMM), Readdata2'length))when TWO_FETCHES ="10"
else Readdata; 

 process(clk) 
 begin
if(rising_edge(clk)) then

buffer_output <= PREDICTION_SIGNAL & Readdata1 & Readdata2 & PC & WRITE_REG1 & WRITE_REG2;

end if;

end process ;



end Behavioral ;
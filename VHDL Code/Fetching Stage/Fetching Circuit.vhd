LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY FETCHING_CIRCUIT IS
PORT (INSTRUCTION_MEMORY: STD_LOGIC_VECTOR(15 DOWNTO 0);
      PC: STD_LOGIC_VECTOR(31 DOWNTO 0);
      RST, CLK, RESET_FETCHING_AND_STALL_PC, RESET_SIGNAL_FROM_EXECUTION_CIRCUIT_BRANCH_DETECTION, HAZARD_DETECTION_LW, PREDICTION_SIGNAL: IN STD_LOGIC;
      FE_ID: OUT STD_LOGIC_VECTOR(64 DOWNTO 0);
      TWO_FETCHES,TWO_FETCHES_BEFORE_DFF: OUT STD_LOGIC);
END ENTITY;

ARCHITECTURE ARCH OF FETCHING_CIRCUIT IS
SIGNAL RESET_SIGNAL: STD_LOGIC; -- TO RESET FETCHING REGISTER
SIGNAL TFF_INPUT_SIGNAL,TFF_OUTPUT_SIGNAL: STD_LOGIC; -- TO CONNECT DFF WITH INVERTER THEN CONNECT TO AND GATE
SIGNAL FETCH_REG_31_16,FETCH_REG_15_0: STD_LOGIC_VECTOR(15 DOWNTO 0); -- FOR FIRST AND SECOND FETCH FROM INSTRUCTION MEMORY
SIGNAL FETCH_REG_D: STD_LOGIC_VECTOR(64 DOWNTO 0); -- INPUT TO FETCH REG
SIGNAL FETCH_REG_Q: STD_LOGIC_VECTOR(64 DOWNTO 0); -- OUTPUT OF FETCH REG
SIGNAL TWO_FETCHES_SIGNAL_BEFORE_DFF: STD_LOGIC; -- TWO FETCHES BEFORE DFF
SIGNAL TWO_FETCHES_SIGNAL_AFTER_DFF: STD_LOGIC; -- TWO FETCHES AFTER DFF
SIGNAL IF_DE_WRITE_ENABLE: STD_LOGIC; -- WRITE ENABLE FOR IF/DE
SIGNAL TFF_RESET: STD_LOGIC; -- TO RESET TFF
BEGIN
    RESET_SIGNAL <= RST OR RESET_SIGNAL_FROM_EXECUTION_CIRCUIT_BRANCH_DETECTION OR RESET_FETCHING_AND_STALL_PC;
    FETCH_REG_D <= PREDICTION_SIGNAL & PC & FETCH_REG_31_16 & FETCH_REG_15_0;
    TWO_FETCHES_SIGNAL_BEFORE_DFF <= TFF_INPUT_SIGNAL AND (NOT TFF_OUTPUT_SIGNAL);
    IF_DE_WRITE_ENABLE <= NOT HAZARD_DETECTION_LW;
    TFF_INPUT_SIGNAL <= FETCH_REG_Q(29) OR FETCH_REG_Q(28);
    FE_ID <= FETCH_REG_Q;
    TWO_FETCHES <= TWO_FETCHES_SIGNAL_AFTER_DFF;
    TFF_RESET <= RST OR TWO_FETCHES_SIGNAL_AFTER_DFF;
    TWO_FETCHES_BEFORE_DFF <= TWO_FETCHES_SIGNAL_BEFORE_DFF;
    
    -- FETCHING FIRST INSTRUCTION
    WITH TWO_FETCHES_SIGNAL_BEFORE_DFF SELECT FETCH_REG_31_16 <=
    INSTRUCTION_MEMORY WHEN '0',
    FETCH_REG_31_16 WHEN OTHERS;

    -- FETCHING SECOND INSTRUCTION
    WITH TWO_FETCHES_SIGNAL_BEFORE_DFF SELECT FETCH_REG_15_0 <=
    INSTRUCTION_MEMORY WHEN '1',
    FETCH_REG_15_0 WHEN OTHERS;

    -- PORT MAP FE/ID BUFFER
    FE_ID_REG: ENTITY WORK.REG(BEHAVIOURAL) GENERIC MAP (N=>65) PORT MAP (D=>FETCH_REG_D, RST=>RESET_SIGNAL, CLK=>CLK, WR_ENABLE=> IF_DE_WRITE_ENABLE, Q=>FETCH_REG_Q);
    -- PORT MAP DFF
    DFF: ENTITY WORK.DFF(BEHAVIOURAL) PORT MAP (TWO_FETCHES_SIGNAL_BEFORE_DFF,RST,CLK,TWO_FETCHES_SIGNAL_AFTER_DFF);
    -- PORT MAP DFF AS TFF
    TFF: ENTITY WORK.DFF(BEHAVIOURAL) PORT MAP (TFF_INPUT_SIGNAL,TFF_RESET,CLK,TFF_OUTPUT_SIGNAL);
END ARCHITECTURE;
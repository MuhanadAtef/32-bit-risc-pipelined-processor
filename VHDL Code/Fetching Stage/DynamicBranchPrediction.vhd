LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY DYNAMIC_BRANCH IS
    PORT(ADDRESS: IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- ADDRESS TO BE UPDATED FROM EXECUTE STAGE
         REG_DATA: IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- REGISTER DATA TO JUMP TO
         FIRST_16_BITS_INST_MEM: IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- FIRST 16 BIT OF THE INSTRUCTION WHICH CONTAINS THE OP CODE , DEST REG
         ENABLE,CLK,RST,JZ_EXE_STAGE,ZERO_FLAG: IN STD_LOGIC;
         PREDICTION: OUT STD_LOGIC;
         SELECT_REG: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         PREDICTION_ADDRESS: OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END ENTITY;

ARCHITECTURE ARCH OF DYNAMIC_BRANCH IS
-- DYNAMIC BRANCH PREDICTION CACHE
TYPE STATES IS (STRONGLY_NOT_TAKEN,WEAKLY_NOT_TAKEN,WEAKLY_TAKEN,STRONGLY_TAKEN);
TYPE DYNAMIC_BRANCH_CACHE IS ARRAY(0 TO 31) OF STATES;
SIGNAL CACHE : DYNAMIC_BRANCH_CACHE;
SIGNAL PREDICTION_SIGNAL: STD_LOGIC;
SIGNAL UNCONDITIONAL_JMP: STD_LOGIC; -- EQUALS TO '1' WHEN JMP,CALL
SIGNAL JZ_SIGNAL: STD_LOGIC; -- EQUALS '1' WHEN THE CURRENT INSTRUCTION IN FETCHING STAGE IS JZ
BEGIN
    -- EDIT DYNAMIC BRANCH CACHE BASED ON EXECUTION UNIT
    PROCESS (CLK) IS
    VARIABLE CURRENT_STATE : STATES;
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF RST = '1' THEN
                CACHE <= (OTHERS => STRONGLY_NOT_TAKEN);
            -- UPDATE CACHE WHEN IT'S A JZ OPERATION
            ELSIF JZ_EXE_STAGE = '1' THEN   
                CASE CURRENT_STATE IS
                    WHEN STRONGLY_NOT_TAKEN => 
                        IF ZERO_FLAG = '1' THEN CURRENT_STATE := WEAKLY_NOT_TAKEN; ELSE CURRENT_STATE := STRONGLY_NOT_TAKEN; END IF;
                    WHEN WEAKLY_NOT_TAKEN =>
                        IF ZERO_FLAG = '1' THEN CURRENT_STATE := WEAKLY_TAKEN; ELSE CURRENT_STATE := STRONGLY_NOT_TAKEN; END IF;
                    WHEN WEAKLY_TAKEN =>
                        IF ZERO_FLAG = '1' THEN CURRENT_STATE := STRONGLY_TAKEN; ELSE CURRENT_STATE := WEAKLY_NOT_TAKEN; END IF;
                    WHEN STRONGLY_TAKEN =>
                        IF ZERO_FLAG = '1' THEN CURRENT_STATE := STRONGLY_TAKEN; ELSE CURRENT_STATE := WEAKLY_TAKEN; END IF;    
                END CASE;
                CACHE(TO_INTEGER(UNSIGNED(ADDRESS))) <= CURRENT_STATE;
            END IF ;
        END IF ;
    END PROCESS;

    -- PREDICTION SIGNAL TO PC
    PROCESS (CLK) IS
    BEGIN
        IF FALLING_EDGE(CLK) THEN
            IF JZ_SIGNAL = '1' THEN
                CASE CACHE(TO_INTEGER(UNSIGNED(REG_DATA(4 DOWNTO 0)))) IS
                    WHEN WEAKLY_TAKEN | STRONGLY_TAKEN => PREDICTION_SIGNAL <= '1';
                    WHEN OTHERS => PREDICTION_SIGNAL <= '0';
                END CASE ;
            ELSE
                PREDICTION_SIGNAL <= '0';
            END IF ;
        END IF ;
    END PROCESS;

    JZ_SIGNAL <= (NOT FIRST_16_BITS_INST_MEM(15)) AND FIRST_16_BITS_INST_MEM(14) AND (NOT FIRST_16_BITS_INST_MEM(11)) AND (NOT FIRST_16_BITS_INST_MEM(10)) AND (NOT FIRST_16_BITS_INST_MEM(9)); 
    UNCONDITIONAL_JMP <= ((NOT FIRST_16_BITS_INST_MEM(15)) AND FIRST_16_BITS_INST_MEM(14)) AND (NOT FIRST_16_BITS_INST_MEM(11)) AND (FIRST_16_BITS_INST_MEM(10) OR FIRST_16_BITS_INST_MEM(9));
    PREDICTION <= (PREDICTION_SIGNAL OR UNCONDITIONAL_JMP) AND ENABLE;
    PREDICTION_ADDRESS <= REG_DATA;
    SELECT_REG <= FIRST_16_BITS_INST_MEM(8 DOWNTO 6);

END ARCHITECTURE;

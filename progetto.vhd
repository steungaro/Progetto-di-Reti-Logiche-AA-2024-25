------------------------------------------------------------
----------------------- PROVA FINALE -----------------------
----------------- PROGETTO DI RETI LOGICHE -----------------
------------------ Prof. Gianluca Palermo ------------------
------------------------------------------------------------
-- Stefano Ungaro ------------------- (209901 / 10836481) --
-- Alessandro Ferdinando Verrengia -- (212680 / 10834099) --
------------------------------------------------------------

-- LIBRERIE UTILIZZATE
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY project_reti_logiche IS
	PORT
	(
		i_clk       : IN  std_logic; -- clock
        i_rst       : IN  std_logic; -- reset ASINCRONO
        i_start     : IN  std_logic; -- start SINCRONO
        i_add       : IN  std_logic_vector(15 downto 0); -- indirizzo iniziale

        o_done      : OUT std_logic; -- segnale di fine elaborazione

        o_mem_addr  : OUT std_logic_vector(15 downto 0); -- indirizzo a cui effettuare lettura o scrittura
        i_mem_data  : IN  std_logic_vector(7 downto 0); -- dato letto dalla memoria
        o_mem_data  : OUT std_logic_vector(7 downto 0); -- dato da scrivere in memoria
        o_mem_we    : OUT std_logic; -- segnale di write enable (0 = leggi, 1 = scrivi)
        o_mem_en    : OUT std_logic -- segnale di enable memoria (0 = no azione memoria, 1 = azione memoria)
	);
END project_reti_logiche;

ARCHITECTURE Behavioral OF project_reti_logiche IS -- definizione comportamentale della macchina a stati finiti
	TYPE STATO_T IS (IDLE, SET_READ, WAIT_MEM, CALC, DONE); -- definizione degli stati per FSM
	SIGNAL  current:    STATO_T; -- stato corrente
    SIGNAL  lunghezza:  INTEGER; -- lunghezza del vettore da analizzare
    SIGNAL  i:          INTEGER; -- contatore
    SIGNAL  s:          std_logic; -- segnale tipo di filtro (0 per ordine 3 e 1 per ordine 5)
    SIGNAL  filtro:     INTEGER (6 DOWNTO 0); -- valori del filtro
    SIGNAL  valori:     INTEGER (6 DOWNTO 0); -- valori del vettore da filtrare

BEGIN
	PROCESS (i_clk, i_rst) -- PROCESS PRINCIPALE PER LA GESTIONE DELLA MACCHINA
    VARIABLE pre_norm:  INTEGER; -- variabile prima della normalizzazione
    VARIABLE norm:      INTEGER; -- variabile dopo la normalizzazione
    VARIABLE c:         INTEGER; -- contatore per i cicli

	BEGIN
		IF i_rst = '1' THEN -- reset asincrono ricevuto
			o_done   <= '0';
			o_mem_en <= '0';
			current  <= IDLE;
		ELSIF rising_edge(i_clk) THEN
			CASE current IS

				WHEN IDLE => -- attesa dello START
					o_done <= '0';
                    IF i_start = '1' THEN           -- ho ricevuto lo start
                        current     <= SET_READ;
                        i           <= 0;
                        lunghezza   <= 0;
                        filtro      <= (OTHERS => 0); -- inizializzo il filtro
                        valori      <= (OTHERS => 0); -- inizializzo i valori
                    ELSE                            -- non ho ricevuto lo start
                        current     <= IDLE;
                    END IF;

				WHEN SET_READ => -- richiesta di lettura dalla memoria --> poi WAIT
                    o_mem_addr      <= i_add + i;
                    o_mem_we        <= '0'; -- ho effettuato una lettura
                    o_mem_en        <= '1'; -- abilito la memoria per la lettura
                    current         <= WAIT_MEM;
                
				WHEN WAIT_MEM => -- attesa della risposta della memoria -> molti controlli sulla ii
                    -- se i = 0 sto leggendo k1 e poi torno in SET_READ
                    IF i = 0 THEN -- K1
                        lunghezza   <= TO_INTEGER(i_mem_data) * 128;
                        current     <= SET_READ;
                    END IF;

                    -- se i = 1 sto leggendo k2 e poi torno in SET_READ
                    IF i = 1 THEN -- K2
                        lunghezza   <= lunghezza + TO_INTEGER(i_mem_data);
                        current     <= SET_READ; -- FILTRO 7 BYTE???
                    END IF;

                    -- se i = 2 sto leggendo s e poi torno in SET_READ
                    IF i = 2 THEN
                        s           <= i_mem_data(0);

                        -- se s = 1 i = i + 6 + 1 = i + 7
                        IF i_mem_data(0) = '1' THEN
                            i       <= i + 7;
                        END IF;

                        current     <= SET_READ;
                    END IF;
                    -- se i > 2 e i < 17 sto leggendo cil filtro e poi torno in SET_READ
                    IF i > 2 AND i < 17 THEN
                        filtro(i - 3) <= TO_INTEGER(i_mem_data);
                        current       <= SET_READ;
                    END IF;

                    -- se i > 16 sto leggendo w1...wk --> inserisco i valori in valori effettuando uno shift da destra a sinistra
                    IF i > 16 THEN
                        valori(0)      <= valori(1);
                        valori(1)      <= valori(2);
                        valori(2)      <= valori(3);
                        valori(3)      <= valori(4);
                        valori(4)      <= valori(5);
                        valori(5)      <= valori(6);
                        valori(6)      <= TO_INTEGER(i_mem_data);
                        current        <= SET_READ;

                        IF i < 19 THEN
                            current <= SET_READ;
                        ELSE
                            current <= CALC;
                    END IF;
                    
                    i        <= i + 1;
                    o_mem_en <= '0';
                    o_mem_we <= '0';
                    
                WHEN CALC => -- calcolo del valore filtrato e normalizzazione
                    pre_norm := 0;

                    FOR c IN 0 TO 6 LOOP
                        pre_norm := pre_norm + valori(i) * filtro(i);
                    END LOOP;

                    IF pre_norm < 0 THEN
                        IF s = '0' THEN
                            norm := (pre_norm >> 4 + 1) + (pre_norm >> 6 + 1) + (pre_norm >> 8 + 1) + (pre_norm >> 10 + 1);
                        ELSE
                            norm := (pre_norm >> 6 + 1) + (pre_norm >> 10 + 1);
                        END IF;
                        
                    ELSE
                        IF s = '0' THEN
                            norm := (pre_norm >> 4) + (pre_norm >> 6) + (pre_norm >> 8) + (pre_norm >> 10);
                        ELSE
                            norm := (pre_norm >> 6) + (pre_norm >> 10);
                        END IF;
                    END IF;

                    o_mem_we <= '1';
                    o_mem_en <= '1';
                    o_mem_addr <= i_add + i;
                    o_mem_data <= std_logic_vector(TO_SIGNED(norm, 8));

                    
                    IF i = lunghezza + 17 THEN
                        current <= DONE;
                    ELSE
                        IF i > lunghezza + 17 - 4 THEN
                            current <= CALC;

                            valori(0)      <= valori(1);
                            valori(1)      <= valori(2);
                            valori(2)      <= valori(3);
                            valori(3)      <= valori(4);
                            valori(4)      <= valori(5);
                            valori(5)      <= valori(6);
                            valori(6)      <= 0;

                        ELSE
                            current <= SET_READ;
                        END IF;
                    END IF;
                    
                    i <= i + 1;

				WHEN DONE => -- elaborazione terminata -> o_done = 1
                    o_done <= '1';

                    IF i_start = '0' THEN
                        -- se abbasso il segnale di start posso ripartire --> IDLE
                        current <= IDLE;
                        ELSE
                        -- altrimenti rimango in DONE
                        current <= DONE;
                    END IF;
					
				WHEN OTHERS => -- default
			END CASE;
		END IF;
	END PROCESS;
END Behavioral;

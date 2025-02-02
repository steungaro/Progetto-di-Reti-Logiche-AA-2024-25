------------------------------------------------------------
----------------------- PROVA FINALE -----------------------
----------------- PROGETTO DI RETI LOGICHE -----------------
------------------ Prof. Gianluca Palermo ------------------
------------------------------------------------------------
-- Stefano Ungaro ------------------- (209901 / 10836481) --
-- Alessandro Ferdinando Verrengia -- (212680 / 10834099) --
------------------------------------------------------------


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
    SIGNAL  filtro:     INTEGER (6 DOWNTO 0); -- valori del filtro
    SIGNAL  valori:     INTEGER (6 DOWNTO 0); -- valori del vettore da filtrare

BEGIN
	PROCESS (i_clk, i_rst) -- PROCESS PRINCIPALE PER LA GESTIONE DELLA MACCHINA
    VARIABLE pre_norm:  INTEGER; -- variabile per la normalizzazione

	BEGIN
		IF i_rst = '1' THEN -- reset asincrono ricevuto
			o_done   <= '0';
			o_mem_en <= '0';
			current  <= IDLE;
		ELSIF rising_edge(i_clk) THEN
			CASE current IS

				WHEN IDLE => -- attesa dello START
					o_done <= '0';
                    IF i_start = '1' THEN   -- ho ricevuto lo start
                        current   <= SET_READ;
                        i         <= 0;
                        lunghezza <= 0;
                    ELSE                    -- non ho ricevuto lo start
                        current   <= IDLE;
                    END IF;

				WHEN SET_READ => -- richiesta di lettura dalla memoria --> poi WAIT
					
				WHEN WAIT_MEM => -- attesa della risposta della memoria -> molti controlli sulla i
				
                WHEN CALC => -- calcolo del valore filtrato e normalizzazione
                    pre_norm := 0;

				WHEN DONE => -- elaborazione terminata -> o_done = 1
                
                    -- se abbasso il segnale di start posso ripartire --> IDLE
                    -- altrimenti rimango in DONE
					
				WHEN OTHERS => -- default
			END CASE;
		END IF;
	END PROCESS;
END Behavioral;

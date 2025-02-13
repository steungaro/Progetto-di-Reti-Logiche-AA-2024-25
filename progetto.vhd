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
		i_clk		: IN  std_logic; -- clock
		i_rst		: IN  std_logic; -- reset ASINCRONO
		i_start		: IN  std_logic; -- start SINCRONO
		i_add		: IN  std_logic_vector(15 DOWNTO 0); -- indirizzo iniziale

		o_done		: OUT std_logic; -- segnale di fine elaborazione

		o_mem_addr	: OUT std_logic_vector(15 DOWNTO 0);	-- indirizzo a cui effettuare lettura o scrittura
		i_mem_data	: IN  std_logic_vector(7 DOWNTO 0);		-- dato letto dalla memoria
		o_mem_data	: OUT std_logic_vector(7 DOWNTO 0);		-- dato da scrivere in memoria
		o_mem_we	: OUT std_logic;	-- segnale di write enable (0 = leggi, 1 = scrivi)
		o_mem_en	: OUT std_logic 	-- segnale di enable memoria (0 = no azione memoria, 1 = azione memoria)
	);
END project_reti_logiche;

ARCHITECTURE Behavioral OF project_reti_logiche IS	-- definizione comportamentale della'entity
	TYPE STATO_T IS (IDLE, SET_READ, WAIT_MEM, CALC, DONE, FETCH);	-- definizione degli stati per FSM
	TYPE int_array IS ARRAY (6 DOWNTO 0) OF INTEGER; -- definizione del tipo per un array di interi	
	SIGNAL  current:	STATO_T;	-- stato corrente
	SIGNAL  lunghezza:	INTEGER;	-- lunghezza del vettore da analizzare
	SIGNAL  i:			INTEGER;	-- contatore della posizione nella memoria
	SIGNAL  s:			std_logic;	-- segnale tipo di filtro (0 per ordine 3 e 1 per ordine 5)
	SIGNAL  filtro:		int_array;	-- valori del filtro
	SIGNAL  valori:		int_array;	-- valori del vettore da filtrare

BEGIN
	PROCESS (i_clk, i_rst)	-- PROCESS PER LA GESTIONE DELLA MACCHINA
	VARIABLE pre_norm:			INTEGER;	-- variabile prima della normalizzazione
	VARIABLE norm:				INTEGER;	-- variabile dopo la normalizzazione
	VARIABLE c:					INTEGER;	-- contatore per i cicli
	VARIABLE shift_4: 			INTEGER;	-- variabili per lo shift
	VARIABLE shift_6:	 		INTEGER;	-- variabili per lo shift
	VARIABLE shift_8: 			INTEGER;	-- variabili per lo shift
	VARIABLE shift_10:	 		INTEGER;	-- variabili per lo shift
	VARIABLE sign_correction: 	INTEGER;	-- variabile per la correzione del segno

	BEGIN
		IF i_rst = '1' THEN 	-- reset asincrono ricevuto -> torno allo stato iniziale e torno allo stato iniziale
			o_done		<= '0';
			o_mem_en	<= '0';
			current 	<= IDLE;
		ELSIF rising_edge(i_clk) THEN
			CASE current IS
	
				WHEN IDLE => -- attesa dello START
					o_done <= '0';
					IF i_start = '1' THEN				-- ho ricevuto lo start -> inizializzo tutti i valori e poi passo a SET_READ
						i			<= 0;
						lunghezza	<= 0;
						s			<= '0';
						filtro		<= (OTHERS => 0); 	-- inizializzo il filtro
						valori		<= (OTHERS => 0); 	-- inizializzo i valori
						current		<= SET_READ;		-- prossimo stato
					ELSE								-- non ho ricevuto lo start -> rimango in IDLE
						current		<= IDLE;
					END IF;

				WHEN SET_READ =>						-- richiesta di lettura dalla memoria utilizzando i come posizione -> poi WAIT_MEM
					o_mem_addr		<= std_logic_vector(UNSIGNED(i_add) + TO_UNSIGNED(i, 16)); -- indirizzo di lettura
					o_mem_we		<= '0'; 			-- effettuo una lettura, we = 0
					o_mem_en		<= '1'; 			-- abilito la memoria per la lettura, en = 1
					current			<= WAIT_MEM;		-- prossimo stato

				WHEN WAIT_MEM => 						-- attesa della risposta della memoria per un ciclo di clock -> poi FETCH
					current			<= FETCH;

				WHEN FETCH =>							-- salvataggio della risposta della memoria, in base alla i capisco cosa sto leggendo
					
					CASE i IS
						-- se i = 0 sto leggendo K1 e poi torno in SET_READ
						WHEN 0 =>			-- K1 (8 bit più significativi di lunghezza)
							lunghezza	<= TO_INTEGER(unsigned(i_mem_data)) * 128;
							current		<= SET_READ;

						-- se i = 1 sto leggendo K2 e poi torno in SET_READ
						WHEN 1 => 			-- K2 (8 bit meno significativi di lunghezza)
							lunghezza	<= lunghezza + TO_INTEGER(unsigned(i_mem_data));
							current		<= SET_READ; 

						-- se i = 2 sto leggendo S e poi torno in SET_READ
						WHEN 2 =>
							s			<= i_mem_data(0);
							current		<= SET_READ;

						WHEN OTHERS =>
							
							-- se i > 2 e i < 17 sto leggendo il filtro C1...C7 oppure C8...C14 e poi torno in SET_READ
							IF i > 2 AND i < 17 THEN
								IF s = '1' AND i > 9 THEN
									filtro(i - 10) 	<= TO_INTEGER(SIGNED(i_mem_data)); -- sto leggendo i valori del filtro di ordine 5, quindi la i andrà da 10 a 16 inclusi
								END IF;
								IF s = '0' AND i < 10 THEN
									filtro(i - 3) 	<= TO_INTEGER(SIGNED(i_mem_data)); -- sto leggendo i valori del filtro di ordine 3, quindi la i andrà da 3 a 9 inclusi
									filtro(0)		<= 0; -- il primo valore del filtro di ordine 3 è sempre 0
									filtro(6)		<= 0; -- l'ultimo valore del filtro di ordine 3 è sempre 0
								END IF;
								current			<= SET_READ;

					-- se i > 16 sto leggendo W1...Wk -> inserisco i valori in valori effettuando uno shift dell'array da destra a sinistra
							ELSIF i > 16 THEN
								valori(0)		<= valori(1);
								valori(1)		<= valori(2);
								valori(2)		<= valori(3);
								valori(3)		<= valori(4);
								valori(4)		<= valori(5);
								valori(5)		<= valori(6);
								valori(6)		<= TO_INTEGER(SIGNED(i_mem_data));
								current			<= SET_READ;

								IF i < 20 THEN 		-- sto leggendo uno dei primi tre valori, quindi non vado a calcolare il valore filtrato ma torno in SET_READ
									current <= SET_READ;
								ELSE				-- sto leggendo uno dei valori dal quarto in poi, quindi vado a calcolare il valore filtrato -> CALC
									current <= CALC;
								END IF;
							END IF;
					END CASE;						
					i			<= i + 1; 	-- incremento il contatore
					o_mem_en 	<= '0'; 	-- disabilito la memoria
					o_mem_we 	<= '0';		-- disabilito la scrittura
					
				WHEN CALC => 				-- calcolo del valore filtrato e normalizzazione
					pre_norm := 0; 			-- inizializzo la variabile pre_norm locale a ogni ciclo

					-- calcolo del valore filtrato (pre_norm) -> uso i valori esplicitamente perché con un ciclo for calcolerei in maniera sequenziale e non parallela (più attesa)
					pre_norm := (valori(0) * filtro(0)) + (valori(1) * filtro(1)) + 
								(valori(2) * filtro(2)) + (valori(3) * filtro(3)) + 
								(valori(4) * filtro(4)) + (valori(5) * filtro(5)) + 
								(valori(6) * filtro(6));

					-- Se pre_norm è negativo, aggiungo 1 a ogni shift
					IF pre_norm < 0 THEN
						sign_correction := 1;
					ELSE
						sign_correction := 0;
					END IF;

					-- Calcolo gli shift
					shift_4  	:= TO_INTEGER(shift_right(TO_SIGNED(pre_norm, 32), 4)) 	+ sign_correction;
					shift_6  	:= TO_INTEGER(shift_right(TO_SIGNED(pre_norm, 32), 6)) 	+ sign_correction;
					shift_8  	:= TO_INTEGER(shift_right(TO_SIGNED(pre_norm, 32), 8)) 	+ sign_correction;
					shift_10	:= TO_INTEGER(shift_right(TO_SIGNED(pre_norm, 32), 10)) + sign_correction;

					-- Selezione dei contributi in base a s
					IF s = '0' THEN
						norm := shift_4 + shift_6 + shift_8 + shift_10;
					ELSE
						norm := shift_6 + shift_10;
					END IF;

					o_mem_we 	<= '1'; 			-- abilito la scrittura
					o_mem_en 	<= '1';				-- abilito la memoria
					o_mem_addr  <= std_logic_vector(UNSIGNED(i_add) + TO_UNSIGNED(i - 4 + lunghezza, 16));	-- indirizzo di scrittura, tengo conto che i tiene la posizione relativa nell'array dell'elemento più a destra (+ 3) e che è già stato incrementato in FETCH (+ 1)

					IF norm > 127 THEN				-- saturazione del valore normalizzato per evitare overflow (parole di 8 bit)
						norm := 127;
					ELSIF norm < -128 THEN
						norm := -128;
					END IF;

					o_mem_data 	<= std_logic_vector(TO_SIGNED(norm, 8)); -- scrivo il valore normalizzato in memoria

					
					IF i = lunghezza + 16 + 4 THEN 			-- se ho calcolato i valori fino a lunghezza + 17 + 4 di shift - 1, ho finito -> DONE
						current <= DONE;
					ELSE									-- altrimenti devo fare altri calcoli
						IF i > lunghezza + 16 THEN			-- se sto per richiedere il valore successivo all'ultimo in memoria (lunghezza + 17 + 1) inserisco degli zeri
							valori(0)		<= valori(1);
							valori(1)		<= valori(2);
							valori(2)		<= valori(3);
							valori(3)		<= valori(4);
							valori(4)		<= valori(5);
							valori(5)		<= valori(6);
							valori(6)		<= 0;

							current 		<= CALC;		-- rimango in CALC
							i 				<= i + 1;		-- incremento il contatore (non verrà fatto in FETCH perché non ci vado)
						ELSE								-- altrimenti vado a leggere il valore successivo
							current 		<= SET_READ;	-- richiedo il valore successivo
						END IF;
					END IF;

				WHEN DONE => 	-- elaborazione terminata -> o_done = 1 finché start non viene abbassato
					o_done 	<= '1';
					o_mem_en <= '0';
					o_mem_we <= '0';

					IF i_start = '0' THEN
						-- se abbasso il segnale di start posso ripartire -> IDLE
						current <= IDLE;
						ELSE
						-- altrimenti rimango in DONE
						current <= DONE;
					END IF;
					
				WHEN OTHERS => -- default, non previsto
			END CASE;
		END IF;
	END PROCESS;
END Behavioral;
# ⚙️ Progetto di Reti Logiche – Filtro Differenziale su RAM

> Prova finale del corso di **Reti Logiche**, Anno Accademico 2024/2025  
> Politecnico di Milano  
> **Valutazione finale: 30 e lode**
> **Autori**: Stefano Ungaro e Alessandro Verrengia

---

## 🧠 Descrizione del Progetto

Questo progetto ha l’obiettivo di implementare in **VHDL** un componente hardware in grado di:
- interfacciarsi con una memoria RAM,
- leggere una sequenza di Byte da elaborare,
- applicare un **filtro differenziale** selezionabile (ordine 3 o 5),
- scrivere in memoria i risultati filtrati.

Il sistema si presta a essere integrato in pipeline digitali per elaborazioni di segnali, e rispetta vincoli stringenti di compattezza, efficienza e correttezza funzionale e temporale.

---

## 📚 Specifica Tecnica

- La sequenza da elaborare è preceduta da un **preambolo di 17 Byte**, che specifica:
  - lunghezza della sequenza `K` (2 Byte),
  - selezione del filtro (`S`: 1 Byte il cui LSB determina quale utilizzare tra ordine 3 o 5),
  - 14 coefficienti (entrambi i filtri sono codificati nel preambolo).

- I filtri disponibili sono:
  - Ordine 3: `[0, -1, 8, 0, -8, 1, 0]` con normalizzazione `n = 12`
  - Ordine 5: `[1, -9, 45, 0, -45, 9, -1]` con normalizzazione `n = 60`
NB: è possibile cambiare i coefficienti (ma non il valore di normalizzazione) modificando gli array istanziati nel Testbench.

- **Normalizzazione**:
  - Implementata tramite shift logici a destra e compensazioni per valori negativi,
  - Approccio efficiente per l'uso in hardware (no divisione esplicita).

- I risultati (`R1...Rk`) vengono scritti in memoria subito dopo i valori di ingresso.

---

## 🏗️ Architettura Hardware

Il componente è realizzato con:
- **Un unico processo VHDL**, che integra una **FSM completamente specificata**.
- **Sette stati principali**:
  - `IDLE` → `SET_READ` → `WAIT_MEM` → `FETCH` → `PRE` → `NORM_WRITE` → `DONE`
- **Ottimizzazione del percorso critico** tramite separazione dei calcoli nei due stati `PRE` e `NORM_WRITE`, migliorando lo slack e la stabilità.

### Segnali principali

- `i_clk`, `i_rst`, `i_start`, `i_add`, `i_mem_data` – controllo e indirizzamento
- `o_mem_addr`, `o_mem_data`, `o_mem_en`, `o_mem_we` – output del componente (interfaccia con la RAM)
- `o_done` – segnale di fine elaborazione

---

## ⏱️ Risultati di Sintesi

Sintesi effettuata con **Xilinx Vivado Webpack** su FPGA **Artix-7 (xc7a200tfbg484-1)**.

| Risorsa         | Utilizzo | Totale disponibile | Utilizzo % |
|-----------------|----------|--------------------|------------|
| Slice LUTs      | 773      | 134600             | 0.57%      |
| Slice Registers | 171      | 269200             | 0.06%      |
| Latch           | 0        | 269200             | 0.00%      |

⏱️ **Worst Negative Slack**: 6.995 ns su clock di 20 ns → il percorso critico impiega circa **13 ns**  
🔧 Nessun latch generato → logica **sintetizzabile e pulita**

---

## 🧪 Test Bench e Simulazioni

Le simulazioni sono state svolte in modalità **Behavioral**, **Post-Synthesis Functional** e **Post-Synthesis Timing** (facoltativa ma superata).

### Test principali eseguiti:
- ✅ Lunghezza minima (7 byte) – Verifica della correttezza
- 🔄 Reset asincrono – Interruzione e ripartenza
- 🧵 Lunghezza massima (32.759 byte) – Stress test temporale e funzionale
- 🔢 Valori estremi – Saturazione corretta oltre ±127
- 🔁 Multi-esecuzione – Elaborazioni consecutive con filtri diversi
- 🧠 Verifica con esempi manuali e da specifica

Tutti i test sono **stati superati** con risultati conformi alle attese.

---

## 📦 Struttura del Progetto

```bash
📁 progetto_reti_logiche
├── CONSEGNA/
│   └── 10836481_10834099.vhd          # Componente principale
│   └── 10836481_10834099.pdf           # Relazione di progetto
├── Testbench/
│   └── *.vhd                          # Test bench utilizzati
├── README.md
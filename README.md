# NES IDE

Ambiente di sviluppo per la Nintendo Entertainment System contenuto in **un solo file HTML** (`NES_IDE.html`): editor, linguaggio ad alto livello, assembler 6502, editor grafici e musicale, emulatore e debugger. Si apre in un browser moderno, senza installazione e senza connessione.

## Avvio rapido

1. Aprire `NES_IDE.html` in un browser (Chrome, Edge, Firefox, Safari).
2. Scegliere un esempio dal menu **Esempi** oppure scrivere il proprio codice.
3. **▶ RUN** (`F9` o `Ctrl+Invio`) compila e avvia il gioco nello schermo a destra.
4. Controlli: frecce, `Z` = B, `X` = A, `Invio` = Start, `Shift` = Select (cliccare prima sullo schermo). Sui dispositivi touch compaiono i tasti a schermo.

Esportazione: **↓ .NES** (ROM per altri emulatori o hardware), **↓ HTML** (pagina giocabile autonoma), **💾 SALVA FILE**, **📦 ZIP** (intero progetto), **🔗 LINK** (progetto nell'indirizzo, utile con la pagina pubblicata su un sito).

## Linguaggio NESC

NESC è un linguaggio ad alto livello che viene compilato in assembly 6502 all'interno dell'IDE. I file con estensione `.nc` possono essere il file principale del progetto oppure essere inclusi con `.include "file.nc"`. Il compilatore genera reset, NMI, lettura del controller e vettori: bastano `init()` e `frame()`.

```c
var px, py, score;      // variabili a 8 bit (zero page)
var buf[16];            // array (RAM $0300 in poi)
const SPEED = 2;

func init() {           // eseguita una volta, a schermo spento
  load_palette(palette);
  px = 120; py = 200;
}

func frame() {          // eseguita a ogni vblank (60 Hz)
  if (pad & BTN_LEFT) { px -= SPEED; }
  spr(0, px, py, 1);
}

asm {                   // assembly grezzo: dati, palette, tile
palette: .byte $0F,$30,$16,$27, ...
}
```

| Elemento | Dettagli |
|---|---|
| Dichiarazioni | `var a, b;` (8 bit) · `var16 a, b;` (16 bit, 0–65535) · `var v[N];` · `const K = 5;` · `func nome(p1, p2) { ... }` · `var t;` locale dentro una funzione |
| Istruzioni | `x = e;` · `x += e;` · `x -= e;` · `v[i] = e;` · `if / else if / else` · `while` · `for (i = 0; i < 5; i += 1) { ... }` · `return;` · `return espressione;` · `nome(args);` |
| Espressioni | `+ - * / % & \| ^ << >>` (scorrimento con costante), chiamate di funzione con argomenti, parentesi, numeri decimali, `$hex`, `%bin`, `v[i]`, `rand()`, `peek(addr)` |
| Condizioni | `== != < > <= >=`, `&&`, `\|\|` (`&&` ha la precedenza), valore diverso da zero |
| Costanti predefinite | `BTN_A BTN_B BTN_SELECT BTN_START BTN_UP BTN_DOWN BTN_LEFT BTN_RIGHT`; variabile `pad` = stato del controller |
| Funzioni predefinite | `spr(n, x, y, tile [, attr])` (n costante) · `spri(i, x, y, tile [, attr])` (i è un'espressione: utile nei cicli) · `poke(addr, v)` · `ppu_addr(hi, lo)` · `ppu_write(v)` · `load_palette(etichetta)` · `scroll(x, y)` · `wait_vblank()` |
| Assembly | blocco `asm { ... }`; le righe che iniziano con `.`, `;` o `etichetta:` al livello superiore passano invariate (tile, dati, blocchi degli editor) |

Tipi: `var` a 8 bit e `var16` a 16 bit, entrambi senza segno. Un'espressione è a 16 bit se contiene una `var16` o un numero maggiore di 255; assegnandola a una `var` si tronca al byte basso. `* / %` lavorano solo a 8 bit; parametri e valori di ritorno sono a 8 bit. Limiti attuali: niente ricorsione (parametri e variabili locali sono statici); niente array locali; al massimo 208 variabili; la divisione procede per sottrazioni ripetute (lenta con quozienti grandi) e la divisione per zero restituisce 255; `x % 1` va scritto con lo spazio, altrimenti `%1` è letto come numero binario. Gli errori indicano file e riga.

## Assembler

Assembler a due passate per tutte le istruzioni 6502 ufficiali, con etichette, costanti, espressioni (`<x`, `>x`) e i modi di indirizzamento standard.

```
.org $8000            indirizzo                     .include "file"     inserisce un file
.byte 1,2,$FF  (.db)  byte                          .macro nome a,b     macro (.endmacro)
.word etichetta (.dw) parole a 16 bit               .rept N             ripete un blocco (.endrept)
.res 16               spazio vuoto                  .if costante        condizione (.else, .endif)
.mirror v|h           mirroring                     @nome:              etichetta locale
.mapper 0|1|2|3|4     mapper                        .chr N / .tile …    tile (8 righe di cifre 0–3 o .)
.prgbanks N  .chrbanks N  .bank K                   banchi (PRG 16 KB, CHR 8 KB)
```

I vettori vanno in `.org $FFFA` con `.word nmi, reset, irq` (NESC li genera da solo). Gli **avvisi** (⚠) segnalano valori fuori da un byte ed etichette mai usate; gli **errori** (✖) indicano file e riga e sono cliccabili.

## Progetti

Più file per progetto (schede in alto, ★ = file principale), salvataggio e apertura in `.zip`, macro, `.include`, ricerca (`Trova`, `Trova in tutti`, `Sostituisci tutto`), salto a simbolo e annulla per le modifiche automatiche degli editor.

## Editor grafici e musicale

Gli editor scrivono blocchi riconoscibili nel file principale e li rileggono da lì: il progetto resta un insieme di normali file di testo.

| Editor | Blocco nel sorgente | Contenuto |
|---|---|---|
| Tile (512 tile, 4 colori, specchio, copia/incolla, **importa immagine**) | `; <GFX>` | righe `.chr` e `.tile` |
| Schermate (32×30, attributi di colore) e livelli | `; <NT>` | `screen`, `screen_pal`, `screen_1…` |
| Livelli (fino a 4 schermate, **orizzontali o verticali**) | `; <LV>` | colonne o righe e attributi per lo scorrimento (`level_cols`/`level_rows`, …) |
| Sprite composti e animazioni | `; <MS>` | `meta_0…`, `meta_table` (dy, tile, attr, dx; `$80` chiude il frame); `draw_meta` pronta |
| Musica (tracker a 4 canali, fino a 120 righe) | `; <MU>` | `music_chN`, tabelle delle note; driver `music_init`/`music_update` pronto |

Le modifiche entrano nel sorgente con «Applica al codice» o con RUN (il pulsante ↶ ANNULLA le annulla). Il driver musicale reale e l'anteprima del tracker producono gli stessi registri APU.

## Emulatore e debugger

- **CPU 6502** completa, comprese le istruzioni non ufficiali; coincide con il log di riferimento di `nestest` su tutte le 8991 istruzioni.
- **PPU:** sfondo, sprite 8×8 e 8×16, scroll per riga, limite di 8 sprite per riga con flag di overflow, sprite 0 hit approssimato, NTSC o PAL.
- **Mapper:** 0 (NROM), 1 (MMC1, modo PRG standard), 2 (UxROM), 3 (CNROM), 4 (MMC3 con IRQ di scanline).
- **Audio** (Web Audio): due onde quadre con sweep, triangolo, rumore e DMC.
- **Debugger:** registri, istruzioni disassemblate con nome dell'etichetta, memoria, passo singolo, frame, breakpoint; viewer di palette, sprite (OAM), nametable e pattern table.
- **Stati salvati**, riavvolgimento (circa 20 secondi), screenshot PNG e registrazione video `.webm`.

## Esempi

| Esempio | Contenuto |
|---|---|
| Sprite con la croce direzionale | palette, tile, sprite, controller, NMI |
| Schermata | sfondo disegnato con l'editor schermate |
| Progetto multi-file con macro | `main.asm`, `nes.inc`, `gfx.asm` |
| **Pong** | giocatore contro CPU, punteggio a cifre |
| **Meteore** | schivare le rocce, game over e ripartenza |
| Livello con scorrimento / Livello verticale | 4 schermate, colonne o righe caricate al volo |
| Musica | brano di prova con il driver |
| **NESC: Raccogli le monete** | gioco completo in linguaggio ad alto livello |
| **NESC: Piattaforme** | salto con gravità, atterraggio su piattaforme, monete, punteggio; lo sfondo è disegnato da codice con `var16` |
| **NESC: Sparatutto** | proiettili e nemici con array e cicli, collisioni, game over e ripartenza con Start |

## Stato di avanzamento

Stima del completamento per area, aggiornata a ogni rilascio. Il riferimento per il confronto è un ambiente completo per un altro sistema a 8 bit (compilatore proprio, emulatore, editor grafici e sonori, strumenti di profilo).

| Area | Stato | Note |
|---|---|---|
| Linguaggio ad alto livello (NESC) | **78%** | variabili, array, `if`/`while`/`for`, funzioni con parametri e ritorno, `* / %`, `&&`/`\|\|`, funzioni predefinite; mancano array locali, ricorsione, `* / %` a 16 bit, valori con segno, ottimizzazione del codice |
| Progetti (file, zip, macro, esempi) | **80%** | |
| Grafica (tile, immagini, sprite, schermate, livelli) | **80%** | |
| Suono (tracker, driver, sweep, DMC) | **65%** | un solo brano per progetto, niente inviluppi o effetti |
| Emulatore (CPU, mapper 0–4, PAL) | **65%** | niente temporizzazione al ciclo della PPU; mancano altri mapper |
| Debug (registri, memoria, viewer, stati) | **70%** | |
| Editor di testo (ricerca, simboli, avvisi) | **60%** | |
| Esportazione (`.nes`, `.asm`, zip, HTML, link) | **70%** | |
| Aiuto ed esempi | **70%** | 11 esempi, quattro giochi completi |
| **Media** | **71%** | |

Prossime voci in programma: ottimizzazione del codice generato in NESC, sostituzione in tutto il progetto, esportazione GIF, altri mapper (MMC5, VRC), più brani per progetto con strumenti ed effetti, sprite 0 hit e PPU più accurati.

## Limiti noti

- Lo scroll cambia per riga e non per pixel; lo sprite 0 hit è approssimato.
- MMC1 supporta solo il modo PRG standard; le tabelle di note del tracker e del DMC sono NTSC anche in PAL.
- L'audio è approssimato con Web Audio.
- Il file generato con «↓ HTML» contiene l'intero IDE oltre alla ROM.


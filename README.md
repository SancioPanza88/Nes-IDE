# NES IDE

Un ambiente di sviluppo per la NES (Nintendo Entertainment System) in **un solo file HTML**: si apre in un browser, non serve installare nulla né avere internet.
Dentro c'è tutto quello che serve per scrivere, assemblare, provare ed esportare un gioco.

> **Stato del progetto:** è in costruzione. Funziona per scrivere e provare giochi in assembly 6502, ma non è ancora completo come un ambiente professionale (vedi «Cosa manca»).
> Il codice è stato collaudato con test automatici (CPU, assembler, mapper, grafica), ma **non è mai stato aperto in un browser vero**: se un pulsante non risponde, è un difetto da segnalare.

## Come si usa

1. Apri `NES_IDE.html` in un browser moderno (Chrome, Edge, Firefox, Safari).
2. Scegli un esempio dal menu **Esempi** oppure scrivi il tuo codice a sinistra.
3. Premi **▶ RUN** (o `F9`, o `Ctrl+Invio`): il codice viene assemblato e il gioco parte nello schermo a destra.
4. Clicca sullo schermo per usare la tastiera: **frecce**, **Z** = B, **X** = A, **Invio** = Start, **Shift** = Select.
5. **↓ .NES** scarica la ROM, che funziona anche in altri emulatori.

Gli errori compaiono nella console sotto l'editor, con file e riga; cliccando sull'errore ti porta al punto giusto.

## Cosa c'è dentro

**Editor e assembler**
- Editor con evidenziazione e numeri di riga, salvataggio automatico nel browser.
- Assembler 6502 completo per le istruzioni ufficiali, con etichette, costanti, espressioni, `.byte`, `.word`, `.res`, `.org`.
- **Progetti con più file** (schede in alto), `.include "file"`, **macro** (`.macro` … `.endmacro`), `.rept`, `.if`/`.else`/`.endif`, etichette locali `@nome`.
- Salvataggio e apertura di tutto il progetto in **.zip**.

**Emulatore NES**
- CPU 6502 verificata istruzione per istruzione con il test standard `nestest`: **tutte le 8991 istruzioni** del log di riferimento, comprese le istruzioni **non ufficiali** (LAX, SAX, DCP, ISB, SLO, RLA, SRE, RRA e NOP varie).
- PPU con sfondo, sprite (8×8 e 8×16), scroll che può cambiare **riga per riga**, sprite 0 hit approssimato, **limite di 8 sprite per riga** con flag di overflow, modalità **NTSC o PAL** (menu in alto).
- Audio: due onde quadre (con **sweep**), triangolo, rumore e **canale DMC** (campioni), approssimati con Web Audio.
- **Mapper:** 0 (NROM), 1 (MMC1, modo PRG standard), 2 (UxROM), 3 (CNROM) e **4 (MMC3)** con banchi PRG da 8 KB, banchi CHR da 1 KB e **interrupt di scanline (IRQ)**, con più banchi PRG/CHR.

**Musica**
- **Tracker** a 4 colonne (quadra 1, quadra 2, triangolo, rumore), fino a 120 righe: suoni le note con la tastiera, scegli volume e duty, ascolti l'anteprima e premi «Applica al codice».
- **Driver 6502 pronto** (`music_init`, `music_update`): lo inserisci con un pulsante, chiami `jsr music_init` una volta e `jsr music_update` a ogni NMI. Il driver reale e l'anteprima producono gli stessi registri APU (verificato).

**Editor grafici**
- **Tile:** disegni i 512 tile (8×8, 4 colori), con specchio, copia e incolla, scelta dei colori NES, anteprima nel gioco in esecuzione.
- **Importa immagine:** converte un PNG/JPG nei 4 colori della palette scelta (fino a 16 tile di larghezza).
- **Schermate e livelli:** disegni lo sfondo (32×30 tile) con i colori (palette per blocchi 2×2). Con **＋ Schermata** (fino a 4) costruisci un livello largo, e l'editor genera da solo i dati per lo scorrimento orizzontale (colonne e attributi, blocco `<LV>`). L'esempio «Livello con scorrimento» contiene il motore pronto: `put_col` carica le colonne mentre la telecamera si muove, avanti e indietro.
- **Sprite composti e animazioni:** componi personaggi con più tile, con specchio, e crei i frame di un'animazione. Una rotina `draw_meta` pronta li copia negli sprite.

**Debugger**
- Registri, istruzioni disassemblate dal PC (con il nome dell'etichetta), memoria, passo singolo, un frame alla volta, breakpoint.

## Strumenti dell'editor

- **↶ ANNULLA:** annulla l'ultimo «Applica al codice» (tile, schermate, sprite) o «Sostituisci tutto» (fino a 30 passi). Per il testo digitato vale l'annulla normale del browser.
- **Cerca / sostituisci** sopra l'editor (senza distinzione tra maiuscole e minuscole, nel file aperto) e **Vai a simbolo…** per saltare a un'etichetta anche in un altro file.
- **Debugger:** oltre a registri e memoria, mostra la **palette PPU** (32 colori) e la lista degli **sprite (OAM)**.
- **💾 STATO / ⏏ CARICA STATO:** salva e ricarica lo stato dell'emulatore. **⏪ RIAVVOLGI:** tieni premuto per tornare indietro negli ultimi ~20 secondi.
- **📷** salva uno screenshot PNG; **⏺ REC** registra un video `.webm` (non GIF).
- **Controlli touch** sullo schermo (croce, A, B, Select, Start): compaiono sui dispositivi con touch.
- **Avvisi del compilatore** (⚠ in giallo nella console, cliccabili): valori fuori da un byte (`lda #300`, `.byte 999`) ed etichette mai usate. Gli errori (✖) indicano file e riga.
- **Viewer dei nametable** nel Debugger: i 4 nametable della PPU con il mirroring e un riquadro rosso sull'area visibile.
- **Trova in tutti** cerca in ogni file del progetto e porta alla riga cliccando.
- **? GUIDA:** guida rapida integrata.

## Esempi inclusi (menu «Esempi»)

| Esempio | Cosa mostra |
|---|---|
| Sprite con la croce direzionale | il minimo: palette, tile, sprite, controller, NMI |
| Modello vuoto | punto di partenza |
| Schermata | uno sfondo disegnato con l'editor schermate |
| Progetto multi-file con macro | `main.asm` + `nes.inc` (macro) + `gfx.asm` |
| Livello con scorrimento | 4 schermate disegnate con l'editor, scorrimento orizzontale con le frecce, colonne caricate al volo (anche all'indietro) |
| Musica | un brano di prova (melodia, basso, triangolo, batteria) suonato dal driver |
| **Pong** | tu (frecce su/giù) contro la CPU, rimbalzi, punteggio a cifre, azzeramento a 10 |
| **Meteore** | schiva le rocce con sinistra/destra, punteggio a due cifre, game over (nave rossa) e Start per ricominciare |

Pong e Meteore sono progetti con più file (`main.asm`, `nes.inc`, `font.asm`) e usano macro, etichette locali `@` e `.rept`: sono un buon punto di partenza da modificare.
Sono stati verificati con test automatici sulla logica (movimento, rimbalzi, collisioni, punti, game over), **ma non giocati con le mani**: come «sensazione di gioco» (velocità, difficoltà) sono da provare.

## Come lavorano gli editor con il codice

Gli editor non salvano in file separati: scrivono nel sorgente blocchi riconoscibili, e li rileggono da lì. Così il progetto resta un normale insieme di file `.asm`.

| Blocco | Cosa contiene | Come usarlo |
|---|---|---|
| `; <GFX> … ; </GFX>` | righe `.chr` e `.tile` con i tile | caricati nella CHR della ROM |
| `; <NT> … ; </NT>` | `screen` (1024 byte), `screen_pal` (16 byte) ed eventuali `screen_1…` | copiali nella PPU (vedi esempio «Schermata») |
| `; <MU> … ; </MU>` | `MUS_SPEED`, `MUS_ROWS`, `music_ch0…3` (2 byte per riga: nota, registro) e le tabelle delle note | letti dal driver musicale |
| `; <LV> … ; </LV>` | `LEVEL_W`, `LEVEL_MAXCAM`, `level_colptr`, `level_cols`, `level_attr` (generato, non modificarlo) | usato dal motore di scorrimento |
| `; <MS> … ; </MS>` | `meta_0…` e `meta_table` | `draw_meta` li disegna negli sprite |

Gli editor applicano le modifiche al codice quando premi **Applica al codice** o **RUN**. I blocchi si scrivono nel file principale (★) e prima del `.org $FFFA` dei vettori.

**Formato degli sprite composti:** per ogni sprite quattro byte `dy, tile, attr, dx` (spostamenti con segno rispetto al punto di riferimento), poi `$80` per chiudere il frame. I tile usano la tabella scelta da PPUCTRL bit 3.

## Direttive dell'assembler

```
.org $8000           indirizzo
.byte 1,2,$FF        byte (anche .db)
.word etichetta      parole a 16 bit (anche .dw)
.res 16              spazio vuoto
.mirror v|h          mirroring dello sfondo
.mapper N            0, 1, 2 o 3
.prgbanks N          banchi PRG da 16 KB
.chrbanks N          banchi CHR da 8 KB
.bank K              scrive nel banco K a $8000 (l'ultimo è fisso a $C000)
.chr N / .tile …     tile N, poi 8 righe di 8 cifre 0–3 (o .)
.include "file"      inserisce un altro file
.macro nome a,b      definisce una macro (chiusa da .endmacro)
.rept N              ripete un blocco (chiuso da .endrept)
.if costante         assemblaggio condizionale (.else, .endif)
@nome:               etichetta locale
```

Ricorda di mettere i vettori a `.org $FFFA` con `.word nmi, reset, 0`.

## Cosa manca (onestamente)

Questo non è ancora un ambiente completo. Mancano:
- **scorrimento verticale** e livelli più larghi di 4 schermate (oggi solo orizzontale, max 4);
- **audio ancora approssimato:** niente interruzioni del DMC, un solo brano per progetto, niente strumenti con inviluppo personalizzato, nessun effetto (vibrato, slide);
- **linguaggio ad alto livello** per la NES (oggi si scrive solo assembly);
- **emulatore ancora semplificato:** niente temporizzazione al ciclo della PPU (lo scroll cambia per riga, non per pixel), sprite 0 hit approssimato, MMC1 solo nel modo PRG standard, mancano altri mapper (MMC5, VRC…), le tabelle di note del tracker e del DMC sono quelle NTSC anche in modalità PAL;
- **altri strumenti:** esportazione GIF, viewer dei pattern table, sostituzione in tutto il progetto, avvisi più numerosi del compilatore;

## Collaudo

Test automatici eseguiti con Node (non in un browser; avvisi, viewer nametable e ricerca in tutti i file inclusi; decodifica DMC, sweep e driver musicale contro l'anteprima inclusi; stati salvati, annulla, cerca/sostituisci, vai a simbolo e viewer inclusi): confronto della CPU con il log di riferimento di `nestest` (5003 istruzioni), assembler e modi di indirizzamento, mapper 1/2/3, scroll per riga, debugger e breakpoint, logica dei registri audio, macro/include/`.if`/etichette locali, zip (compreso uno zip compresso creato altrove), importazione immagini e rotina `draw_meta` eseguita nell'emulatore.
**Non verificati:** l'aspetto e i clic nell'interfaccia (compresi touch, screenshot e registrazione video), il suono reale (tracker, sweep, DMC), il comportamento con giochi commerciali, la compatibilità con giochi commerciali e con hardware vero.

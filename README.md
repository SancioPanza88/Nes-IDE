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
- CPU 6502 verificata istruzione per istruzione con il test standard `nestest` (istruzioni ufficiali).
- PPU con sfondo, sprite (8×8 e 8×16), scroll che può cambiare **riga per riga**, sprite 0 hit approssimato.
- Audio: due onde quadre, triangolo e rumore.
- **Mapper:** 0 (NROM), 1 (MMC1, modo PRG standard), 2 (UxROM), 3 (CNROM), con più banchi PRG/CHR.

**Editor grafici**
- **Tile:** disegni i 512 tile (8×8, 4 colori), con specchio, copia e incolla, scelta dei colori NES, anteprima nel gioco in esecuzione.
- **Importa immagine:** converte un PNG/JPG nei 4 colori della palette scelta (fino a 16 tile di larghezza).
- **Schermate:** disegni lo sfondo (32×30 tile) con i colori (palette per blocchi 2×2).
- **Sprite composti e animazioni:** componi personaggi con più tile, con specchio, e crei i frame di un'animazione. Una rotina `draw_meta` pronta li copia negli sprite.

**Debugger**
- Registri, istruzioni disassemblate dal PC (con il nome dell'etichetta), memoria, passo singolo, un frame alla volta, breakpoint.

## Come lavorano gli editor con il codice

Gli editor non salvano in file separati: scrivono nel sorgente blocchi riconoscibili, e li rileggono da lì. Così il progetto resta un normale insieme di file `.asm`.

| Blocco | Cosa contiene | Come usarlo |
|---|---|---|
| `; <GFX> … ; </GFX>` | righe `.chr` e `.tile` con i tile | caricati nella CHR della ROM |
| `; <NT> … ; </NT>` | `screen` (1024 byte) e `screen_pal` (16 byte) | copiali nella PPU (vedi esempio «Schermata») |
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
- **mappe dei livelli** con più schermate e scorrimento;
- **editor musicale** (tracker) e un driver audio da inserire nel gioco;
- **audio fedele:** sweep delle onde quadre e canale DMC (campioni);
- **linguaggio ad alto livello** per la NES (oggi si scrive solo assembly);
- **emulatore più fedele:** limite di 8 sprite per riga, MMC3 e altri mapper, istruzioni non ufficiali, NTSC/PAL, stati salvati e riavvolgimento;
- **strumenti dell'editor:** ricerca, annulla dopo «Applica al codice», pannello dei problemi, viewer di PPU/OAM, screenshot e GIF, controlli touch, guida integrata.

## Collaudo

Test automatici eseguiti con Node (non in un browser): confronto della CPU con il log di riferimento di `nestest` (5003 istruzioni), assembler e modi di indirizzamento, mapper 1/2/3, scroll per riga, debugger e breakpoint, logica dei registri audio, macro/include/`.if`/etichette locali, zip (compreso uno zip compresso creato altrove), importazione immagini e rotina `draw_meta` eseguita nell'emulatore.
**Non verificati:** l'aspetto e i clic nell'interfaccia, il suono reale, la compatibilità con giochi commerciali e con hardware vero.

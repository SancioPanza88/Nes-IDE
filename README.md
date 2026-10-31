# NES IDE

Un ambiente di sviluppo per la NES (Nintendo Entertainment System) in **un solo file HTML**: si apre in un browser, non serve installare nulla né avere internet.
Dentro c'è tutto quello che serve per scrivere, assemblare, provare ed esportare un gioco.

> **Stato del progetto:** è in costruzione. Funziona per scrivere e provare giochi in assembly 6502, ma non è ancora completo come un ambiente professionale (vedi «Cosa manca»).


## Come si usa

1. Apri `NES_IDE.html` in un browser moderno (Chrome, Edge, Firefox, Safari).
2. Scegli un esempio dal menu **Esempi** (c'è anche un gioco completo: vedi «Esempio completo: Tomb Raider») oppure scrivi il tuo codice a sinistra.
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

## Esempio completo: Tomb Raider: The Prophecy (demake)

Un piccolo gioco d'avventura con la **visuale isometrica** di *Tomb Raider: The Prophecy* (GBA), in un solo file `.asm` (mapper 0, 32 KB PRG + 8 KB CHR, nessun audio). È giocabile dall'inizio alla fine: tre stanze, finale compreso. Serve da esempio di un progetto vero: apri il sorgente, leggilo, cambialo.

**Per provarlo:** scegline il file `tomb_raider.asm` (o l'esempio nel menu), premi **▶ RUN**, clicca sullo schermo e premi **Invio** al titolo. `tomb_raider.nes` è la ROM già assemblata, per altri emulatori.

| Tasto | Azione |
|---|---|
| Frecce | Muovi Lara in 8 direzioni (le diagonali seguono gli assi delle caselle) |
| **X** (A) | Salta nella direzione in cui guarda |
| **Z** (B) | Spara |
| Camminare contro un blocco | Lo spinge (tieni premuto giù+destra) |
| **Invio** (Start) | Inizia / ricomincia |

**Come si gioca, in breve.** Hai 6 cuori; le medipack ne ridanno 3. Nella prima stanza salta la fossa e prendi la chiave per aprire la porta; nella seconda spingi il blocco sulla piastra per aprire l'uscita; nella terza prendi l'Ankh, e il gioco finisce. Pipistrelli (2 colpi) e lupi (3 colpi) ti ostacolano; le fosse costano 2 cuori.

**Cosa mostra, tecnicamente**
- **Isometria:** ogni stanza è una griglia 8×8 di caselle da 32×16 pixel; la posizione è in 1/16 di casella e lo schermo si ricava da `x = 128 + pi − pj`, `y = 72 + (pi + pj) / 2`.
- **Dietro e davanti:** Lara passa dietro a pilastri e blocchi grazie alla priorità degli sprite.
- **Aggiornamenti della PPU:** durante il gioco si scrivono solo piccole liste di tile nel vblank; le stanze si caricano a schermo spento.
- **Tile:** 249 tile di sfondo su 256 e 85 di sprite, nel blocco `; <GFX>`, quindi si ritoccano con l'**Editor tile**.

**Dati da modificare a mano** (tutti nel sorgente)

| Cosa | Etichette |
|---|---|
| Colori delle stanze / degli sprite | `r0_pal`, `r1_pal`, `r2_pal` / `sprpal` |
| Mappa di collisione 8×8 (0 libero, 1 pilastro, 2 fossa, 3 vuoto, 4 piastra, 5 blocco) | `r0_map`, `r1_map`, `r2_map` |
| Nemici e oggetti di ogni stanza | `rN_en`, `rN_it` |
| Vita dei nemici, salto, punto di partenza | `ehp0`, `jztab`, `sp_i` / `sp_j` / `sp_f` |

**Limiti da sapere**
- Le scenografie delle stanze sono nametable compresse (`rN_nt`), **non** nel formato dell'**Editor schermate**: se premi «Applica al codice» lì, viene scritto un blocco `; <NT>` che il gioco non usa. Per rifare una stanza serve rigenerare i dati.
- I tile di sfondo sono quasi finiti (249/256).
- Su una vera NES può sfarfallare quando troppi sprite stanno sulla stessa riga (qui il limite di 8 per riga non è emulato).
- Il gioco è stato collaudato con una versione precedente di NES IDE e con test automatici, **ma non con questa versione, né in un browser vero o su NES reale**. Usa solo direttive di base (`.org`, `.byte`, `.word`, `.mirror`, `.chr`, `.tile`), quindi dovrebbe assemblare; se non succede, segnala il numero di riga che compare nella console.

**Idee per continuare:** altre stanze e un secondo livello, una leva e una trappola a spuntoni, un'animazione di morte, la musica (appena ci sarà un driver audio).

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

# PulseCoach — Runbook della demo live

Copione per la demo al corso universitario. Un arco unico: la giornata di un
utente su telefono e smartwatch, poi un allenamento in coppia tra due
dispositivi.

**Formato:** ~14 minuti · 2 presentatori · 3 dispositivi · rete via hotspot proprio.

---

## Ruoli e dispositivi

| Ruolo | Dispositivi | Responsabilità |
|---|---|---|
| **Presentatore 1** | 📱 Telefono fisico (device principale) | Guida il flusso principale su hardware reale: onboarding, piano AI con sensori reali (meteo/posizione/battito), avvio sessione. È il **peer B** nella sessione condivisa. |
| **Presentatore 2** | ⌚ Emulatore Wear · 📲 Emulatore tablet | Gestisce i due emulatori: mostra la schermata watch che rispecchia la sessione, il layout adattivo sul tablet, e fa da **peer A** (login email+password, tier `signedInFree` — no Pro) nella sessione condivisa e nel social. |

---

## Copione minuto-per-minuto

### 1 · Apertura — `0:00 → 1:00` · *nessuno schermo*

- **P1 + P2** — problema in una frase, pitch in una frase. Sguardi sul pubblico.
- **Battuta:** *«Allenarsi bene senza palestra è un problema di contesto: tempo,
  meteo, energia. PulseCoach genera ogni giorno un piano adattivo e ti accompagna
  dal telefono all'orologio.»*

### 2 · First-run onboarding + layout adattivo — `1:00 → 4:00` · 📲 Tablet

Il tablet parte da **installazione pulita** (dati app cancellati): il router lo
forza sull'onboarding, così mostri il first-run completo da zero. Il layout
adattivo si vede "gratis" all'arrivo su Today.

- **P2 fa:**
  - Avvia l'app fresca → **disclaimer** (accetta), **carosello** di onboarding
    (i 3 pannelli, incluso "I tuoi dati restano tuoi"), **profilo** (livello /
    obiettivo / durata / attrezzi).
  - Tocca **Inizia** → l'app atterra su **Today**. Fai notare che la navigazione è
    una `NavigationRail` laterale, non la barra inferiore del telefono.
- **P1 dice:** *«L'onboarding è tutto locale: disclaimer e profilo vivono nel DB
  del dispositivo, nessun account richiesto. E lo stesso identico codebase, a 600 px
  di larghezza, commuta il layout su rail laterale — una sola app, tre form factor.»*

> **Transizione:** durante il segmento 3–4 (che è sul telefono) P2 accede in
> background sul tablet come **peer A** (seed user 1), pronto per la sessione condivisa.

### 3 · Piano AI con sensori reali — `4:00 → 6:30` · 📱 Telefono

Il telefono è il device **caldo**: profilo già onboardato, così vai dritto al valore.

- **P1 fa:**
  - Apri **Today** e tocca **rigenera piano**: l'isolate AI produce il piano del
    giorno in tempo reale.
  - Apri la spiegazione del piano e mostra dove entrano **meteo, qualità dell'aria
    e posizione reali** (letti dai sensori/API sul telefono fisico) nel contesto.
- **P2 dice:** *«Il piano non è statico: legge posizione e meteo dal vivo tramite
  API reali, li mette in cache offline, e l'inferenza gira in un isolate separato
  per non bloccare la UI. Questa parte richiede hardware vero — per questo è sul
  telefono, non sull'emulatore.»*

### 4 · Sessione + smartwatch — `6:30 → 9:30` · 📱 Telefono + ⌚ Wear

- **P1 fa** (telefono): avvia una sessione dalla Today, lascia scorrere gli step,
  porta la sessione fino a un blocco di **riposo** e poi a fine. Torna alla Today:
  la sessione è marcata completata e persiste.
- **P2 mostra** (Wear): sull'emulatore Wear compaiono in tempo reale la schermata
  **step + timer + battito live**, poi la **rest screen**, infine il **summary**
  a fine sessione — rispecchiando ciò che P1 fa sul telefono.
- **P2 dice:** *«Il telefono trasmette lo stato della sessione all'orologio via
  watch_connectivity: passo, secondi rimanenti e frequenza cardiaca. Il
  completamento è scritto una sola volta nel DB locale ed è la fonte di verità per
  tutte le schermate.»*

### 5 · Sessione condivisa & social — `9:30 → 12:30` · 📲 Tablet + 📱 Telefono

> **Gate:** entrambi i peer sono a **signedInFree** (solo login, no Pro). La
> sessione condivisa **non** ha entitlement guard — funziona con il solo account.
> Il Pro entra solo nel beat finale, mostrato **come feature**.

**a) Sessione condivisa + social (gratis) — `9:30 → 11:30`**

- **P2 fa:**
  - Sul tablet (già loggato come **peer A** nella transizione del segmento 2) crea
    una sessione condivisa → mostra il **join code**.
  - Dopo il join, mostra la **lobby** con le presenze dei due utenti in tempo reale.
- **P1 fa:**
  - Sul telefono (loggato come **peer B**) inserisci il join code → entri nella
    lobby, il tablet aggiorna la presenza dal vivo.
  - Passa su **amici** e **feed** per chiudere il giro social di base.
- **P2 dice:** *«Presenza e broadcast passano da Supabase Realtime: quando uno dei
  due entra, l'altro schermo si aggiorna senza refresh manuale. Tutto questo è
  gratis con un account.»*

**b) Il modello Pro — paywall come feature — `11:30 → 12:30`**

- **P2 fa:** sul tablet tocca una funzione **Pro-gated** (es. punti classifica /
  progressi completi) → compare il **paywall / upsell sheet**. Non acquistare:
  mostralo e chiudilo.
- **P2 dice:** *«Sessione condivisa e amici sono gratuiti; punti classifica e
  progressi completi sono la leva Pro. L'entitlement è servito da RevenueCat con
  fallback offline: se il gate non risponde, l'app degrada al tier free, non crasha.»*

### 6 · Chiusura & architettura — `12:30 → 14:00` · 📱 Telefono

- **P1 fa:**
  - Apri **Progress** per mostrare la persistenza dei dati accumulati durante la demo.
  - *Facoltativo:* metti il telefono in **modalità aereo** e riapri l'app →
    catalogo e piano reggono da cache (risposta pronta al «e senza rete?»).
- **P1 + P2 dice:** *«Clean Architecture, offline-first con Drift, AI in isolate,
  sync realtime: un'unica base per telefono, watch e tablet. Grazie.»*

---

## Pre-flight · 15 minuti prima

### Ambiente & rete
- [ ] **Hotspot** del telefono acceso; tablet ed emulatore Wear connessi ad esso, non al Wi-Fi dell'aula.
- [ ] **Scalda la cache**: apri l'app una volta connesso così meteo/AQI e catalogo sono già in Drift.
- [ ] Backend Supabase raggiungibile: prova un login con un seed user prima di iniziare.
- [ ] **Video di backup** pronto in una tab: catena telefono→watch (30–40 s).
- [ ] Luminosità schermi al massimo, blocco automatico e notifiche silenziati.

### P1 · Telefono fisico
- [ ] Permessi **posizione + health/battito + notifiche** già concessi.
- [ ] Profilo **già onboardato** e device caldo (Today con piano visibile).
- [ ] Loggato come **peer B** (seed user 2).
- [ ] Telefono **accoppiato** all'emulatore Wear di P2 (check congiunto, vedi sotto).

### P2 · Emulatori (Wear + tablet)
- [ ] Tablet a **installazione pulita / dati app cancellati**, così il router forza l'onboarding (disclaimer + profilo) al primo avvio. Verificato con un giro di prova, poi ripulito di nuovo.
- [ ] Emulatore tablet avviato in **orizzontale** per esaltare la NavigationRail.
- [ ] Credenziali **peer A** (seed user 1, email+password) pronte per il login post-onboarding; tier `signedInFree` (**no Pro** — è voluto). Account peer A ha già **amici + feed** lato server (non vuoto).
- [ ] Verificato che toccando una funzione Pro compare il **paywall / upsell sheet** (non deve restare bianco). Se RevenueCat non ha offerte, prepara comunque il beat a voce.
- [ ] Emulatore Wear avviato e **accoppiato** al telefono di P1; bridge watch_connectivity verificato con una sessione di prova completa (step → rest → summary).
- [ ] Sessione condivisa di prova creata e distrutta una volta (verifica join code + presenza).

---

## Se qualcosa si rompe · fallback

| Severità | Sintomo | Contromossa |
|---|---|---|
| **Alta** | Pairing watch non aggancia | Non insistere dal vivo oltre 15 s. Passa al **video di backup** telefono→watch e continua a narrare. La sessione sul telefono prosegue comunque. |
| **Media** | Realtime social non aggiorna la presenza | Fai **pull-to-refresh** nella lobby. Se resta muto, mostra leaderboard/feed con i dati seed e descrivi il flusso realtime a voce. |
| **Media** | Meteo/posizione lenti o a vuoto | La cache scaldata copre il buco: il piano si genera lo stesso. Evita di ri-triggerare la posizione dal vivo se ha già risposto una volta. |
| **Bassa** | Piano AI lento a rigenerare | Riempi con la spiegazione del piano **già presente**; l'inferenza gira in isolate e non blocca la UI, quindi puoi parlare mentre elabora. |
| **Domanda attesa** | «E senza rete?» | Preparata: **modalità aereo** nel segmento 6 → catalogo e piano da cache Drift. Trasforma il rischio in feature. |

---

## Note di verità (dal codice, da tenere a mente)

1. **Il pairing `watch_connectivity` è il punto fragile #1.** Emulatore Wear ↔
   telefono fisico va provato a fondo — è l'unica parte con video di backup obbligatorio.
2. **Il layout tablet è automatico**: `pulse_coach/lib/shared/widgets/app_shell.dart`
   commuta a `NavigationRail` a ≥600 px. Nessuna schermata dedicata.
3. **La sessione condivisa è realmente peer-to-peer** via Supabase Realtime
   (`features/social/shared_session`): join code → lobby → presence/broadcast.
4. **Due gate distinti** (`core/cloud/entitlement_gate.dart`): il **login**
   (`accountFree` → `signedInFree`) sblocca social + sessione condivisa; il **Pro**
   (`signedInFree` → `pro`, via RevenueCat, nessun toggle debug) sblocca solo punti
   classifica e progressi completi. La sessione condivisa non ha entitlement guard
   (`submit_shared_session_result_use_case.dart`) → basta l'account.

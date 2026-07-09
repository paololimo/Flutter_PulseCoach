# PulseCoach — Runbook della demo live

Copione per la demo al corso universitario. Un arco unico: la giornata di un
utente su telefono e smartwatch, poi un allenamento in coppia tra due
dispositivi.

**Formato:** ~14 minuti · 2 presentatori · 3 dispositivi · rete via hotspot proprio.

---

## Ruoli e dispositivi

Setup a **4 device**: il **fisico** serve solo per l'intro (disclaimer +
onboarding + sensori reali); la parte **interattiva** (sessione, watch, sessione
condivisa) gira su **3 emulatori** — vedi "Comandi operativi" per gli AVD esatti.

| Ruolo | Dispositivi | Responsabilità |
|---|---|---|
| **Presentatore 1** | 📱 Telefono fisico (intro) · 📲 `Android_Phone` (emu) | Intro su hardware reale: onboarding + piano AI con **sensori reali** (meteo/posizione). Poi sull'emulatore telefono avvia la sessione ed è **peer B** nella sessione condivisa. |
| **Presentatore 2** | ⌚ `WearOS_Companion` · 🖥️ `Android_Tablet` | Gestisce watch (mirror della sessione) e tablet (layout adattivo); fa da **peer A** (login email+password, tier `signedInFree` — no Pro) nella sessione condivisa e nel social. |

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
- **P1 + P2 dice:** *«E notate cosa avete appena visto: l'app ha continuato a
  funzionare in modalità aereo. L'intelligenza è tutta on-device — i dati sanitari
  non lasciano mai il telefono. La privacy qui non è una policy, è una proprietà
  dell'architettura. Clean Architecture, offline-first con Drift, AI in isolate,
  sync realtime: un'unica base per telefono, watch e tablet. Grazie.»*

---

## Comandi operativi · device & emulatori (dry-run validato)

Assegnazione a **4 dispositivi** — decisa dopo la prova di banco, perché isola i
sensori veri sull'hardware e sposta la coppia sessione↔watch su **emulatore↔
emulatore** (dove il pairing è meno fragile del fisico↔emulatore):

| Ruolo | AVD / device | Immagine | Serve per |
|---|---|---|---|
| 📱 Fisico **pulito** — *solo intro* | SM A520F | Android 8 | Seg 2–3: disclaimer, onboarding, **meteo/AQI/posizione reali**. **Non** usato nella demo live |
| 📲 **`Android_Phone`** | Pixel · Play + GMS · API 34 | `google_apis_playstore` | Seg 4: sessione (peer del watch) · Seg 5: peer sessione condivisa |
| ⌚ **`WearOS_Companion`** | Wear OS 4 · **API 33** (accoppiabile) | `android-33;android-wear` | Seg 4: mirror step/timer/HR |
| 🖥️ **`Android_Tablet`** | Pixel Tablet · API 34 | `android-34;google_apis` | Seg 2 layout adattivo (NavigationRail ≥600 px) · Seg 5: secondo peer |

> I 3 AVD della demo sono **già creati**. L'iPad simulator è scartato: iOS non ha
> tap da riga di comando → non pilotabile in modo affidabile. Il tablet è un
> **emulatore Android** (NavigationRail comunque a ≥600 px, guidabile via `adb`).
> ⚠️ Gli **ID `emulator-55xx` si riassegnano** a ogni avvio/riavvio adb: ricava
> sempre l'ID reale con `flutter devices` / `adb devices -l`, e distingui i modelli
> con `adb -s <id> shell getprop ro.product.model`
> (`sdk_gphone64_arm64` telefono/tablet · `sdk_gwear_arm64` watch).

> ⚠️ Gli **ID cambiano**: dopo un riavvio dell'adb server o un secondo emulatore,
> le porte si riassegnano (nella prova il phone-emu ha preso `5554` e il Wear
> `5556`). Ricontrolla sempre con `flutter devices` / `adb devices -l` e distingui
> i modelli: `adb -s <id> shell getprop ro.product.model` → `sdk_gphone64_arm64`
> (telefono) vs `sdk_gwear_arm64` (watch). Far girare **4 VM insieme è pesante**:
> nella prova iPad + Wear si sono spenti sotto carico — avviali con margine e
> verifica che restino su prima di iniziare.

### 1 · Avvio emulatori

```bash
# i 3 AVD della demo (già creati)
flutter emulators --launch Android_Phone
flutter emulators --launch WearOS_Companion
flutter emulators --launch Android_Tablet

# attendi il boot completo di ciascuno (può volerci >1 min a freddo):
adb -s <ID> wait-for-device
until [ "$(adb -s <ID> shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 2; done

flutter devices   # conferma quali ID emulator-55xx hanno preso (cambiano!)
```

### 2 · Installazione / avvio app

L'app **non è preinstallata** su un emulatore appena creato. Usa il **debug apk**
(non `flutter install` liscio, che cerca il *release* e fallisce con
`app-release.apk does not exist`):

```bash
# telefono-emu (da pulse_coach/): APK già in build/, oppure ricostruiscilo
adb -s emulator-5554 install -r -t build/app/outputs/flutter-apk/app-debug.apk
# watch-emu (da pulse_coach/wear/): la prima build richiede ~30 s
( cd wear && flutter build apk --debug \
  && adb -s emulator-5556 install -r -t build/app/outputs/flutter-apk/app-debug.apk )

# launch (usa am start col component esplicito: monkey a volte non aggancia)
adb -s emulator-5554 shell am start -n com.pulsecoach.pulse_coach/.MainActivity
adb -s emulator-5556 shell am start -n com.pulsecoach.pulse_coach/com.pulsecoach.pulse_coach_wear.MainActivity
# 🖥️ iPad
xcrun simctl launch <UDID> com.paololimonta.pulsecoach
```

### 3 · Reset device per l'onboarding (segmento 2)

Il router salta l'onboarding se trova dati residui (SharedPreferences + DB Drift):
al primo avvio atterra su **Oggi**, non sul disclaimer. **Confermato in prova su
entrambe le piattaforme.** Svuota i dati:

```bash
# Android (fisico per l'intro, o emulatore tablet) — pm clear azzera anche i permessi
adb -s <ANDROID_ID> shell pm clear com.pulsecoach.pulse_coach
adb -s <ANDROID_ID> shell am start -n com.pulsecoach.pulse_coach/.MainActivity
# verifica: deve comparire "I tuoi dati restano tuoi." + "Avviso medico"
```

### 4 · Pairing dei due emulatori (segmento 4) — **punto fragile #1**

Il watch rispecchia la sessione **solo** con un pairing reale del **Wearable Data
Layer** (GMS): `watch_connectivity` non ha altro trasporto. Verificato in prova che
`adb forward tcp:5601` **da solo non basta** — il nodo Data-Layer (porta guest
`5601`) resta **chiuso** finché GMS non entra in modalità pairing, e ciò lo fa
**solo** l'assistente **«Pair Wearable» di Android Studio**. (Idem col telefono
fisico, che oltretutto è Android 8 → troppo vecchio: scartato.)

**Perché «Pair Wearable» non funzionava:** l'immagine Wear di default è **Wear OS
6.0 / API 36** (Android 16), troppo recente per l'assistente. Serve un'immagine
**accoppiabile — Wear OS 4 / API 33**. È **già installata** e l'AVD
**`WearOS_Companion`** è **già creato** con quella (per rifarli da zero):

```bash
SDK=~/Library/Android/sdk
"$SDK/cmdline-tools/latest/bin/sdkmanager" "system-images;android-33;android-wear;arm64-v8a"
echo no | "$SDK/cmdline-tools/latest/bin/avdmanager" create avd \
  -n WearOS_Companion -k "system-images;android-33;android-wear;arm64-v8a" -d wearos_large_round
```

Poi il pairing vero (GUI, una tantum) in **Android Studio → Device Manager**:
menu ⋮ dell'AVD **`Android_Phone`** (ha già Google Play + GMS) → **«Pair Wearable»**
→ scegli **`WearOS_Companion`** → completa l'assistente (stesso account Google su
entrambi). Da qui in poi il nodo Data-Layer è aperto e l'app rispecchia la sessione.

Verifica **prima** della demo con una sessione di prova completa (step → rest →
summary). Se in aula non aggancia entro ~15 s, **non insistere**: passa al **video
di backup** (vedi tabella fallback) — è per questo che è obbligatorio.

---

## Pre-flight · 15 minuti prima

### Ambiente & rete
- [ ] **Hotspot** del telefono acceso; tablet ed emulatore Wear connessi ad esso, non al Wi-Fi dell'aula. ⚠️ **Single point of failure**: da questo hotspot dipendono realtime, meteo e RevenueCat insieme — se cade, cadono i segmenti 3, 5 e il paywall in un colpo. Il fallback universale è il beat offline del segmento 6 (vedi tabella).
- [ ] **Scalda la cache**: apri l'app una volta connesso così meteo/AQI e catalogo sono già in Drift.
- [ ] Backend Supabase raggiungibile: prova un login con un seed user prima di iniziare.
- [ ] **Video di backup** pronto in una tab: catena telefono→watch (30–40 s).
- [ ] Luminosità schermi al massimo, blocco automatico e notifiche silenziati.

### P1 · Fisico (intro) + `Android_Phone` (emu)
- [ ] **Fisico pulito** (`pm clear`): al primo avvio atterra sul **disclaimer**. Permessi posizione già concessi così il **meteo reale** entra nel piano (in prova: "Temperatura: 33°").
- [ ] **`Android_Phone`** avviato, app installata (debug apk) e **onboardato** (Oggi con piano). È il device della **sessione** live e il **peer B** (login seed user 2) nella sessione condivisa.

### P2 · `WearOS_Companion` + `Android_Tablet`
- [ ] **`WearOS_Companion`** (Wear OS 4 / API 33) **accoppiato** ad `Android_Phone` via Android Studio → "Pair Wearable" (vedi §4). Bridge verificato con una sessione di prova completa (step → rest → summary). ⚠️ Se non si accoppia → **video di backup**.
- [ ] **`Android_Tablet`** a **installazione pulita** (`pm clear`), così il router forza l'onboarding al primo avvio. In orizzontale per la NavigationRail. ⚠️ Se atterra su Today, ripeti il wipe.
- [ ] Credenziali **peer A** (seed user 1, email+password) pronte; tier `signedInFree` (**no Pro** — voluto). Account peer A ha già **amici + feed** lato server. ⚠️ **Peer A già loggato con lobby di prova aperta prima della demo**: se il login fallisce lo scopri solo al segmento 5 sul palco.
- [ ] Verificato che una funzione Pro apre il **paywall / upsell sheet** (non bianco). Se RevenueCat non ha offerte, prepara il beat a voce.
- [ ] Sessione condivisa di prova creata e distrutta una volta (join code + presenza).

---

## Se qualcosa si rompe · fallback

| Severità | Sintomo | Contromossa |
|---|---|---|
| **Alta** | Pairing watch non aggancia | Non insistere dal vivo oltre 15 s. Passa al **video di backup** telefono→watch e continua a narrare. La sessione sul telefono prosegue comunque. |
| **Alta** | Peer A non risulta loggato al segmento 5 | Non improvvisare il login in silenzio. P2 rifà il login live sul tablet mentre P1 copre con la battuta social (amici/feed); poi crea il join code. Se anche il login live tentenna, mostra feed/leaderboard con i dati seed e descrivi la sessione condivisa a voce. |
| **Media** | Tablet atterra su Today invece dell'onboarding | Il wipe non è andato a fondo. Non forzare: descrivi l'onboarding a voce («disclaimer + profilo, tutto locale, nessun account») e passa dritto al layout adattivo — la NavigationRail è comunque visibile su Today. |
| **Media** | Battito vuoto sul telefono/Wear al segmento 4 | Usa la battuta preparata («il battito arriva da Health quando disponibile; qui mostriamo lo stream»). Step e timer sul Wear reggono senza HR: non insistere sul campo battito. |
| **Media** | Realtime social non aggiorna la presenza | Fai **pull-to-refresh** nella lobby. Se resta muto, mostra leaderboard/feed con i dati seed e descrivi il flusso realtime a voce. |
| **Media** | Meteo/posizione lenti o a vuoto | La cache scaldata copre il buco: il piano si genera lo stesso. Evita di ri-triggerare la posizione dal vivo se ha già risposto una volta. |
| **Bassa** | Piano AI lento a rigenerare | Riempi con la spiegazione del piano **già presente**; l'inferenza gira in isolate e non blocca la UI, quindi puoi parlare mentre elabora. |
| **Domanda attesa** | «E senza rete?» | Preparata: **modalità aereo** nel segmento 6 → catalogo e piano da cache Drift. Trasforma il rischio in feature. |
| **Domanda attesa** | «Ma il cloud non imparerebbe meglio? On-device è una scelta ideologica che costa in qualità?» | «No, è un vincolo trasformato in feature. Il bandit impara on-device dall'RPE senza rete, ed è proprio il fatto che tutto sia locale a rendere possibile l'explainability: la spiegazione è proiettata dagli stessi segnali che l'engine usa, non da un modello remoto opaco. Privacy ed explainability sono la stessa scelta architetturale.» |
| **Domanda attesa** | «È vera AI o if-else?» | «Vero online learner — bandit ε-greedy che aggiorna la policy dall'RPE percepito — ma incapsulato in un gate deterministico: sceglie solo dentro l'insieme di azioni che le regole di sicurezza hanno già dichiarato ammissibili.» |

---

## Note di verità (dal codice, da tenere a mente)

1. **Il pairing `watch_connectivity` è il punto fragile #1 — confermato in prova.**
   Richiede un pairing reale del Wearable Data Layer (GMS): il solo
   `adb forward tcp:5601` **non basta**, il mirror resta muto sia fisico↔emulatore
   sia emulatore↔emulatore. Va accoppiato a mano (Android Studio → "Pair Wearable")
   e provato a fondo — è l'unica parte con **video di backup obbligatorio**. Dettagli
   e comandi: sezione «Comandi operativi · §4».
2. **Il layout tablet è automatico**: `pulse_coach/lib/shared/widgets/app_shell.dart`
   commuta a `NavigationRail` a ≥600 px. Nessuna schermata dedicata.
3. **La sessione condivisa è realmente peer-to-peer** via Supabase Realtime
   (`features/social/shared_session`): join code → lobby → presence/broadcast.
4. **Due gate distinti** (`core/cloud/entitlement_gate.dart`): il **login**
   (`accountFree` → `signedInFree`) sblocca social + sessione condivisa; il **Pro**
   (`signedInFree` → `pro`, via RevenueCat, nessun toggle debug) sblocca solo punti
   classifica e progressi completi. La sessione condivisa non ha entitlement guard
   (`submit_shared_session_result_use_case.dart`) → basta l'account.

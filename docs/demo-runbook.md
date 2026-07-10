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
| **Presentatore 1** | 📱 Telefono fisico (intro) · 📲 `Phone_Play` (emu) | Intro su hardware reale: onboarding + piano AI con **sensori reali** (meteo/posizione). Poi sull'emulatore telefono avvia la sessione ed è **peer B** nella sessione condivisa. |
| **Presentatore 2** | ⌚ `WearOS_Companion` · 🖥️ `Android_Tablet` | Gestisce watch (mirror della sessione **solo**) e tablet (layout adattivo); fa da **peer A / host** (login email+password, **Pro** attivo) nella sessione condivisa e nel social. |

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

### 5 · Sessione condivisa & social (feature Pro) — `9:30 → 12:30` · 📲 Tablet + 📱 Telefono

> **Gate (dry-run 2026-07-09):** in questa build **tutto il Social — amici, feed,
> confronto, classifica E la sessione condivisa — è Pro** (`social_page.dart` →
> paywall se `tier != pro`). Quindi il paywall è il **gate d'ingresso**, non un
> beat separato. Per la demo **entrambi i peer hanno il Pro** (concesso via
> RevenueCat, §4) così la sessione condivisa è accessibile.

**a) Il paywall come gate — `9:30 → 10:00`**

- **P1 fa** (device **non-Pro** — il telefono fisico dell'intro è account-free):
  tocca **Social** → compare il **paywall / upsell sheet**. Non acquistare: mostra
  e chiudi. *(Se il fisico non è a portata, narralo — vedi fallback.)*
- **P2 dice:** *«Social, amici e allenamento in coppia sono la leva Pro.
  L'entitlement è servito da RevenueCat con fallback offline: se il gate non
  risponde, l'app degrada al tier free, non crasha.»*

**b) Sessione condivisa + social (sbloccati col Pro) — `10:00 → 12:30`**

- **P2 fa** (tablet — **peer A + Pro**): **Social → Amici → «Sessione condivisa»**
  → mostra il **join code** nella «Sala d'attesa».
- **P1 fa** (Phone_Play — **peer B + Pro**): **Social → «Unisciti a una sessione»**
  → inserisce il join code → entra nella lobby; il tablet aggiorna la presenza dal vivo.
- **P2 fa:** l'host tocca **«Avvia»** (si abilita solo quando il 2° peer è entrato)
  → parte la sessione condivisa (**«2 participants»**) su entrambi. Poi passa su
  **amici** e **feed** per chiudere il giro social.
- **P2 dice:** *«Presenza e broadcast passano da Supabase Realtime: quando uno dei
  due entra, l'altro schermo si aggiorna senza refresh manuale.»*

> ⚠️ **Il watch NON rispecchia la sessione condivisa** (mirror solo per la sessione
> *solo* del seg. 4). Resta connesso ma mostra lo stato precedente — non fermarti su di lui qui.

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

### 🚀 Sequenza demo — in ordine (app, AVD, login e Pro sono GIÀ pronti)

> Ordine pensato per **non** far fallire il login: rete pulita prima, watch dopo.
> ID freschi ogni volta: `adb devices -l` → phone=`1080x2400`, tablet=`2560x1600`,
> watch=model `gwear`. Nomi AVD esatti: `Phone_Play` · `Android_Tablet` · `WearOS_Companion`.

```bash
# 1. SOLO phone + tablet (rete pulita → login/realtime affidabili)
flutter emulators --launch Phone_Play
flutter emulators --launch Android_Tablet
adb devices -l                                     # ricava PHONE_ID / TABLET_ID
adb -s <PHONE_ID>  shell am start -n com.pulsecoach.pulse_coach/.MainActivity
adb -s <TABLET_ID> shell am start -n com.pulsecoach.pulse_coach/.MainActivity

# 2. login e Pro PERSISTONO dai run precedenti → di norma NIENTE da fare.
#    Se il Social mostra il paywall o il login non c'è più → §4 / §5.
#    Se «Accesso non riuscito» con credenziali giuste = rete satura, non le creds.

# 3. sessione condivisa (in-app, §5): tablet «Sessione condivisa» → join code →
#    phone «Unisciti a una sessione» → codice → host «Avvia».

# 4. ADESSO il watch (NON riparte già connesso — §3)
flutter emulators --launch WearOS_Companion
adb devices -l                                     # ricava WATCH_ID
adb -s <PHONE_ID> forward tcp:5601 tcp:5601
adb -s <WATCH_ID> reverse tcp:5601 tcp:5601
adb -s <PHONE_ID> shell monkey -p com.google.android.apps.wear.companion -c android.intent.category.LAUNCHER 1
sleep 12
adb -s <PHONE_ID> logcat -d | grep -i onConnectedNodes    # deve dire isNearby=true
adb -s <WATCH_ID> shell am start -n com.pulsecoach.pulse_coach/com.pulsecoach.pulse_coach_wear.MainActivity
#    nodo non su? → GUI «Pair Wearable» (§3)
```

---

Assegnazione a **4 dispositivi** — decisa dopo la prova di banco, perché isola i
sensori veri sull'hardware e sposta la coppia sessione↔watch su **emulatore↔
emulatore** (dove il pairing è meno fragile del fisico↔emulatore):

| Ruolo | AVD / device | Immagine | Serve per |
|---|---|---|---|
| 📱 Fisico **pulito** — *solo intro* | SM A520F | Android 8 | Seg 2–3: disclaimer, onboarding, **meteo/AQI/posizione reali**. **Non** usato nella demo live |
| 📲 **`Phone_Play`** | Pixel · Play + GMS · API 34 | `google_apis_playstore` | Seg 4: sessione (peer del watch) · Seg 5: **peer B** sessione condivisa (login `marco.rossi`) |
| ⌚ **`WearOS_Companion`** | Wear OS 4 · **API 33** (accoppiabile) | `android-33;android-wear` | Seg 4: mirror step/timer/HR |
| 🖥️ **`Android_Tablet`** | Pixel Tablet · API 34 | `android-34;google_apis` | Seg 2 layout adattivo (NavigationRail ≥600 px) · Seg 5: **peer A/host** (login `paolo.coach`) |

> ⚠️ **Nome AVD reale del telefono = `Phone_Play`** (non `Android_Phone`, che era il
> nome nella prima stesura). Verificalo con `flutter emulators`.

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

> 🔴 **Lezione dal dry-run 2026-07-09 — saturazione di rete = login/realtime rotti.**
> Con **3–4 VM Android insieme** lo stack di rete dell'emulatore degrada (misurato
> **66% packet loss** verso Supabase, DHCP che rinnova l'IP a metà richiesta): il
> **login Supabase fallisce** ("Accesso non riuscito") anche con **credenziali
> valide** — non è colpa dei defines né della password. **Contromossa:** fai il
> **login + join sessione condivisa con SOLO phone + tablet accesi** (rete pulita →
> login passa al primo colpo), e **accendi il watch dopo**. Login, Pro e pairing
> **persistono** al riavvio delle VM (stanno sul disco dell'AVD); il **bridge adb**
> (`forward`/`reverse`) e a volte il nodo GMS **no** → vanno rifatti (vedi §3).

### 1 · Avvio emulatori

```bash
# PRIMA phone + tablet (rete pulita per login/sessione condivisa). Watch DOPO.
flutter emulators --launch Phone_Play
flutter emulators --launch Android_Tablet
# ...fai login + Pro + join sessione condivisa, POI:
flutter emulators --launch WearOS_Companion

# attendi il boot completo di ciascuno (può volerci >1 min a freddo):
until [ "$(adb -s <ID> shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 2; done
adb devices -l    # gli ID cambiano! distingui: wm size 1080x2400=phone · 2560x1600=tablet
```

> App, AVD, login e Pro sono **già installati/configurati** e **persistono** ai
> riavvii → il giorno della demo **non** rebuildi né reinstalli. (Solo se un device
> viene azzerato con `pm clear`: app da reinstallare e Pro da riconcedere.)

### 2 · Reset device per l'onboarding (segmento 2)

Il router salta l'onboarding se trova dati residui (SharedPreferences + DB Drift):
al primo avvio atterra su **Oggi**, non sul disclaimer. **Confermato in prova su
entrambe le piattaforme.** Svuota i dati:

```bash
# Android (fisico per l'intro, o emulatore tablet) — pm clear azzera anche i permessi
adb -s <ANDROID_ID> shell pm clear com.pulsecoach.pulse_coach
adb -s <ANDROID_ID> shell am start -n com.pulsecoach.pulse_coach/.MainActivity
# verifica: deve comparire "I tuoi dati restano tuoi." + "Avviso medico"
```

### 3 · Watch: riaggancio a ogni demo (+ setup una-tantum) — senza Gmail

Il watch rispecchia la sessione **solo** con un pairing reale del **Wearable Data
Layer** (GMS): `watch_connectivity` non ha altro trasporto. `adb forward tcp:5601`
**da solo non basta**; serve il broker gRPC dell'assistente **«Pair Wearable» di
Android Studio**.

**Il watch NON riparte già connesso.** Il pairing resta configurato in GMS, ma a ogni
riavvio delle VM il **bridge adb si azzera** e il nodo va **rieccitato**. Questo è
ciò che fai **ogni demo**, dopo aver avviato il watch:

```bash
adb devices -l                                     # ID freschi: watch = model gwear
adb -s <PHONE_ID> forward tcp:5601 tcp:5601
adb -s <WATCH_ID> reverse tcp:5601 tcp:5601
# fa ripartire la companion → riapre il nodo Data-Layer
adb -s <PHONE_ID> shell monkey -p com.google.android.apps.wear.companion -c android.intent.category.LAUNCHER 1
sleep 12
adb -s <PHONE_ID> logcat -d | grep -i onConnectedNodes   # atteso: Node{WearOS_Companion,...,isNearby=true}
# lancia l'app wear
adb -s <WATCH_ID> shell am start -n com.pulsecoach.pulse_coach/com.pulsecoach.pulse_coach_wear.MainActivity
```

> ⚠️ La companion può far comparire sul telefono un pop-up **«Choose a device to be
> managed by Wear OS»** → **BACK** per chiuderlo, il nodo GMS resta su.
> Se il nodo **non** riaggancia via CLI → **Android Studio → Device Manager → ⋮
> `Phone_Play` → «Pair Wearable» → `WearOS_Companion»**. La companion Pixel Watch è
> **già installata**, quindi l'assistente **non chiede Gmail**.

> 🔵 **Limite noto — il watch NON rispecchia la sessione CONDIVISA** (solo quella
> *solo*, seg. 4). Nel seg. 5 il watch resta connesso ma mostra l'ultimo stato della
> sessione solo. Per il mirror live usa una sessione solo.

Verifica **prima** della demo con una sessione **solo** completa (step → rest →
summary). Se in aula non aggancia entro ~15 s, **non insistere** → **video di backup**.

<details><summary><b>Setup una-tantum (già fatto — solo se azzeri l'AVD/`pm clear`)</b></summary>

L'assistente «Pair Wearable» pretende la companion **Pixel Watch**
(`com.google.android.apps.wear.companion`) che da Play Store vorrebbe un login Google.
Si aggira **sideloadando l'APK** (già in `~/Downloads/`, da APKMirror), poi la GUI
«Pair Wearable» procede senza account:

```bash
adb -s <PHONE_ID> install -r -t ~/Downloads/com.google.android.apps.wear.companion_*.apk
# poi Android Studio → Device Manager → ⋮ Phone_Play → «Pair Wearable» → WearOS_Companion
```
(L'immagine Wear dev'essere **Wear OS 4 / API 33**; l'AVD `WearOS_Companion` lo è già.)
</details>

### 4 · Sbloccare il Pro (obbligatorio per Social + sessione condivisa)

⚠️ **Aggiornamento dry-run 2026-07-09:** in questa build il Social e la sessione
condivisa sono **Pro-gated** (`social_page.dart:107` → `tier == pro`), non basta il
login come diceva la vecchia nota. Il Pro viene da RevenueCat (nessun toggle debug).
Concedilo via **RevenueCat REST v2** con la secret in `pulse_coach/.rc-secret`
(gitignored). L'app usa un `app_user_id` **anonimo per-install**, quindi il grant va
fatto **su ogni dispositivo** e **si perde con `pm clear`** (nuovo ID → rifare):

```bash
cd pulse_coach
SECRET=$(cat .rc-secret | tr -d '\n\r ')
PROJ=proj8397e138          # progetto "Pulse Coach"
ENT=entlc01d59f113         # entitlement lookup_key "pro"
EXP=$(( ($(date +%s) + 31536000) * 1000 ))   # +1 anno

# ricava l'app_user_id anonimo di un device (app debuggable):
get_auid () { adb -s "$1" shell run-as com.pulsecoach.pulse_coach \
  cat /data/data/com.pulsecoach.pulse_coach/shared_prefs/com_revenuecat_purchases_preferences.xml \
  | grep -oE '\$RCAnonymousID:[a-f0-9]+' | head -1; }

for DEV in <PHONE_ID> <TABLET_ID>; do
  AUID=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$(get_auid $DEV)")
  curl -s -X POST \
    "https://api.revenuecat.com/v2/projects/$PROJ/customers/$AUID/actions/grant_entitlement" \
    -H "Authorization: Bearer $SECRET" -H "Content-Type: application/json" \
    -d "{\"entitlement_id\":\"$ENT\",\"expires_at\":$EXP}" | grep -o active_entitlements
done
# poi RIAVVIA l'app su entrambi (force-stop + am start) → il gate rilegge RevenueCat
```

### 5 · Sessione condivisa (segmento 5) — flusso in-app

1. **Tablet (peer A / host)** già loggato `paolo.coach` + Pro → tab **Social → Amici**
   → **«Sessione condivisa»** → compare **join code** (es. `3BGVWE`) nella «Sala d'attesa».
2. **Phone (peer B)** loggato `marco.rossi` + Pro → **Social → «Unisciti a una
   sessione»** → digita il join code → **Join**.
3. La **presenza realtime** (Supabase) sincronizza: il tablet elenca entrambi
   (`@paolo_c` + `@marco_r`) e il bottone **«Avvia»** si abilita.
4. **Host tocca «Avvia»** → parte la sessione condivisa (**«2 participants»**) su
   entrambi. (Credenziali seed: password condivisa `pulse_claude`.)

---

## Pre-flight · 15 minuti prima

### Ambiente & rete
- [ ] **Hotspot** del telefono acceso; tablet ed emulatore Wear connessi ad esso, non al Wi-Fi dell'aula. ⚠️ **Single point of failure**: da questo hotspot dipendono realtime, meteo e RevenueCat insieme — se cade, cadono i segmenti 3, 5 e il paywall in un colpo. Il fallback universale è il beat offline del segmento 6 (vedi tabella).
- [ ] **Scalda la cache**: apri l'app una volta connesso così meteo/AQI e catalogo sono già in Drift.
- [ ] Backend Supabase raggiungibile: prova un login con un seed user prima di iniziare.
- [ ] **Video di backup** pronto in una tab: catena telefono→watch (30–40 s).
- [ ] Luminosità schermi al massimo, blocco automatico e notifiche silenziati.

### P1 · Fisico (intro) + `Phone_Play` (emu)
- [ ] **Fisico pulito** (`pm clear`): al primo avvio atterra sul **disclaimer**. Permessi posizione già concessi così il **meteo reale** entra nel piano (in prova: "Temperatura: 33°").
- [ ] **`Phone_Play`** avviato, app installata (debug apk) e **onboardato** (Oggi con piano). È il device della **sessione** live e il **peer B** (login `marco.rossi` / `pulse_claude`) nella sessione condivisa.
- [ ] **Companion Pixel Watch sideloadata** su `Phone_Play` (§3) — prerequisito per il pairing senza Gmail.

### P2 · `WearOS_Companion` + `Android_Tablet`
- [ ] **`WearOS_Companion`** (Wear OS 4 / API 33) **accoppiato** a `Phone_Play` via Android Studio → "Pair Wearable" (vedi §3). Nodo verificato con `logcat | grep onConnectedNodes` **e** una sessione **solo** completa (step → rest → summary). ⚠️ Se non si accoppia → **video di backup**.
- [ ] **`Android_Tablet`** loggato come **peer A/host** (`paolo.coach` / `pulse_claude`), **Pro attivo** (§4), in orizzontale per la NavigationRail. (Per rimostrare l'onboarding da zero: `pm clear` + riavvio.)
- [ ] **Pro concesso a ENTRAMBI** i device via RevenueCat REST (§4) e verificato che **Social apre la schermata vera** (tab Amici/Feed/Confronto/Classifica), non il paywall. ⚠️ Il grant **si perde con `pm clear`** → rifallo dopo ogni wipe.
- [ ] **Login testato con SOLO phone+tablet accesi** (rete pulita) prima di accendere il watch — evita il fallimento da saturazione.
- [ ] Sessione condivisa di prova creata e distrutta una volta (join code + presenza + «Avvia» abilitato).

---

## Se qualcosa si rompe · fallback

| Severità | Sintomo | Contromossa |
|---|---|---|
| **Alta** | Pairing watch non aggancia | Non insistere dal vivo oltre 15 s. Passa al **video di backup** telefono→watch e continua a narrare. La sessione sul telefono prosegue comunque. |
| **Alta** | Peer A non risulta loggato al segmento 5 | Non improvvisare il login in silenzio. P2 rifà il login live sul tablet mentre P1 copre con la battuta social (amici/feed); poi crea il join code. Se anche il login live tentenna, mostra feed/leaderboard con i dati seed e descrivi la sessione condivisa a voce. |
| **Alta** | Login «Accesso non riuscito» con credenziali giuste | **Rete satura dell'emulatore** (troppe VM). Le credenziali sono valide — non ritoccarle. **Spegni il watch**, lascia solo phone+tablet, ritenta: il login passa. Login/Pro **persistono**, riaccendi il watch dopo. (§ warning "saturazione di rete".) |
| **Alta** | Social mostra il paywall Pro invece della schermata vera | Il **grant Pro non è attivo** su quel device (o perso con un `pm clear`). Rifai il grant RevenueCat (§4) e **riavvia l'app**. Se in aula non risolvi, mostra il flusso a voce. |
| **Media** | Watch connesso ma fermo su stato vecchio in seg. 5 | **Atteso**: il mirror è cablato solo alla sessione **solo**, non alla condivisa (§3). Non è un bug live — mostra il mirror nel seg. 4 (sessione solo), non nel 5. |
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

1. **Il pairing `watch_connectivity` — RISOLTO senza Gmail (dry-run 2026-07-09).**
   Richiede il Wearable Data Layer (GMS): il solo `adb forward tcp:5601` non basta,
   serve il broker «Pair Wearable» di Android Studio, che a sua volta pretende la
   companion **Pixel Watch** — **sideloadala** (APK) per saltare il login Google.
   Il nodo va **rieccitato a ogni riavvio** (bridge `forward`/`reverse` + rilancio
   companion). Il mirror funziona **solo per la sessione solo**, non per la condivisa.
   Resta l'unica parte con **video di backup obbligatorio**. Dettagli e comandi: §3 + §3.
2. **Il layout tablet è automatico**: `pulse_coach/lib/shared/widgets/app_shell.dart`
   commuta a `NavigationRail` a ≥600 px. Nessuna schermata dedicata.
3. **La sessione condivisa è realmente peer-to-peer** via Supabase Realtime
   (`features/social/shared_session`): join code → lobby → presence/broadcast.
4. **⚠️ CORRETTO (dry-run 2026-07-09): il Social — e con esso l'ingresso alla
   sessione condivisa — è Pro-gated.** `social_page.dart:107` mostra il
   `_LockedBanner`/paywall se `tier != SubscriptionTier.pro`. Quindi non basta il
   login: serve **Pro** (via RevenueCat, nessun toggle debug → concesso via REST, §4).
   Il tier viene da `entitlement_gate.dart` → `isProFetcher` = solo RevenueCat
   (`entitlements.active['pro']`), su `app_user_id` **anonimo per-install**. La
   *submit* del risultato condiviso non ha guard, ma **l'UI per arrivarci sì**.
   (La vecchia nota "basta l'account" era sbagliata.)

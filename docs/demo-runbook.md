# PulseCoach — Comandi demo (emulatori + pairing watch)

AVD: `Phone_Play` · `Android_Tablet` · `WearOS_Companion`.

## 1 · Funzione di risoluzione ID

Copia-incolla una volta per terminale. La richiami con `resolve_ids` ogni volta
che avvii/riavvii un emulatore: popola `$PHONE_ID` / `$TABLET_ID` / `$WATCH_ID`
(watch = model `gwear`, tablet = `wm size` `2560x1600`, resto = phone).

```bash
resolve_ids() {
  PHONE_ID=""; TABLET_ID=""; WATCH_ID=""
  local id model size
  while read -r id; do
    [ -z "$id" ] && continue
    model=$(adb -s "$id" shell getprop ro.product.model </dev/null | tr -d '\r')
    case "$model" in
      *gwear*) WATCH_ID="$id" ;;
      *)
        size=$(adb -s "$id" shell wm size </dev/null | grep -oE '[0-9]+x[0-9]+' | tail -1)
        case "$size" in
          2560x1600) TABLET_ID="$id" ;;
          *) PHONE_ID="$id" ;;
        esac
        ;;
    esac
  done <<< "$(adb devices | tail -n +2 | awk 'NF{print $1}')"
  export PHONE_ID TABLET_ID WATCH_ID
  echo "PHONE_ID=$PHONE_ID  TABLET_ID=$TABLET_ID  WATCH_ID=$WATCH_ID"
}
```

## 2 · Avvio emulatori

Phone + tablet prima (rete pulita), watch dopo.

```bash
flutter emulators --launch Phone_Play
flutter emulators --launch Android_Tablet
sleep 20                                           # boot a freddo: dai margine
resolve_ids
adb -s "$PHONE_ID"  shell am start -n com.pulsecoach.pulse_coach/.MainActivity
adb -s "$TABLET_ID" shell am start -n com.pulsecoach.pulse_coach/.MainActivity

flutter emulators --launch WearOS_Companion
sleep 15
resolve_ids                                        # ora popola anche $WATCH_ID
```

## 3 · Pairing watch

Il watch **non riparte già connesso**: il nodo GMS va rieccitato a ogni riavvio delle VM.

```bash
resolve_ids
adb -s "$PHONE_ID" forward tcp:5601 tcp:5601
adb -s "$WATCH_ID" reverse tcp:5601 tcp:5601
adb -s "$PHONE_ID" shell monkey -p com.google.android.apps.wear.companion -c android.intent.category.LAUNCHER 1
sleep 12
adb -s "$PHONE_ID" logcat -d | grep -i onConnectedNodes    # deve dire isNearby=true
adb -s "$WATCH_ID" shell am start -n com.pulsecoach.pulse_coach/com.pulsecoach.pulse_coach_wear.MainActivity
```

Se `onConnectedNodes` non mostra `isNearby=true` entro ~15s → Android Studio →
Device Manager → ⋮ `Phone_Play` → «Pair Wearable» → `WearOS_Companion`.

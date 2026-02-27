# Teams WebView App — Guida Completa

## Struttura del progetto
```
teams_app/
├── lib/
│   └── main.dart              ← Codice principale app
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/com/teamsaz/teamsapp/MainActivity.kt
│   │       └── res/
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   └── Assets.xcassets/
│   ├── Runner.xcodeproj/
│   ├── Runner.xcworkspace/
│   └── Podfile
├── .github/
│   └── workflows/
│       └── build-ios.yml      ← Build iOS automatica su Mac cloud (GRATIS)
└── pubspec.yaml
```

---

## Cosa fa l'app

- Carica **teams.microsoft.com** con user agent **desktop Chrome** (funziona come da PC)
- Splash screen con logo Teams mentre carica
- Barra di progresso durante il caricamento
- Schermata "Nessuna connessione" con pulsante Riprova
- Pulsante Back Android funzionante
- Blocca i popup "Scarica l'app nativa" di Teams
- Permessi automatici per microfono e fotocamera (chiamate)
- Supporto orientamento verticale e orizzontale
- Cookie e sessione salvati (rimani loggato)

---

## PERCORSO A — iPhone da Windows (RACCOMANDATO, tutto GRATIS)

> Niente Mac fisico richiesto. La build avviene su un Mac virtuale di GitHub.

### Strumenti necessari (tutti gratuiti)
| Strumento | A cosa serve |
|---|---|
| **Git** (già installato) | Caricare il codice su GitHub |
| **GitHub** (account gratuito) | Ospitare il progetto e far girare la build |
| **GitHub Actions** (incluso in GitHub) | Compila l'IPA su Mac cloud gratuito |
| **iTunes** per Windows | Comunicare con l'iPhone |
| **Sideloadly** per Windows | Installare l'IPA sull'iPhone |

---

### FASE 1 — Crea repository GitHub

1. Vai su **github.com** → crea account (o accedi)
2. Clic su **"New repository"**
3. Nome: `teams-app`
4. Visibilità: **Public** (i runner macOS gratuiti di GitHub Actions funzionano su repo pubbliche)
5. Clic **"Create repository"**

### FASE 2 — Carica il progetto su GitHub

Apri Git Bash nella cartella `teams_app` ed esegui:

```bash
# Inizializza git
git init
git add .
git commit -m "Primo commit — Teams WebView App"

# Collegati al tuo repository (sostituisci TUONOME con il tuo username GitHub)
git remote add origin https://github.com/TUONOME/teams-app.git
git branch -M main
git push -u origin main
```

### FASE 3 — Avvia la build iOS (automatica)

Non devi fare niente: il push del codice avvia automaticamente la build.

Oppure avviala manualmente:
1. Vai su `github.com/TUONOME/teams-app`
2. Clic su **"Actions"** in alto
3. Clic su **"Build iOS IPA"** a sinistra
4. Clic su **"Run workflow"** → **"Run workflow"**

La build dura circa **15-20 minuti**.

### FASE 4 — Scarica l'IPA

1. Vai su **Actions** nel tuo repository
2. Clic sull'ultima build completata (pallino verde)
3. Scorri in basso fino ad **"Artifacts"**
4. Clic su **"teams-app-ios"** → scarica lo ZIP
5. Estrai lo ZIP → trovi `teams_app.ipa`

### FASE 5 — Installa su iPhone con Sideloadly

1. **Installa iTunes** (da Apple o Microsoft Store)
2. **Scarica Sideloadly** (cerca "sideloadly.io" e scarica la versione Windows)
3. **Collega iPhone al PC** con cavo USB
4. **Sblocca il telefono** e tocca "Fidati di questo computer"
5. **Apri Sideloadly**:
   - Trascina il file `teams_app.ipa` nella finestra di Sideloadly
   - Il tuo iPhone dovrebbe apparire in alto
   - Inserisci il tuo **Apple ID** (quello gratuito va benissimo)
   - Clic su **"Start"**
6. Su iPhone: **Impostazioni → Generali → Gestione VPN e dispositivo → [tuo Apple ID] → Considera attendibile**
7. Apri l'app **Teams** dalla schermata Home

> **Nota scadenza**: Con Apple ID gratuito l'app scade ogni **7 giorni**.
> Basta rifare il passo 5 (Sideloadly) per rinnovarla in 2 minuti.
> Con un **Apple Developer account a pagamento (€99/anno)** non scade mai.

---

## PERCORSO B — Android APK (più semplice, Windows o Mac)

### Prerequisiti
1. Installa **Flutter**: vai su flutter.dev/docs/get-started/install → scarica per Windows
2. Aggiungi `flutter/bin` al PATH
3. Installa **Android Studio** (include l'SDK Android)
4. Verifica: `flutter doctor`

### Build APK
```bash
cd teams_app
flutter pub get
flutter build apk --release
```

L'APK si trova in:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Installa l'APK
**Via cavo USB:**
```bash
flutter install
```

**Condividi il file APK** (WhatsApp, email, Drive):
1. Apri il file APK sul telefono Android
2. Se appare "Installazione da sorgenti sconosciute" → Impostazioni → attiva
3. Tocca **Installa**

---

## PERCORSO C — iPhone con Mac fisico

> Se hai accesso a un Mac (anche di un collega), questo è il percorso più pulito.

1. Installa Xcode dall'App Store
2. Installa Flutter: `flutter.dev/docs/get-started/install/macos`
3. ```bash
   cd teams_app
   flutter pub get
   cd ios && pod install && cd ..
   open ios/Runner.xcworkspace
   ```
4. In Xcode: **Signing & Capabilities** → seleziona il tuo Team (Apple ID gratuito)
5. Cambia Bundle ID in qualcosa di unico: `com.tuonome.teamsapp`
6. ```bash
   flutter build ipa
   ```
7. IPA in: `build/ios/ipa/teams_app.ipa`
8. Installa con **AltStore** o **Sideloadly**

---

## Problemi comuni

| Problema | Soluzione |
|---|---|
| GitHub Actions fallisce | Controlla i log nella tab "Actions" → clicca sulla build fallita |
| Sideloadly chiede password | Usa la App Password di Apple (non la password iCloud) se hai 2FA attiva |
| App non si apre dopo installazione | Vai in Impostazioni → Generali → Gestione VPN e dispositivo → fidati del developer |
| Teams mostra versione mobile | L'user agent desktop è configurato, attendi il caricamento completo |
| Build APK Android fallisce | Esegui `flutter clean` poi riprova |
| `flutter: command not found` | Aggiungi flutter/bin al PATH di sistema |

---

## Supporto
Se hai problemi, condividi il log di errore dalla tab "Actions" di GitHub.

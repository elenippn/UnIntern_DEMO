# UnIntern (DEMO) —  (Backend + Frontend)

## Περιγραφή

Η εφαρμογή **UnIntern** είναι μια πλατφόρμα που συνδέει φοιτητές με εταιρείες για θέσεις πρακτικής άσκησης.

Αυτό το repository είναι **monorepo** και περιέχει:

- **Backend (FastAPI + SQLite):** REST API server
- **Frontend (Flutter):** εφαρμογή για Windows / Web / Android

Δομή:

```
UnIntern_DEMO/
├── backend/   # FastAPI app
└── frontend/  # Flutter app
```

---

## Δυνατότητες

- Εγγραφή και σύνδεση χρηστών (φοιτητές & εταιρείες)
- Προβολή και αναζήτηση θέσεων πρακτικής
- Διαχείριση προφίλ
- News feed με posts
- Αλληλεπίδραση (likes, comments, saves)
- Σύστημα chat
- Ανέβασμα media files

---

## Γρήγορη εγκατάσταση (Windows)

### Προαπαιτούμενα

- Windows
- Python 3.10+
- Flutter (stable)
- Git
- (Web) Chrome

---

## 1) Backend (FastAPI)

### 1.1 Clone

```powershell
cd C:\Users\<TO_ONOMA_SOU>\Documents
git clone https://github.com/elenippn/UnIntern_DEMO.git
cd UnIntern_DEMO\backend
```

### 1.2 Virtual environment

```powershell
py -m venv .venv
```

### 1.3 Activate venv

```powershell
.venv\Scripts\Activate.ps1
```

Αν εμφανιστεί σφάλμα execution policy, τρέξε **μία φορά**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

και ξανά:

```powershell
.venv\Scripts\Activate.ps1
```

### 1.4 Install dependencies

```powershell
pip install -r requirements.txt
```

### 1.5 Βάση (SQLite) / Seed

Το backend χρησιμοποιεί SQLite.

- Αν θέλεις να δημιουργήσεις/επαναφέρεις βάση με αρχικά δεδομένα:

```powershell
py -m app.seed
```

### 1.6 Εκκίνηση server

```powershell
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Έλεγχος:

- http://127.0.0.1:8000/
- http://127.0.0.1:8000/docs

Άφησε αυτό το terminal ανοιχτό.

---

## 2) Frontend (Flutter)

### 2.1 Setup

Άνοιξε **νέο** PowerShell (ο backend να τρέχει στο άλλο) και τρέξε:

```powershell
cd C:\Users\<TO_ONOMA_SOU>\Documents\UnIntern_DEMO\frontend
flutter pub get
```

### 2.2 Run

Windows Desktop:

```powershell
flutter run -d windows
```

Web (Chrome):

```powershell
flutter run -d chrome
```

Android emulator:

```powershell
flutter run
```

---

## APK Release (Android)

Η εφαρμογή μπορεί να παραδοθεί και ως **release APK**.

Η δημιουργία APK απαιτεί Android toolchain (Android SDK / build-tools) και σωστό setup στο Flutter.
Σε περιβάλλον **macOS** είναι εφικτό να παραχθεί APK, αρκεί να έχει εγκατασταθεί το Android Studio και να έχουν ρυθμιστεί σωστά τα paths.

Από τον φάκελο του Flutter project:

```powershell
cd C:\Users\<TO_ONOMA_SOU>\Documents\UnIntern_DEMO\frontend
flutter clean
flutter pub get
flutter build apk --release
```

Το παραγόμενο αρχείο βρίσκεται συνήθως στο:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Backend hosting και καθυστέρηση απόκρισης (Render)

Το backend είναι φιλοξενούμενο στο Render με το δωρεάν (free) πακέτο.
Στο free tier το Render μπορεί να κάνει **cold start** όταν η υπηρεσία μείνει ανενεργή, με αποτέλεσμα η **πρώτη** κλήση στο API να αργεί (μερικά δευτερόλεπτα) μέχρι να «ξυπνήσει» ο server.

---

## API Base URL (Frontend ↔ Backend)

Το frontend χρησιμοποιεί by default:

- Windows/Desktop: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- Web: `http://<current-host>:8000`

Αν χρειαστεί, μπορείς να κάνεις override με compile-time flag:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

---

## Δοκιμαστικοί λογαριασμοί

Μετά το seed, μπορείς να συνδεθείς ενδεικτικά με:

- Student: `eleni` / `pass1234`
- Company: `techcorp` / `pass1234`

---

## Troubleshooting

### Backend: Port 8000 already in use

```powershell
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### Frontend: δεν συνδέεται με backend

- Βεβαιώσου ότι ο backend τρέχει και ανοίγει το `http://127.0.0.1:8000/`.
- Για web, βεβαιώσου ότι τρέχεις backend στο ίδιο machine/port.
- Δοκίμασε restart και των δύο (Ctrl+C και ξανά start).

---

## Σημειώσεις για demo assets

Σε αυτό το demo repo μπορεί να υπάρχουν committed artifacts (π.χ. SQLite βάση/Uploads). Αν θέλεις “production-style” repo (χωρίς generated data), πρόσθεσε τα σχετικά paths στο `.gitignore`.

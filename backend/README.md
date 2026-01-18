# UnIntend Backend (Setup + Βάση)

## Προαπαιτούμενα

- Windows
- Python 3.x (προτείνεται 3.10+)
- Git
- PowerShell (για activation του venv)

## 1) Κατέβασμα κώδικα (git clone)

```powershell
git clone https://github.com/elenippn/Unintend_backend.git
```

Μπες στον φάκελο που κατέβασες το project (βάζεις το **δικό σου** path):

```powershell
cd C:\Users\<TO_ONOMA_SOU>\<KAPOIOS_FAKOLOS>\Unintend_backend
```

## 2) Δημιουργία virtual environment

```powershell
py -m venv .venv
```

## 3) Ενεργοποίηση venv (PowerShell)

```powershell
.venv\Scripts\Activate.ps1
```

Αν σου βγάλει error για execution policy, τρέξε **μία φορά**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

…και μετά ξανατρέξε:

```powershell
.venv\Scripts\Activate.ps1
```

## 4) Εγκατάσταση dependencies

```powershell
pip install -r requirements.txt
```

## 5) Βάση δεδομένων (SQLite) + Seed

Η βάση είναι **SQLite** και αποθηκεύεται ως αρχείο:

- `unintend.db` (δημιουργείται στο root του project όταν τρέχεις το app/seed)

Για να “κατεβάσεις/στήσεις” τη βάση με αρχικά δεδομένα (μόνο την **πρώτη φορά**):

```powershell
py -m app.seed
```

Το seed τυπώνει και έτοιμους test λογαριασμούς (π.χ. `eleni / pass1234`).

## 6) Εκκίνηση server

```powershell
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Health check:

- http://127.0.0.1:8000/

## 7) (Optional) Reset της βάσης

Αν θέλεις να ξεκινήσεις από την αρχή:

1. Κλείσε τον server
2. Σβήσε το αρχείο `unintend.db`
3. Ξανατρέξε:

```powershell
py -m app.seed
```

## Έτοιμη

Αν όλα τα παραπάνω τρέξουν χωρίς errors, είσαι έτοιμη.

---

## Deploy στο Render (SQLite + Persistent Disk) — προτεινόμενο για demo

Αν θέλεις η εφαρμογή (και το APK release) να δουλεύει "κανονικά" από Render με SQLite, πρέπει να κάνεις persist:

- **τη βάση** (το αρχείο sqlite)
- **τα uploads** (εικόνες posts/profiles)

### 1) Persistent Disk

Στο Render Web Service (backend) πρόσθεσε **Persistent Disk** με:

- Mount path: `/var/data`

### 2) Environment variables (Render)

Βάλε τα παρακάτω env vars στο Render service:

- `DATABASE_URL=sqlite:////var/data/unintend.db`
- `UPLOADS_DIR=/var/data/uploads`
- `PUBLIC_BASE_URL=https://<your-service>.onrender.com`

### 3) Start command (Render)

Χρησιμοποίησε start command:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT --proxy-headers
```

### 4) Seed μία φορά (Render)

Μετά το πρώτο deploy, τρέξε ένα one-off command (Render Shell/Jobs):

```bash
python -m app.seed
```

Από εκεί και πέρα η sqlite βάση/εικόνες θα μένουν μόνιμα στο disk.

---

## Χρήση ήδη-φτιαγμένης SQLite βάσης (χωρίς seed)

Αν έχεις ήδη ένα έτοιμο `unintend.db` και δεν θέλεις να τρέξει `python -m app.seed` στο Render:

1) Κράτα το Persistent Disk + env vars όπως στο section πιο πάνω.

2) Χρησιμοποίησε start command που κάνει init μόνο αν λείπει η βάση:

```bash
bash scripts/render_start.sh
```

3) Δώσε στο Render **ένα** από τα παρακάτω env vars (μόνο για το πρώτο boot):

- `INITIAL_DB_URL` = ένα public direct-download link στο `.db` (π.χ. GitHub release asset)
	- Θα κατεβεί αυτόματα στην persistent διαδρομή που δείχνει το `DATABASE_URL`.

ή

- `INITIAL_DB_PATH` = path μέσα στο repo (π.χ. `initial_data/unintend.db`)
	- Σημείωση: θα πρέπει να το έχεις committed στο repo (και να μην το κόβει το `.gitignore`).

Μετά την πρώτη επιτυχημένη εκκίνηση, μπορείς να αφαιρέσεις το `INITIAL_DB_URL/INITIAL_DB_PATH`.

### Επικαιροποίηση βάσης από Git (overwrite)

Το init script by default **δεν** αντικαθιστά μια υπάρχουσα βάση στο persistent disk.
Αν ο συνεργάτης σου ανέβασε νεότερη SQLite βάση στο Git και θέλεις να την "περάσεις" στο Render:

1) Βάλε/ενημέρωσε `INITIAL_DB_URL` (ή `INITIAL_DB_PATH`)
2) Βάλε προσωρινά `FORCE_DB_INIT=1`
3) Κάνε Redeploy/Restart το service
4) Μόλις περάσει η βάση, αφαίρεσε το `FORCE_DB_INIT` (και προαιρετικά και το `INITIAL_DB_URL`)

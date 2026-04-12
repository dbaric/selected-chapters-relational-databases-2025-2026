# Mermaid Dijagrami — UNIST Rezervacijski Sustav

## Generiranje slika

Zahtijeva `npx` (Node.js) i `ImageMagick`. Sve datoteke su u `images/diagrams/`.

```bash
# Sve se izvršava iz korijena projekta (dnrdb/)
CFG=images/diagrams/mermaid.config.json

# 1. Izvuci SVG-ove da dobiješ prirodne dimenzije
for slug in slika1-konceptualni slika2-logicki slika3-relacijski; do
  npx @mermaid-js/mermaid-cli \
    -i images/diagrams/${slug}.mmd \
    -o /tmp/${slug}.svg \
    -c $CFG -q
done

# 2. Ispiši dimenzije (koristi za -w i -H u koraku 3)
python3 -c "
import re
for slug in ['slika1-konceptualni','slika2-logicki','slika3-relacijski']:
    c = open(f'/tmp/{slug}.svg').read()[:400]
    m = re.search(r'viewBox=\"[\d.]+ [\d.]+ ([\d.]+) ([\d.]+)\"', c)
    if m:
        w,h = float(m.group(1)), float(m.group(2))
        print(f'{slug}: w={w:.0f} h={h:.0f}  → render -w {int(w)+40} -H {int(h)+40}')
"

# 3. Render PNG-ova (zadnje izmjerene dimenzije + 40px buffer, scale 3)
npx @mermaid-js/mermaid-cli -i images/diagrams/slika1-konceptualni.mmd \
  -o images/diagrams/slika1-konceptualni.png -c $CFG -s 3 -w 1748 -H 648 -q
npx @mermaid-js/mermaid-cli -i images/diagrams/slika2-logicki.mmd \
  -o images/diagrams/slika2-logicki.png    -c $CFG -s 3 -w 1851 -H 1186 -q
npx @mermaid-js/mermaid-cli -i images/diagrams/slika3-relacijski.mmd \
  -o images/diagrams/slika3-relacijski.png -c $CFG -s 3 -w 2403 -H 1903 -q

# 4. Autocrop rubnog bijelog prostora
for f in images/diagrams/*.png; do magick "$f" -trim +repage "$f"; done
```

> **Napomene:**
> - Izvorne `.mmd` datoteke i `mermaid.config.json` su u `images/diagrams/` — to su jedine datoteke potrebne za regeneraciju
> - `direction LR` mora biti unutar tijela `erDiagram` bloka (ne u `%%{init}%%` direktivi — to ne radi u v11)
> - Atributi entiteta moraju biti jedan po retku; Mermaid parser ne podržava `;` separator unutar `{ }`
> - Dimenzije (`-w`, `-H`) odgovaraju prirodnoj SVG veličini + 40px; ako se dijagram promijeni, ponovi korak 1–2 za nove dimenzije
> - GENDER i FILE nemaju stranog ključa pa layout engine ih smješta slobodno (donji lijevi kut)

---

## Slika 1 — Konceptualni dijagram

```mermaid
erDiagram
    direction LR
    CATEGORY |o--o{ EVENT : "classifies"
    ORGANIZATION |o--o{ PERSON : "employs"
    ORGANIZATION ||--o{ ORGANIZATION_EVENT : "organizes"
    ORGANIZATION_EVENT }o--|| EVENT : ""
    EVENT ||--|{ OPTION : "has"
    EVENT ||--o{ EVENT_TRAINER : "trains"
    EVENT_TRAINER }o--|| PERSON : ""
    OPTION ||--o{ RESERVATION : "receives"
    PERSON ||--o{ RESERVATION : "makes"

    CATEGORY { string name }
    EVENT {
        string title
        string location
        datetime starts_at
        datetime ends_at
    }
    OPTION {
        string title
        int total_units
        bool is_waitlistable
    }
    RESERVATION {
        int status
        bool queued
        datetime attended_at
    }
    PERSON {
        string first_name
        string last_name
        string email
    }
    ORGANIZATION { string name }
```

---

## Slika 2 — Logički model

```mermaid
erDiagram
    direction LR
    CATEGORY |o--o{ EVENT : "classifies"
    ORGANIZATION |o--o{ PERSON : "employs"
    ORGANIZATION ||--o{ ORGANIZATION_EVENT : ""
    ORGANIZATION_EVENT }o--|| EVENT : ""
    EVENT ||--|{ OPTION : "has"
    EVENT ||--o{ EVENT_TRAINER : ""
    EVENT_TRAINER }o--|| PERSON : ""
    OPTION ||--o{ RESERVATION : "receives"
    PERSON ||--o{ RESERVATION : "makes"
    PERSON }o--o| COUNTRY : ""
    PERSON }o--o| SHIRT_SIZE : ""
    PERSON }o--o| FACULTY : ""

    CATEGORY { string name }
    EVENT {
        string title
        string location "null"
        datetime starts_at
        datetime ends_at
    }
    OPTION {
        string title
        string description "null"
        int total_units
        int available_units
        int taken_units
        int wait_list_units
        bool is_waitlistable
        bool is_auto_confirmable
    }
    RESERVATION {
        int status
        bool queued
        datetime attended_at "null"
        string notes "null"
    }
    PERSON {
        string first_name
        string last_name
        string email "null"
        string phone "null"
        string tax_number "null"
        string country "null"
        string shirt_size "null"
        string faculty "null"
        int year_of_study "null"
    }
    ORGANIZATION { string name }
    COUNTRY { string value }
    SHIRT_SIZE { string value }
    FACULTY { string value }
    GENDER { string value }
    FILE {
        string name
        string type
        int size
        string hash
    }
```

---

## Slika 3 — Relacijski model

```mermaid
erDiagram
    direction LR
    CATEGORY |o--o{ EVENT : "SET NULL"
    ORGANIZATION |o--o{ PERSON : "SET NULL"
    ORGANIZATION ||--o{ ORGANIZATION_EVENT : "CASCADE"
    ORGANIZATION_EVENT }o--|| EVENT : "CASCADE"
    EVENT ||--|{ OPTION : "RESTRICT"
    EVENT ||--o{ EVENT_TRAINER : "CASCADE"
    EVENT_TRAINER }o--|| PERSON : "RESTRICT"
    OPTION ||--o{ RESERVATION : "RESTRICT"
    PERSON ||--o{ RESERVATION : "RESTRICT"
    PERSON }o--o| COUNTRY : ""
    PERSON }o--o| SHIRT_SIZE : ""
    PERSON }o--o| FACULTY : ""

    CATEGORY {
        INTEGER id PK
        VARCHAR name
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    EVENT {
        INTEGER id PK
        VARCHAR title
        TEXT description
        TEXT image
        VARCHAR location
        TIMESTAMP starts_at
        TIMESTAMP ends_at
        TIMESTAMP published_at
        TIMESTAMP archived_at
        TIMESTAMP cancelled_at
        TIMESTAMP opens_at
        TIMESTAMP closes_at
        TEXT notes
        TEXT cancellation_reason
        TIMESTAMP reservations_open_at
        TIMESTAMP reservations_close_at
        TIMESTAMP reservations_cancel_at
        TIMESTAMP deleted_at
        INTEGER category_id FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    OPTION {
        INTEGER id PK
        VARCHAR title
        TEXT description
        INTEGER total_units
        INTEGER available_units
        INTEGER taken_units
        INTEGER wait_list_units
        BOOLEAN is_waitlistable
        BOOLEAN is_auto_confirmable
        BOOLEAN is_sport_only
        BOOLEAN is_student_only
        TIMESTAMP deleted_at
        INTEGER event_id FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    RESERVATION {
        INTEGER id PK
        INTEGER status
        BOOLEAN queued
        TIMESTAMP attended_at
        TEXT notes
        TIMESTAMP deleted_at
        INTEGER person_id FK
        INTEGER option_id FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    PERSON {
        INTEGER id PK
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR email
        VARCHAR phone
        VARCHAR tax_number
        VARCHAR country
        VARCHAR shirt_size
        VARCHAR faculty
        INTEGER year_of_study
        TEXT dirty_socks
        TEXT image
        INTEGER organization_id FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    ORGANIZATION {
        INTEGER id PK
        VARCHAR name
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    ORGANIZATION_EVENT {
        INTEGER organization_id FK
        INTEGER event_id FK
    }
    EVENT_TRAINER {
        INTEGER event_id FK
        INTEGER person_id FK
    }
    COUNTRY {
        INTEGER id PK
        VARCHAR value
        VARCHAR label
    }
    SHIRT_SIZE {
        INTEGER id PK
        VARCHAR value
        VARCHAR label
    }
    FACULTY {
        INTEGER id PK
        VARCHAR value
        VARCHAR label
    }
    GENDER {
        INTEGER id PK
        VARCHAR value
        VARCHAR label
    }
    FILE {
        INTEGER id PK
        VARCHAR name
        VARCHAR type
        INTEGER size
        VARCHAR hash
        TIMESTAMP created_at
        TIMESTAMP deleted_at
    }
```

# Prompt za generiranje nedostajućih grafikona u SEMINAR.md

---

## Uloga i cilj

Ti si agent koji automatski detektira nedostajuće slike u SEMINAR.md, generira ih kao PNG grafikone i integrira ih natrag u dokument. Vrijednosti u grafikonima dolaze isključivo iz stvarnih EXPLAIN ANALYZE mjerenja na lokalnoj bazi — bez hardkodiranih procjena.

---

## 0. Preduvjeti

Baza mora biti pokrenuta i populirana:

```bash
# Provjera broja redaka (očekivano: 5 008)
psql -U unist_rezervacije -h localhost -p 5432 -d unist_rezervacije \
     -c "SELECT COUNT(*) FROM event;"

# Ako baza nije populirana ili treba reset:
bash /Users/drazenbaric/Projects/dnrdb/data/setup.sh
```

Seed (`data/seed.sql`) sadrži 8 ručnih evenata + 5 000 generiranih via `generate_series` raspoređenih 2010–2030. Raspon upita 2025-01-01 – 2026-01-01 zahvaća ~258 redaka (~5 %) — selektivnost dovoljna da planer odabere Bitmap Index Scan.

---

## 1. Otkrivanje placeholdera

Pročitaj datoteku:

```
/Users/drazenbaric/Projects/dnrdb/SEMINAR.md
```

Pronađi sve linije koje odgovaraju uzorku (Python regex):

```
^> _\[Slika (\d+)\. (.+?)\]_$
```

Za svaki pogodak zabilježi:
- broj slike (capture group 1)
- potpuni opis (capture group 2)
- broj linije u datoteci

Ako nema pogodaka, ispiši `Nema nedostajućih slika.` i završi.

---

## 2. Mapiranje placeholdera na grafikon

**Naziv datoteke** prema shemi `slika{N}-{slug}.png`:

| Slika | Ključne riječi | Naziv datoteke |
|-------|----------------|----------------|
| 4 | `bez` i `Seq Scan` | `slika4-explain-bez-indeksa.png` |
| 5 | `s indeksom` i `Index Scan` | `slika5-explain-s-indeksom.png` |

**Izlazna putanja:** `/Users/drazenbaric/Projects/dnrdb/images/diagrams/{naziv_datoteke}`

---

## 3. Generiranje PNG grafikona

Napiši Python skriptu `generate_charts_tmp.py` u radnom direktoriju i izvrši je naredbom:

```bash
cd /Users/drazenbaric/Projects/dnrdb && python3 generate_charts_tmp.py
```

### 3a. Mjerenje — psql subprocess

Skripta mora sama pokrenuti mjerenja. Ne smije koristiti hardkodirane vrijednosti.

```python
import re, subprocess

PSQL = ["psql", "-U", "unist_rezervacije", "-h", "localhost",
        "-p", "5432", "-d", "unist_rezervacije", "-v", "ON_ERROR_STOP=1"]

RANGE_QUERY = """
SELECT id, title, starts_at FROM event
WHERE  starts_at >= '2025-01-01'
  AND  starts_at <  '2026-01-01'
"""

def psql(sql):
    r = subprocess.run(PSQL + ["-c", sql], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    return r.stdout

def explain(sql):
    return psql(f"EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n{sql}")
```

**Mjerenje bez indeksa (Seq Scan):**
```python
psql("DROP INDEX IF EXISTS idx_event_starts_at; DROP INDEX IF EXISTS idx_event_active_starts;")
out_bez = explain(RANGE_QUERY)
```

**Parsiranje Seq Scan outputa:**
```python
def parse_seq_scan(text):
    exec_ms  = float(re.search(r"Execution Time:\s+([\d.]+)", text).group(1))
    rows_ret = int(re.search(r"actual time=[\d.]+\.\.[\d.]+ rows=(\d+)", text).group(1))
    removed  = int(re.search(r"Rows Removed by Filter:\s+(\d+)", text).group(1))
    return {"exec_ms": exec_ms, "rows_scanned": rows_ret + removed, "rows_returned": rows_ret}
```

**Mjerenje s indeksom (Bitmap Index Scan):**
```python
psql("CREATE INDEX idx_event_starts_at ON event (starts_at);")
psql("CREATE INDEX idx_event_active_starts ON event (starts_at) WHERE deleted_at IS NULL;")
out_s = explain(RANGE_QUERY)
```

**Parsiranje Bitmap Heap Scan outputa:**
```python
def parse_bitmap_scan(text):
    exec_ms  = float(re.search(r"Execution Time:\s+([\d.]+)", text).group(1))
    # Bitmap Heap Scan = vanjski čvor, prvi "actual time=... rows=N"
    rows_ret = int(re.search(r"actual time=[\d.]+\.\.[\d.]+ rows=(\d+)", text).group(1))
    return {"exec_ms": exec_ms, "rows_scanned": rows_ret, "rows_returned": rows_ret}
```

### 3b. Grafikoni

Koristi `plotly.graph_objects` s `kaleido` za PNG export.

**Metrike — samo stvarno izmjerene vrijednosti, bez planerov estimata:**

| Label | Chart 4 (bez) | Chart 5 (s) |
|-------|---------------|-------------|
| `"Vrijeme bez indeksa (ms)"` / `"Vrijeme s indeksom (ms)"` | `m_bez["exec_ms"]` | `m_s["exec_ms"]` |
| `"Pregledani retci"` | `m_bez["rows_scanned"]` | `m_s["rows_scanned"]` |
| `"Vraćeni retci"` | `m_bez["rows_returned"]` | `m_s["rows_returned"]` |

**Stilski zahtjevi:**
- Boja: `#6B8FCB` (neutralni steel-blue, isti ton kao ERD dijagrami slika 1–3)
- `orientation="h"`, `textposition="outside"`, `cliponaxis=False`
- `xaxis.range=[0, max(values) * 1.3]` — 30% padding desno
- `yaxis.autorange="reversed"` — gornja metrika prva
- Margine: `l=240, r=180, t=80, b=40`; visina 380px, širina 700px
- Font: `"Arial"` size 13 globalno i na tickfont/textfont
- Bijela pozadina (`paper_bgcolor="white"`, `plot_bgcolor="white"`)
- Bez footer annotacija — kontekst mjerenja dokumentiran je u SEMINAR.md
- `fig.write_image(path, format="png", scale=2)`

---

## 4. Provjera

```bash
ls -lh /Users/drazenbaric/Projects/dnrdb/images/diagrams/slika4-explain-bez-indeksa.png
ls -lh /Users/drazenbaric/Projects/dnrdb/images/diagrams/slika5-explain-s-indeksom.png
```

Ako neka datoteka nedostaje ili je 0 B, dijagnosticiraj i popravi skriptu.

---

## 5. Ažuriranje SEMINAR.md

Zamijeni svaki placeholder s:

```
![{opis}](images/diagrams/{naziv_datoteke})

_{opis}_
```

Okolne prazne linije ostaju nepromijenjene. Ne mijenjaj ništa izvan zamijenjenih linija.

---

## 6. Čišćenje

```bash
rm /Users/drazenbaric/Projects/dnrdb/generate_charts_tmp.py
```

---

## 7. Završna provjera

Ispiši popis zamijenjenih linija s brojevima, npr.:

```
Linija 920: placeholder → slika4-explain-bez-indeksa.png ✓
Linija 933: placeholder → slika5-explain-s-indeksom.png ✓
```

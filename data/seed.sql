-- ============================================================
-- SEED — UNIST Rezervacijski Sustav
-- Pokretanje: psql -U unist_rezervacije -d unist_rezervacije -f seed.sql
-- Pretpostavka: DDL je već primijenjen (schema.sql)
-- ============================================================
-- Redoslijed INSERT-a poštuje FK ovisnosti:
--   lookup → organization → category → person → event
--   → organization_event → option → reservation → event_trainer → file
-- ============================================================
-- Constraint kršenja su zakomentirana blokova odmah ispod
-- validnog primjera na koji se odnose.
-- Format:
--   -- FAILS: <tip constrainta> — <opis>
--   -- <SQL>;
--   -- ERROR: <poruka greške iz PostgreSQL-a>
-- ============================================================


-- ============================================================
-- BLOK 0 — RESET (djeca prije roditelja zbog FK)
-- ============================================================

TRUNCATE TABLE
    event_trainer,
    organization_event,
    reservation,
    option,
    event,
    person,
    category,
    organization,
    faculty,
    shirt_size,
    country,
    gender,
    file
RESTART IDENTITY CASCADE;


-- ============================================================
-- BLOK 1 — LOOKUP TABLICE (bez FK ovisnosti)
-- ============================================================

-- ── gender ───────────────────────────────────────────────────────────────────
INSERT INTO gender (value, label) VALUES
    ('M', 'Muško'),
    ('F', 'Žensko'),
    ('X', 'Ostalo'),
    ('U', 'Neizjašnjeno');

-- FAILS: UNIQUE(value) — 'M' već postoji u tablici gender
-- INSERT INTO gender (value, label) VALUES ('M', 'Muško (duplikat)');
-- ERROR: duplicate key value violates unique constraint "gender_value_uq"
-- DETAIL: Key (value)=(M) already exists.

-- ── country ──────────────────────────────────────────────────────────────────
INSERT INTO country (value, label) VALUES
    ('HR', 'Hrvatska'),
    ('BA', 'Bosna i Hercegovina'),
    ('RS', 'Srbija'),
    ('SI', 'Slovenija'),
    ('DE', 'Njemačka');

-- ── shirt_size ───────────────────────────────────────────────────────────────
INSERT INTO shirt_size (value, label) VALUES
    ('XS', 'Extra Small'),
    ('S',  'Small'),
    ('M',  'Medium'),
    ('L',  'Large'),
    ('XL', 'Extra Large');

-- ── faculty (svi UNIST fakulteti) ────────────────────────────────────────────
INSERT INTO faculty (value, label) VALUES
    ('FESB',  'Fakultet elektrotehnike, strojarstva i brodogradnje'),
    ('PMFST', 'Prirodoslovno-matematički fakultet u Splitu'),
    ('PFST',  'Pravni fakultet u Splitu'),
    ('EFST',  'Ekonomski fakultet u Splitu'),
    ('FGAG',  'Fakultet građevinarstva, arhitekture i geodezije'),
    ('KBF',   'Katolički bogoslovni fakultet'),
    ('MF',    'Medicinski fakultet'),
    ('KIFS',  'Kineziološki fakultet u Splitu');


-- ============================================================
-- BLOK 2 — ORGANIZATIONS (bez FK ovisnosti)
-- ============================================================

INSERT INTO organization (name) VALUES
    ('Unisport Health'),                     -- id=1 | sadrži 'Uni' → vidljiv u upitu 7.2
    ('Splitski akademski sportski savez'),    -- id=2 | SASS — bez 'Uni'
    ('Hrvatski akademski sportski savez');    -- id=3 | HASS — bez 'Uni'


-- ============================================================
-- BLOK 3 — CATEGORIES (bez FK ovisnosti)
-- ============================================================

INSERT INTO category (name) VALUES
    ('Sport'),      -- id=1 | košarka, trčanje
    ('Rekreacija'), -- id=2 | plivanje, fitness
    ('Zdravlje'),   -- id=3 | joga, wellness
    ('Zabava'),     -- id=4 | ples (soft-deleted event)
    ('Kultura');    -- id=5 | namjerno BEZ događaja → LEFT JOIN demo u upitu 7.1

-- FAILS: UNIQUE(name) — 'Sport' već postoji u tablici category
-- INSERT INTO category (name) VALUES ('Sport');
-- ERROR: duplicate key value violates unique constraint "category_name_uq"
-- DETAIL: Key (name)=(Sport) already exists.


-- ============================================================
-- BLOK 4 — PERSONS (FK → organization, nullable)
-- ============================================================

INSERT INTO person
    (first_name, last_name, email,
     faculty, year_of_study, shirt_size, country, organization_id)
VALUES
    -- id=1  | org=Unisport Health | PMFST, 2. godina
    ('Ana',      'Horvat',  'ana.horvat@student.pmfst.hr',
     'PMFST', 2, 'S',  'HR', 1),
    -- id=2  | org=SASS | FESB, 3. godina
    ('Ivan',     'Kovač',   'ivan.kovac@student.fesb.hr',
     'FESB',  3, 'L',  'HR', 2),
    -- id=3  | org=Unisport Health | KBF, 1. godina
    ('Marija',   'Novak',   'marija.novak@student.kbf.hr',
     'KBF',   1, 'M',  'HR', 1),
    -- id=4  | org=SASS | PFST, 4. godina
    ('Pero',     'Perić',   'pero.peric@student.pfst.hr',
     'PFST',  4, 'M',  'HR', 2),
    -- id=5  | org=HASS | FGAG, 2. godina
    ('Luka',     'Babić',   'luka.babic@student.fgag.hr',
     'FGAG',  2, 'L',  'HR', 3),
    -- id=6  | org=Unisport Health | PMFST, 1. godina
    ('Maja',     'Vuković', 'maja.vukovic@student.pmfst.hr',
     'PMFST', 1, 'S',  'HR', 1),
    -- id=7  | org=NULL (organization_id je nullable)
    ('Tomislav', 'Jurić',   'tomislav.juric@student.unist.hr',
     'MF',    5, 'XL', 'HR', NULL),
    -- id=8  | trener | year_of_study=NULL (nije student, nullable)
    ('Nikola',   'Trener',  'nikola.trener@unist.hr',
     'KIFS',  NULL, 'L', 'HR', 1),
    -- id=9  | org=SASS | strani student (country='BA')
    ('Sara',     'Čović',   'sara.covic@student.efst.hr',
     'EFST',  3, 'S',  'BA', 2),
    -- id=10 | email=NULL (email polje je nullable — nije NOT NULL)
    ('Dino',     'Milić',   NULL,
     'FESB',  2, 'M',  'HR', 3);


-- ── Varijacije vezane za osobu 1 (Ana Horvat) ─────────────────────────────────

-- FAILS: UNIQUE(email) — isti email kao osoba id=1, različito prezime
-- INSERT INTO person (first_name, last_name, email, faculty, year_of_study, organization_id)
-- VALUES ('Ana', 'Jurić', 'ana.horvat@student.pmfst.hr', 'PMFST', 2, 1);
-- ERROR: duplicate key value violates unique constraint "person_email_uq"
-- DETAIL: Key (email)=(ana.horvat@student.pmfst.hr) already exists.

-- PROLAZI: isto ime i prezime kao osoba id=1, ali DRUGAČIJI email
-- Uniqueness je isključivo na email polju — ime i prezime nisu ograničeni
INSERT INTO person (first_name, last_name, email, faculty, year_of_study, organization_id)
VALUES ('Ana', 'Horvat', 'a.horvat@student.fesb.hr', 'FESB', 1, 2);
-- OK — id=11

-- ── Ostale varijacije (fails) ────────────────────────────────────────────────

-- FAILS: CHECK(year_of_study BETWEEN 1 AND 8) — vrijednost 10 van valjanih 1–8
-- INSERT INTO person (first_name, last_name, email, year_of_study)
-- VALUES ('Test', 'Student', 'test.x@student.unist.hr', 10);
-- ERROR: new row for relation "person" violates check constraint "person_year_of_study_chk"

-- FAILS: NOT NULL(first_name) — obavezno polje ne smije biti NULL
-- INSERT INTO person (first_name, last_name, email)
-- VALUES (NULL, 'Anonimni', 'anon@student.unist.hr');
-- ERROR: null value in column "first_name" of relation "person" violates not-null constraint


-- ============================================================
-- BLOK 5 — EVENTS (FK → category, nullable)
-- Svi eventi u 2025. godini (upiti 7.2 i 7.3 filtriraju tu godinu)
-- ============================================================

INSERT INTO event
    (title, description, location,
     starts_at, ends_at, published_at,
     category_id)
VALUES
    -- id=1 | org=Unisport Health | category=Zdravlje (3)
    ('Jutarnja joga',
     'Tečaj hatha joge za studente svih razina, jutarnji termin. '
     'Nije potrebno predznanje — potrebna udobna odjeća i prostirka.',
     'Sportski centar Gripe',
     '2025-10-01 08:00:00', '2025-10-01 09:00:00',
     '2025-09-15 12:00:00',
     3),

    -- id=2 | org=Unisport Health | category=Rekreacija (2)
    ('Plivanje za početnike',
     'Rekreativno plivanje u grupama od 3 polaznika. Instruktor prisutan. '
     'Namijenjen studentima koji ne znaju ili slabo znaju plivati.',
     'Bazen Gripe',
     '2025-11-05 09:00:00', '2025-11-05 11:00:00',
     '2025-10-20 10:00:00',
     2),

    -- id=3 | org=Unisport Health + HASS (zajednički) | category=Rekreacija (2)
    ('Fitness vikend',
     'Intenzivni jednodnevni program funkcionalnog treninga na kampusu UNIST. '
     'Zajednička organizacija Unisport Healtha i HASS-a.',
     'Kampus UNIST, dvorana B2',
     '2025-09-15 10:00:00', '2025-09-15 12:00:00',
     '2025-09-01 09:00:00',
     2),

    -- id=4 | org=Unisport Health | category=Zdravlje (3)
    ('Večernja joga',
     'Opuštajuća joga za kraj radnog dana. Fokus na disanju i relaksaciji. '
     'Svi stupnjevi iskustva dobrodošli.',
     'Sportski centar Gripe',
     '2025-12-10 18:00:00', '2025-12-10 19:00:00',
     '2025-11-25 14:00:00',
     3),

    -- id=5 | org=SASS | category=Sport (1)
    ('Košarkaški turnir',
     'Međufakultetski turnir 3x3 košarke. Timovi od 3 igrača. '
     'Pobjednik dobiva pehar i godišnju pretplatu na SASS aktivnosti.',
     'Dvorana Gripe',
     '2025-10-20 10:00:00', '2025-10-20 14:00:00',
     '2025-10-05 08:00:00',
     1),

    -- id=6 | org=SASS | category=Sport (1)
    ('Maratonski trening',
     'Grupni trening na Marjanu za sve razine trkača. '
     'Pace grupe: 5:00/km, 5:45/km i 6:30/km. Rastanak kod klupe.',
     'Park Marjan — ulaz kod zoo-vrta',
     '2025-11-12 07:00:00', '2025-11-12 09:00:00',
     '2025-10-28 11:00:00',
     1),

    -- id=7 | org=SASS | category=Rekreacija (2)
    ('Zimski fitness',
     'Zimski program funkcionalnog treninga. Svaki sudionik dobiva '
     'individualni plan vježbanja za prosinac.',
     'Kampus UNIST, dvorana B2',
     '2025-12-15 09:00:00', '2025-12-15 11:00:00',
     '2025-12-01 13:00:00',
     2),

    -- id=8 | org=Unisport Health | category=Zabava (4) | SOFT-DELETED
    ('Ples za početnike',
     'Uvod u Latino plesove — salsa i bachata za apsolutne početnike.',
     'KIC Split',
     '2025-10-05 18:00:00', '2025-10-05 20:00:00',
     NULL,
     4);

-- Soft-delete i otkazivanje događaja 8
UPDATE event
SET  deleted_at          = '2025-09-28 10:00:00',
     cancelled_at        = '2025-09-28 10:00:00',
     cancellation_reason = 'Nedovoljan broj prijavljenih sudionika'
WHERE id = 8;

-- ── Bulk generacija za EXPLAIN ANALYZE demonstraciju (§5.7) ──────────────────
-- 5 000 evenata ravnomjerno raspoređenih 2010-01-01 → ~2030-01-01 (35 h/event).
-- Raspon upita 2025-01-01 → 2026-01-01 pokriva ~250 redaka (~5 %) —
-- dovoljno za demonstraciju Bitmap Index Scan nasuprot Seq Scan.
INSERT INTO event (title, location, starts_at, ends_at, category_id)
SELECT
    'Generiran događaj #' || i,
    'Lokacija '           || ((i % 10) + 1),
    '2010-01-01'::timestamp + (i * interval '35 hours'),
    '2010-01-01'::timestamp + (i * interval '35 hours') + interval '2 hours',
    (i % 4) + 1
FROM generate_series(1, 5000) AS gs(i);


-- ── Varijacije (fails) ────────────────────────────────────────────────────────

-- FAILS: CHECK(ends_at > starts_at) — kraj je ranije od početka
-- INSERT INTO event (title, starts_at, ends_at)
-- VALUES ('Loš termin', '2025-10-01 10:00:00', '2025-10-01 08:00:00');
-- ERROR: new row for relation "event" violates check constraint "event_ends_after_starts"

-- FAILS: FOREIGN KEY(category_id) — kategorija s id=9999 ne postoji
-- INSERT INTO event (title, starts_at, ends_at, category_id)
-- VALUES ('FK test', '2025-10-01 10:00:00', '2025-10-01 11:00:00', 9999);
-- ERROR: insert or update on table "event" violates foreign key constraint "event_category_fk"
-- DETAIL: Key (category_id)=(9999) is not present in table "category".

-- FAILS: NOT NULL(title) — naziv događaja je obavezan
-- INSERT INTO event (title, starts_at, ends_at)
-- VALUES (NULL, '2025-10-01 10:00:00', '2025-10-01 11:00:00');
-- ERROR: null value in column "title" of relation "event" violates not-null constraint


-- ============================================================
-- BLOK 6 — ORGANIZATION_EVENT (M:N junction)
-- Poravnanje: nazivi organizacija su desno-popunjeni do dužine
-- najduljeg naziva ("Unisport Health" = 15 znakova)
-- ============================================================

INSERT INTO organization_event (organization_id, event_id) VALUES
    (1, 1),   -- Unisport Health → Jutarnja joga
    (1, 2),   -- Unisport Health → Plivanje za početnike
    (1, 3),   -- Unisport Health → Fitness vikend  (zajednički)
    (3, 3),   -- HASS            → Fitness vikend  (isti event, M:N demo)
    (1, 4),   -- Unisport Health → Večernja joga
    (2, 5),   -- SASS            → Košarkaški turnir
    (2, 6),   -- SASS            → Maratonski trening
    (2, 7),   -- SASS            → Zimski fitness
    (1, 8);   -- Unisport Health → Ples za početnike  (soft-deleted event)

-- Unisport Health: eventi 1,2,3,4 → 4 aktiv. eventi 2025 → HAVING >= 3 ✓ (upit 7.2)
-- SASS:            eventi 5,6,7   → 3 eventi, ali bez 'Uni' → ne prolazi WHERE
-- HASS:            event 3        → 1 event → ne prolazi HAVING


-- ============================================================
-- BLOK 7 — OPTIONS (FK → event, NOT NULL)
-- Inicijalni seed: available_units = total_units, ostali counteri = 0
-- Trigger C1/C2 automatski ažurira sve counter kolone pri INSERT rezervacije
-- ============================================================

INSERT INTO option
    (title,
     total_units, available_units,
     is_waitlistable, is_auto_confirmable, is_sport_only, is_student_only,
     event_id)
VALUES
    -- id=1  | event=1 (Jutarnja joga)      | standardna mjesta, samo studenti
    ('Standardna prijava',  20, 20, FALSE, FALSE, FALSE, TRUE,  1),
    -- id=2  | event=1 (Jutarnja joga)      | VIP, mali kapacitet, WAITLIST=TRUE → upit 7.4
    ('VIP pristup',          5,  5, TRUE,  FALSE, FALSE, FALSE, 1),
    -- id=3  | event=2 (Plivanje)           | jako mali kapacitet, WAITLIST=TRUE → upit 7.4
    ('Početnička grupa',     3,  3, TRUE,  FALSE, FALSE, TRUE,  2),
    -- id=4  | event=3 (Fitness vikend)     | velik kapacitet, nema waitliste
    ('Vikend paket',        25, 25, FALSE, FALSE, FALSE, FALSE, 3),
    -- id=5  | event=4 (Večernja joga)      | srednji kapacitet, WAITLIST=TRUE, studenti
    ('Večernji termin',     10, 10, TRUE,  FALSE, FALSE, TRUE,  4),
    -- id=6  | event=5 (Košarkaški turnir)  | sport-only
    ('Tim A',                8,  8, FALSE, FALSE, TRUE,  FALSE, 5),
    -- id=7  | event=5 (Košarkaški turnir)  | sport-only
    ('Tim B',                8,  8, FALSE, FALSE, TRUE,  FALSE, 5),
    -- id=8  | event=6 (Maratonski trening) | velika utrka, puno mjesta
    ('5km utrka',           30, 30, FALSE, FALSE, FALSE, FALSE, 6),
    -- id=9  | event=7 (Zimski fitness)     | standardna zimska prijava
    ('Zimska prijava',      20, 20, FALSE, FALSE, FALSE, FALSE, 7),
    -- id=10 | event=8 (Ples, soft-deleted) | soft-deleted zajedno s eventom
    ('Osnovna prijava',     15, 15, FALSE, FALSE, FALSE, FALSE, 8);

-- Soft-delete opcije 10 (prati event 8 koji je otkazan)
UPDATE option SET deleted_at = '2025-09-28 10:00:00' WHERE id = 10;


-- ============================================================
-- BLOK 8a — RESERVATIONS INSERT
-- Trigger C1/C2 (BEFORE INSERT) automatski:
--   - zaključava option redak (FOR UPDATE — race condition zaštita)
--   - postavlja queued=FALSE ako ima slobodnih mjesta → taken++, available--
--   - postavlja queued=TRUE  ako je puno i is_waitlistable=TRUE → wait_list++
--   - baca EXCEPTION         ako je puno i is_waitlistable=FALSE
-- Svi INSERT-i koriste DEFAULT status=0 (PENDING)
-- Poravnanje: imena osoba desno-popunjena do dužine "Tomislav" (8 znakova)
-- ============================================================

-- ── Option 1: Standardna prijava (total=20, waitlistable=FALSE) ───────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (1, 1),   -- Ana      | queued=FALSE | available: 20→19
    (2, 1),   -- Ivan     | queued=FALSE | available: 19→18
    (3, 1),   -- Marija   | queued=FALSE | available: 18→17
    (9, 1);   -- Sara     | queued=FALSE | available: 17→16

-- ── Option 2: VIP pristup (total=5, waitlistable=TRUE) ────────────────────────
-- Prvih 5 rezervacija zauzimaju sva redovna mjesta (queued=FALSE):
INSERT INTO reservation (person_id, option_id) VALUES
    (4, 2),   -- Pero     | queued=FALSE | available: 5→4
    (5, 2),   -- Luka     | queued=FALSE | available: 4→3
    (6, 2),   -- Maja     | queued=FALSE | available: 3→2
    (7, 2),   -- Tomislav | queued=FALSE | available: 2→1
    (2, 2);   -- Ivan     | queued=FALSE | available: 1→0 ← kapacitet iscrpljen

-- Sljedeće 2 idu na čekalnu listu (queued=TRUE automatski jer available=0):
INSERT INTO reservation (person_id, option_id) VALUES
    (1, 2),   -- Ana      | queued=TRUE  | wait_list: 0→1
    (3, 2);   -- Marija   | queued=TRUE  | wait_list: 1→2
-- Stanje Option 2: taken=5, available=0, wait_list=2

-- FAILS: trigger C1/C2 RAISE EXCEPTION — option puna, waitlistable=FALSE
-- INSERT INTO reservation (person_id, option_id) VALUES (9, 6);
-- ERROR: Opcija 6 je popunjena i ne podržava čekalnu listu.

-- ── Option 3: Početnička grupa (total=3, waitlistable=TRUE) ───────────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (1, 3),   -- Ana      | queued=FALSE | available: 3→2
    (3, 3),   -- Marija   | queued=FALSE | available: 2→1
    (6, 3),   -- Maja     | queued=FALSE | available: 1→0 ← kapacitet iscrpljen
    (7, 3);   -- Tomislav | queued=TRUE  | wait_list: 0→1
-- Stanje Option 3: taken=3, available=0, wait_list=1

-- ── Option 4: Vikend paket (total=25, waitlistable=FALSE) ─────────────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (2, 4),   -- Ivan     | queued=FALSE
    (4, 4),   -- Pero     | queued=FALSE
    (9, 4);   -- Sara     | queued=FALSE

-- ── Option 5: Večernji termin (total=10, waitlistable=TRUE) ───────────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (1, 5),   -- Ana      | queued=FALSE
    (9, 5);   -- Sara     | queued=FALSE

-- ── Option 6: Tim A (total=8, sport_only, waitlistable=FALSE) ─────────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (2, 6),   -- Ivan     | queued=FALSE
    (5, 6);   -- Luka     | queued=FALSE

-- ── Option 7: Tim B (total=8, sport_only, waitlistable=FALSE) ─────────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (4, 7),   -- Pero     | queued=FALSE
    (7, 7);   -- Tomislav | queued=FALSE

-- ── Option 8: 5km utrka (total=30, waitlistable=FALSE) ───────────────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (3, 8),   -- Marija   | queued=FALSE
    (6, 8),   -- Maja     | queued=FALSE
    (7, 8);   -- Tomislav | queued=FALSE

-- ── Option 9: Zimska prijava (total=20, waitlistable=FALSE) ───────────────────
INSERT INTO reservation (person_id, option_id) VALUES
    (9, 9),   -- Sara     | queued=FALSE
    (1, 9),   -- Ana      | queued=FALSE
    (4, 9);   -- Pero     | queued=FALSE


-- ============================================================
-- BLOK 8b — RESERVATIONS UPDATE (promjena statusa)
-- Trigger C3 (AFTER UPDATE) pali isključivo pri promjeni statusa u/iz 2 (CANCELLED):
--   status → 2: dekrementira taken (ili wait_list ako queued=TRUE), inkrementira available
--   status ← 2: inkrementira taken (ili wait_list), dekrementira available
-- Promjena u status=1 (CONFIRMED) ne aktivira trigger C3
-- ============================================================

-- ── CONFIRMED (status=1) — trigger C3 NE pali ────────────────────────────────
UPDATE reservation
SET    status = 1
WHERE  (person_id, option_id) IN (
    (1, 1), (2, 1),                          -- Option 1: Ana, Ivan
    (4, 2), (5, 2), (6, 2), (7, 2), (2, 2), -- Option 2: svih 5 redovnih mjesta
    (1, 3), (3, 3),                          -- Option 3: Ana, Marija
    (2, 4), (4, 4),                          -- Option 4: Ivan, Pero
    (2, 6), (5, 6),                          -- Option 6: Ivan, Luka (Tim A)
    (7, 7),                                  -- Option 7: Tomislav (Tim B)
    (9, 9)                                   -- Option 9: Sara
);

-- ── CANCELLED (status=2) — trigger C3 vraća kapacitet ────────────────────────
UPDATE reservation
SET    status = 2
WHERE  (person_id, option_id) IN (
    (9, 1),   -- Sara     | Option 1 | C3: taken-1, available+1
    (9, 5),   -- Sara     | Option 5 | C3: taken-1, available+1
    (6, 8),   -- Maja     | Option 8 | C3: taken-1, available+1
    (3, 8),   -- Marija   | Option 8 | C3: taken-1, available+1
    (4, 9)    -- Pero     | Option 9 | C3: taken-1, available+1
);

-- Tomislav (7,3) ostaje queued=TRUE, PENDING → Option 3 zadržava wait_list=1


-- ── Finalno stanje option countera ────────────────────────────────────────────
-- opt | total | taken | avail | w_list | napomena
-- ----+-------+-------+-------+--------+--------------------------------
--  1  |  20   |   3   |  17   |   0    | Sara cancelled
--  2  |   5   |   5   |   0   |   2    | Ana, Marija na čekalnoj listi
--  3  |   3   |   3   |   0   |   1    | Tomislav na čekalnoj listi
--  4  |  25   |   3   |  22   |   0    |
--  5  |  10   |   1   |   9   |   0    | Sara cancelled
--  6  |   8   |   2   |   6   |   0    |
--  7  |   8   |   2   |   6   |   0    |
--  8  |  30   |   1   |  29   |   0    | Maja, Marija cancelled
--  9  |  20   |   2   |  18   |   0    | Pero cancelled
-- 10  |  15   |   0   |  15   |   0    | soft-deleted

-- ============================================================
-- RUČNO POKRETANJE — Trigger C1 + C2 (enforce_option_capacity)
-- INSERT na reservation automatski aktivira trigger; nije ga
-- moguće pozvati direktno, ali efekt je odmah vidljiv.
--
-- Stanje PRIJE:
-- SELECT id, taken_units, available_units, wait_list_units
-- FROM   option WHERE id = 8;
--
-- INSERT INTO reservation (person_id, option_id) VALUES (10, 8);
--
-- Stanje NAKON (taken++, available-- ili wait_list++ ako puno):
-- SELECT id, taken_units, available_units, wait_list_units
-- FROM   option WHERE id = 8;
--
-- PRETHODNA POKRETANJA: PostgreSQL ne logira pojedinačne okidaje
-- triggera. Kumulativni učinak svih dosadašnjih aktivacija vidljiv
-- je u option tablici:
-- SELECT id, title, taken_units, available_units, wait_list_units
-- FROM   option ORDER BY id;
-- ============================================================


-- ── Constraint kršenja vezana za status i FK RESTRICT ─────────────────────────

-- FAILS: CHECK(status IN (0, 1, 2)) — status 99 nije validan
-- UPDATE reservation SET status = 99 WHERE id = 1;
-- ERROR: new row for relation "reservation" violates check constraint "reservation_status_chk"

-- FAILS: FK RESTRICT — person 1 (Ana) ima aktivne rezervacije (ON DELETE RESTRICT)
-- DELETE FROM person WHERE id = 1;
-- ERROR: update or delete on table "person" violates foreign key constraint
--        "reservation_person_fk" on table "reservation"

-- FAILS: FK RESTRICT — option 1 ima rezervacije (ON DELETE RESTRICT)
-- DELETE FROM option WHERE id = 1;
-- ERROR: update or delete on table "option" violates foreign key constraint
--        "reservation_option_fk" on table "reservation"

-- ============================================================
-- RUČNO POKRETANJE — Trigger C3 (sync_option_capacity)
-- UPDATE statusa na 2 (CANCELLED) aktivira trigger C3 koji
-- vraća slobodno mjesto. Status ← 2 (re-aktivacija) ga oduzima.
--
-- Otkazivanje (taken--, available++):
-- SELECT o.taken_units, o.available_units
-- FROM   option o JOIN reservation r ON r.option_id = o.id
-- WHERE  r.id = 3;
--
-- UPDATE reservation SET status = 2 WHERE id = 3 AND status <> 2;
--
-- SELECT o.taken_units, o.available_units
-- FROM   option o JOIN reservation r ON r.option_id = o.id
-- WHERE  r.id = 3;
--
-- PRETHODNA POKRETANJA: kao i za trigger C1/C2, vidljivi kroz
-- trenutne counter vrijednosti u option tablici.
-- ============================================================


-- ============================================================
-- BLOK 8c — RESERVATIONS UPDATE (attended_at)
-- Označava fizički dolazak na događaj za potvrđene rezervacije.
-- Nije svaka CONFIRMED rezervacija rezultirala dolaskom — namjerno
-- su neke ostavljene bez attended_at (npr. Option 9) radi demonstracije
-- razlike između "potvrđeno" i "prisustvovao".
-- ============================================================

-- ── Event 1 (Jutarnja joga, 2025-10-01 08:00) ─────────────────────────────────
UPDATE reservation SET attended_at = '2025-10-01 08:10:00'
WHERE (person_id, option_id) = (1, 1);   -- Ana      | Option 1

UPDATE reservation SET attended_at = '2025-10-01 08:15:00'
WHERE (person_id, option_id) = (2, 1);   -- Ivan     | Option 1

UPDATE reservation SET attended_at = '2025-10-01 08:05:00'
WHERE (person_id, option_id) = (4, 2);   -- Pero     | Option 2 (VIP)

UPDATE reservation SET attended_at = '2025-10-01 08:20:00'
WHERE (person_id, option_id) = (5, 2);   -- Luka     | Option 2 (VIP)

UPDATE reservation SET attended_at = '2025-10-01 08:10:00'
WHERE (person_id, option_id) = (6, 2);   -- Maja     | Option 2 (VIP)

UPDATE reservation SET attended_at = '2025-10-01 08:30:00'
WHERE (person_id, option_id) = (7, 2);   -- Tomislav | Option 2 (VIP)

UPDATE reservation SET attended_at = '2025-10-01 08:15:00'
WHERE (person_id, option_id) = (2, 2);   -- Ivan     | Option 2 (VIP)

-- ── Event 2 (Plivanje za početnike, 2025-11-05 09:00) ─────────────────────────
UPDATE reservation SET attended_at = '2025-11-05 09:15:00'
WHERE (person_id, option_id) = (1, 3);   -- Ana      | Option 3

UPDATE reservation SET attended_at = '2025-11-05 09:20:00'
WHERE (person_id, option_id) = (3, 3);   -- Marija   | Option 3

-- ── Event 3 (Fitness vikend, 2025-09-15 10:00) ────────────────────────────────
UPDATE reservation SET attended_at = '2025-09-15 10:05:00'
WHERE (person_id, option_id) = (2, 4);   -- Ivan     | Option 4

UPDATE reservation SET attended_at = '2025-09-15 10:10:00'
WHERE (person_id, option_id) = (4, 4);   -- Pero     | Option 4

-- ── Event 5 (Košarkaški turnir, 2025-10-20 10:00) ─────────────────────────────
UPDATE reservation SET attended_at = '2025-10-20 10:05:00'
WHERE (person_id, option_id) = (2, 6);   -- Ivan     | Option 6 (Tim A)

UPDATE reservation SET attended_at = '2025-10-20 10:15:00'
WHERE (person_id, option_id) = (5, 6);   -- Luka     | Option 6 (Tim A)

UPDATE reservation SET attended_at = '2025-10-20 10:10:00'
WHERE (person_id, option_id) = (7, 7);   -- Tomislav | Option 7 (Tim B)

-- ── Event 7 (Zimski fitness, 2025-12-15 09:00) ────────────────────────────────
-- Sara (9, 9) potvrđena ali BEZ attended_at — prikazuje razliku CONFIRMED ≠ attended

-- ============================================================
-- RUČNO POKRETANJE — Trigger B (set_updated_at)
-- Bilo koji UPDATE koji mijenja poslovne kolone aktivira trigger B.
--
-- Stanje PRIJE:
-- SELECT id, title, location, updated_at FROM event WHERE id = 1;
--
-- UPDATE event SET location = 'Nova dvorana' WHERE id = 1;
--
-- Stanje NAKON (updated_at automatski ažuriran, nije naveden u SET):
-- SELECT id, title, location, updated_at FROM event WHERE id = 1;
--
-- PRETHODNA POKRETANJA: PostgreSQL ne logira okidaje triggera B.
-- Posljednje aktiviranje vidljivo je kao updated_at vrijednost:
-- SELECT id, title, updated_at FROM event ORDER BY updated_at DESC;
-- SELECT id, person_id, option_id, updated_at
-- FROM   reservation ORDER BY updated_at DESC;
-- ============================================================


-- ============================================================
-- BLOK 9 — EVENT_TRAINER (M:N junction: event ↔ person)
-- Poravnanje: puna imena osoba desno-popunjena do "Nikola Trener" (13 znakova)
-- ============================================================

INSERT INTO event_trainer (event_id, person_id) VALUES
    (1, 8),   -- Nikola Trener → trener na Jutarnjoj jogi
    (2, 8),   -- Nikola Trener → trener na Plivanju
    (4, 8),   -- Nikola Trener → trener na Večernjoj jogi
    (5, 4);   -- Pero Perić    → trener na Košarci  (ujedno i sudionik na Tim B)

-- FAILS: PRIMARY KEY(event_id, person_id) — isti par već postoji
-- INSERT INTO event_trainer (event_id, person_id) VALUES (1, 8);
-- ERROR: duplicate key value violates unique constraint "event_trainer_pk"
-- DETAIL: Key (event_id, person_id)=(1, 8) already exists.

-- FAILS: FK(person_id) ON DELETE RESTRICT — trener ne može biti obrisan dok je dodijeljen
-- DELETE FROM person WHERE id = 8;
-- ERROR: update or delete on table "person" violates foreign key constraint
--        "event_trainer_person_fk" on table "event_trainer"


-- ============================================================
-- BLOK 10 — FILES (bez FK — polymorphic asocijacija)
-- ============================================================

INSERT INTO file (name, type, size, hash) VALUES
    ('jutarnja-joga-plakat.jpg', 'image/jpeg', 245120,
     'a3f2b1c9d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3'),
    ('unisport-logo.png',        'image/png',   82400,
     'b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1');


-- ============================================================
-- NAPOMENA: Provjera rezultata složenih upita
-- ============================================================
-- Upit 7.1: 5 redaka; Zdravlje(7 conf), Rekreacija(5 conf), Sport(3 conf),
--           Zabava(0 — soft-deleted event), Kultura(0 — nema eventa, LEFT JOIN)
-- Upit 7.2: 1 redak;  Unisport Health, 4 eventi, 15 sudionika, ~47% occ
-- Upit 7.3: 9 opcija sortiranih po popunjenosti; Option 2 i 3 po 100%
-- Upit 7.4: 6 osoba ispod 80% — Ana(40%), Marija(25%), Pero(50%),
--           Maja(33%), Tomislav(50%), Sara(25%)
-- ============================================================


-- ============================================================
-- RUČNO POKRETANJE — View event_option_stats
-- View se izračunava u trenutku upita (nije materijaliziran);
-- nema prethodnih pokretanja — svaki SELECT vraća aktualno stanje.
--
-- Cijeli view:
-- SELECT * FROM event_option_stats;
--
-- Filtrirano (kao u upitu 7.3):
-- SELECT event_title, option_title, occupancy_percent
-- FROM   event_option_stats
-- WHERE  starts_at >= '2025-01-01' AND starts_at < '2026-01-01'
-- ORDER BY occupancy_percent DESC NULLS LAST;
--
-- Inspekcija definicije viewa:
-- SELECT definition FROM pg_views WHERE viewname = 'event_option_stats';
-- ============================================================


-- ============================================================
-- RUČNO POKRETANJE — check_capacity_integrity() + pg_cron
--
-- Jednokratno pokretanje funkcije:
-- SELECT check_capacity_integrity();
--
-- PRETHODNA POKRETANJA — discrepancy log (svaki run upisuje redak):
-- SELECT checked_at, option_id, issue
-- FROM   integrity_log
-- ORDER BY checked_at DESC LIMIT 20;
--
-- PRETHODNA POKRETANJA — pg_cron job history:
-- SELECT jobid, start_time, end_time, status, return_message
-- FROM   cron.job_run_details
-- WHERE  command LIKE '%check_capacity_integrity%'
-- ORDER BY start_time DESC LIMIT 10;
-- ============================================================

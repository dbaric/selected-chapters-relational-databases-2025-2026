-- ============================================================
-- UNIST Rezervacijski Sustav — PostgreSQL DDL
-- S0 artefakt: finalni CREATE TABLE za svih 13 entiteta
-- ============================================================
-- Redosljed kreiranja poštuje FK ovisnosti:
--   lookup tablice → organization → category → person
--   → event → option → reservation → file
--   → organization_event → event_trainer
-- ============================================================

-- ============================================================
-- SEKVENCE (eksplicitne, radi vidljivosti mehanizma — §5.1)
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS gender_seq       START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS country_seq      START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS shirt_size_seq   START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS faculty_seq      START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS organization_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS category_seq     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS person_seq       START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS event_seq        START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS option_seq       START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS reservation_seq  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS file_seq         START WITH 1 INCREMENT BY 1;

-- ============================================================
-- LOOKUP TABLICE
-- ============================================================

CREATE TABLE gender (
    id    INTEGER      NOT NULL DEFAULT nextval('gender_seq'),
    value VARCHAR(10)  NOT NULL,
    label VARCHAR(50)  NOT NULL,
    CONSTRAINT gender_pk        PRIMARY KEY (id),
    CONSTRAINT gender_value_uq  UNIQUE (value)
);

CREATE TABLE country (
    id    INTEGER      NOT NULL DEFAULT nextval('country_seq'),
    value VARCHAR(10)  NOT NULL,
    label VARCHAR(100) NOT NULL,
    CONSTRAINT country_pk       PRIMARY KEY (id),
    CONSTRAINT country_value_uq UNIQUE (value)
);

CREATE TABLE shirt_size (
    id    INTEGER      NOT NULL DEFAULT nextval('shirt_size_seq'),
    value VARCHAR(10)  NOT NULL,
    label VARCHAR(50)  NOT NULL,
    CONSTRAINT shirt_size_pk       PRIMARY KEY (id),
    CONSTRAINT shirt_size_value_uq UNIQUE (value)
);

CREATE TABLE faculty (
    id    INTEGER       NOT NULL DEFAULT nextval('faculty_seq'),
    value VARCHAR(20)   NOT NULL,
    label VARCHAR(200)  NOT NULL,
    CONSTRAINT faculty_pk       PRIMARY KEY (id),
    CONSTRAINT faculty_value_uq UNIQUE (value)
);

-- ============================================================
-- ORGANIZACIJA
-- ============================================================

CREATE TABLE organization (
    id         INTEGER       NOT NULL DEFAULT nextval('organization_seq'),
    name       VARCHAR(200)  NOT NULL,
    created_at TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP     NOT NULL DEFAULT NOW(),
    CONSTRAINT organization_pk PRIMARY KEY (id)
);

-- ============================================================
-- KATEGORIJA
-- ============================================================

CREATE TABLE category (
    id         INTEGER       NOT NULL DEFAULT nextval('category_seq'),
    name       VARCHAR(100)  NOT NULL,
    created_at TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP     NOT NULL DEFAULT NOW(),
    CONSTRAINT category_pk      PRIMARY KEY (id),
    CONSTRAINT category_name_uq UNIQUE (name)
);

-- ============================================================
-- OSOBA
-- ============================================================

CREATE TABLE person (
    id              INTEGER       NOT NULL DEFAULT nextval('person_seq'),
    first_name      VARCHAR(100)  NOT NULL,
    last_name       VARCHAR(100)  NOT NULL,
    email           VARCHAR(255),
    phone           VARCHAR(30),
    tax_number      VARCHAR(20),
    country         VARCHAR(10),
    shirt_size      VARCHAR(10),
    faculty         VARCHAR(20),
    year_of_study   INTEGER,
    dirty_socks     TEXT,
    image           TEXT,
    organization_id INTEGER,
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
    CONSTRAINT person_pk                PRIMARY KEY (id),
    CONSTRAINT person_email_uq          UNIQUE (email),
    CONSTRAINT person_year_of_study_chk CHECK (year_of_study BETWEEN 1 AND 8),
    CONSTRAINT person_organization_fk   FOREIGN KEY (organization_id)
        REFERENCES organization (id) ON DELETE SET NULL
);

-- ============================================================
-- DOGAĐAJ
-- ============================================================

CREATE TABLE event (
    id                     INTEGER       NOT NULL DEFAULT nextval('event_seq'),
    title                  VARCHAR(300)  NOT NULL,
    description            TEXT,
    image                  TEXT,
    location               VARCHAR(300),
    starts_at              TIMESTAMP     NOT NULL,
    ends_at                TIMESTAMP     NOT NULL,
    published_at           TIMESTAMP,
    archived_at            TIMESTAMP,
    cancelled_at           TIMESTAMP,
    opens_at               TIMESTAMP,
    closes_at              TIMESTAMP,
    notes                  TEXT,
    cancellation_reason    TEXT,
    reservations_open_at   TIMESTAMP,
    reservations_close_at  TIMESTAMP,
    reservations_cancel_at TIMESTAMP,
    deleted_at             TIMESTAMP,
    category_id            INTEGER,
    created_at             TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMP     NOT NULL DEFAULT NOW(),
    CONSTRAINT event_pk                 PRIMARY KEY (id),
    CONSTRAINT event_ends_after_starts  CHECK (ends_at > starts_at),
    CONSTRAINT event_category_fk        FOREIGN KEY (category_id)
        REFERENCES category (id) ON DELETE SET NULL
);

-- ============================================================
-- OPCIJA
-- ============================================================

CREATE TABLE option (
    id                  INTEGER       NOT NULL DEFAULT nextval('option_seq'),
    title               VARCHAR(300)  NOT NULL,
    description         TEXT,
    total_units         INTEGER       NOT NULL DEFAULT 0,
    available_units     INTEGER       NOT NULL DEFAULT 0,
    taken_units         INTEGER       NOT NULL DEFAULT 0,
    wait_list_units     INTEGER       NOT NULL DEFAULT 0,
    is_waitlistable     BOOLEAN       NOT NULL DEFAULT FALSE,
    is_auto_confirmable BOOLEAN       NOT NULL DEFAULT FALSE,
    is_sport_only       BOOLEAN       NOT NULL DEFAULT FALSE,
    is_student_only     BOOLEAN       NOT NULL DEFAULT FALSE,
    deleted_at          TIMESTAMP,
    event_id            INTEGER       NOT NULL,
    created_at          TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP     NOT NULL DEFAULT NOW(),
    CONSTRAINT option_pk                      PRIMARY KEY (id),
    CONSTRAINT option_total_units_chk         CHECK (total_units     >= 0),
    CONSTRAINT option_available_units_chk     CHECK (available_units >= 0),
    CONSTRAINT option_taken_units_chk         CHECK (taken_units     >= 0),
    CONSTRAINT option_wait_list_units_chk     CHECK (wait_list_units >= 0),
    CONSTRAINT option_event_fk                FOREIGN KEY (event_id)
        REFERENCES event (id) ON DELETE RESTRICT
);

-- ============================================================
-- REZERVACIJA
-- ============================================================

CREATE TABLE reservation (
    id          INTEGER   NOT NULL DEFAULT nextval('reservation_seq'),
    status      INTEGER   NOT NULL DEFAULT 0,  -- 0=pending, 1=confirmed, 2=cancelled
    attended_at TIMESTAMP,
    notes       TEXT,
    deleted_at  TIMESTAMP,
    queued      BOOLEAN   NOT NULL DEFAULT FALSE,
    person_id   INTEGER   NOT NULL,
    option_id   INTEGER   NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT reservation_pk         PRIMARY KEY (id),
    CONSTRAINT reservation_status_chk CHECK (status IN (0, 1, 2)),
    CONSTRAINT reservation_person_fk  FOREIGN KEY (person_id)
        REFERENCES person (id) ON DELETE RESTRICT,
    CONSTRAINT reservation_option_fk  FOREIGN KEY (option_id)
        REFERENCES option (id) ON DELETE RESTRICT
);

-- ============================================================
-- DATOTEKA (namjerno bez FK — polimorfna asocijacija)
-- ============================================================

CREATE TABLE file (
    id         INTEGER       NOT NULL DEFAULT nextval('file_seq'),
    name       VARCHAR(300)  NOT NULL,
    type       VARCHAR(100)  NOT NULL,
    size       INTEGER       NOT NULL,
    hash       VARCHAR(256)  NOT NULL,
    created_at TIMESTAMP     NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP,
    CONSTRAINT file_pk PRIMARY KEY (id)
    -- FK namjerno izostavljen: asocijacija se rješava na aplikacijskom sloju
    -- jer isti file može biti vezan za event, osobu ili organizaciju
);

-- ============================================================
-- JUNCTION TABLICE
-- ============================================================

CREATE TABLE organization_event (
    organization_id INTEGER NOT NULL,
    event_id        INTEGER NOT NULL,
    CONSTRAINT organization_event_pk      PRIMARY KEY (organization_id, event_id),
    CONSTRAINT org_event_organization_fk  FOREIGN KEY (organization_id)
        REFERENCES organization (id) ON DELETE CASCADE,
    CONSTRAINT org_event_event_fk         FOREIGN KEY (event_id)
        REFERENCES event (id) ON DELETE CASCADE
);

CREATE TABLE event_trainer (
    event_id  INTEGER NOT NULL,
    person_id INTEGER NOT NULL,
    CONSTRAINT event_trainer_pk         PRIMARY KEY (event_id, person_id),
    CONSTRAINT event_trainer_event_fk   FOREIGN KEY (event_id)
        REFERENCES event (id) ON DELETE CASCADE,
    CONSTRAINT event_trainer_person_fk  FOREIGN KEY (person_id)
        REFERENCES person (id) ON DELETE RESTRICT
);

-- ============================================================
-- TRIGGERI — KATEGORIJA B: automatsko ažuriranje updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_updated_at
BEFORE UPDATE ON event
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER option_updated_at
BEFORE UPDATE ON option
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER reservation_updated_at
BEFORE UPDATE ON reservation
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER person_updated_at
BEFORE UPDATE ON person
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER organization_updated_at
BEFORE UPDATE ON organization
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER category_updated_at
BEFORE UPDATE ON category
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TRIGGERI — KATEGORIJA C: kapacitetno upravljanje
-- ============================================================

-- C1+C2: BEFORE INSERT — provjera kapaciteta, postavljanje queued
--        zastavice i ažuriranje option brojača u jednoj operaciji.
--        FOR UPDATE zaključava redak opcije radi sprječavanja
--        race conditiona (dva korisnika istovremeno rezerviraju
--        zadnje slobodno mjesto).

CREATE OR REPLACE FUNCTION enforce_option_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_available    INTEGER;
    v_waitlistable BOOLEAN;
BEGIN
    SELECT available_units, is_waitlistable
    INTO   v_available, v_waitlistable
    FROM   option
    WHERE  id = NEW.option_id
    FOR UPDATE;

    IF v_available <= 0 AND NOT v_waitlistable THEN
        RAISE EXCEPTION
            'Opcija % je popunjena i ne podržava čekalnu listu.',
            NEW.option_id;
    END IF;

    IF v_available > 0 THEN
        UPDATE option
        SET    taken_units     = taken_units + 1,
               available_units = GREATEST(available_units - 1, 0)
        WHERE  id = NEW.option_id;
        NEW.queued := FALSE;
    ELSE
        UPDATE option
        SET    wait_list_units = wait_list_units + 1
        WHERE  id = NEW.option_id;
        NEW.queued := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reservation_enforce_capacity
BEFORE INSERT ON reservation
FOR EACH ROW EXECUTE FUNCTION enforce_option_capacity();

-- C3: AFTER UPDATE — promjena statusa rezervacije.
--     OLD.queued određuje koji se brojač dekrementira pri otkazivanju:
--     regularna rezervacija oslobađa available_units,
--     wait list rezervacija oslobađa wait_list_units.

CREATE OR REPLACE FUNCTION sync_option_capacity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 2 AND OLD.status <> 2 THEN
        IF OLD.queued THEN
            UPDATE option
            SET    wait_list_units = GREATEST(wait_list_units - 1, 0)
            WHERE  id = NEW.option_id;
        ELSE
            UPDATE option
            SET    taken_units     = GREATEST(taken_units - 1, 0),
                   available_units = available_units + 1
            WHERE  id = NEW.option_id;
        END IF;

    ELSIF OLD.status = 2 AND NEW.status <> 2 THEN
        IF NEW.queued THEN
            UPDATE option
            SET    wait_list_units = wait_list_units + 1
            WHERE  id = NEW.option_id;
        ELSE
            UPDATE option
            SET    taken_units     = taken_units + 1,
                   available_units = GREATEST(available_units - 1, 0)
            WHERE  id = NEW.option_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reservation_sync_capacity
AFTER UPDATE ON reservation
FOR EACH ROW EXECUTE FUNCTION sync_option_capacity();

-- ============================================================
-- VIEW — agregirana statistika opcija (§5.6)
-- ============================================================

CREATE OR REPLACE VIEW event_option_stats AS
SELECT
    e.id                                                            AS event_id,
    e.title                                                         AS event_title,
    COALESCE(c.name, 'Bez kategorije')                              AS category_name,
    e.starts_at,
    e.ends_at,
    o.id                                                            AS option_id,
    o.title                                                         AS option_title,
    o.total_units,
    o.taken_units,
    o.available_units,
    o.wait_list_units,
    o.is_waitlistable,
    ROUND(
        o.taken_units::NUMERIC / NULLIF(o.total_units, 0) * 100, 2
    )                                                               AS occupancy_percent
FROM   event e
INNER JOIN option   o ON o.event_id  = e.id
LEFT  JOIN category c ON c.id        = e.category_id
WHERE  e.deleted_at IS NULL
  AND  o.deleted_at IS NULL;

-- ============================================================
-- INDEKSI (§5.7)
-- ============================================================

-- Primjer 1: B-tree indeks za range upite po datumu početka
CREATE INDEX idx_event_starts_at ON event (starts_at);

-- Primjer 2: Parcijalni indeks — pokriva samo aktivne (ne soft-deleted) događaje;
--            manji od punog indeksa jer obrisane retke uopće ne indeksira.
CREATE INDEX idx_event_active_starts ON event (starts_at)
WHERE deleted_at IS NULL;

-- ============================================================
-- RASPOREĐENA PROCEDURA PROVJERE INTEGRITETA (§5.8)
-- ============================================================

-- Korak 1 — Tablica za zapis odstupanja
CREATE TABLE IF NOT EXISTS integrity_log (
    id         SERIAL    PRIMARY KEY,
    checked_at TIMESTAMP NOT NULL DEFAULT NOW(),
    option_id  INTEGER,
    issue      TEXT      NOT NULL
);

-- Korak 2 — Funkcija provjere kapacitetnih invarijanata:
--   available_units + taken_units = total_units
--   wait_list_units = broj aktivnih rezervacija s queued = TRUE
CREATE OR REPLACE FUNCTION check_capacity_integrity()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT
            o.id,
            o.total_units,
            o.available_units,
            o.taken_units,
            o.wait_list_units,
            COUNT(*) FILTER (WHERE res.queued = FALSE
                             AND   res.status IN (0, 1)
                             AND   res.deleted_at IS NULL) AS actual_taken,
            COUNT(*) FILTER (WHERE res.queued = TRUE
                             AND   res.status <> 2
                             AND   res.deleted_at IS NULL) AS actual_queued
        FROM   option o
        LEFT JOIN reservation res ON res.option_id = o.id
        WHERE  o.deleted_at IS NULL
        GROUP BY o.id
    LOOP
        IF r.taken_units <> r.actual_taken THEN
            INSERT INTO integrity_log (option_id, issue)
            VALUES (r.id,
                    FORMAT('taken_units=%s, ali stvarnih potvrđenih rezervacija=%s',
                           r.taken_units, r.actual_taken));
        END IF;

        IF (r.available_units + r.taken_units) <> r.total_units THEN
            INSERT INTO integrity_log (option_id, issue)
            VALUES (r.id,
                    FORMAT('available(%s) + taken(%s) ≠ total(%s)',
                           r.available_units, r.taken_units, r.total_units));
        END IF;

        IF r.wait_list_units <> r.actual_queued THEN
            INSERT INTO integrity_log (option_id, issue)
            VALUES (r.id,
                    FORMAT('wait_list_units=%s, ali stvarnih na čekanju=%s',
                           r.wait_list_units, r.actual_queued));
        END IF;
    END LOOP;
END;
$$;

-- Korak 3 — Raspored s pg_cron (svaki dan u 03:00)
--   Zahtijeva instaliranu pg_cron ekstenziju na serveru.
--   Alternativa bez ekstenzije: OS-level cron → psql -c "SELECT check_capacity_integrity()"
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    PERFORM cron.schedule(
        'integrity-check-daily',
        '0 3 * * *',
        'SELECT check_capacity_integrity()'
    );
    RAISE NOTICE 'pg_cron: raspored integrity-check-daily postavljen.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron nije dostupan (%). Raspored nije postavljen — pokrenuti ručno: SELECT check_capacity_integrity()', SQLERRM;
END;
$$;

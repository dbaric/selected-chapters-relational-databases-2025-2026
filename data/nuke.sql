-- ============================================================
-- NUKE — UNIST Rezervacijski Sustav
-- Pokretanje: psql -U unist_rezervacije -d unist_rezervacije -f nuke.sql
-- UPOZORENJE: Briše SVE tablice, triggere, funkcije i sekvence.
--             Nepovratan! Koristiti samo u dev/test okruženjima.
-- ============================================================
-- Redosljed čišćenja:
--   triggeri → tablice (CASCADE) → funkcije → sekvence
-- ============================================================


-- ============================================================
-- TRIGGERI — kategorija C (kapacitetno upravljanje)
-- ============================================================

DROP TRIGGER IF EXISTS reservation_enforce_capacity  ON reservation;
DROP TRIGGER IF EXISTS reservation_sync_capacity     ON reservation;

-- ============================================================
-- TRIGGERI — kategorija B (automatsko ažuriranje updated_at)
-- ============================================================

DROP TRIGGER IF EXISTS event_updated_at        ON event;
DROP TRIGGER IF EXISTS option_updated_at       ON option;
DROP TRIGGER IF EXISTS reservation_updated_at  ON reservation;
DROP TRIGGER IF EXISTS person_updated_at       ON person;
DROP TRIGGER IF EXISTS organization_updated_at ON organization;
DROP TRIGGER IF EXISTS category_updated_at     ON category;

-- ============================================================
-- TABLICE (CASCADE automatski uklanja FK i ovisne objekte)
-- Djeca prije roditelja samo za preglednost — CASCADE bi
-- svejedno razriješio ovisnosti.
-- ============================================================

DROP TABLE IF EXISTS event_trainer        CASCADE;
DROP TABLE IF EXISTS organization_event   CASCADE;
DROP TABLE IF EXISTS reservation          CASCADE;
DROP TABLE IF EXISTS file                 CASCADE;
DROP TABLE IF EXISTS option               CASCADE;
DROP TABLE IF EXISTS event                CASCADE;
DROP TABLE IF EXISTS person               CASCADE;
DROP TABLE IF EXISTS category             CASCADE;
DROP TABLE IF EXISTS organization         CASCADE;
DROP TABLE IF EXISTS faculty              CASCADE;
DROP TABLE IF EXISTS shirt_size           CASCADE;
DROP TABLE IF EXISTS country              CASCADE;
DROP TABLE IF EXISTS gender               CASCADE;

-- ============================================================
-- TRIGGER FUNKCIJE
-- ============================================================

DROP FUNCTION IF EXISTS set_updated_at();
DROP FUNCTION IF EXISTS enforce_option_capacity();
DROP FUNCTION IF EXISTS sync_option_capacity();

-- ============================================================
-- SEKVENCE
-- ============================================================

DROP SEQUENCE IF EXISTS gender_seq;
DROP SEQUENCE IF EXISTS country_seq;
DROP SEQUENCE IF EXISTS shirt_size_seq;
DROP SEQUENCE IF EXISTS faculty_seq;
DROP SEQUENCE IF EXISTS organization_seq;
DROP SEQUENCE IF EXISTS category_seq;
DROP SEQUENCE IF EXISTS person_seq;
DROP SEQUENCE IF EXISTS event_seq;
DROP SEQUENCE IF EXISTS option_seq;
DROP SEQUENCE IF EXISTS reservation_seq;
DROP SEQUENCE IF EXISTS file_seq;

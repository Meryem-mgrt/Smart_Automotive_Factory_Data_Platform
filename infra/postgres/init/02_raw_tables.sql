-- =====================================================================
-- 02_raw_tables.sql : tables de la couche raw (une table par type de message MQTT)
-- Règles : pas de clés étrangères ni de contraintes métier, on garde tout ce qui arrive.
-- Le nettoyage se fait plus tard dans staging (DBT).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Télémétrie des capteurs, partitionnée par jour pour rester rapide avec des millions de lignes
-- ---------------------------------------------------------------------
CREATE TABLE raw.telemetry (
    message_id   UUID        NOT NULL,                 -- identifiant unique du message (idempotence)
    machine_id   TEXT        NOT NULL,                 -- machine émettrice, ex. L1-RB03
    line_id      TEXT        NOT NULL,                 -- ligne de production, ex. L1
    ts           TIMESTAMPTZ NOT NULL,                 -- horodatage de la mesure (côté machine, UTC)
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now(),   -- horodatage de réception (côté plateforme)
    payload      JSONB       NOT NULL,                 -- message JSON complet tel que reçu
    PRIMARY KEY (message_id, ts)                       -- la clé d'une table partitionnée doit contenir ts
) PARTITION BY RANGE (ts);                             -- une partition par jour, sur la colonne ts

-- Partition de secours : reçoit tout message dont le jour n'a pas de partition dédiée
CREATE TABLE raw.telemetry_default PARTITION OF raw.telemetry DEFAULT;

-- Index pour retrouver vite les dernières mesures d'une machine
CREATE INDEX idx_telemetry_machine_ts ON raw.telemetry (machine_id, ts DESC);

-- ---------------------------------------------------------------------
-- Fonction qui crée la partition d'un jour donné (appelée par l'API en Phase 2 et par Airflow)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION raw.ensure_telemetry_partition(p_day DATE)  -- p_day : le jour à préparer
RETURNS VOID                                                           -- ne renvoie rien
LANGUAGE plpgsql                                                       -- langage procédural PostgreSQL
AS $$
DECLARE
    part_name TEXT := format('telemetry_%s', to_char(p_day, 'YYYYMMDD'));  -- nom, ex. telemetry_20261109
    start_ts  TIMESTAMPTZ := p_day::TIMESTAMP AT TIME ZONE 'UTC';          -- début du jour en UTC
    end_ts    TIMESTAMPTZ := (p_day + 1)::TIMESTAMP AT TIME ZONE 'UTC';    -- début du jour suivant en UTC
BEGIN
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS raw.%I PARTITION OF raw.telemetry FOR VALUES FROM (%L) TO (%L)',
        part_name, start_ts, end_ts                                        -- crée la partition si absente
    );
END;
$$;

-- Prépare les partitions d'aujourd'hui et des deux jours suivants
SELECT raw.ensure_telemetry_partition(current_date + i) FROM generate_series(0, 2) AS i;

-- ---------------------------------------------------------------------
-- Changements d'état des machines (RUN, IDLE, STOP, FAULT, MAINT)
-- ---------------------------------------------------------------------
CREATE TABLE raw.state_events (
    message_id   UUID PRIMARY KEY,                     -- identifiant unique du message
    machine_id   TEXT        NOT NULL,                 -- machine concernée
    line_id      TEXT        NOT NULL,                 -- ligne de production
    ts           TIMESTAMPTZ NOT NULL,                 -- moment du changement d'état
    state        TEXT        NOT NULL,                 -- nouvel état tel que reçu
    stop_code    TEXT,                                 -- code d'arrêt éventuel (S01, S02...)
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now(),   -- moment de réception
    payload      JSONB       NOT NULL                  -- message JSON complet
);
CREATE INDEX idx_state_events_machine_ts ON raw.state_events (machine_id, ts DESC);  -- accès par machine et date

-- ---------------------------------------------------------------------
-- Pièces produites : bonnes ou rebut
-- ---------------------------------------------------------------------
CREATE TABLE raw.production_events (
    message_id   UUID PRIMARY KEY,                     -- identifiant unique du message
    machine_id   TEXT        NOT NULL,                 -- machine qui a produit la pièce
    line_id      TEXT        NOT NULL,                 -- ligne de production
    ts           TIMESTAMPTZ NOT NULL,                 -- moment de production
    variant      TEXT,                                 -- variante du véhicule (BERLINE, SUV)
    result       TEXT        NOT NULL,                 -- GOOD ou SCRAP, tel que reçu
    defect_code  TEXT,                                 -- code défaut si rebut (D01, D02...)
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now(),   -- moment de réception
    payload      JSONB       NOT NULL                  -- message JSON complet
);
CREATE INDEX idx_production_events_machine_ts ON raw.production_events (machine_id, ts DESC);  -- accès par machine et date

-- ---------------------------------------------------------------------
-- Alarmes (seuil franchi, défaut détecté)
-- ---------------------------------------------------------------------
CREATE TABLE raw.alarms (
    message_id   UUID PRIMARY KEY,                     -- identifiant unique du message
    machine_id   TEXT        NOT NULL,                 -- machine concernée
    line_id      TEXT        NOT NULL,                 -- ligne de production
    ts           TIMESTAMPTZ NOT NULL,                 -- moment de l'alarme
    severity     TEXT,                                 -- gravité (INFO, WARNING, CRITICAL)
    alarm_code   TEXT,                                 -- code de l'alarme
    message      TEXT,                                 -- texte libre
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now(),   -- moment de réception
    payload      JSONB       NOT NULL                  -- message JSON complet
);
CREATE INDEX idx_alarms_machine_ts ON raw.alarms (machine_id, ts DESC);  -- accès par machine et date

-- ---------------------------------------------------------------------
-- Messages rejetés par la validation FastAPI : on les garde pour comprendre l'erreur
-- ---------------------------------------------------------------------
CREATE TABLE raw.rejected_messages (
    id           BIGSERIAL PRIMARY KEY,                -- identifiant technique
    topic        TEXT        NOT NULL,                 -- topic MQTT d'origine
    payload      TEXT,                                 -- contenu brut (peut ne pas être du JSON valide)
    error        TEXT        NOT NULL,                 -- raison du rejet
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now()    -- moment de réception
);

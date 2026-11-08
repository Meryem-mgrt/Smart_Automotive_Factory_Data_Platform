-- =====================================================================
-- 00_create_airflow_db.sql : crée la base des métadonnées d'Airflow
-- Séparée de factory_dw pour ne pas mélanger données métier et technique.
-- Exécuté une seule fois, au premier démarrage (volume pgdata vide).
-- =====================================================================

CREATE DATABASE airflow;  -- le nom doit correspondre à AIRFLOW_DB dans .env

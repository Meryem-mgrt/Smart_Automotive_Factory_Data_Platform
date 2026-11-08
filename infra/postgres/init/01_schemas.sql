-- =====================================================================
-- 01_schemas.sql : crée les couches de la base factory_dw
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS raw;        -- messages MQTT tels que reçus, jamais modifiés
CREATE SCHEMA IF NOT EXISTS ref;        -- référentiels (machines, lignes, codes), chargés par DBT seeds
CREATE SCHEMA IF NOT EXISTS staging;    -- données nettoyées et typées, construites par DBT
CREATE SCHEMA IF NOT EXISTS marts;      -- modèle en étoile et KPI, lus par Power BI et le chatbot
CREATE SCHEMA IF NOT EXISTS ml;         -- variables, prédictions et anomalies des modèles IA
CREATE SCHEMA IF NOT EXISTS odoo_sync;  -- copie des données Odoo utiles au calcul (Phase 4)

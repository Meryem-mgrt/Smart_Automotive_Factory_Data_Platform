#!/bin/bash
# =====================================================================
# 04_readonly_role.sh : crée le compte bi_reader (lecture seule) pour Power BI et le chatbot
# Un script shell est utilisé ici pour lire READONLY_PASSWORD dans l'environnement du conteneur.
# =====================================================================

# Arrête le script à la première erreur
set -e

# Exécute du SQL dans la base de l'usine avec le super-utilisateur du conteneur
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Crée le rôle de connexion avec le mot de passe fourni par .env
    CREATE ROLE bi_reader LOGIN PASSWORD '${READONLY_PASSWORD}';
    -- Autorise la connexion à la base de l'usine
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO bi_reader;
    -- Autorise l'accès aux schémas marts et ref (jamais raw ni staging)
    GRANT USAGE ON SCHEMA marts, ref TO bi_reader;
    -- Donne la lecture sur les tables déjà présentes de ces schémas
    GRANT SELECT ON ALL TABLES IN SCHEMA marts, ref TO bi_reader;
    -- Donne automatiquement la lecture sur les futures tables créées par le super-utilisateur (DBT)
    ALTER DEFAULT PRIVILEGES FOR ROLE ${POSTGRES_USER} IN SCHEMA marts, ref GRANT SELECT ON TABLES TO bi_reader;
EOSQL

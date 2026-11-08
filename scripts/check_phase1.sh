#!/bin/bash
# =====================================================================
# check_phase1.sh : vérifie que l'infrastructure de la Phase 1 fonctionne de bout en bout
# Usage : bash scripts/check_phase1.sh   (ou : make check)
# =====================================================================

# Arrête à la première commande en erreur
set -e
# Charge les variables du fichier .env (POSTGRES_USER, POSTGRES_DB...)
set -a; source .env; set +a

# Petite fonction d'affichage d'une étape réussie
ok() { echo "  [OK] $1"; }

echo "1) Services Docker"
# Compte les services en état "healthy" ou "running"
docker compose ps --format '{{.Name}} {{.State}} {{.Health}}'

echo "2) PostgreSQL : schémas attendus"
# Liste les schémas métier présents dans la base
SCHEMAS=$(docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc \
  "SELECT string_agg(schema_name, ',' ORDER BY schema_name) FROM information_schema.schemata WHERE schema_name IN ('raw','ref','staging','marts','ml','odoo_sync')")
# Compare avec la liste attendue
[ "$SCHEMAS" = "marts,ml,odoo_sync,raw,ref,staging" ] && ok "6 schémas présents" || { echo "  [ERREUR] schémas : $SCHEMAS"; exit 1; }

echo "3) PostgreSQL : tables raw"
# Compte les tables de la couche raw (partitions comprises)
N=$(docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema='raw' AND table_name IN ('telemetry','state_events','production_events','alarms','rejected_messages')")
# Doit en trouver 5
[ "$N" = "5" ] && ok "5 tables raw présentes" || { echo "  [ERREUR] $N tables sur 5"; exit 1; }

echo "4) MQTT : aller-retour publication / abonnement"
# S'abonne en arrière-plan pendant 5 secondes, puis publie un message de test
docker compose exec -T mosquitto sh -c "mosquitto_sub -t usine/test -C 1 -W 5 > /tmp/mqtt_test.txt &  sleep 1; mosquitto_pub -t usine/test -m ping; sleep 1; cat /tmp/mqtt_test.txt" | grep -q ping \
  && ok "message reçu par l'abonné" || { echo "  [ERREUR] MQTT ne répond pas"; exit 1; }

echo "5) Airflow : santé de l'interface"
# Interroge l'endpoint de santé d'Airflow
curl -fsS http://localhost:8080/health > /dev/null && ok "Airflow répond sur http://localhost:8080" || { echo "  [ERREUR] Airflow injoignable"; exit 1; }

echo "Phase 1 validée."

# =====================================================================
# Makefile : raccourcis du projet (toutes les commandes passent par Docker)
# =====================================================================
.PHONY: help up down ps logs psql check reset

help:  ## Liste les commandes
	@echo "make up     : démarre l'infrastructure"
	@echo "make down   : arrête les conteneurs (données conservées)"
	@echo "make ps     : état des conteneurs"
	@echo "make logs   : journaux en direct"
	@echo "make psql   : console SQL dans la base factory_dw"
	@echo "make check  : vérifie la Phase 1 de bout en bout"
	@echo "make reset  : DÉTRUIT les volumes (données perdues) et repart de zéro"

up:  ## Démarre tous les services en arrière-plan
	docker compose up -d

down:  ## Arrête les services sans supprimer les volumes
	docker compose down

ps:  ## Affiche l'état des services
	docker compose ps

logs:  ## Suit les journaux de tous les services
	docker compose logs -f --tail=100

psql:  ## Ouvre psql dans le conteneur PostgreSQL
	docker compose exec postgres sh -c 'psql -U $$POSTGRES_USER -d $$POSTGRES_DB'

check:  ## Lance le script de vérification
	bash scripts/check_phase1.sh

reset:  ## Supprime conteneurs ET volumes (irréversible)
	docker compose down -v

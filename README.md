# Smart Factory — Plateforme Data & IoT pour une usine automobile

Plateforme Data Engineering pour **une usine automobile fictive** (3 lignes, 27 machines) :
simulateur IoT → MQTT → FastAPI → PostgreSQL → Airflow + DBT → Odoo (ERP/MES) → IA → Power BI,
puis chatbot, Keycloak (SSO) et application mobile.

## Architecture (flux principal)

```
Simulateur → Mosquitto (MQTT) → FastAPI → PostgreSQL (raw → staging → marts)
                                              ↑ Airflow + DBT (transforme)
                                              ↓ lecture seule
                          Power BI · Modèles IA · Chatbot · App mobile
Odoo ⇄ Airflow (API)        Keycloak = authentification (Phase 8)
```

## Phases

| Phase | Contenu | État |
| --- | --- | --- |
| 0 | Cadrage, dépôt, référentiels (seeds) | fait |
| 1 | Infrastructure Docker Compose | livrée, à tester avec `make check` |
| 2 | Simulateur + ingestion MQTT/FastAPI | à faire |
| 3 | Airflow + DBT | à faire |
| 4 | Intégration Odoo | à faire |
| 5 | IA (anomalies, maintenance prédictive) | à faire |
| 6 | Power BI | à faire |
| 7 | Chatbot | à faire |
| 8 | Keycloak | à faire |
| 9 | App mobile | à faire |
| 10 | Tests, documentation, soutenance | à faire |

## Structure du dépôt

| Dossier | Rôle |
| --- | --- |
| `docs/` | cadrage, architecture, décisions (`adr/`) |
| `infra/` | configuration Mosquitto, scripts SQL d'initialisation PostgreSQL, Keycloak |
| `simulator/` | simulateur de capteurs (Phase 2) |
| `api/` | FastAPI : ingestion MQTT et endpoints (Phase 2) |
| `dbt/` | seeds (référentiels), modèles staging et marts (Phase 3) |
| `airflow/dags/` | DAG d'orchestration (Phase 3) |
| `odoo/` | configuration et modules Odoo (Phase 4) |
| `ml/` | modèles IA et MLflow (Phase 5) |
| `chatbot/` | chatbot (Phase 7) |
| `mobile/` | application mobile (Phase 9) |
| `powerbi/` | fichier `.pbix` et captures (Phase 6) |
| `tests/` | tests d'intégration de bout en bout |

## Démarrage (Phase 1)

```bash
cp .env.example .env     # puis changer les mots de passe
make up                  # démarre Mosquitto, PostgreSQL et Airflow
make check               # vérifie schémas, tables raw, MQTT et Airflow
```

- Airflow : http://localhost:8080 (compte défini dans `.env`)
- PostgreSQL : `localhost:5432`, base `factory_dw` ; compte lecture seule `bi_reader`
- MQTT : `localhost:1883`

## Conventions

- Branches : `main` (stable), `dev`, `feat/<sujet>`.
- Commits : `feat:`, `fix:`, `docs:` + message court.
- Tables et colonnes en anglais ; horodatages en UTC (`timestamptz`).
- Aucun secret dans le dépôt : tout passe par `.env`.

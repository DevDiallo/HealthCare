# HealthCare Microservices Platform

Plateforme SaaS de gestion hospitaliere multi-tenant, basee sur une architecture microservices avec API Gateway Nginx.

## Stack

- Frontend: React + TypeScript + Redux Toolkit + Axios + React Router + Formik + Yup
- Backend: Java 21 + Spring Boot + Spring Security + JWT + JPA + Swagger
- Data: PostgreSQL
- Gateway: Nginx (reverse proxy, CORS, TLS, timeout, logs)
- Containerisation: Docker + Docker Compose

## Services

- auth-service: http://localhost/api/auth
- hospital-service: http://localhost/api/hospitals
- patient-service: http://localhost/api/patients
- doctor-service: http://localhost/api/doctors
- appointment-service: http://localhost/api/appointments
- notification-service: http://localhost/api/notifications

## Lancement rapide

1. Generer les certificats TLS:
   - bash scripts/generate-certs.sh
2. Lancer la plateforme:
   - docker compose up --build
3. Ouvrir l'application:
   - https://localhost

## Developpement local

### Architecture locale sans Docker

Ce mode conserve la meme architecture:

- React (frontend)
- Nginx API Gateway
- 6 microservices Spring Boot
- PostgreSQL local

Le gateway local ecoute sur `http://localhost:8080` et route:

- `/` vers le frontend React (`localhost:5173`)
- `/api/auth/*` vers `auth-service` (`localhost:8081`)
- `/api/hospitals/*` vers `hospital-service` (`localhost:8082`)
- `/api/patients/*` vers `patient-service` (`localhost:8083`)
- `/api/doctors/*` vers `doctor-service` (`localhost:8084`)
- `/api/appointments/*` vers `appointment-service` (`localhost:8085`)
- `/api/notifications/*` vers `notification-service` (`localhost:8086`)

### Prerequis (sans Docker)

- Java 21
- Maven
- Node.js 20+
- Nginx
- PostgreSQL local (port `5432`, user/password par defaut: `healthcare/healthcare`)

### Lancer toute la plateforme en local

Depuis la racine du projet:

- `bash scripts/start-local.sh`

Le script:

- demarre les 6 microservices Spring en arriere-plan
- demarre le frontend Vite en arriere-plan
- demarre Nginx avec la config `gateway/nginx.local.conf`
- tente de creer automatiquement les bases PostgreSQL si `psql` est disponible

Arreter la plateforme:

- `bash scripts/stop-local.sh`

Logs locaux:

- `.local-runtime/logs/`

### Backend

- cd backend/auth-service && mvn spring-boot:run
- cd backend/hospital-service && mvn spring-boot:run
- cd backend/patient-service && mvn spring-boot:run
- cd backend/doctor-service && mvn spring-boot:run
- cd backend/appointment-service && mvn spring-boot:run
- cd backend/notification-service && mvn spring-boot:run

### Frontend

- cd frontend
- npm install
- npm run dev

## Tests

- cd backend/<service>
- mvn test

## Swagger

Chaque service expose Swagger via:

- /swagger-ui.html
- /v3/api-docs

## Multi-tenant

Le JWT transporte:

- userId
- hospitalId
- role

Les services appliquent le filtrage par tenant via le contexte de securite et les filtres JWT.

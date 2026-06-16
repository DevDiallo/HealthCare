# Architecture Technique

## Vue globale

Frontend React -> API Gateway Nginx -> Microservices Spring Boot -> PostgreSQL

## Principes

- Aucun appel frontend direct vers les microservices
- Toutes les routes passent par la gateway Nginx
- Un service = un contexte metier autonome
- Une base logique par service (schemas separates via bases dediees)

## Securite

- JWT Bearer pour authentification
- RBAC selon roles: SUPER_ADMIN, HOSPITAL_ADMIN, DOCTOR, PATIENT, NURSE, RECEPTIONIST
- Contexte tenant derive du token (hospitalId)

## Multi-tenant

- Filtrage de donnees base sur hospitalId
- SUPER_ADMIN multi-hopitaux
- Autres roles limites a leur etablissement

## Disponibilite

- Nginx upstream avec least_conn
- Timeouts et gestion d'erreurs standardisee
- Health endpoint gateway: /health

## Observabilite

- Logs Nginx access/error
- Actuator health pour les services

## Conventions backend

- controller
- service / serviceImpl
- repository
- entity
- dto
- mapper
- config
- security
- exception
- util

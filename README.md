# TP Terraform DevOps S8


## Description
Infrastructure AWS avec Terraform - Provider Docker, GitHub, puis AWS.

## Prérequis
- Terraform >= 1.6
- Docker Desktop
- Git

## Structure
- `tp-docker/` : Exercice provider Docker
- `tp-github/` : Exercice provider GitHub  
- `tp-aws/` : Infrastructure AWS complète


## Etape 1 — Provider Docker

### Ce que j'ai fait
Au lieu de créer des containers Docker manuellement avec `docker run`,
j'ai décrit l'infrastructure dans des fichiers Terraform (`.tf`).
Terraform crée, modifie ou détruit les ressources automatiquement.

### Ressources créées
- Un container **nginx** exposé sur le port 8081
- Un réseau Docker **app-network**

### Commandes utilisées
```bash
terraform init   # Télécharge le provider Docker
terraform plan   # Aperçu de ce qui va être créé
terraform apply  # Crée vraiment les ressources
```

### Résultat
- nginx répond sur http://localhost:8081
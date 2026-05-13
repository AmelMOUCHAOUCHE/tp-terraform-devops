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

### le travail fait
- Créé un container **nginx** exposé sur le port 8081
- Créé un container **redis** sur le même réseau Docker
- Vérifié l'**idempotence** : 2ème apply = 0 changes
- Testé **terraform destroy** : 5 ressources supprimées proprement

### Commandes utilisées
```bash
terraform init   # Télécharge le provider Docker
terraform plan   # Aperçu de ce qui va être créé
terraform apply  # Crée vraiment les ressources
```

### Résultat
- nginx répond sur http://localhost:8081
- redis tourne sur le même réseau que nginx
- terraform destroy supprime tout proprement

## Etape 2 — Provider GitHub 

### le travail fait
- Créé un dépôt GitHub **tp-terraform-amel-demo** avec Terraform
- Ajouté une protection de branche sur `main`
- Ajouté un secret GitHub Actions `DATABASE_URL`

### Résultat
- Dépôt créé automatiquement sur GitHub
- Branche main protégée
- Secret DATABASE_URL configuré

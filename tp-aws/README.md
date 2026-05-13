## Étape 3 — AWS Infrastructure

### Membres
- Amel Mouchaouche 
- Olubusola Odufejo Ogoe

### Prérequis
- Terraform >= 1.6
- Docker Desktop
- LocalStack
- AWS CLI configuré (`aws configure`)
- Une paire de clés SSH (`~/.ssh/tp_terraform`)

### Structure des fichiers
tp-aws/
├── versions.tf       # Providers requis (aws, random)
├── provider.tf       # Configuration provider AWS + default_tags
├── main.tf           # Toutes les ressources AWS
├── variables.tf      # Déclaration des variables
├── outputs.tf        # Valeurs exportées
├── terraform.tfvars  # Valeurs (sans secrets)
└── .gitignore        # Exclusions Git

### Déploiement
```bash
# Phase 1 - LocalStack
tflocal init
tflocal plan
tflocal apply

# Phase 2 - AWS réel
terraform init
terraform plan
terraform apply
```

### Ressources créées

| Ressource | ID |
|---|---|
| VPC | `vpc-0ef7ce62b294d0988` |
| Internet Gateway | `igw-0dc0ee026938826cc` |
| Subnet public | `subnet-003bb7c825d4c6d3c` |
| Route Table | `rtb-0456f61d8fc2a8794` |
| Security Group | `sg-01439c0583da77cf1` |
| Key Pair | `tp-terraform-amel-key` |
| EC2 Instance | `i-0b39e628b44977221` |
| S3 Bucket | `tp-terraform-amelassets-f2c84ea0` |

### Outputs terraform output

instance_public_dns = "ec2-13-36-244-44.eu-west-3.compute.amazonaws.com"
instance_public_ip  = "13.36.244.44"
s3_bucket_name      = "tp-terraform-amel-assets-f2c84ea0"
ssh_command         = "ssh -i ~/.ssh/tp_terraform ubuntu@13.36.244.44"
vpc_id              = "vpc-0ef7ce62b294d0988"

### Connexion SSH démontrée

```bash
ssh -i ~/.ssh/tp_terraform ubuntu@13.36.244.44
```

Vérifications sur l'instance :

OS     : Ubuntu 24.04.1 LTS - kernel 6.17.0-1012-aws x86_64
IP     : 13.36.244.44
Disque : 19G total, 17G disponible (volume gp3 20Go)


### Destruction des ressources

```bash
terraform destroy
# Destroy complete! Resources: 12 destroyed.
```


## Bonus A — RDS PostgreSQL en subnet privé

L'objectif de ce bonus est d'ajouter une base de données PostgreSQL dans un subnet privé, 
accessible uniquement depuis l'instance EC2.

### Ressources créées

| Ressource | ID/Valeur |
|---|---|
| Subnet privé 1 (10.0.2.0/24, eu-west-3a) | `subnet-07a3bca8783c00571` |
| Subnet privé 2 (10.0.3.0/24, eu-west-3b) | `subnet-0d32de01d907d0c75` |
| DB Subnet Group | `tp-terraform-amel-db-subnet-group` |
| Security Group RDS (port 5432 depuis EC2 uniquement) | `sg-0f9b6b8c60b1cf82f` |
| RDS PostgreSQL 15, db.t3.micro | `db-GRIHXUFOLN6S3JYTSRA7TV5XTI` |

### Output db_endpoint
db_endpoint = "tp-terraform-amel-db.c3qsso6ykzti.eu-west-3.rds.amazonaws.com:5432"

### Points clés

- La base de données n'a pas d'IP publique (`publicly_accessible = false`)
- Elle est accessible uniquement depuis le Security Group de l'EC2 sur le port 5432
- `skip_final_snapshot = true` pour pouvoir faire le destroy sans erreur
- Deux subnets privés dans deux AZ différentes sont requis par RDS

---

## Bonus B — Application Load Balancer

L'objectif est d'ajouter un ALB devant l'EC2 pour que ce soit lui le point d'entrée public 
sur le port 80, et non l'EC2 directement.

### Ressources créées

| Ressource | ID/Valeur |
|---|---|
| Subnet public 2 (10.0.4.0/24, eu-west-3b) | `subnet-0bbfc662bd0b35259` |
| Security Group ALB (port 80 public) | `sg-06f003a676212609b` |
| Application Load Balancer | `tp-terraform-amel-alb` |
| Target Group (port 80, HTTP) | `tp-terraform-amel-tg` |
| Listener (port 80 -> forward vers target group) | actif |
| Attachment EC2 -> Target Group | actif |

### Output alb_dns_name
alb_dns_name = "tp-terraform-amel-alb-1709616083.eu-west-3.elb.amazonaws.com"

### Points clés

- L'ALB nécessite obligatoirement deux subnets publics dans deux AZ différentes
- Le health check est configuré sur `/` avec un seuil de 2 checks
- Le listener redirige tout le trafic HTTP port 80 vers le target group EC2

---

## Bonus C — Terraform Workspaces

L'objectif est de gérer plusieurs environnements avec le même code Terraform en utilisant 
les workspaces.

### Workspaces créés

```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```
default

dev
prod


### Configuration dans main.tf

```hcl
locals {
  instance_type = {
    dev  = "t3.micro"
    prod = "t3.small"
  }
}
```

L'instance EC2 utilise automatiquement le bon type selon le workspace actif :

```hcl
instance_type = local.instance_type[terraform.workspace]
```

### Points clés

- En workspace `dev` : instance `t3.micro`
- En workspace `prod` : instance `t3.small`
- Chaque workspace a son propre state isolé
- Le code HCL est identique pour les deux environnements

### Outputs complets (workspace default)
alb_dns_name        = "tp-terraform-amel-alb-1709616083.eu-west-3.elb.amazonaws.com"
db_endpoint         = "tp-terraform-amel-db.c3qsso6ykzti.eu-west-3.rds.amazonaws.com:5432"
instance_public_dns = "ec2-15-236-42-219.eu-west-3.compute.amazonaws.com"
instance_public_ip  = "15.236.42.219"
s3_bucket_name      = "tp-terraform-amel-assets-404d9f7b"
ssh_command         = "ssh -i ~/.ssh/tp_terraform ubuntu@15.236.42.219"
vpc_id              = "vpc-09fd10f9f3d81e103"

### Destruction

```bash
terraform workspace select default
terraform destroy
```
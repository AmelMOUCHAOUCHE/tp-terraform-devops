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

### Ressources créées

| Ressource | ID/Valeur |
|---|---|
| Subnet privé 1 (10.0.2.0/24, eu-west-3a) | `subnet-05fdda1c60338fbad` |
| Subnet privé 2 (10.0.3.0/24, eu-west-3b) | `subnet-0a8265b1fc6015f82` |
| DB Subnet Group | `tp-terraform-amel-db-subnet-group` |
| Security Group RDS (port 5432 depuis EC2 uniquement) | `sg-0b3a48eded0cff571` |
| RDS PostgreSQL 15, db.t3.micro | `db-OMRHQJAYGLHCJ75QMJJSSYJ6NU` |

### Output db_endpoint
db_endpoint = "tp-terraform-amel-db.c3qsso6ykzti.eu-west-3.rds.amazonaws.com:5432"

### Points clés
- La BDD n'a pas d'IP publique (`publicly_accessible = false`)
- Accessible uniquement depuis le Security Group de l'EC2 (port 5432)
- `skip_final_snapshot = true` pour faciliter le destroy

---

## Bonus B — Application Load Balancer

### Ressources créées

| Ressource | ID/Valeur |
|---|---|
| Subnet public 2 (10.0.4.0/24, eu-west-3b) | `subnet-07c9e597cc876d5fa` |
| Security Group ALB (port 80 public) | `sg-00cbZ393b8d33791a8` |
| Application Load Balancer | `tp-terraform-nom-alb` |
| Target Group (port 80, HTTP) | `tp-terraform-amel-tg` |
| Listener (port 80 → forward) | 
| Attachment EC2 → Target Group | 

### Output alb_dns_name
alb_dns_name = "tp-terraform-amel-alb-1244261838.eu-west-3.elb.amazonaws.com"

### Points clés
- L'ALB est le point d'entrée public sur le port 80
- Nécessite 2 subnets publics dans 2 AZ différentes (obligatoire AWS)
- Health check sur `/` avec seuil de 2 checks

### Outputs complets après bonus A + B
alb_dns_name        = "tp-terraform-amel-alb-1244261838.eu-west-3.elb.amazonaws.com"
db_endpoint         = "tp-terraform-amel-db.c3qsso6ykzti.eu-west-3.rds.amazonaws.com:5432"
instance_public_dns = "ec2-15-224-15-62.eu-west-3.compute.amazonaws.com"
instance_public_ip  = "15.224.15.62"
s3_bucket_name      = "tp-terraform-amel-assets-f5012338"
ssh_command         = "ssh -i ~/.ssh/tp_terraform ubuntu@15.224.15.62"
vpc_id              = "vpc-021a9be5b385d1b78"

### Destruction

```bash
terraform destroy
# Destroy complete! Resources: 24 destroyed.
```

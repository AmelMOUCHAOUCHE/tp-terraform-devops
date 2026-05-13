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
| Key Pair | `tp-terraform-tonprenom-key` |
| EC2 Instance | `i-0b39e628b44977221` |
| S3 Bucket | `tp-terraform-tonprenom-assets-f2c84ea0` |

### Outputs terraform output

instance_public_dns = "ec2-13-36-244-44.eu-west-3.compute.amazonaws.com"
instance_public_ip  = "13.36.244.44"
s3_bucket_name      = "tp-terraform-tonprenom-assets-f2c84ea0"
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
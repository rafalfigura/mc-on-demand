# Minecraft On Demand Terraform Infrastructure

Minecraft On-Demand is a cool project for quickly setting up your own Minecraft server. Just for the code, tweak a few settings, and bam – you've got a working server!
You can customize the server to your liking by following the step-by-step documentation we provide.
Our project stays up-to-date with the latest Minecraft versions, so you're always in the loop without any update hassles. 
Enjoy setting up and managing your Minecraft server effortlessly with Minecraft On-Demand!

## Prerequisites
1. AWS Account (required)
2. Domain Name (required)
3. S3 Bucket for Terraform State (AWS CLI or AWS Console)
4. DynamoDB Table for Terraform State Locking (AWS CLI or AWS Console)


## How to use

1. Clone this repository
2. Update the `terraform/config/config.remote` with proper bucket, and dynamodb table
3. Update the `terraform/terraform.tfvars` with proper values.
4. Setup  GitHub Secrets with AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION) 
   - **DO NOT USE ROOT ACCOUNT CREDENTIALS**
5. Deploy with GitHub Action 

# Thanks to all the people who made this possible

Thanks to [itzg](https://github.com/itzg), [JKolios](https://github.com/JKolios), [shiouen](https://github.com/shiouen), and [doctorray117](https://github.com/doctorray117)

Repositories userd to create this project:
2. https://github.com/JKolios/minecraft-ondemand-terraform
2. https://github.com/shiouen/mod
3. https://github.com/doctorray117/minecraft-ondemand/blob/main/README.md



## TODO
1. S3 backup
2. EFS S3 Sync (server files editing)
3. Different versions of minecraft server enabled (e.g. Spigot, Paper, etc.)
4. Proper documentation
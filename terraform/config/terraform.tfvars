// Region used for ecs cluster (minecraft server)
aws_region  = "eu-central-1"

// Domain name for the Minecraft server (root domain)
domain_name = "example.com"

// Subdomain name for the Minecraft server (also used for all other resources)
name = "minecraft"

// Budget configuration (optional)
// Amount is in USD
budget_enabled = false
budget_amount = 5
budget_notification_emails = []

// Email notifications - about server start (optional)
# server_notifications_email_addresses = []


// Fargate Spot instances are typically cheaper than regular Fargate instances
// because they allow you to use spare capacity in the AWS infrastructure at a lower cost.
// However, it's important to note that Spot Instances, including Fargate Spot, can be terminated by AWS
// if the capacity is needed elsewhere.
// This is because Spot Instances use spare capacity, and AWS reclaims it
// when required by regular On-Demand instances.

# fargate_spot_pricing = false

// Minecraft Edition
// Valid values are: "java", "bedrock"

# minecraft_edition = "java"


// Minecraft image versions

// Java: itzg/minecraft-server:latest
// Versions can be found here: https://hub.docker.com/r/itzg/minecraft-server/tags
# minecraft_image_bedrock = null

// Bedrock: itzg/minecraft-bedrock-server:latest
// Versions can be found here: https://hub.docker.com/r/itzg/minecraft-bedrock-server/tags
# minecraft_image_java = null

// Save server logs in CloudWatch
# save_server_logs = false

// Additional server environment variables (optional) Eula is default & required for Java edition
# server_environment_variables = [
#  {name: "EULA", value: "TRUE"},
# ]

// Server shutdown timeout in minutes (optional)
# server_shutdown_timeout = 20

// Server startup timeout timeout before terminating in minutes (optional)
# server_startup_timeout = 10

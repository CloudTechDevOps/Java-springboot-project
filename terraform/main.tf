module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  azs          = var.azs
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
}

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.security.database_security_group_id]
  instance_class     = var.db_instance_class
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/${var.environment}/database/username"
  description = "Database username consumed by the application instance."
  type        = "String"
  value       = var.db_username

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/${var.environment}/database/password"
  description = "Database password consumed by the application instance."
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "application" {
  source = "./modules/application"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  subnet_id           = module.networking.public_subnet_ids[0]
  security_group_id   = module.security.application_security_group_id
  instance_type       = var.instance_type
  key_name            = var.key_name
  db_address          = module.database.db_address
  db_name             = var.db_name
  db_username_param   = aws_ssm_parameter.db_username.name
  db_password_param   = aws_ssm_parameter.db_password.name
  db_username_param_arn = aws_ssm_parameter.db_username.arn
  db_password_param_arn = aws_ssm_parameter.db_password.arn
}

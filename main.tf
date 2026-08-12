module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
}

module "security" {
  source = "./modules/security"

  vpc_id = module.vpc.vpc_id
  my_ip  = var.my_ip
}

module "rds" {
  source = "./modules/rds"

  db_subnets = module.vpc.db_subnets
  rds_sg     = module.security.rds_sg
}

module "ecr" {
  source = "./modules/ecr"
}

module "iam" {
  source = "./modules/iam"
}

module "alb" {
  source = "./modules/alb"

  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  alb_sg         = module.security.alb_sg
}

module "waf" {
  source = "./modules/waf"

  resource_arn = module.alb.alb_arn
}

module "monitoring" {
  source = "./modules/monitoring"

  cluster_name = module.ecs_cluster.cluster_name
  alert_email  = var.alert_email
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"
}

module "ecs_iam" {
  source = "./modules/ecs-iam"
}

module "ecs_capacity" {
  source = "./modules/ecs-capacity"

  cluster_name         = module.ecs_cluster.cluster_name
  instance_profile_arn = module.ecs_iam.instance_profile_arn
  ecs_node_sg          = module.security.ecs_nodes_sg
  private_subnets      = module.vpc.app_subnets
}

module "ecs_services" {
  source = "./modules/ecs-services"

  cluster_id                      = module.ecs_cluster.cluster_id
  frontend_tg_arn                 = module.alb.frontend_tg_arn
  backend_tg_arn                  = module.alb.backend_tg_arn
  frontend_image                  = "${module.ecr.frontend_repo_url}:latest"
  backend_image                   = "${module.ecr.backend_repo_url}:latest"
  execution_role_arn              = module.iam.ecs_execution_role_arn
  subnets                         = module.vpc.app_subnets
  frontend_sg_id                  = module.security.frontend_sg
  backend_sg_id                   = module.security.backend_sg
  frontend_capacity_provider_name = module.ecs_capacity.frontend_capacity_provider_name
  backend_capacity_provider_name  = module.ecs_capacity.backend_capacity_provider_name
  db_host                         = module.rds.db_host
  db_port                         = module.rds.db_port
  db_name                         = var.db_name
  db_user                         = var.db_username
  db_secret_arn                   = module.rds.secret_arn

  depends_on = [module.ecs_capacity]
}


module "jenkins" {
  source = "./modules/jenkins"
  public_subnet_id = module.vpc.public_subnets[0]
  jenkins_sg       = module.security.jenkins_sg
  key_name         = var.key_name
  instance_profile = module.iam.ec2_instance_profile
}

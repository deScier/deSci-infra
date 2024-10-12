module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.my_vpc.id
}

module "descier_instance" {
  source            = "./modules/ec2"
  ami_id            = "ami-123456"
  instance_type     = "t2.micro"
  subnet_id         = module.vpc.public_subnet.id
  security_group_id = module.security.allow_web.id
  instance_name     = "descier_instance"
}
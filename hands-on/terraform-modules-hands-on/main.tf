terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"
}

module "webserver" {
  source        = "./modules/nginx_server"
  instance_type = "t2.micro"
}

output "web_server_id" {
  value = module.webserver.instance_id
}
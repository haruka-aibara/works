resource "aws_vpc" "peer" {
  count = var.vpc_peering ? 1 : 0

  cidr_block = "172.31.0.0/16"
}

data "aws_arn" "peer" {
  count = var.vpc_peering ? 1 : 0

  arn = aws_vpc.peer[0].arn
}

resource "hcp_aws_network_peering" "peer" {
  count = var.vpc_peering ? 1 : 0

  hvn_id          = hcp_hvn.learn_hcp_vault_hvn.hvn_id
  peering_id      = var.peering_id
  peer_vpc_id     = aws_vpc.peer[0].id
  peer_account_id = aws_vpc.peer[0].owner_id
  peer_vpc_region = data.aws_arn.peer[0].region
}

resource "hcp_hvn_route" "peer_route" {
  count = var.vpc_peering ? 1 : 0

  hvn_link         = hcp_hvn.learn_hcp_vault_hvn.self_link
  hvn_route_id     = var.route_id
  destination_cidr = aws_vpc.peer[0].cidr_block
  target_link      = hcp_aws_network_peering.peer[0].self_link
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  count = var.vpc_peering ? 1 : 0

  vpc_peering_connection_id = hcp_aws_network_peering.peer[0].provider_peering_id
  auto_accept               = true
}

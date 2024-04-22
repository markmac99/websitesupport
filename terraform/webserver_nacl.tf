# copyright mark mciontyre, 2024-

# create the NACL here

variable "blocked_cidrs" {
  type = list(string)
  default = [
    "152.42.128.0/17","85.208.96.0/24", "213.180.192.0/19", "5.255.192.0/18",
    "185.191.171.0/24", "87.250.224.0/19", "95.108.213.0/24", "114.119.128.0/19", 
    "91.92.246.0/24"]
}

resource "aws_network_acl" "webserver_nacl" {
  tags = {
    Name = "Webserver_nacl"
  }
  vpc_id = data.aws_vpc.main.id
}

resource "aws_network_acl_association" "webserver_nacl_assoc" {
  network_acl_id = aws_network_acl.webserver_nacl.id
  subnet_id      = data.aws_subnet.subnet2.id
}

resource "aws_network_acl_rule" "ingress_block_rules" {
  network_acl_id = aws_network_acl.webserver_nacl.id
  count       = "${length(var.blocked_cidrs)}"
  rule_number = "${5 + count.index}"
  egress      = false
  protocol    = "tcp"
  rule_action = "deny"
  cidr_block  = "${element(var.blocked_cidrs, count.index)}"
  from_port   = 0
  to_port     = 65535
}

resource "aws_network_acl_rule" "i100" {
  network_acl_id = aws_network_acl.webserver_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535

}

resource "aws_network_acl_rule" "i101" {
  network_acl_id = aws_network_acl.webserver_nacl.id
  rule_number    = 101
  egress         = false
  protocol       = "all"
  rule_action    = "allow"
  ipv6_cidr_block     = "::/0"
  from_port      = 0
  to_port        = 65535

}
resource "aws_network_acl_rule" "e100" {
  network_acl_id = aws_network_acl.webserver_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}
resource "aws_network_acl_rule" "e101" {
  network_acl_id = aws_network_acl.webserver_nacl.id
  rule_number    = 101
  egress         = true
  protocol       = "all"
  rule_action    = "allow"
  ipv6_cidr_block     = "::/0"
  from_port      = 0
  to_port        = 65535
}

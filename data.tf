data "aws_vpc" "example" {

    id = "vpc-07eede624774fec02"
}

# creating security group 
resource "aws_security_group" "allow_tls" {
  name        = "ashu_allow_boa_rules" # changed here
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.example.id # changed here 

  tags = {
    Name = "ashu_allow_boa_rules" # changed here
  }
}
# adding egress out going connection rules for ipv4 and ipv6 extra comment

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# ingress 22 and 80 port allow 

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
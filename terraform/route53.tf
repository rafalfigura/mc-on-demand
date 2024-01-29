resource "aws_route53_query_log" "query-log" {
  provider                 = aws.us-east-1
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.query-log-group.arn
  zone_id                  = aws_route53_zone.hosted-zone.zone_id
}

// dummy record, to be changed whenever the container launches
// which is why changes to the `records` property are ignored
resource "aws_route53_record" "hosted-zone-a-record" {
  name     = local.subdomain
  provider = aws.us-east-1
  records  = ["192.168.1.1"]
  ttl      = 30
  type     = "A"
  zone_id  = aws_route53_zone.hosted-zone.zone_id

  lifecycle {
    ignore_changes = [
      records
    ]
  }
}

// @TODO - create an ability to auto create hosted zone if it doesn't exist
resource "aws_route53_record" "root-hosted-zone-ns-record" {
  name     = local.subdomain
  provider = aws.us-east-1
  records  = aws_route53_zone.hosted-zone.name_servers
  ttl      = 172800
  type     = "NS"
  zone_id  = data.aws_route53_zone.root-hosted-zone.zone_id
}

resource "aws_route53_zone" "hosted-zone" {
  name     = local.subdomain
  provider = aws.us-east-1
}

resource "aws_cloudwatch_log_group" "query-log-group" {
  name              = "/aws/route53/${aws_route53_zone.hosted-zone.name}"
  retention_in_days = local.log_retention_in_days
  provider          = aws.us-east-1
}
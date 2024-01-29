resource "aws_budgets_budget" "default" {
  count             = var.budget_enabled ? 1 : 0
  name              = "${var.name}-mc-on-demand"
  budget_type       = "COST"
  limit_amount      = var.budget_amount
  limit_unit        = "USD"
  time_period_end   = "2087-01-01_00:00"
  time_period_start = "2010-01-01_00:00"
  time_unit         = "MONTHLY"

  cost_filter {
    name = "TagKeyValue"
    values = [
      "mc-on-demand${"$"}${local.subdomain}"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_notification_emails
  }
}
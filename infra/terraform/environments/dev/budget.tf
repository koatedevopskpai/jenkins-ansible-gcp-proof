# -----------------------------------------------------------------------------
# FinOps notifications - monthly budget alerts scoped to this workload's label; no spending cap.
# GCP budgets use the BILLING ACCOUNT's currency (GBP here).
# -----------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "budget" {
  display_name = "${local.name_prefix}-budget-alerts"
  type         = "email"
  labels = {
    email_address = var.budget_alerts_email
  }
}

resource "google_billing_budget" "budget" {
  billing_account = var.billing_account_id
  display_name    = "${local.name_prefix}-monthly"

  amount {
    specified_amount {
      units = var.budget_limit_gbp
    }
  }

  budget_filter {
    projects        = ["projects/${data.google_project.current.number}"]
    calendar_period = "MONTH"

    labels = {
      workload = var.workload
    }
  }

  threshold_rules {
    threshold_percent = 0.8
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.budget.id]
  }
}

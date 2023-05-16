resource "volterra_network_policy" "allow_all" {
  name      = format("%s-allow-all-%s", var.project_prefix, var.project_suffix)
  namespace = var.f5xc_namespace
  endpoint {
    any = true
  }
  rules {
    egress_rules {
      action = "ALLOW"
      metadata {
        name = "allow-egress-all"
      }
      any         = true
      all_traffic = true
    }
    ingress_rules {
      action = "ALLOW"
      metadata {
        name = "allow-ingress-all"
      }
      any         = true
      all_traffic = true
    }
  }
}

resource "volterra_active_network_policies" "active" {
  depends_on = [volterra_network_policy.allow_all]
  namespace  = var.f5xc_namespace
  policies {
    name      = format("%s-allow-all-%s", var.project_prefix, var.project_suffix)
    namespace = var.f5xc_namespace
    tenant    = var.f5xc_tenant
  }
}
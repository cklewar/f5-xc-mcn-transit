module "app_namespace" {
  source                        = "./modules/f5xc/namespace"
  f5xc_namespace_name           = format("%s-transit-%s", var.project_prefix, var.project_suffix)
  f5xc_namespace_create_timeout = "5s"
  providers                     = {
    volterra = volterra.default
  }
}

resource "volterra_network_policy" "allow_all" {
  name      = format("%s-allow-all-%s", var.project_prefix, var.project_suffix)
  namespace = module.app_namespace.namespace["name"]
  provider  = volterra.default
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

/*resource "volterra_active_network_policies" "active" {
  depends_on = [volterra_network_policy.allow_all]
  namespace  = var.f5xc_namespace # module.app_namespace.namespace["name"]
  provider   = volterra.default
  policies {
    name      = format("%s-allow-all-%s", var.project_prefix, var.project_suffix)
    namespace = module.app_namespace.namespace["name"]
    tenant    = var.f5xc_tenant
  }
}*/

resource "volterra_forward_proxy_policy" "forward_all" {
  name      = format("%s-forward-all-%s", var.project_prefix, var.project_suffix)
  provider  = volterra.default
  any_proxy = true
  allow_all = true
  namespace = var.f5xc_namespace
}
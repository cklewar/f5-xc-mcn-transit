provider "google" {
  region  = var.gcp_region
  alias   = "us-east1"
  project = var.gcp_project_id
}

resource "google_compute_network" "spoke_a" {
  name                            = format("%s-spoke-a-%s", var.project_prefix, var.project_suffix)
  project                         = var.gcp_project_id
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "spoke_b" {
  name                            = format("%s-spoke-b-%s", var.project_prefix, var.project_suffix)
  project                         = var.gcp_project_id
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "spoke_a" {
  name          = format("%s-spoke-a-%s", var.project_prefix, var.project_suffix)
  region        = var.gcp_region
  project       = var.gcp_project_id
  network       = google_compute_network.spoke_a.self_link
  ip_cidr_range = var.gcp_spoke_a_ip_cidr_range
}

resource "google_compute_subnetwork" "spoke_b" {
  name          = format("%s-spoke-b-%s", var.project_prefix, var.project_suffix)
  region        = var.gcp_region
  project       = var.gcp_project_id
  network       = google_compute_network.spoke_b.self_link
  ip_cidr_range = var.gcp_spoke_b_ip_cidr_range
}

resource "google_compute_firewall" "spoke-a-private" {
  name    = format("%s-spoke-a-private-%s", var.project_prefix, var.project_suffix)
  network = google_compute_network.spoke_a.name
  project = var.gcp_project_id
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    "10.0.0.0/8"
  ]
}

resource "google_compute_firewall" "spoke-b-private" {
  name    = format("%s-spoke-b-private-%s", var.project_prefix, var.project_suffix)
  network = google_compute_network.spoke_b.name
  project = var.gcp_project_id
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    "10.0.0.0/8"
  ]
}

resource "google_compute_firewall" "spoke_a_ssh" {
  name    = format("%s-spoke-a-allow-ssh-%s", var.project_prefix, var.project_suffix)
  network = google_compute_network.spoke_a.name
  project = var.gcp_project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "spoke_b_ssh" {
  name    = format("%s-spoke-b-allow-ssh-%s", var.project_prefix, var.project_suffix)
  network = google_compute_network.spoke_b.name
  project = var.gcp_project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

module "gcp" {
  source                            = "./modules/f5xc/site/gcp"
  f5xc_tenant                       = var.f5xc_tenant
  f5xc_api_url                      = var.f5xc_api_url
  f5xc_gcp_cred                     = var.f5xc_gcp_cred
  f5xc_api_token                    = var.f5xc_api_token
  f5xc_namespace                    = var.f5xc_namespace
  f5xc_gcp_region                   = var.gcp_region
  f5xc_gcp_site_name                = format("%s-gcp-%s", var.project_prefix, var.project_suffix)
  f5xc_gcp_zone_names               = ["us-east1-b", "us-east1-c", "us-east1-d"]
  f5xc_gcp_ce_gw_type               = "multi_nic"
  f5xc_gcp_node_number              = 3
  f5xc_gcp_outside_network_name     = format("%s-gcp-outside-%s", var.project_prefix, var.project_suffix)
  f5xc_gcp_outside_subnet_name      = format("%s-gcp-outside-%s", var.project_prefix, var.project_suffix)
  f5xc_gcp_inside_network_name      = format("%s-gcp-inside-%s", var.project_prefix, var.project_suffix)
  f5xc_gcp_inside_subnet_name       = format("%s-gcp-inside-%s", var.project_prefix, var.project_suffix)
  f5xc_gcp_outside_primary_ipv4     = "10.102.32.0/24"
  f5xc_gcp_inside_primary_ipv4      = "10.102.33.0/24"
  f5xc_gcp_default_ce_sw_version    = true
  f5xc_gcp_default_ce_os_version    = true
  f5xc_gcp_default_blocked_services = true
  ssh_public_key                    = file(var.ssh_public_key_file)
  providers                         = {
    google = google.us-east1
  }
}

data "google_compute_network" "hub" {
  depends_on = [module.gcp]
  name       = format("%s-gcp-%s", var.project_prefix, var.project_suffix)
  project    = var.gcp_project_id
}

resource "google_compute_network_peering" "spoke_a" {
  name                 = format("%s-hub-spoke-a-%s", var.project_prefix, var.project_suffix)
  network              = google_compute_network.spoke_a.self_link
  peer_network         = data.google_compute_network.hub.self_link
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "spoke_b" {
  name                 = format("%s-hub-spoke-b-%s", var.project_prefix, var.project_suffix)
  network              = google_compute_network.spoke_b.self_link
  peer_network         = data.google_compute_network.hub.self_link
  import_custom_routes = true
  export_custom_routes = true
}
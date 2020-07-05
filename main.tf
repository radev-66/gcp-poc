variable "project_id" {
    type = string
    default = "crucial-study-270402"
}

variable "image_id" {
    type = string
    default = "deb-java-app-image"
}

variable "region1" {
    type = string
    default = "us-central1"
}

variable service_port {
    type = number
    default = 8080
}

variable service_port_name {
    type = string
    default = "custom-http"
}

provider "google" {
  version = "3.5.0"


  project = var.project_id
  region  = var.region1
  zone    = "us-central1-c"
}

resource "google_compute_router" "nat-router-us-central1" {
  name    = "nat-router-us-central1"
  region  = var.region1
  network  = "default"
}

resource "google_compute_router_nat" "nat-config1" {
  name                               = "nat-config1"
  router                             = google_compute_router.nat-router-us-central1.name
  region                             = var.region1
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


resource "google_compute_firewall" "default" {
  name    = "allow-port-8080-for-java-app"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  source_tags = ["app-server"]
}

resource "google_compute_firewall" "egress" {
  name    = "allow-port-443-to-okta"
  network = "default"
  direction = "EGRESS"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["app-server"]
}




resource "google_compute_instance_template" "appserver" {
  name         = "app-server-template"
  machine_type = "n1-standard-1"
  tags         = ["app-server"]

  disk {
    source_image = "deb-java-app-image"
    auto_delete  = true
    disk_size_gb = 10
    boot         = true
  }

  network_interface {
    network = "default"
  }

  metadata = {
    foo = "bar"
  }

}


resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/actuator/health"
    port         = "8080"
  }
}

resource "google_compute_instance_group_manager" "appserver-igm" {
  name = "appserver-igm"

  base_instance_name = "appserver"
  zone               = "us-central1-a"

  version {
    instance_template  = google_compute_instance_template.appserver.id
  }

  #target_pools = [google_compute_target_pool.appserver.id]
  target_size  = 1

  named_port {
    name = var.service_port_name
    port = var.service_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}


module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google"
  version           = "~> 3.1"

  name              = "external-http-lb"
  project           = var.project_id
  target_tags       = google_compute_instance_template.appserver.tags

  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 8080
      port_name                       = var.service_port_name
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      session_affinity                = null
      affinity_cookie_ttl_sec         = null

     health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/actuator/health"
        port                = 8080
        host                = null
        logging             = null
     }

      log_config = {
        enable = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Each node pool instance group should be added to the backend.
          group                        = google_compute_instance_group_manager.appserver-igm.name
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        },
      ]
    }
  }
}

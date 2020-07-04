variable "project_id" {
    type = string
    default = "crucial-study-270402"
}

variable "image_id" {
    type = string
    default = "deb-java-app-image"
}

provider "google" {
  version = "3.5.0"


  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
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
  target_size  = 2

  named_port {
    name = "custom-http"
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}

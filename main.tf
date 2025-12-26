terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "bindplane" {
  name         = "bindplane-server"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    # startup script will read this metadata key
    db_password = var.db_password
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  tags = ["bindplane"]
}

resource "google_compute_firewall" "bindplane_fw" {
  name    = "bindplane-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "3001", "5432"]
  }

  target_tags  = ["bindplane"]
  source_ranges = ["0.0.0.0/0"]
}
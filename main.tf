terraform {
  backend "gcs" {
    bucket      = "otowotf-state-infra"
    prefix      = "terraform/state"
    credentials = "/tmp/account.json"
  }
}

provider "google" {
  credentials = file("/tmp/account.json")
  project     = "project-2-443816"
  region      = "us-east1"
  zone        = "us-east1-b"
}

resource "google_compute_network" "main" {
  name                    = "main-vpc"
  auto_create_subnetworks  = false
}

resource "google_compute_subnetwork" "main" {
  name                       = "main-subnet"
  region                     = "us-east1"
  network                    = google_compute_network.main.id
  ip_cidr_range              = "10.0.1.0/24"
  private_ip_google_access   = true
}

resource "google_compute_firewall" "web_server_sg" {
  name    = "web-server-sg"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8090", "9090", "3000", "3100", "8081", "5173", "5432", "8080", "8000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_disk" "additional_disk" {
  name  = "my-disk"
  size  = 50
  type  = "pd-ssd"
  zone  = "us-east1-b"
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "n2-standard-4"
  zone         = "us-east1-b"
  
  boot_disk {
    initialize_params {
      image = "projects/project-2-443816/global/images/ubuntu-ansible-docker"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.web_server_key.public_key_openssh}"
  }

  attached_disk {
    source      = google_compute_disk.additional_disk.id
    device_name = "my-disk"
  }


  provisioner "file" {
    source      = "ansible_files/monitoring.yml"
    destination = "/tmp/monitoring.yml"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.web_server_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "file" {
    source      = "ansible_files/service.yml"
    destination = "/tmp/service.yml"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.web_server_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "file" {
    source      = "ansible_files/config.yml"
    destination = "/tmp/network.yml"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.web_server_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "file" {
    source      = "ansible_files/dashboard.yml"
    destination = "/tmp/dashboard.yml"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.web_server_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.web_server_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }

    inline = [
      "echo \"[web_servers]\" > /tmp/inventory.ini",
      "echo \"${self.network_interface[0].access_config[0].nat_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file='/tmp/private_key.pem'\" >> /tmp/inventory.ini",
      "echo '${tls_private_key.web_server_key.private_key_pem}' > /tmp/private_key.pem",
      "chmod 600 /tmp/private_key.pem",
      "ansible-playbook -i /tmp/inventory.ini /tmp/config.yml -vvv",
      "ansible-playbook -i /tmp/inventory.ini /tmp/monitoring.yml -vvv",
      "ansible-playbook -i /tmp/inventory.ini /tmp/service.yml -vvv",
      "ansible-playbook -i /tmp/inventory.ini /tmp/dashboard.yml -vvv"
    ]
  }

  depends_on = [
    google_compute_firewall.web_server_sg,
    google_compute_subnetwork.main
  ]
}

resource "tls_private_key" "web_server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

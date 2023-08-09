# GKE cluster
data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.27."
}


resource "google_container_cluster" "gke_cluster" {
  name = "${var.project_id}-gke-cluster"
  location = "${var.region}-a"
  initial_node_count = 2
  /* node_version = "1.20"
  min_master_version = "1.20" */
  remove_default_node_pool = true

  /* provider = google-beta */
/* 
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
      
    }
  }
  /* node_config {
    machine_type = "n1-standard-1"
    oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
    ]
  } */ 
  
}

resource "google_sql_database_instance" "cloud_sql_instance" {
  name = "firstproject-cloud-sql-instance"
  database_version = "MYSQL_5_7"
  region = "europe-west3"
  settings {
    tier = "db-f1-micro"
    backup_configuration {
      enabled = true
      start_time = "09:00"
      
    }
    ip_configuration {
      ipv4_enabled = true
      private_network = google_compute_network.vpc.self_link 
    }
  }
}

resource "google_container_node_pool" "gke_node_pool" {
    name = google_container_cluster.gke_cluster.name
    location = "${var.region}-a"
    cluster = google_container_cluster.gke_cluster.name
    
    version = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
    node_count = var.gke_num_nodes

    node_config {
      machine_type = "e2-micro"
      oauth_scopes = [
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    
    labels = {
        env = var.project_id
    } 

    tags = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    }


    autoscaling{
        min_node_count = 2
        max_node_count = 7

    }
  
}

/* resource "google_container_node_pool_autoscaling" "gke_node_pool_autoscaler" {
    node_pool_id = google_container_node_pool.gke_node_pool.id
    autoscaling_profile {
        min_node_count = 1
        max_node_count = 5
    }
    autoscaling{
        min_node_count = 1
        max_node_count = 5
    }
} */




# VPC

resource "google_compute_network" "vpc" {
  name = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name = "${var.project_id}-subnet"
  region = var.region
  network = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.name
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

variable "project_id" {
    default = "meta-falcon-395212"
    description = "project id"
}

variable "region" {
    default = "europe-west3"
    description = "region"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}
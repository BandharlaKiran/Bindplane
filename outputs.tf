output "bindplane_ui_url" {
  description = "URL to the BindPlane UI"
  value       = "http://${google_compute_instance.bindplane.network_interface[0].access_config[0].nat_ip}:3001"
}
resource "kubernetes_daemon_set_v1" "smartctl_exporter" {
  metadata {
    name      = "smartctl-exporter"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "smartctl-exporter"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.arpa.home/name" = "smartctl-exporter"
      }
    }
    template {
      metadata {
        labels = {
          "app.arpa.home/name" = "smartctl-exporter"
        }
      }
      spec {
        container {
          name              = "main"
          image             = "quay.io/prometheuscommunity/smartctl-exporter:v0.11.0@sha256:aa34799fcc8d278e427a3995bbdc334e7be6508cb8b2d406f38a3a1a2b1b582f"
          image_pull_policy = "IfNotPresent"
          args = [
            "--smartctl.path=/usr/sbin/smartctl",
            "--smartctl.interval=120s",
            "--web.listen-address=0.0.0.0:9633",
            "--web.telemetry-path=/metrics"
          ]
          port {
            name           = "http"
            container_port = 9633
            host_port      = 9633
          }
          security_context {
            privileged  = true
            run_as_user = 0
          }
          volume_mount {
            name       = "dev"
            mount_path = "/hostdev"
          }
        }
        host_network = true
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
        volume {
          name = "dev"
          host_path {
            path = "/dev"
          }
        }
      }
    }
  }
}

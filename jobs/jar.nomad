job "web" {
  datacenters = ["dc1"]
  type = "service"
  update {
    stagger      = "30s"
    max_parallel = 1
  }
  group "web" {
    count = 1
    task "frontend" {
      driver = "java"

      config {
        jar_path = "local/SBSample-0.0.1-SNAPSHOT.jar"
        args    = [
          "--server.port=${NOMAD_PORT_http}"
        ]
      }

      artifact = {
        source = "http://nexus.example.com:8080/SBSample-0.0.1-SNAPSHOT.jar"
      }

      service {
        tags = ["web"]
        port = "http"

        check {
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        memory = 100
        network {
          port "http" {}
        }
      }

    }
  }
}

job "web" {
  datacenters = ["dc1"]
  type = "service"
  group "web" {
    count = 2
    task "frontend" {
      driver = "raw_exec"

      config {
        command = "/bin/http-server"
        args    = ["/tmp", "-p", "${NOMAD_PORT_http}"]

      }

      service {
        tags = ["web", "urlprefix-:7000 proto=tcp"]
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

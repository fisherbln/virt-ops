variable "nexus_password" {
  default = "1nternalUseOnly"
  type    = string
}
variable "vector_agent_host" {
  default = "10.45.0.2"
  type    = string
}
variable "vector_agent_port" {
  default = 6000
  type    = number
}

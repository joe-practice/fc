variable "region" {
  default = "us-west-2"

}

variable "public_key_path" {
    default = "~/.ssh/id_rsa.pub"
}

variable "key_name" {
    default = "terraform"
}

variable "home_ip" { default = "73.241.107.94/32" }

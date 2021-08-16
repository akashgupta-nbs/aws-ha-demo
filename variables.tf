variable "vpc-id" {
  type        = string
  default = "vpc-f8a10b85"
}
variable "subnet-ids" {
  type        = list(string)
  default = ["subnet-5e2b4f7f","subnet-8260fbdd"]
}

variable "cidr-blocks" {
  type        = list
  default = ["0.0.0.0/0"]
}

variable "image-id" {
  type        = string
  description = "Choose the ubuntu image 18.04"
}

variable "instance-type" {
  type        = string
}

variable "min-size" {
}
variable "desire-cap" {
}
variable "max-size" {
}
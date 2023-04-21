variable "triton_url" {
  type = string
  default = "https://cloudapi.de-gt-2.cns.tgos.xyz"
}

variable "triton_account" {
  type = string
  default = "hbloed"
}

variable "triton_key_id" {
  type = string
  default = "c7:6d:b4:e9:f9:33:44:7d:cb:6e:58:41:b6:b6:7f:c7"
}

variable "image_version" {
  type = string
  default = "2023040501"
}

packer {
  required_plugins {
    triton = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/triton"
    }
  }
}

source "triton" "postgresql13-pgautofailover" {
  image_name    = "postgresql13-pgautofailover"
  image_version = "${var.image_version}"
  source_machine_image_filter {
    most_recent = "true"
    name        = "base-64-lts"
    type        = "zone-dataset"
  }
  source_machine_name    = "image_builder_${uuidv4()}"
  source_machine_package = "sample-1G"
  ssh_username           = "root"

  triton_url = var.triton_url
  triton_account = var.triton_account
  triton_key_id = var.triton_key_id
}

build {
  sources = ["source.triton.postgresql13-pgautofailover"]

  provisioner "shell" {
    inline = [
      "pkgin -y update",
      "pkgin -y install postgresql13-server",
      "pkgin -y install postgresql13-contrib",
      "pkgin -y install tmux",

      # GCC 10 (required for pg_auto_failover)
      "pkgin -y install gcc10",

      # gnu make
      "pkgin -y install gmake",

      # Postgresql sets up its own database - we delete it here so patroni has full control
      "rm -rf /var/pgsql/data/*",

      # Build and install pg_auto_failover
      "pkgin -y install git",
      "pkgin -y install pkg-config",
      "pkgin -y install libyaml",
      "git clone https://github.com/siepkes/pg_auto_failover /tmp/pg_auto_failover -b v1.5.2-smartos",
      "cd /tmp/pg_auto_failover && LDFLAGS='-fstack-protector' CFLAGS='-D__EXTENSIONS__ -D__illumos__=1' make",
      "cd /tmp/pg_auto_failover && make install",
    ]
  }

}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

source "virtualbox-iso" "ubuntu-desktop" {
  # Ubuntu 24.04 Server ISO
  iso_url          = "https://releases.ubuntu.com/noble/ubuntu-24.04.2-live-server-amd64.iso"
  iso_checksum     = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
  
  boot_command     = [
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "<tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait>",
        "c<wait5>",
        "set gfxpayload=keep<enter><wait5>",
        "linux /casper/vmlinuz <wait5>",
        "autoinstall quiet fsck.mode=skip noprompt <wait5>",
        "net.ifnames=0 biosdevname=0 systemd.unified_cgroup_hierarchy=1 <wait5>",
        "ds=\"nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\" <wait5>",
        "---<enter><wait5>",
        "initrd /casper/initrd<enter><wait5>",
        "boot<enter>"
  ]
  boot_wait        = "5s"

  # VM Hardware Settings
  guest_os_type    = "Ubuntu_64"
  disk_size        = 25600   # 25GB
  memory           = 4096    # 4GB RAM
  cpus             = 2
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "30m"
  headless         = true
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"

  # VirtualBox Tweaks
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--vram", "128"],   # Needed for GUI
    ["modifyvm", "{{.Name}}", "--nic1", "nat"]   
  ]

  # Serve autoinstall files via HTTP
  http_directory = "http"

  # Output
  vm_name = "ubuntu-24.04-desktop"
  format  = "ova"
}

build {
  sources = ["source.virtualbox-iso.ubuntu-desktop"]
  
  # Add shell provisioner to install Ubuntu Desktop after the base installation
  provisioner "shell" {
    inline = [
      "echo '${var.ssh_password}' | sudo -S lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv",
      "echo '${var.ssh_password}' | sudo -S resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv",
      "echo 'Installing Ubuntu Desktop environment...'",
      "echo '${var.ssh_password}' | sudo -S apt-get update",
      "echo '${var.ssh_password}' | sudo -S apt-get upgrade -y",
      
      # Install Ubuntu Desktop
      "echo '${var.ssh_password}' | sudo -S apt-get install -y ubuntu-desktop",
      
      # Optional: Install common desktop applications
       "echo '${var.ssh_password}' | sudo -S apt-get install -y nmap wireshark ",
      
      # Optional: Enable automatic login for the user
      "echo '${var.ssh_password}' | sudo -S sed -i 's/#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/' /etc/gdm3/custom.conf",
      "echo '${var.ssh_password}' | sudo -S sed -i 's/#  AutomaticLogin = user1/AutomaticLogin = ${var.ssh_username}/' /etc/gdm3/custom.conf",
      
      
      # Optional: Verify installation
      "echo '${var.ssh_password}' | sudo -S systemctl status gdm3 || true",

      # Install Docker
      "echo '${var.ssh_password}' | sudo -S apt-get install ca-certificates curl",
      "echo '${var.ssh_password}' | sudo -S install -m 0755 -d /etc/apt/keyrings",
      "echo '${var.ssh_password}' | sudo -S curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "echo '${var.ssh_password}' | sudo -S chmod a+r /etc/apt/keyrings/docker.asc",
      "echo '${var.ssh_password}' | sudo -S bash -c 'echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable\" > /etc/apt/sources.list.d/docker.list'",
      "echo '${var.ssh_password}' | sudo -S apt-get update",
      "echo '${var.ssh_password}' | sudo -S apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
    # Ensure enough timeout for the potentially lengthy desktop installation
    ]
    timeout = "60m"
  }
  
  # Optional: You can add additional provisioners to customize the desktop environment
  # For example, to set a desktop background, install themes, etc.
}
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      	version = "2.53.0"
    }
  }
}

provider "azurerm" {
	subscription_id = var.subscriptionID
	features {}
}

resource "azurerm_virtual_machine" "NoteezyVM" {
  count = var.vmCount
  name                  = "NoteezyVM-${count.index+1}"
  location              = var.location
  resource_group_name   = var.resourceGroupName
  network_interface_ids = [element(var.network_interface_id, count.index+1)]
  vm_size               = "Standard_DS1_v2"
	
	delete_os_disk_on_termination = true
	delete_data_disks_on_termination = true
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "noteezy${count.index+1}"
    admin_username = var.loginNameVM
    admin_password = var.passwordVM
  }
  os_profile_linux_config {
    disable_password_authentication = true
	ssh_keys{
      path     = "/home/${var.loginNameVM}/.ssh/authorized_keys"
      key_data = "${var.publicSSH}"
	}
  }
  
    provisioner "remote-exec" {
    inline = [
	"sudo apt update",
	"sudo apt -y install nginx",
	"sudo ufw --force enable",
	"sudo ufw allow 'Nginx HTTP'",
	"sudo ufw allow 22",
	"wget -O nginx.conf https://github.com/noteezy/DevOpsCrashCourse/blob/master/HW3/vm${count.index+1}.conf?raw=true",
	"sudo cp -f nginx.conf /etc/nginx/nginx.conf",
	"sudo systemctl restart nginx",
	]
	connection {
		host = element(var.network_interface_ips, count.index+1)
		agent = false
		type = "ssh"
		user = var.loginNameVM
		private_key = "${file(var.privateKeyPath)}"
	}
  }
}

resource "azurerm_virtual_machine" "NoteezyVMLB" {
  name                  = "NoteezyVMLB"
  location              = var.location
  resource_group_name   = var.resourceGroupName
  network_interface_ids = [var.network_interface_id.0]
  vm_size               = "Standard_DS1_v2"

	delete_os_disk_on_termination = true
	delete_data_disks_on_termination = true
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdiskLB"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "NoteezyVMLB"
    admin_username = var.loginNameVM
    admin_password = var.passwordVM
  }
  os_profile_linux_config {
    disable_password_authentication = true
	ssh_keys{
      path     = "/home/${var.loginNameVM}/.ssh/authorized_keys"
      key_data = "${var.publicSSH}"
	}
  }
  
    provisioner "remote-exec" {
    inline = [
	"sudo apt update",
	"sudo apt -y install nginx",
	"sudo ufw --force enable",
	"sudo ufw allow 'Nginx HTTP'",
	"sudo ufw allow 22",
	"wget -O nginx.conf https://github.com/noteezy/DevOpsCrashCourse/blob/master/HW3/load_balancer.conf?raw=true",
	"sudo cp -f nginx.conf /etc/nginx/nginx.conf",
	"sudo systemctl restart nginx",
	]
	connection {
		host = element(var.network_interface_ips, 0)
		agent = false
		type = "ssh"
		user = var.loginNameVM
		private_key = "${file(var.privateKeyPath)}"
	}
  }
}


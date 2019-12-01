# Kubernetes bare metal provisioning

Based on [https://github.com/hobby-kube/provisioning](https://github.com/hobby-kube/provisioning).
Cleaned up to keep only the needed modules.  
If need be, we can use modules directly from the original GitHub repo (see [below](#using-modules-independently)).

Modifications include:

- Possibility to define different server types for master, worker and storage nodes
- Added OVH dns provider.  

I don't use Terraform to create the Kubernetes cluster itself, only to prepare the nodes.  
I then use Ansible to prepare the nodes and deploy the kubernetes cluster (`k3s`).

<!-- TOC -->

- [Kubernetes bare metal provisioning](#kubernetes-bare-metal-provisioning)
    - [Resources created](#resources-created)
    - [Setup](#setup)
        - [Terraform State](#terraform-state)
        - [Variables](#variables)
        - [Configuration](#configuration)
            - [OVH](#ovh)
            - [Hetzner](#hetzner)
        - [Execute](#execute)
    - [Using modules independently](#using-modules-independently)

<!-- /TOC -->

## Resources created

By executing this plan, it will create Hetzner cloud resources, by default
one master node, two worker nodes and two storage nodes.  
A DNS entry will be created for each node based on the hostname format defined.  
Additionally, if `use_floating_ip_as_lb` is set to `true`, a floating IP address will be
created at Hetzner, pointing to the master server.  
The root domain defined by `domain` will point to this IP.  
A `CNAME` record is created with a wildcard to point everything under `subdomain` to `domain`
(for instance if the domain is `test.com` and subdomain is `k8s`, it will create `*.k8s.test.com` CNAME to `test.com.`)
For convenience, an `api` CNAME record is created, pointing to the first master.

## Setup

See original repository.  
The following packages are required to be installed locally:

```sh
brew install terraform kubectl jq wireguard-tools
```

Modules are using ssh-agent for remote operations. Add your SSH key with `ssh-add -K` if Terraform repeatedly fails to connect to remote hosts.

### Terraform State

The Terraform state (terraform.tfstate file) is using the local backend (see main.tf).  
You can specify another local directory in the init command:

```bash
terraform init -backend-config=/your/directory/backend.tf
```

With the backend.tf containing for instance:

```bash
path = "/your/directory/terraform.tfstate"
```

This allows to store the tfstate separately.

### Variables

**Important:** Modify only [main.tf](main.tf) in project root, comment or uncomment sections as needed. 
To assign variables, see [https://learn.hashicorp.com/terraform/getting-started/variables.html#assigning-variables](https://learn.hashicorp.com/terraform/getting-started/variables.html#assigning-variables).
You can either specify them through environment variables (TF_VAR_variable_name) or the `var-file` flag, 
pointing to a file containing the values.

### Configuration

#### OVH

To use OVH as your DNS provider, install their cli, and launch the setup
to create the needed credentials:

```bash
pip install ovhcli
ovh setup init
```

You can copy `ovh_application_key` and `ovh_application_secret` in
the variables file.  
You need to have an existing domain available, and specify it in the `domain` variable.

#### Hetzner

To use Hetzner, you need generate an API token.  
In the Hetzner console website, in the Access Menu, you will find an API Token tab, where
you can do it.

You can then add it in the variables file.

### Execute

From the root of this project...

```sh
# fetch the required modules
terraform init
# or terraform init -backend-config=/your/directory/backend.tf

# see what `terraform apply` will do
terraform plan
# or terraform plan -var-file=/your/directory/variables.tf

# execute it
terraform apply
# or terraform apply -var-file=/your/directory/variables.tf
```

## Using modules independently

Modules in this repository can be used independently:

```hcl
module "kubernetes" {
  source = "github.com/hobby-kube/provisioning/service/kubernetes"
}
```

After adding this to your plan, run `terraform get` to fetch the module.

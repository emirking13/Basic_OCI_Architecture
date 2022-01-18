
# ------ Retrieve Regional / Cloud Data
# -------- Get a list of Availability Domains
data "oci_identity_availability_domains" "AvailabilityDomains" {
    compartment_id = var.compartment_ocid
}
data "template_file" "AvailabilityDomainNames" {
    count    = length(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains)
    template = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains[count.index]["name"]
}
# -------- Get a list of Fault Domains
data "oci_identity_fault_domains" "FaultDomainsAD1" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
    compartment_id = var.compartment_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD2" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 1)["name"]
    compartment_id = var.compartment_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD3" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 2)["name"]
    compartment_id = var.compartment_ocid
}
# -------- Get Home Region Name
data "oci_identity_region_subscriptions" "RegionSubscriptions" {
    tenancy_id = var.tenancy_ocid
}
data "oci_identity_region_subscriptions" "HomeRegion" {
    tenancy_id = var.tenancy_ocid
    filter {
        name = "is_home_region"
        values = [true]
    }
}
#output "Home_Region" {
# value = data.oci_identity_region_subscriptions.HomeRegion.region_subscriptions
#}
data "oci_identity_regions" "Regions" {
}
#data "oci_identity_tenancy" "Tenancy" {
#    tenancy_id = var.tenancy_ocid
#}

locals {
#    HomeRegion = [for x in data.oci_identity_region_subscriptions.RegionSubscriptions.region_subscriptions: x if x.is_home_region][0]
#    home_region = lookup(
#        {
#            for r in data.oci_identity_regions.Regions.regions : r.key => r.name
#        },
#        data.oci_identity_tenancy.Tenancy.home_region_key
#    )
    home_region = lookup(element(data.oci_identity_region_subscriptions.HomeRegion.region_subscriptions, 0), "region_name")
}
output "Home_Region_Name" {
 value = local.home_region
}
# ------ Get List Service OCIDs
data "oci_core_services" "RegionServices" {
}
# ------ Get List Images
data "oci_core_images" "InstanceImages" {
    compartment_id           = var.compartment_ocid
}

# ------ Home Region Provider
provider "oci" {
    alias            = "home_region"
    region           = local.home_region
}

# ------ Root Compartment
locals {
    DeploymentCompartment_id              = var.compartment_ocid
}

output "DeploymentCompartmentId" {
    value = local.DeploymentCompartment_id
}

# ------ Create Virtual Cloud Network
resource "oci_core_vcn" "Okitvcn001" {
    # Required
    compartment_id = local.DeploymentCompartment_id
    cidr_blocks    = ["10.0.0.0/16"]
    # Optional
    dns_label      = "vcn001"
    display_name   = "okitvcn001"
    freeform_tags  = {"okit_version": "0.28.0", "okit_reference": "okit-6e61fdd2-012b-4a59-abf2-0be5f66b0991"}
}

locals {
    Okitvcn001_id                       = oci_core_vcn.Okitvcn001.id
    Okitvcn001_dhcp_options_id          = oci_core_vcn.Okitvcn001.default_dhcp_options_id
    Okitvcn001_domain_name              = oci_core_vcn.Okitvcn001.vcn_domain_name
    Okitvcn001_default_dhcp_options_id  = oci_core_vcn.Okitvcn001.default_dhcp_options_id
    Okitvcn001_default_security_list_id = oci_core_vcn.Okitvcn001.default_security_list_id
    Okitvcn001_default_route_table_id   = oci_core_vcn.Okitvcn001.default_route_table_id
}


# ------ Create Security List
# ------- Update VCN Default Security List
resource "oci_core_default_security_list" "Okitsl001" {
    # Required
    manage_default_resource_id = local.Okitvcn001_default_security_list_id
    egress_security_rules {
        # Required
        protocol    = "all"
        destination = "0.0.0.0/0"
        # Optional
        destination_type  = "CIDR_BLOCK"
        description  = ""
    }
    ingress_security_rules {
        # Required
        protocol    = "6"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        description  = ""
        tcp_options {
            min = "22"
            max = "22"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "1"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        description  = ""
        icmp_options {
            type = "3"
            code = "4"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "1"
        source      = "10.0.0.0/16"
        # Optional
        source_type  = "CIDR_BLOCK"
        description  = ""
        icmp_options {
            type = "3"
        }
    }
    # Optional
    display_name   = "okitsl001"
    freeform_tags  = {"okit_version": "0.28.0", "okit_reference": "okit-81649e7e-5a62-4587-859e-b17d564735de"}
}

locals {
    Okitsl001_id = oci_core_default_security_list.Okitsl001.id
}


# ------ Create Route Table
# ------- Update VCN Default Route Table
resource "oci_core_default_route_table" "Okitrt001" {
    # Required
    manage_default_resource_id = local.Okitvcn001_default_route_table_id
    # Optional
    display_name   = "okitrt001"
    freeform_tags  = {"okit_version": "0.28.0", "okit_reference": "okit-0260ba33-bece-451d-9e56-625ef2c1b4ed"}
}

locals {
    Okitrt001_id = oci_core_default_route_table.Okitrt001.id
    }


# ------ Create Dhcp Options
# ------- Update VCN Default Route Table
resource "oci_core_default_dhcp_options" "Okitdo001" {
    # Required
    manage_default_resource_id = local.Okitvcn001_default_dhcp_options_id
    options    {
        type  = "DomainNameServer"
        server_type = "VcnLocalPlusInternet"
    }
    options    {
        type  = "SearchDomain"
        search_domain_names      = ["okitvcn001.oraclevcn.com"]
    }
    # Optional
    display_name   = "okitdo001"
    freeform_tags  = {"okit_version": "0.28.0", "okit_reference": "okit-a9bb188f-d875-4dac-8848-8ae1e3990e34"}
}

locals {
    Okitdo001_id = oci_core_default_dhcp_options.Okitdo001.id
    }


# ------ Create Subnet
# ---- Create Public Subnet
resource "oci_core_subnet" "Okitsn001" {
    # Required
    compartment_id             = local.DeploymentCompartment_id
    vcn_id                     = local.Okitvcn001_id
    cidr_block                 = "10.0.0.0/24"
    # Optional
    display_name               = "okitsn001"
    dns_label                  = "sn001"
    dhcp_options_id            = local.Okitvcn001_dhcp_options_id
    prohibit_public_ip_on_vnic = false
    freeform_tags              = {"okit_version": "0.28.0", "okit_reference": "okit-09a7d8d4-d47d-418e-b9dc-3a3dc0e5feea"}
}

locals {
    Okitsn001_id              = oci_core_subnet.Okitsn001.id
    Okitsn001_domain_name     = oci_core_subnet.Okitsn001.subnet_domain_name
}


# ------ Get List Images
data "oci_core_images" "Okitin001Images" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = "8"
    shape                    = "VM.Standard.E3.Flex"
}

# ------ Create Instance
resource "oci_core_instance" "Okitin001" {
    # Required
    compartment_id      = local.DeploymentCompartment_id
    shape               = "VM.Standard.E3.Flex"
    # Optional
    display_name        = "okitin001"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Okitsn001_id
        # Optional
        assign_public_ip = true
        display_name     = "okitin001"
        hostname_label   = "okitin0010"
        skip_source_dest_check = "false"
        freeform_tags    = {"okit_version": "0.28.0", "okit_reference": "okit-caeeb2fd-8191-4c52-96c7-380081f84a7c"}
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("")
    }
    shape_config {
        #Optional
        memory_in_gbs = 16
        ocpus = 1
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.Okitin001Images.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
    freeform_tags              = {"okit_version": "0.28.0", "okit_reference": "okit-caeeb2fd-8191-4c52-96c7-380081f84a7c"}
}

locals {
    Okitin001_id            = oci_core_instance.Okitin001.id
    Okitin001_public_ip     = oci_core_instance.Okitin001.public_ip
    Okitin001_private_ip    = oci_core_instance.Okitin001.private_ip
}

output "Okitin001PublicIP" {
    value = local.Okitin001_public_ip
}

output "Okitin001PrivateIP" {
    value = local.Okitin001_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments


# ------ Get List Images
data "oci_core_images" "Okitin002Images" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = "8"
    shape                    = "VM.Standard.E3.Flex"
}

# ------ Create Instance
resource "oci_core_instance" "Okitin002" {
    # Required
    compartment_id      = local.DeploymentCompartment_id
    shape               = "VM.Standard.E3.Flex"
    # Optional
    display_name        = "okitin002"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Okitsn001_id
        # Optional
        assign_public_ip = true
        display_name     = "okitin002"
        hostname_label   = "okitin0020"
        skip_source_dest_check = "false"
        freeform_tags    = {"okit_version": "0.28.0", "okit_reference": "okit-8e4d4bdf-2368-4ff7-933a-d8f72870cd50"}
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("")
    }
    shape_config {
        #Optional
        memory_in_gbs = 16
        ocpus = 1
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.Okitin002Images.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
    freeform_tags              = {"okit_version": "0.28.0", "okit_reference": "okit-8e4d4bdf-2368-4ff7-933a-d8f72870cd50"}
}

locals {
    Okitin002_id            = oci_core_instance.Okitin002.id
    Okitin002_public_ip     = oci_core_instance.Okitin002.public_ip
    Okitin002_private_ip    = oci_core_instance.Okitin002.private_ip
}

output "Okitin002PublicIP" {
    value = local.Okitin002_public_ip
}

output "Okitin002PrivateIP" {
    value = local.Okitin002_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments


# ------ Get List Images
data "oci_core_images" "Okitin003Images" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = "8"
    shape                    = "VM.Standard.E3.Flex"
}

# ------ Create Instance
resource "oci_core_instance" "Okitin003" {
    # Required
    compartment_id      = local.DeploymentCompartment_id
    shape               = "VM.Standard.E3.Flex"
    # Optional
    display_name        = "okitin003"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Okitsn001_id
        # Optional
        assign_public_ip = true
        display_name     = "okitin003"
        hostname_label   = "okitin0030"
        skip_source_dest_check = "false"
        freeform_tags    = {"okit_version": "0.28.0", "okit_reference": "okit-138b4635-afc6-4e53-a9aa-daf511cc97d5"}
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("")
    }
    shape_config {
        #Optional
        memory_in_gbs = 16
        ocpus = 1
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.Okitin003Images.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
    freeform_tags              = {"okit_version": "0.28.0", "okit_reference": "okit-138b4635-afc6-4e53-a9aa-daf511cc97d5"}
}

locals {
    Okitin003_id            = oci_core_instance.Okitin003.id
    Okitin003_public_ip     = oci_core_instance.Okitin003.public_ip
    Okitin003_private_ip    = oci_core_instance.Okitin003.private_ip
}

output "Okitin003PublicIP" {
    value = local.Okitin003_public_ip
}

output "Okitin003PrivateIP" {
    value = local.Okitin003_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments


# ------ Create Loadbalancer
resource "oci_load_balancer_load_balancer" "Okitlb001" {
    # Required
    compartment_id = local.DeploymentCompartment_id
    shape          = "flexible"
    display_name   = "okitlb001"
    subnet_ids     = [
                    local.Okitsn001_id                    ]
    # Optional
    is_private     = false
    shape_details {
        #Required
        maximum_bandwidth_in_mbps = 10
        minimum_bandwidth_in_mbps = 10
    }
    freeform_tags  = {"okit_version": "0.28.0", "okit_reference": "okit-e85e20af-468d-4025-b348-17ad6f5140f5"}
}

locals {
    Okitlb001_id            = oci_load_balancer_load_balancer.Okitlb001.id
    Okitlb001_ip_address    = oci_load_balancer_load_balancer.Okitlb001.ip_address_details[0]["ip_address"]
    Okitlb001_url           = format("http://%s", oci_load_balancer_load_balancer.Okitlb001.ip_address_details[0]["ip_address"])
}

output "Okitlb001IPAddress" {
    value = local.Okitlb001_ip_address
}

output "Okitlb001URL" {
    value = format("http://%s", local.Okitlb001_ip_address)
}

locals {
    Okitlb001_backend_set_name = "Okitlb001BackendSet"
    Okitlb001_listener_name    = "Okitlb001Listener"
}

# ------ Create Loadbalancer Backend Set
resource "oci_load_balancer_backend_set" "Okitlb001BackendSet" {
    # Required
    health_checker {
        # Required
        protocol            = "HTTP"
        # Optional
        interval_ms         = 5000
        port                = "80"
#        response_body_regex = 
#        retries             = 100
#        return_code         = 200
        timeout_in_millis   = 3000
        url_path            = "/"
    }
    load_balancer_id = local.Okitlb001_id
    name             = substr(local.Okitlb001_backend_set_name, 0, 32)
    policy           = "ROUND_ROBIN"
}

locals {
    Okitlb001BackendSet_id   = oci_load_balancer_backend_set.Okitlb001BackendSet.id
    Okitlb001BackendSet_name = oci_load_balancer_backend_set.Okitlb001BackendSet.name
}

# ------ Create Loadbalancer Backend
resource "oci_load_balancer_backend" "Okitlb001Backend1" {
    # Required
    backendset_name  = local.Okitlb001BackendSet_name
    ip_address       = local.Okitin001_private_ip
    load_balancer_id = local.Okitlb001_id
    port             = "80"
    # Optional
#    backup           = 
#    drain            = 
#    offline          = 
#    weight           = 
}
resource "oci_load_balancer_backend" "Okitlb001Backend2" {
    # Required
    backendset_name  = local.Okitlb001BackendSet_name
    ip_address       = local.Okitin002_private_ip
    load_balancer_id = local.Okitlb001_id
    port             = "80"
    # Optional
#    backup           = 
#    drain            = 
#    offline          = 
#    weight           = 
}
resource "oci_load_balancer_backend" "Okitlb001Backend3" {
    # Required
    backendset_name  = local.Okitlb001BackendSet_name
    ip_address       = local.Okitin003_private_ip
    load_balancer_id = local.Okitlb001_id
    port             = "80"
    # Optional
#    backup           = 
#    drain            = 
#    offline          = 
#    weight           = 
}

# ------ Create Loadbalancer Listener
resource "oci_load_balancer_listener" "Okitlb001Listener" {
    # Required
    default_backend_set_name = local.Okitlb001BackendSet_name
    load_balancer_id         = local.Okitlb001_id
    name                     = substr(local.Okitlb001_listener_name, 0, 32)
    port                     = "80"
    protocol                 = "HTTP"
    # Optional
    connection_configuration {
        # Required
        idle_timeout_in_seconds = 1200
    }
#    hostname_names           = []
#    path_route_set_name      = 
#    rule_set_names           = []
#    ssl_configuration {
#        # Required
#        certificate_name        = 
#        # Optional
#        verify_depth            = 
#        verify_peer_certificate = 
#    }
}

locals {
    Okitlb001Listener_id            = oci_load_balancer_listener.Okitlb001Listener.id
}


# 
# Equinix Metal 2nd Generation ARM Hardware
#
# This configuration file will override the defaults in vars.tf
#
# c3.large.arm64 - 80 Core Ampere Altra Q80-30, 256GB, 2x960GB NVMe, 2x25Gbps
#             https://metal.equinix.com/product/servers/c3-large-arm64/
#
metal_controller_type       = "c3.large.arm64"
metal_dashboard_type        = "c3.large.arm64"
metal_compute-arm_type      = "c3.large.arm64"
openstack_compute-arm_count = 1
openstack_compute-x86_count = 0

metal_metro = "da"

# Use an existing project:
# metal_create_project        = false
# metal_project_id           = "..."
#
# Or create a new one (default), requiring organization_id :
# metal_create_project        = true
# metal_organization_id       = "..."

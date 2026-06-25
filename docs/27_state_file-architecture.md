# Azure Architecture: 27_state_file

## Header

- **Resource group:** `27_state_file`
- **Subscription:** `a3ea6416-7936-4e88-8568-4d67676f0cbd`
- **Primary resource group region:** `eastus`
- **Application runtime region:** `eastus2`
- **Purpose:** Task Manager web application hosted on Azure Container Apps with Azure Application Gateway, Azure Container Registry, Azure Cosmos DB, and Azure networking.

## Summary

This Azure environment hosts a task manager web application. People reach the service through Azure Application Gateway, which acts as the public front door. The gateway routes traffic to the Flask application running in Azure Container Apps.

The application image is stored in Azure Container Registry, and the running app stores task data in Azure Cosmos DB using the MongoDB API. The virtual network provides the cloud network layout for the gateway, private endpoints, and Container Apps integration where region placement allows.

The resource group also contains the Terraform state storage account and a few older Cosmos DB accounts. The active app configuration in the Terraform files points at `taskmanagercosmosmhr02`, `task-manager-app`, and `taskmanagermhracr`.

## Resource Inventory

| Resource | Azure type | Region | Role in the design |
|---|---|---:|---|
| `mhstate01` | `Microsoft.Storage/storageAccounts` | `eastus` | Stores Terraform state for infrastructure management. |
| `task-manager-nsg` | `Microsoft.Network/networkSecurityGroups` | `eastus` | Network security group associated with the Container Apps subnet. |
| `task-manager-vnet` | `Microsoft.Network/virtualNetworks` | `eastus` | Virtual network with address space `10.10.0.0/16`. |
| `privatelink.azurecr.io` | `Microsoft.Network/privateDnsZones` | `global` | Private DNS zone for Azure Container Registry private endpoint resolution. |
| `task-manager-cosmos-mhr` | `Microsoft.DocumentDB/databaseAccounts` | `eastus` | Existing Cosmos DB account in the group; not the active Terraform default. |
| `privatelink.azurecr.io/task-manager-acr-vnet-link` | `Microsoft.Network/privateDnsZones/virtualNetworkLinks` | `global` | Links private ACR DNS to the task manager virtual network. |
| `taskmanagermhracr` | `Microsoft.ContainerRegistry/registries` | `eastus` | Premium Azure Container Registry; contains the `task-manager` repository. |
| `task-manager-acr-pe` | `Microsoft.Network/privateEndpoints` | `eastus` | Private endpoint for ACR in the private endpoints subnet. |
| `taskmanagercosmosmhr01` | `Microsoft.DocumentDB/databaseAccounts` | `eastus` | Existing Cosmos DB account in the group; not the active Terraform default. |
| `task-manager-acr-pe.nic.6d8872cc-7459-4ad6-b011-74ca02d29a6d` | `Microsoft.Network/networkInterfaces` | `eastus` | Network interface created for the ACR private endpoint. |
| `task-manager-agw-pip` | `Microsoft.Network/publicIPAddresses` | `eastus` | Static public IP for Azure Application Gateway. |
| `taskmanagercosmosmhr02` | `Microsoft.DocumentDB/databaseAccounts` | `eastus2` | Active Cosmos DB account for the task app; MongoDB API with `taskdb` and `tasks`. |
| `task-manager-cae-eastus2` | `Microsoft.App/managedEnvironments` | `eastus2` | Managed environment for Azure Container Apps. |
| `task-manager-app` | `Microsoft.App/containerApps` | `eastus2` | Active Flask task manager application container. |

## Architecture Diagram

```mermaid
graph LR
    USER["People using the app<br/>Browser"]

    subgraph RG["Resource Group: 27_state_file"]
        subgraph NETWORK["Network Layer"]
            PIP["task-manager-agw-pip<br/>Public IP<br/>Standard / Static"]
            AGW["task-manager-agw<br/>Application Gateway<br/>Standard_v2 / Capacity 1"]
            VNET["task-manager-vnet<br/>Virtual Network<br/>10.10.0.0/16"]
            AGWSUB["application-gateway-subnet<br/>10.10.4.0/24"]
            APPSUB["container-apps-subnet<br/>10.10.2.0/23"]
            PESUB["private-endpoints-subnet<br/>10.10.1.0/24"]
            NSG["task-manager-nsg<br/>Network Security Group"]
        end

        subgraph COMPUTE["Application Layer"]
            CAE["task-manager-cae-eastus2<br/>Container Apps Environment<br/>eastus2"]
            APP["task-manager-app<br/>Azure Container App<br/>Flask API on port 3000"]
            MI["System Assigned Managed Identity<br/>Assigned to Container App"]
        end

        subgraph DELIVERY["Image Delivery Layer"]
            ACR["taskmanagermhracr<br/>Azure Container Registry<br/>Premium"]
            REPO["task-manager repository<br/>Container image source"]
            PE["task-manager-acr-pe<br/>Private Endpoint"]
            NIC["Private endpoint NIC<br/>task-manager-acr-pe.nic..."]
            DNS["privatelink.azurecr.io<br/>Private DNS Zone"]
            DNSLINK["task-manager-acr-vnet-link<br/>DNS zone to VNet link"]
        end

        subgraph DATA["Data Layer"]
            COSMOS["taskmanagercosmosmhr02<br/>Cosmos DB for MongoDB<br/>Database: taskdb<br/>Collection: tasks"]
            OLD1["task-manager-cosmos-mhr<br/>Existing Cosmos DB account"]
            OLD2["taskmanagercosmosmhr01<br/>Existing Cosmos DB account"]
        end

        subgraph OPS["Operations Layer"]
            STATE["mhstate01<br/>Storage Account<br/>Terraform state"]
        end
    end

    USER ==>|"Opens task manager website"| PIP
    PIP ==>|"Public frontend address"| AGW
    AGW ==>|"HTTP listener on port 80"| APP
    AGW -.->|"Health probe / over HTTPS backend settings"| APP

    VNET -->|"Contains gateway subnet"| AGWSUB
    VNET -->|"Contains Container Apps subnet when VNet integration is used"| APPSUB
    VNET -->|"Contains private endpoint subnet"| PESUB
    APPSUB -->|"Associated with"| NSG
    AGW -->|"Deployed into"| AGWSUB
    CAE -.->|"Managed environment for"| APP

    ACR -->|"Stores image"| REPO
    REPO -->|"Container image: task-manager:latest"| APP
    PE -->|"Private access to registry"| ACR
    PE -->|"Uses private endpoint NIC"| NIC
    PE -->|"Placed in"| PESUB
    DNS -->|"Resolves private registry endpoint"| PE
    DNSLINK -->|"Links private DNS to"| VNET

    APP ==>|"Creates, reads, updates, deletes task records"| COSMOS
    APP -.->|"Uses Container App secret: cosmos-connection-string"| COSMOS
    APP -.->|"Has Azure identity for future least-privilege access"| MI

    STATE -.->|"Stores Terraform state for this deployment"| RG
    OLD1 -.->|"Existing account in same resource group"| DATA
    OLD2 -.->|"Existing account in same resource group"| DATA
```

## Relationship Details

- **Visitor path:** A browser reaches the static public IP for Application Gateway. Application Gateway is the managed public entry point and sends healthy requests to `task-manager-app`.
- **Application runtime:** `task-manager-app` runs the Flask service in Azure Container Apps inside the `task-manager-cae-eastus2` managed environment.
- **Image delivery:** `taskmanagermhracr` stores the `task-manager` container repository. The Container App is configured to pull the `task-manager:latest` image from this registry.
- **Data path:** The Flask app stores task records in Cosmos DB for MongoDB. The Terraform configuration names the active database as `taskdb` and collection as `tasks`.
- **Secrets:** The app receives database connectivity through a Container App secret named `cosmos-connection-string`. Secret values are intentionally not shown in this document.
- **Network layout:** The virtual network uses `10.10.0.0/16` and includes separate subnets for Application Gateway, Container Apps, and private endpoints.
- **Private registry access:** A private endpoint, private DNS zone, and DNS virtual network link exist for Azure Container Registry private connectivity.
- **Operations:** `mhstate01` supports infrastructure operations by storing Terraform state.

## Notes And Recommendations

- The visual icon presentation is available in the Cursor canvas `azure-task-manager-system-design.canvas.tsx`.
- The resource group contains older Cosmos DB accounts in addition to the active `taskmanagercosmosmhr02` account. Keep them only if they are still needed.
- Application Gateway currently exposes HTTP on port `80`. For production, add HTTPS listener configuration with a certificate.
- ACR is Premium and has private endpoint support configured. The current Container App registry configuration uses an admin password secret; using managed identity with least privilege is a stronger long-term pattern.
- Cosmos DB public network access is enabled in Terraform. Consider private access and stricter firewall rules for production.

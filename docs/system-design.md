# System Design — MHR Azure Task Manager

> Mermaid diagrams covering the architecture, network topology, and request flow for the Azure-based Task Manager application.

---

## 1. High-Level Architecture

```mermaid
graph TB
    subgraph Internet["🌐 Internet"]
        User["End User / Browser"]
    end

    subgraph Azure["☁️ Azure Subscription"]
        subgraph Networking["📡 Networking"]
            AG_PIP["Public IP<br/>task-manager-agw-pip"]
            AG["Azure Application Gateway<br/>SKU: Standard_v2<br/>Port: 80"]
            VNET["Virtual Network<br/>10.10.0.0/16"]
        end

        subgraph Compute["🖥 Compute"]
            CAE["Container Apps Environment<br/>task-manager-cae"]
            ACA["Container App<br/>task-manager-app<br/>Port: 3000<br/>CPU: 0.25 | Memory: 0.5Gi"]
        end

        subgraph Data["💾 Data & Registry"]
            ACR["Azure Container Registry<br/>taskmanagermhracr<br/>SKU: Premium"]
            Cosmos["Azure Cosmos DB<br/>MongoDB API v4.2<br/>taskmanagercosmosmhr02"]
            DB[(taskdb.tasks)]
        end

        subgraph Security["🔒 Security & Private Endpoints"]
            PE_ACR["Private Endpoint<br/>ACR"]
            DNS["Private DNS Zone<br/>privatelink.azurecr.io"]
            NSG["Network Security Group<br/>task-manager-nsg"]
        end

        subgraph StateMgmt["📁 Terraform State"]
            SA["Storage Account<br/>mhstate01"]
            CONTAINER["Blob Container<br/>tfstate"]
            TFSTATE["project-name.tfstate"]
        end
    end

    User -->|HTTPS / HTTP| AG_PIP
    AG_PIP --> AG
    AG -->|Backend Pool<br/>FQDN: ACA| ACA
    ACA -->|Pull Image| ACR
    ACA -->|MongoDB Connection String| Cosmos
    Cosmos --> DB
    ACR -.->|Private Link| PE_ACR
    PE_ACR -.-> DNS
    VNET -->|Subnets| AG
    VNET -->|Subnets| CAE
    VNET -->|Subnets| PE_ACR
    NSG -->|Assoc.| CAE
    SA --> CONTAINER --> TFSTATE
```

---

## 2. Network Topology

```mermaid
graph LR
    subgraph VNET["Virtual Network: task-manager-vnet<br/>10.10.0.0/16"]
        subgraph AG_SUBNET["application-gateway-subnet<br/>10.10.4.0/24"]
            AG["Application Gateway"]
        end

        subgraph CA_SUBNET["container-apps-subnet<br/>10.10.2.0/23"]
            CAE["Container Apps Environment"]
            NSG["NSG: task-manager-nsg"]
        end

        subgraph PE_SUBNET["private-endpoints-subnet<br/>10.10.1.0/24"]
            PE_ACR["Private Endpoint<br/>ACR"]
        end
    end

    PIP["Public IP<br/>Static / Standard"]
    ACR["Azure Container Registry<br/>(privatelink.azurecr.io)"]
    DNS["Private DNS Zone<br/>privatelink.azurecr.io"]

    PIP --> AG
    AG --> CAE
    CAE --> PE_ACR
    PE_ACR --> ACR
    DNS -.->|Resolves| ACR
    NSG -.->|Protects| CA_SUBNET
```

---

## 3. Container App — Internal Design

```mermaid
graph TB
    subgraph ACA["Azure Container App: task-manager-app"]
        subgraph Secrets["🔐 Secrets"]
            SEC_COSMOS["cosmos-connection-string"]
            SEC_ACR["acr-admin-password"]
        end

        subgraph Container["📦 Container: task-manager"]
            Image["Image:<br/>taskmanagermhracr.azurecr.io/task-manager:latest"]
            Gunicorn["Gunicorn<br/>0.0.0.0:3000<br/>1 worker"]
            Flask["Flask App<br/>Python 3.10"]
            API["REST API Endpoints"]
            Healthz["/health<br/>Health Check"]
            Static["Static Files<br/>JS / CSS / Images"]
            Templates["Jinja2 Templates<br/>index.html"]
        end

        subgraph EnvVars["🌱 Environment Variables"]
            COSMOS_CONN["COSMOS_CONNECTION_STRING<br/>from secret"]
            COSMOS_DB["COSMOS_DATABASE_NAME = taskdb"]
            COSMOS_COL["COSMOS_COLLECTION_NAME = tasks"]
        end
    end

    subgraph Data["💾 Data Layer"]
        Cosmos[(Azure Cosmos DB<br/>MongoDB API)]
    end

    Image --> Gunicorn --> Flask
    Flask --> API
    Flask --> Healthz
    Flask --> Static
    Flask --> Templates
    Flask -->|PyMongo| Cosmos
    COSMOS_CONN -->|Injected| Flask
    COSMOS_DB -->|Injected| Flask
    COSMOS_COL -->|Injected| Flask
    SEC_COSMOS -->|Mapped| COSMOS_CONN
```

---

## 4. Request Flow — User Creates a Task

```mermaid
sequenceDiagram
    autonumber
    participant User as End User / Browser
    participant AG as Azure Application Gateway<br/>Port 80
    participant ACA as Azure Container App<br/>Port 3000
    participant Flask as Flask App (Gunicorn)
    participant Cosmos as Cosmos DB<br/>MongoDB API

    User->>AG: POST /tasks<br/>{"title": "New Task"}
    AG->>ACA: Forward request<br/>(HTTPS backend on 443)
    ACA->>Flask: Route to container
    Flask->>Flask: Validate JSON body
    Flask->>Cosmos: db.tasks.insert_one({id, title, completed})
    Cosmos-->>Flask: Acknowledge insert
    Flask-->>ACA: JSON response<br/>201 Created
    ACA-->>AG: Return response
    AG-->>User: 201 Created + task object
```

---

## 5. CI/CD Deployment Flow (Reference)

```mermaid
graph LR
    subgraph Dev["💻 Development"]
        DevCode["Developer"]
        GitRepo["GitHub Repo<br/>mhr-azure-project"]
    end

    subgraph CICD["🔄 CI/CD Pipeline<br/>GitHub Actions"]
        Build["Build Stage"]
        Test["Test Stage"]
        Push["Push to ACR"]
        Deploy["Deploy to ACA"]
    end

    subgraph Azure["☁️ Azure"]
        ACR["Azure Container Registry"]
        ACA["Azure Container App"]
    end

    DevCode -->|Push code| GitRepo
    GitRepo -->|Trigger| Build
    Build --> Test
    Test --> Push
    Push -->|docker push| ACR
    Deploy -->|az containerapp update| ACA
    ACA -->|Pull latest image| ACR
```

---

## 6. Component Legend

| Component | Azure Service | Purpose |
|-----------|-------------|---------|
| **Application Gateway** | `azurerm_application_gateway` | Public HTTPS entry point, load balancer, health probes |
| **Container App** | `azurerm_container_app` | Hosts the Flask Task Manager API |
| **Container Apps Env** | `azurerm_container_app_environment` | Managed serverless compute environment |
| **Container Registry** | `azurerm_container_registry` | Stores Docker images (Premium SKU) |
| **Cosmos DB** | `azurerm_cosmosdb_account` | MongoDB-compatible database for task storage |
| **Virtual Network** | `azurerm_virtual_network` | Isolated network 10.10.0.0/16 |
| **Private Endpoint** | `azurerm_private_endpoint` | Secure private access to ACR |
| **NSG** | `azurerm_network_security_group` | Network security rules for subnets |
| **Terraform State** | `azurerm` backend | Remote state in Azure Blob Storage |

---

*Generated from Terraform infrastructure and application code analysis.*

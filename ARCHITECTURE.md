# Three-Tier Architecture

This diagram shows the full network layout, request flow, and monitoring path for the stack.

```mermaid
flowchart TB
  user[User / Browser]
  dns[Route 53 / DNS]
  waf[WAF]
  alb[ALB\npublic]

  subgraph vpc[VPC: 10.0.0.0/16]
    direction TB

    subgraph publicrt[Public Route Table]
      publicrt1[0.0.0.0/0 -> IGW]
    end

    subgraph privatert[Private Route Table]
      privatert1[0.0.0.0/0 -> NAT Gateway]
    end

    subgraph public[Public Subnets]
      pub1[10.0.1.0/24\npublic-az1]
      pub2[10.0.2.0/24\npublic-az2]
      nat[NAT Gateway]
      jenkins[Jenkins EC2]
      grafana[Grafana EC2]
      alb
    end

    subgraph app[Private App Subnets]
      app1[10.0.11.0/24\napp-az1]
      app2[10.0.12.0/24\napp-az2]
      ecsnodes[ECS EC2 Capacity Nodes]
      frontend[ECS Frontend Service]
      backend[ECS Backend Service]
    end

    subgraph db[Private DB Subnets]
      db1[10.0.21.0/24\ndb-az1]
      db2[10.0.22.0/24\ndb-az2]
      rds[(PostgreSQL RDS)]
    end

    subgraph mgmt[Private Management Subnets]
      mgmt1[10.0.31.0/24\nmanagement-az1]
      mgmt2[10.0.32.0/24\nmanagement-az2]
    end

    subgraph obs[Monitoring Stack]
      influx[InfluxDB EC2]
      telegraf[Telegraf on ECS nodes]
    end
  end

  subgraph support[Supporting AWS Services]
    ecr[(ECR)]
    iam[IAM Roles / Instance Profiles]
    sm[Secrets Manager]
    cw[CloudWatch / SNS Alerts]
  end

  user --> dns --> waf --> alb
  alb --> frontend
  alb --> backend
  frontend --> backend
  backend --> rds

  jenkins --> ecr
  frontend -. pulls image .-> ecr
  backend -. pulls image .-> ecr
  ecsnodes -. pulls telegraf image .-> ecr

  ecsnodes --> telegraf
  telegraf -->|CPU / memory / disk / logs| influx
  grafana -->|InfluxQL via private IP| influx
  grafana -->|Dashboard UI on 3000| user

  jenkins -->|deploys application images| frontend
  jenkins -->|deploys application images| backend
  backend -->|DB password| sm
  ecsnodes --> iam
  jenkins --> iam
  grafana --> nat
  influx --> nat
  ecsnodes --> nat
  jenkins --> nat

  publicrt -. associated with .-> pub1
  publicrt -. associated with .-> pub2
  publicrt -. default route .-> alb

  privatert -. associated with .-> app1
  privatert -. associated with .-> app2
  privatert -. associated with .-> db1
  privatert -. associated with .-> db2
  privatert -. associated with .-> mgmt1
  privatert -. associated with .-> mgmt2

  pub1 --> nat
  pub2 --> nat
  app1 --> nat
  app2 --> nat
  mgmt1 --> nat
  mgmt2 --> nat

  db1 --> rds
  db2 --> rds
  app1 --> ecsnodes
  app2 --> ecsnodes
  pub1 --> grafana
  pub1 --> jenkins
  pub2 --> grafana

  classDef net fill:#f7f7f7,stroke:#666,stroke-width:1px;
  classDef svc fill:#eef6ff,stroke:#2b6cb0,stroke-width:1px;
  classDef data fill:#fff5eb,stroke:#c05621,stroke-width:1px;

  class pub1,pub2,app1,app2,db1,db2,mgmt1,mgmt2,publicrt1,privatert1 net;
  class alb,jenkins,grafana,ecsnodes,frontend,backend,telegraf,influx,waf,dns,user svc;
  class rds,ecr,sm,cw data;
```

## Request Flow

1. The user hits the public endpoint through DNS.
2. WAF inspects the request.
3. ALB receives the request in the public subnet.
4. ALB forwards `/` traffic to the frontend ECS service.
5. ALB forwards `/api/*` traffic to the backend ECS service.
6. Frontend calls backend inside the private app subnets.
7. Backend reads and writes application data in PostgreSQL RDS.
8. ECS tasks and ECS EC2 nodes pull images from ECR.
9. Telegraf runs on every ECS node and ships metrics to InfluxDB.
10. Grafana reads InfluxDB over the private IP and renders dashboards.

## Subnet Layout

- `10.0.1.0/24` and `10.0.2.0/24` are public subnets.
- `10.0.11.0/24` and `10.0.12.0/24` are private app subnets.
- `10.0.21.0/24` and `10.0.22.0/24` are private database subnets.
- `10.0.31.0/24` and `10.0.32.0/24` are private management subnets.
- The VPC CIDR is `10.0.0.0/16`.

## Route Tables

- Public route table sends `0.0.0.0/0` to the Internet Gateway.
- Private route table sends `0.0.0.0/0` to the NAT Gateway.
- Public subnets use the public route table.
- App, database, and management subnets use the private route table.

## Monitoring Path

- ECS nodes expose host tags like `instance_id` and `private_ip`.
- Telegraf collects CPU, memory, disk, and log metrics.
- InfluxDB stores the data.
- Grafana presents an `Instance` dropdown so you can view each ECS node separately.

## Component Map

- `ALB` is the ingress point.
- `ECS Frontend` serves the UI.
- `ECS Backend` serves the API.
- `RDS PostgreSQL` stores persistent app data.
- `Jenkins` builds and deploys application images.
- `ECR` stores frontend and backend images.
- `Grafana` displays observability dashboards.
- `InfluxDB` stores node metrics and logs.
- `Telegraf` collects data from the ECS nodes.


# Architecture

```mermaid
flowchart TB
  user[User]
  dns[DNS]
  waf[WAF]
  alb[ALB]

  subgraph vpc[VPC 10.0.0.0/16]
    igw[Internet Gateway]
    nat[NAT Gateway]

    subgraph pub[Public Subnets]
      pub1[10.0.1.0/24]
      pub2[10.0.2.0/24]
      jenkins[Jenkins EC2]
      grafana[Grafana EC2]
    end

    subgraph app[App Subnets]
      app1[10.0.11.0/24]
      app2[10.0.12.0/24]
      feasg[Frontend ASG]
      beasg[Backend ASG]
      feecs[Frontend ECS Service]
      beecs[Backend ECS Service]
    end

    subgraph db[DB Subnets]
      db1[10.0.21.0/24]
      db2[10.0.22.0/24]
      rds[(PostgreSQL RDS)]
    end

    subgraph mgmt[Management Subnets]
      mgmt1[10.0.31.0/24]
      mgmt2[10.0.32.0/24]
    end

    influx[InfluxDB EC2]
    ecsnodes[ECS EC2 Nodes]
  end

  ecr[(ECR)]
  iam[IAM]
  sm[Secrets Manager]

  user --> dns --> waf --> alb
  alb --> feecs
  alb --> beecs
  feecs --> beecs
  beecs --> rds
  feasg --> ecsnodes
  beasg --> ecsnodes
  ecsnodes --> ecr
  jenkins --> ecr
  jenkins --> feecs
  jenkins --> beecs
  grafana --> influx
  ecsnodes --> influx

  pub1 --> igw
  pub2 --> igw
  app1 --> nat
  app2 --> nat
  db1 --> nat
  db2 --> nat
  mgmt1 --> nat
  mgmt2 --> nat

  classDef net fill:#f7f7f7,stroke:#666;
  classDef svc fill:#eef6ff,stroke:#2b6cb0;
  classDef data fill:#fff5eb,stroke:#c05621;
  class pub1,pub2,app1,app2,db1,db2,mgmt1,mgmt2,igw,nat net;
  class user,dns,waf,alb,jenkins,grafana,influx,ecsnodes,feasg,beasg,feecs,beecs,iam,sm svc;
  class rds,ecr data;
```

## Prompt

Create a clean AWS architecture diagram from this Terraform stack:

- VPC: `10.0.0.0/16`
- Public subnets: `10.0.1.0/24`, `10.0.2.0/24`
- App subnets: `10.0.11.0/24`, `10.0.12.0/24`
- DB subnets: `10.0.21.0/24`, `10.0.22.0/24`
- Management subnets: `10.0.31.0/24`, `10.0.32.0/24`
- Internet Gateway for public subnets
- NAT Gateway in public subnet `10.0.1.0/24`
- ALB in public subnets
- WAF in front of ALB
- ECS cluster on EC2 with two ASGs: frontend and backend
- ECS services: frontend on port `3000`, backend on port `5000`
- Frontend target group path `/`
- Backend target group path `/api/*` and health check `/api/health`
- Backend connects to PostgreSQL RDS in private DB subnets
- Jenkins EC2 in public subnet
- Grafana EC2 in public subnet
- InfluxDB EC2 in private app subnet
- ECR for frontend and backend images
- Secrets Manager for DB password
- Show traffic flow and subnet placement

Keep it diagrammatic, accurate, and minimal.

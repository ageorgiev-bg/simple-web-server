## 1. Architecture Diagram

```text
                    ┌──────────────────────────┐
                    │        Internet          │
                    │   (Users / Browsers)     │
                    └─────────────┬────────────┘
                                  │
                                  │ HTTP/S :80/443
                                  ▼
                    ┌──────────────────────────┐
                    │ AWS ALB (Security Group) │
                    │   Inbound: TCP 80/443    │
                    └─────────────┬────────────┘
                                  │
                                  ▼            
                    ┌──────────────────────────┐
                    │ AWS EC2 (Security Group) │
                    │   Inbound: TCP 80        │
                    └─────────────┬────────────┘
                                  │
                                  ▼
                    ┌──────────────────────────┐
                    │        EC2 Instance      │
                    │  (Amazon Linux / Ubuntu) │
                    │                          │
                    │  ┌────────────────────┐  │
                    │  │  Gunicorn (WSGI)   │  │
                    │  │  Bind: 0.0.0.0:80  │  │
                    │  └─────────┬──────────┘  │
                    │            │             │
                    │  ┌─────────▼──────────┐  │
                    │  │  Flask Application │  │
                    │  │   app.py / wsgi.py │  │
                    │  └─────────┬──────────┘  │
                    │            │ SQLAlchemy  │
                    │            ▼             │
                    │  ┌────────────────────┐  │
                    │  │     MySQL Database │  │
                    │  │   (AWS RDS)        │  │
                    │  │   Port: 3306       │  │
                    │  └────────────────────┘  │
                    │                          │
                    └──────────────────────────┘
```

## 2. Deploment Configuration
1. CD solution must have environment variable `db_admin_creds` containing the admin password
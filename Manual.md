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
                    │  │   MySQL Database   │  │
                    │  │    (AWS RDS)       │  │
                    │  │     Port: 3306     │  │
                    │  └────────────────────┘  │
                    │                          │
                    └──────────────────────────┘
```

## 2. Application Deploment Configuration Considerations
1. Host OS Application-related environment variables (see user_data_v2.sh bootstrap configuration): 
  - `ADMIN_PWD` - must be passed as `TF_VAR_db_admin_creds` via CI/etc thru Terraform and contain RDS DB admin user password
  - `DB_EP` - RDS Aurora DB cluster writer endpoint is passed by Terraform from DB cluster resource
  - `FLASK_USR_PWD` - can be used to pass application user password (its hardcoded atm)
  - `MYSQL_DB` - can be used to pass application DB name (its hardcoded atm)
2. Flask app is deployed via EC2 user data with:
  - flask DB user: flaskuser
  - flask DB user password: flaskPWD
  - Gunicorn server listens on all EC2 network interfaces, on port 80
  - RDS DB bootstrap script: bootstrap_sql.sh
3. Application recovery - If either application user or DB are not available they get re-created, with fail-safe clauses!

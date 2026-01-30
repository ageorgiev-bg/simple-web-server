#!/bin/env bash
set -x

export WEB_APP=${web_app}
export ENVIRONMENT=${environment}
export DB_EP=${db_endpoint}
export ADMIN_PWD=${admin_creds}

# Prepare app dir
mkdir -p /var/app


# Add MariaDB repo

cat << EOF | sudo tee /etc/yum.repos.d/MariaDB.repo
# MariaDB 11.4 RedHatEnterpriseLinux repository list - created 2024-08-13 06:05 UTC
# https://mariadb.org/download/
[mariadb]
name = MariaDB
# rpm.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# baseurl = https://rpm.mariadb.org/11.4/rhel/$releasever/$basearch
baseurl = https://mirrors.gigenet.com/mariadb/yum/11.4/rhel/9/aarch64
# gpgkey = https://rpm.mariadb.org/RPM-GPG-KEY-MariaDB
gpgkey = https://mirrors.gigenet.com/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck = 1
EOF

# Install python 3, mariadb & create venv
sudo dnf install -y python3 MariaDB-server MariaDB-client MariaDB-devel 

cat <<EOF > /var/app/app.py
from flask import Flask, jsonify
from config import Config
from models import db, User

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    @app.route("/")
    def health():
        return jsonify(status="ok", service="flask-ec2-mysql-app")

    @app.route("/users", methods=["GET"])
    def list_users():
        users = User.query.all()
        return jsonify([u.to_dict() for u in users])

    return app

app = create_app()

if __name__ == "__main__":
    # Development only
    app.run(host="0.0.0.0", port=80) # , debug=True
EOF


cat <<EOF > /var/app/config.py
import os

class Config:
    MYSQL_USER = os.getenv("MYSQL_USER", "flaskuser")
    MYSQL_PASSWORD = os.getenv("FLASK_USR_PWD", "flaskPWD")
    MYSQL_HOST = os.getenv("DB_EP", "localhost")
    MYSQL_PORT = os.getenv("MYSQL_PORT", "3306")
    MYSQL_DB = os.getenv("MYSQL_DB", "flaskdb")

    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}"
        f"@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
EOF


cat <<EOF > /var/app/models.py
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from sqlalchemy.dialects.mysql import INTEGER

db = SQLAlchemy()


class User(db.Model):
    __tablename__ = "users"

    # Use MySQL INTEGER type with unsigned=True
    user_id = db.Column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    username = db.Column(db.String(50), nullable=False, unique=True)
    email = db.Column(db.String(100), nullable=False, unique=True)
    password_hash = db.Column(db.String(64), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(
        db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "username": self.username,
            "email": self.email,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
EOF


cat <<EOF > /var/app/wsgi.py
from app import create_app

app = create_app()
EOF


cat <<EOF > /var/app/requirements.txt
flask==3.0.0
gunicorn==21.2.0
flask-sqlalchemy==3.1.1
pymysql==1.1.0
cryptography==46.0.4
EOF


cat <<EOF > /var/app/bootstrap.sql
CREATE DATABASE IF NOT EXISTS flaskdb;

USE flaskdb;

CREATE TABLE users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash CHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'flaskuser' @'%' IDENTIFIED BY 'flaskPWD';

GRANT ALL PRIVILEGES ON flaskdb.* TO 'flaskuser' @'%';

FLUSH PRIVILEGES;
EOF


cat <<EOF > /var/app/init_db.py
#!/usr/bin/env python3
from app import create_app
from models import db

def main():
    app = create_app()
    with app.app_context():
        print("Creating database tables...")
        db.create_all()
        print("Tables created successfully.")

if __name__ == "__main__":
    main()
EOF


# Get RDS cluster CA bundle for region eu-west-1
wget https://truststore.pki.rds.amazonaws.com/eu-west-1/eu-west-1-bundle.pem -O /root/eu-west-1-bundle.pem


db_consistency_check() {
  # Description: Checks app DB consistency & DB user existence
  # Returns:
  #   0 on success, non-zero on failure
  
  local DB_NAME="flaskdb"
  local DB_USER="flaskuser"

  USER_CHECK=$(mariadb -h $${DB_EP} -P 3306 -u admin -p $${ADMIN_PWD} -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = 'flaskuser')" --ssl-verify-server-cert  --ssl-ca=/root/eu-west-1-bundle.pem | grep "$DB_USER" > /dev/null; echo "$?")
  DB_CHECK=$(mariadb --batch --skip-column-names -h $${DB_EP} -P 3306 -u admin -p $${ADMIN_PWD} -e "SHOW DATABASES LIKE '"$DB_NAME"';" | grep "$DB_NAME" > /dev/null; echo "$?")
  
  if [ $USER_CHECK -ne 0 ] || [ $DB_CHECK -ne 0 ]; then
    echo "DB user: $DB_USER/$DB_NAME don't exist, creating them.."
    mariadb -h $${DB_EP} -P 3306 -u admin -p $${ADMIN_PWD} --ssl-verify-server-cert  --ssl-ca=/root/eu-west-1-bundle.pem < /var/app/bootstrap.sql || echo "DB user/db Creation Failed!!!!"
  else
    echo "DB User/DB exist. Exiting.."
  fi
}


db_consistency_check

# Initialize App DB Tables
chmod +x /var/app/init_db.py

cd /var/app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python init_db.py


# Launching the App
nohup gunicorn --bind 0.0.0.0:80 wsgi:app &
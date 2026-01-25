#!/bin/env bash
set -x

export WEB_APP=${web_app}
export ENVIRONMENT=${environment}
export DB_EP=${db_endpoint}
export ADMIN_PWD=${admin_creds}

# Prepare app dir
mkdir -p /var/app
cd /var/app

# Install python 3 & create venv
sudo yum install python3 -y
python3 -m venv venv


cat <<EOF > /var/app/config.py
import os

class Config:
    MYSQL_USER = os.getenv("MYSQL_USER", "flaskuser")
    MYSQL_PASSWORD = os.getenv("FLASK_USR_PWD", "flaskPWD")
    MYSQL_HOST = os.getenv("DB_EP", "localhost")
    MYSQL_DB = os.getenv("MYSQL_DB", "flaskdb")

    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}"
        f"@{MYSQL_HOST}/{MYSQL_DB}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
EOF

cat <<EOF > /var/app/models.py
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name
        }
EOF


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
    app.run(host="0.0.0.0", port=80, debug=True)
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
EOF

cat <<EOF > /var/app/bootstrap.sql
CREATE DATABASE flaskdb;
CREATE USER 'flaskuser'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON flaskdb.* TO 'flaskuser'@'%';
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
wget https://truststore.pki.rds.amazonaws.com/eu-west-1/eu-west-1-bundle.pem


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
    mariadb -h $${DB_EP} -P 3306 -u admin -p $${ADMIN_PWD} --ssl-verify-server-cert  --ssl-ca=/root/eu-west-1-bundle.pem < /var/app/bootstrap.sql
  else
    echo "DB User/DB exist. Exiting.."
  fi
}


db_consistency_check

# Initialize DB Tables
chmod +x init_db.py

source venv/bin/activate
pip install -r requirements.txt
python init_db.py


# Launching the app
nohup gunicorn --bind 0.0.0.0:80 wsgi:app &
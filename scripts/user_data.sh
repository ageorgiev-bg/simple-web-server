#!/bin/env bash
set -x

export WEB_APP=${web-app}
export ENVIRONMENT=${environment}


mkdir -p /var/app
cd /var/app

sudo yum install python3 -y
python3 -m venv venv
source venv/bin/activate

cat <<EOF > /var/app/app.py
from flask import Flask, jsonify

def create_app():
    app = Flask(__name__)

    @app.route("/")
    def health():
        return jsonify(
            status="ok",
            service="$${WEB_APP}-$${ENVIRONMENT}",
        )

    @app.route("/hello/<name>")
    def hello(name):
        return jsonify(message=f"Hello, {name}!")

    return app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)

EOF


cat <<EOF > /var/app/wsgi.py
from app import create_app

app = create_app()
EOF

cat <<EOF > /var/app/requirements.txt
flask==3.0.0
gunicorn==21.2.0
EOF

pip install -r requirements.txt

nohup gunicorn --bind 0.0.0.0:80 wsgi:app &
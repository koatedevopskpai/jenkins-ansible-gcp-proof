from flask import Flask, jsonify
import os

app = Flask(__name__)


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/")
def index():
    return jsonify(
        service="jenkins-ansible-gcp-proof-demo",
        message="Built, tested, scanned and deployed by Jenkins on GCP",
    )


@app.get("/info")
def info():
    return jsonify(
        pipeline="Jenkins (Groovy shared library)",
        config_management="Ansible",
        registry=os.environ.get("AR_REPO", "unknown"),
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))

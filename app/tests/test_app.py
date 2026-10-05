from main import app


def test_health():
    client = app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_index():
    client = app.test_client()
    resp = client.get("/")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["service"] == "jenkins-ansible-gcp-proof-demo"


def test_info():
    client = app.test_client()
    resp = client.get("/info")
    assert resp.status_code == 200
    assert "pipeline" in resp.get_json()

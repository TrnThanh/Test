from fastapi.testclient import TestClient
import pytest


def test_root_endpoint(client: TestClient) -> None:
    """Kiểm tra root / trả về thông tin máy chủ và trạng thái online."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert "app" in data
    assert "version" in data
    assert "docs" not in data
    assert "redoc" not in data


@pytest.mark.parametrize("path", ["/docs", "/redoc", "/openapi.json"])
def test_swagger_and_openapi_disabled(client: TestClient, path: str) -> None:
    """Kiểm tra các endpoint Swagger UI, ReDoc và OpenAPI schema đều trả về mã 404 (đã tắt hoàn toàn)."""
    response = client.get(path)
    assert response.status_code == 404

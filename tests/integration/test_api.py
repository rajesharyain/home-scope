"""
Integration tests for HomeScope API.
Run with: pytest tests/integration/ -v
Requires the API server to be running at http://localhost:8000
"""
import pytest
import httpx

BASE_URL = "http://localhost:8000"


@pytest.fixture(scope="session")
def client():
    return httpx.Client(base_url=BASE_URL, timeout=60.0)


class TestHealth:
    def test_health_returns_ok(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"


class TestGeocode:
    def test_geocode_lisbon_address(self, client):
        resp = client.post(
            "/api/v1/geocode",
            json={"address": "Rua Augusta 150, Lisboa", "country_code": "PT"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "lat" in data
        assert "lng" in data
        assert 38.0 < data["lat"] < 39.5
        assert -9.5 < data["lng"] < -8.5

    def test_geocode_not_found_returns_404(self, client):
        resp = client.post(
            "/api/v1/geocode",
            json={"address": "XXXXINVALIDADDRESSXXXX", "country_code": "PT"},
        )
        assert resp.status_code == 404


class TestAmenities:
    def test_fetch_amenities_returns_list(self, client):
        resp = client.post(
            "/api/v1/amenities",
            json={"lat": 38.7139, "lng": -9.1394, "radius": 1000},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "amenities" in data
        assert isinstance(data["amenities"], list)

    def test_amenities_have_required_fields(self, client):
        resp = client.post(
            "/api/v1/amenities",
            json={"lat": 38.7139, "lng": -9.1394, "radius": 500},
        )
        assert resp.status_code == 200
        amenities = resp.json()["amenities"]
        if amenities:
            a = amenities[0]
            assert "id" in a
            assert "name" in a
            assert "category" in a
            assert "lat" in a
            assert "lng" in a


class TestScore:
    def test_empty_amenities_score_is_zero(self, client):
        resp = client.post(
            "/api/v1/score",
            json={"lat": 38.7139, "lng": -9.1394, "amenities": [], "profile": "default"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["overall"] == 0.0

    def test_score_with_amenities(self, client):
        amenities = [
            {
                "id": "test-1",
                "name": "Metro Baixa-Chiado",
                "category": "transportation",
                "type": "subway_entrance",
                "lat": 38.7108,
                "lng": -9.1399,
                "distance_meters": 300,
                "walking_minutes": 4,
            }
        ]
        resp = client.post(
            "/api/v1/score",
            json={"lat": 38.7139, "lng": -9.1394, "amenities": amenities, "profile": "default"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["overall"] > 0


class TestAnalyze:
    def test_full_analysis_rua_augusta(self, client):
        resp = client.post(
            "/api/v1/analyze",
            json={
                "address": "Rua Augusta 150, Lisboa",
                "country_code": "PT",
                "profile": "default",
                "radius": 2000,
            },
            timeout=90.0,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "score" in data
        assert "amenities" in data
        assert "address" in data
        assert 0 <= data["score"]["overall"] <= 100
        assert len(data["amenities"]) > 0

import pytest
from backend.services.overpass_service import (
    _haversine_meters,
    _walking_minutes,
    _extract_name,
    _extract_type,
    _detect_category,
)
from backend.models.schemas import AmenityCategory


class TestHaversine:
    def test_same_point_is_zero(self):
        assert _haversine_meters(38.71, -9.14, 38.71, -9.14) == 0

    def test_known_distance_approx(self):
        # Lisbon to Porto is ~280km
        dist = _haversine_meters(38.7169, -9.1399, 41.1579, -8.6291)
        assert 270000 < dist < 290000

    def test_short_distance(self):
        dist = _haversine_meters(38.71, -9.14, 38.715, -9.14)
        assert 500 < dist < 600


class TestWalkingMinutes:
    def test_80_meters_is_one_minute(self):
        assert _walking_minutes(80) == 1

    def test_zero_meters_is_one_minute(self):
        assert _walking_minutes(0) == 1

    def test_800_meters_is_ten_minutes(self):
        assert _walking_minutes(800) == 10


class TestExtractName:
    def test_extracts_name_tag(self):
        element = {"tags": {"name": "Supermercado Continente", "amenity": "supermarket"}}
        assert _extract_name(element) == "Supermercado Continente"

    def test_falls_back_to_operator(self):
        element = {"tags": {"operator": "Pingo Doce"}}
        assert _extract_name(element) == "Pingo Doce"

    def test_unknown_when_no_tags(self):
        assert _extract_name({"tags": {}}) == "Unknown"


class TestExtractType:
    def test_amenity_type(self):
        element = {"tags": {"amenity": "school"}}
        assert _extract_type(element) == "school"

    def test_leisure_type(self):
        element = {"tags": {"leisure": "park"}}
        assert _extract_type(element) == "park"


class TestDetectCategory:
    def test_subway_is_transportation(self):
        assert _detect_category("subway_entrance") == AmenityCategory.transportation

    def test_school_is_education(self):
        assert _detect_category("school") == AmenityCategory.education

    def test_hospital_is_healthcare(self):
        assert _detect_category("hospital") == AmenityCategory.healthcare

    def test_supermarket_is_shopping(self):
        assert _detect_category("supermarket") == AmenityCategory.shopping

    def test_unknown_defaults_to_recreation(self):
        assert _detect_category("unknown_type") == AmenityCategory.recreation

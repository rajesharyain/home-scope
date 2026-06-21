import httpx
import math
from typing import Optional, Tuple
from config.settings import settings


def _walking_minutes_estimate(meters: int) -> int:
    return max(1, round(meters / 80))


def _driving_minutes_estimate(meters: int) -> int:
    return max(1, round(meters / 400))  # ~400m/min city driving


class RoutingService:
    """
    Uses OpenRouteService when API key is available; falls back to
    straight-line haversine estimates so the app always works.
    """

    def __init__(self):
        self.client = httpx.AsyncClient(
            base_url=settings.openroute_url,
            timeout=15.0,
            headers={"Authorization": settings.openroute_api_key or ""},
        )
        self._has_key = bool(settings.openroute_api_key)

    async def get_walking_time(
        self, from_lat: float, from_lng: float, to_lat: float, to_lng: float
    ) -> Tuple[int, int]:
        """Returns (distance_meters, walking_minutes)."""
        if not self._has_key:
            dist = self._haversine(from_lat, from_lng, to_lat, to_lng)
            return dist, _walking_minutes_estimate(dist)

        try:
            resp = await self.client.post(
                "/v2/directions/foot-walking/json",
                json={
                    "coordinates": [[from_lng, from_lat], [to_lng, to_lat]],
                    "units": "m",
                },
            )
            resp.raise_for_status()
            data = resp.json()
            route = data["routes"][0]["summary"]
            dist = int(route["distance"])
            minutes = max(1, int(route["duration"] / 60))
            return dist, minutes
        except Exception:
            dist = self._haversine(from_lat, from_lng, to_lat, to_lng)
            return dist, _walking_minutes_estimate(dist)

    async def get_driving_time(
        self, from_lat: float, from_lng: float, to_lat: float, to_lng: float
    ) -> Tuple[int, int]:
        """Returns (distance_meters, driving_minutes)."""
        if not self._has_key:
            dist = self._haversine(from_lat, from_lng, to_lat, to_lng)
            return dist, _driving_minutes_estimate(dist)

        try:
            resp = await self.client.post(
                "/v2/directions/driving-car/json",
                json={
                    "coordinates": [[from_lng, from_lat], [to_lng, to_lat]],
                    "units": "m",
                },
            )
            resp.raise_for_status()
            data = resp.json()
            route = data["routes"][0]["summary"]
            dist = int(route["distance"])
            minutes = max(1, int(route["duration"] / 60))
            return dist, minutes
        except Exception:
            dist = self._haversine(from_lat, from_lng, to_lat, to_lng)
            return dist, _driving_minutes_estimate(dist)

    @staticmethod
    def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> int:
        R = 6371000
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lng2 - lng1)
        a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
        return int(R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))

    async def close(self):
        await self.client.aclose()


routing_service = RoutingService()

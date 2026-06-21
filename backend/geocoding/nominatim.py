import httpx
from typing import Optional
from config.settings import settings
from models.schemas import GeocodeResponse


class NominatimService:
    def __init__(self):
        self.client = httpx.AsyncClient(
            base_url=settings.nominatim_url,
            headers={"User-Agent": settings.nominatim_user_agent},
            timeout=30.0,
        )

    async def geocode(self, address: str, country_code: str = "PT") -> GeocodeResponse:
        params = {
            "q": address,
            "format": "json",
            "limit": 1,
            "addressdetails": 1,
            "countrycodes": country_code.lower(),
        }

        response = await self.client.get("/search", params=params)
        response.raise_for_status()
        results = response.json()

        if not results:
            raise ValueError(f"Address not found: {address}")

        result = results[0]
        addr_details = result.get("address", {})

        return GeocodeResponse(
            lat=float(result["lat"]),
            lng=float(result["lon"]),
            display_name=result.get("display_name", address),
            country=addr_details.get("country", ""),
            city=(
                addr_details.get("city")
                or addr_details.get("town")
                or addr_details.get("municipality")
                or addr_details.get("village")
            ),
            confidence=float(result.get("importance", 1.0)),
        )

    async def reverse_geocode(self, lat: float, lng: float) -> Optional[str]:
        params = {"lat": lat, "lon": lng, "format": "json"}
        response = await self.client.get("/reverse", params=params)
        if response.status_code == 200:
            data = response.json()
            return data.get("display_name")
        return None

    async def close(self):
        await self.client.aclose()


nominatim_service = NominatimService()

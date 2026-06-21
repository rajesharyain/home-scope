from fastapi import APIRouter, HTTPException
from models.schemas import AmenitiesRequest, AmenitiesResponse
from services.overpass_service import overpass_service

router = APIRouter()


@router.post("/amenities", response_model=AmenitiesResponse)
async def fetch_amenities(request: AmenitiesRequest):
    try:
        amenities = await overpass_service.fetch_amenities(
            lat=request.lat,
            lng=request.lng,
            radius=request.radius,
        )
        return AmenitiesResponse(
            amenities=amenities,
            total=len(amenities),
            radius=request.radius,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Amenity fetch error: {e}")

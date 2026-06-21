from fastapi import APIRouter, HTTPException
from models.schemas import GeocodeRequest, GeocodeResponse
from geocoding.nominatim import nominatim_service

router = APIRouter()


@router.post("/geocode", response_model=GeocodeResponse)
async def geocode_address(request: GeocodeRequest):
    try:
        result = await nominatim_service.geocode(request.address, request.country_code)
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Geocoding service error: {e}")

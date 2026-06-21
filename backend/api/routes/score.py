from fastapi import APIRouter, HTTPException
from models.schemas import ScoreRequest, LocationScore
from scoring.scoring_engine import calculate_location_score

router = APIRouter()


@router.post("/score", response_model=LocationScore)
async def calculate_score(request: ScoreRequest):
    try:
        return calculate_location_score(request.amenities, request.profile)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Scoring error: {e}")

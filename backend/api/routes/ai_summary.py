from fastapi import APIRouter, HTTPException
from models.schemas import AiSummaryRequest, AiSummaryResponse
from ai.summary_generator import summary_generator
from config.settings import settings

router = APIRouter()


@router.post("/ai/summary", response_model=AiSummaryResponse)
async def generate_summary(request: AiSummaryRequest):
    if not settings.openai_api_key:
        raise HTTPException(
            status_code=503,
            detail="AI summary not available: OpenAI API key not configured",
        )
    try:
        summary = await summary_generator.generate(
            address=request.address,
            score=request.score,
            amenities=[],
        )
        return AiSummaryResponse(summary=summary)
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI service error: {e}")

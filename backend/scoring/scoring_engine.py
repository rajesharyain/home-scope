import math
from datetime import datetime
from typing import List, Dict

from config.scoring_config import CATEGORY_CONFIG, PROFILE_WEIGHTS
from models.schemas import AmenityModel, CategoryScore, LocationScore, AmenityCategory


def _distance_score(distance_meters: int, max_distance: int) -> float:
    """Exponential decay: score drops as distance increases toward max_distance."""
    if distance_meters <= 0:
        return 100.0
    if distance_meters >= max_distance:
        return 0.0
    return 100.0 * math.exp(-3 * distance_meters / max_distance)


def _count_score(count: int, ideal_count: int) -> float:
    """Saturating score: approaches 100 as count reaches ideal_count."""
    if count <= 0:
        return 0.0
    return min(100.0, 100.0 * (1 - math.exp(-count / ideal_count)))


def _category_score(
    amenities: List[AmenityModel],
    category: str,
    config: dict,
) -> CategoryScore:
    cat_amenities = [a for a in amenities if a.category.value == category]
    cat_amenities.sort(key=lambda a: a.distance_meters or 99999)

    label = config["label"]
    ideal_count = config["ideal_count"]
    max_dist = config["max_distance"]
    dist_w = config["distance_weight"]
    count_w = config["count_weight"]

    if not cat_amenities:
        return CategoryScore(
            id=category,
            label=label,
            score=0.0,
            count=0,
            weight=0.0,
            closest=None,
        )

    closest = cat_amenities[0]
    closest_dist = closest.distance_meters or 0
    d_score = _distance_score(closest_dist, max_dist)
    c_score = _count_score(len(cat_amenities), ideal_count)
    score = dist_w * d_score + count_w * c_score

    return CategoryScore(
        id=category,
        label=label,
        score=round(score, 1),
        count=len(cat_amenities),
        weight=0.0,  # filled in by caller
        closest=closest,
    )


def calculate_location_score(
    amenities: List[AmenityModel],
    profile: str = "default",
) -> LocationScore:
    weights = PROFILE_WEIGHTS.get(profile, PROFILE_WEIGHTS["default"])

    categories: Dict[str, CategoryScore] = {}
    weighted_sum = 0.0
    total_weight = 0.0

    for cat_id, config in CATEGORY_CONFIG.items():
        weight = weights.get(cat_id, 0.0)
        if weight == 0.0:
            continue

        cat_score = _category_score(amenities, cat_id, config)
        cat_score = cat_score.model_copy(update={"weight": weight})
        categories[cat_id] = cat_score

        weighted_sum += cat_score.score * weight
        total_weight += weight

    overall = (weighted_sum / total_weight) if total_weight > 0 else 0.0

    return LocationScore(
        overall=round(overall, 1),
        categories=categories,
        profile=profile,
        calculated_at=datetime.utcnow(),
    )

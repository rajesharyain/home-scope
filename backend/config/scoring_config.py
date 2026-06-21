from typing import Dict, List


PROFILE_WEIGHTS: Dict[str, Dict[str, float]] = {
    "default": {
        "transportation": 0.25,
        "education": 0.20,
        "healthcare": 0.15,
        "shopping": 0.10,
        "safety": 0.15,
        "religion": 0.05,
        "recreation": 0.10,
    },
    "family": {
        "transportation": 0.20,
        "education": 0.30,
        "healthcare": 0.15,
        "shopping": 0.10,
        "safety": 0.15,
        "religion": 0.05,
        "recreation": 0.05,
    },
    "student": {
        "transportation": 0.30,
        "education": 0.25,
        "healthcare": 0.10,
        "shopping": 0.15,
        "safety": 0.10,
        "religion": 0.02,
        "recreation": 0.08,
    },
    "professional": {
        "transportation": 0.30,
        "education": 0.10,
        "healthcare": 0.15,
        "shopping": 0.15,
        "safety": 0.20,
        "religion": 0.02,
        "recreation": 0.08,
    },
    "retired": {
        "transportation": 0.20,
        "education": 0.05,
        "healthcare": 0.30,
        "shopping": 0.15,
        "safety": 0.20,
        "religion": 0.05,
        "recreation": 0.05,
    },
    "investor": {
        "transportation": 0.25,
        "education": 0.15,
        "healthcare": 0.10,
        "shopping": 0.20,
        "safety": 0.20,
        "religion": 0.02,
        "recreation": 0.08,
    },
}

CATEGORY_CONFIG: Dict[str, dict] = {
    "transportation": {
        "label": "Transportation",
        "osm_filters": [
            '["public_transport"="station"]',
            '["railway"="subway_entrance"]',
            '["railway"="station"]',
            '["highway"="bus_stop"]',
            '["amenity"="bus_station"]',
            '["railway"="tram_stop"]',
        ],
        "ideal_count": 5,
        "max_distance": 1000,
        "distance_weight": 0.6,
        "count_weight": 0.4,
    },
    "education": {
        "label": "Education",
        "osm_filters": [
            '["amenity"="school"]',
            '["amenity"="kindergarten"]',
            '["amenity"="university"]',
            '["amenity"="college"]',
            '["amenity"="library"]',
        ],
        "ideal_count": 3,
        "max_distance": 1500,
        "distance_weight": 0.5,
        "count_weight": 0.5,
    },
    "healthcare": {
        "label": "Healthcare",
        "osm_filters": [
            '["amenity"="hospital"]',
            '["amenity"="clinic"]',
            '["amenity"="pharmacy"]',
            '["amenity"="dentist"]',
            '["amenity"="doctors"]',
        ],
        "ideal_count": 3,
        "max_distance": 1500,
        "distance_weight": 0.6,
        "count_weight": 0.4,
    },
    "shopping": {
        "label": "Shopping",
        "osm_filters": [
            '["shop"="supermarket"]',
            '["shop"="mall"]',
            '["shop"="convenience"]',
            '["amenity"="marketplace"]',
        ],
        "ideal_count": 3,
        "max_distance": 1000,
        "distance_weight": 0.5,
        "count_weight": 0.5,
    },
    "safety": {
        "label": "Safety",
        "osm_filters": [
            '["amenity"="police"]',
            '["amenity"="fire_station"]',
        ],
        "ideal_count": 2,
        "max_distance": 2000,
        "distance_weight": 0.4,
        "count_weight": 0.6,
    },
    "religion": {
        "label": "Religion",
        "osm_filters": [
            '["amenity"="place_of_worship"]',
        ],
        "ideal_count": 2,
        "max_distance": 2000,
        "distance_weight": 0.4,
        "count_weight": 0.6,
    },
    "recreation": {
        "label": "Recreation",
        "osm_filters": [
            '["leisure"="park"]',
            '["leisure"="fitness_centre"]',
            '["leisure"="sports_centre"]',
            '["leisure"="swimming_pool"]',
            '["leisure"="playground"]',
            '["amenity"="gym"]',
        ],
        "ideal_count": 3,
        "max_distance": 1500,
        "distance_weight": 0.4,
        "count_weight": 0.6,
    },
}

OSM_TYPE_TO_CATEGORY: Dict[str, str] = {
    # Transportation
    "subway_entrance": "transportation",
    "station": "transportation",
    "bus_stop": "transportation",
    "bus_station": "transportation",
    "tram_stop": "transportation",
    "ferry_terminal": "transportation",
    # Education
    "school": "education",
    "kindergarten": "education",
    "university": "education",
    "college": "education",
    "library": "education",
    # Healthcare
    "hospital": "healthcare",
    "clinic": "healthcare",
    "pharmacy": "healthcare",
    "dentist": "healthcare",
    "doctors": "healthcare",
    # Shopping
    "supermarket": "shopping",
    "mall": "shopping",
    "convenience": "shopping",
    "marketplace": "shopping",
    # Safety
    "police": "safety",
    "fire_station": "safety",
    # Religion
    "place_of_worship": "religion",
    # Recreation
    "park": "recreation",
    "fitness_centre": "recreation",
    "sports_centre": "recreation",
    "swimming_pool": "recreation",
    "playground": "recreation",
    "gym": "recreation",
}

# HomeScope

**Know your neighborhood before you move.**

HomeScope analyzes any address and returns a Location Score based on walkability, nearby schools, hospitals, transport, shopping, recreation, and more. Built for Portugal first, designed for the world.

---

## Quick Start

### Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| Flutter 3.19+ | Yes | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Docker + Docker Compose | Yes | [docker.com](https://docs.docker.com/get-docker/) |
| Xcode 15+ (iPhone) | For iOS | Mac App Store |
| Python 3.12+ | For local backend | [python.org](https://www.python.org/) |

### 1. Clone & configure

```bash
cd /Users/ravi/Documents/Apps/home-scope
cp .env.example .env
# Optionally edit .env to add OPENAI_API_KEY and OPENROUTE_API_KEY
```

### 2. Start the backend

```bash
./scripts/start_backend.sh
```

Or manually:
```bash
docker compose up
```

API will be available at: **http://localhost:8000**
API docs: **http://localhost:8000/docs**

### 3. Run the Flutter app

```bash
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d "iPhone 16" --dart-define=BACKEND_URL=http://localhost:8000
```

---

## Architecture

```
HomeScope
├── mobile/          Flutter app (iOS + Android)
│   ├── lib/
│   │   ├── screens/ All UI screens
│   │   ├── widgets/ Reusable UI components
│   │   ├── providers/ Riverpod state management
│   │   ├── services/ API & cache services
│   │   ├── models/  Data models (Freezed)
│   │   └── config/  Theme, routing, constants
│   └── assets/
│       └── config/  countries.json, scoring_weights.json
│
├── backend/         FastAPI Python backend
│   ├── api/routes/  REST endpoints
│   ├── geocoding/   Nominatim integration
│   ├── services/    Overpass + routing
│   ├── scoring/     Weighted scoring engine
│   ├── ai/          OpenAI summary generation
│   ├── models/      Pydantic schemas
│   └── config/      Settings + scoring config
│
├── database/
│   └── migrations/  PostgreSQL + PostGIS schema
│
└── tests/
    ├── unit/        Python unit tests
    ├── integration/ API integration tests
    └── widget/      Flutter widget tests
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/geocode` | Convert address → lat/lng |
| `POST` | `/api/v1/amenities` | Fetch nearby places (Overpass) |
| `POST` | `/api/v1/score` | Calculate location score |
| `POST` | `/api/v1/ai/summary` | Generate AI neighborhood summary |
| `POST` | `/api/v1/analyze` | **Full pipeline** (recommended) |
| `GET` | `/health` | Health check |
| `GET` | `/docs` | Swagger UI |

### Example: Full Analysis

```bash
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "address": "Rua Augusta 150, Lisboa",
    "country_code": "PT",
    "profile": "default",
    "radius": 2000
  }'
```

---

## Scoring System

### Categories & Weights (Default Profile)

| Category | Weight | What it measures |
|----------|--------|-----------------|
| Transportation | 25% | Metro, bus, train proximity |
| Education | 20% | Schools, universities, libraries |
| Healthcare | 15% | Hospitals, clinics, pharmacies |
| Safety | 15% | Police, fire stations |
| Shopping | 10% | Supermarkets, markets |
| Recreation | 10% | Parks, gyms, sports |
| Religion | 5% | Places of worship |

### User Profiles

Weights automatically adjust based on profile:
- **Family** — More education & parks
- **Student** — More transport & education
- **Professional** — More transport & safety
- **Retired** — More healthcare & safety
- **Investor** — Balanced broad scoring

### Score Labels

| Score | Label |
|-------|-------|
| 80–100 | Excellent |
| 60–79 | Good |
| 40–59 | Fair |
| 0–39 | Poor |

---

## Country Support

Countries are configured in `mobile/assets/config/countries.json`.
No country-specific logic is hardcoded. Adding a new country requires only a JSON entry:

```json
{
  "code": "IT",
  "name": "Italy",
  "language": "it",
  "currency": "EUR",
  "postalPattern": "^\\d{5}$",
  "postalFormat": "NNNNN",
  "postalExample": "00100",
  "nominatimCountry": "Italy",
  "defaultCity": "Roma",
  "center": { "lat": 41.9028, "lng": 12.4964 },
  "defaultZoom": 7
}
```

---

## API Keys

| Key | Required | Purpose | Get it |
|-----|----------|---------|--------|
| `OPENAI_API_KEY` | Optional | AI neighborhood summaries | [platform.openai.com](https://platform.openai.com) |
| `OPENROUTE_API_KEY` | Optional | Accurate walking/driving times | [openrouteservice.org](https://openrouteservice.org) |

Without these keys, the app still works using:
- Built-in fallback text summaries
- Haversine straight-line distance estimates

---

## Testing

### Backend unit tests

```bash
cd /Users/ravi/Documents/Apps/home-scope
python -m pytest tests/unit/ -v
```

### API integration tests (requires running backend)

```bash
./scripts/test_api.sh          # Quick curl-based smoke test
python -m pytest tests/integration/ -v
```

### Flutter widget tests

```bash
cd mobile
flutter test test/
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3 + Material 3 |
| State | Riverpod 2 |
| Navigation | go_router |
| Maps | flutter_map + OpenStreetMap |
| Backend | FastAPI + Python 3.12 |
| Geocoding | Nominatim (OpenStreetMap) |
| Amenities | Overpass API (OSM) |
| Routing | OpenRouteService |
| AI | OpenAI GPT-4o-mini |
| Database | PostgreSQL + PostGIS |
| Cache | Redis |
| Deployment | Docker + Docker Compose |

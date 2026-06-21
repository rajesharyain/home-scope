#!/bin/bash
BASE_URL="http://localhost:8000"

echo "🧪 Testing HomeScope API..."
echo ""

echo "1️⃣  Health check..."
curl -s "$BASE_URL/health" | python3 -m json.tool
echo ""

echo "2️⃣  Geocoding: Rua Augusta 150, Lisboa..."
curl -s -X POST "$BASE_URL/api/v1/geocode" \
  -H "Content-Type: application/json" \
  -d '{"address": "Rua Augusta 150, Lisboa", "country_code": "PT"}' | python3 -m json.tool
echo ""

echo "3️⃣  Full analysis: Rua Augusta 150, Lisboa..."
curl -s -X POST "$BASE_URL/api/v1/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "address": "Rua Augusta 150, Lisboa",
    "country_code": "PT",
    "profile": "default",
    "radius": 2000
  }' | python3 -m json.tool
echo ""

echo "✅ API test complete!"

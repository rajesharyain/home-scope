-- HomeScope Database Schema
-- PostgreSQL + PostGIS

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Analyzed addresses
CREATE TABLE IF NOT EXISTS analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    address_text TEXT NOT NULL,
    display_name TEXT,
    country_code CHAR(3),
    location GEOGRAPHY(POINT, 4326),
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    profile VARCHAR(50) DEFAULT 'default',
    overall_score NUMERIC(5,2),
    ai_summary TEXT,
    raw_data JSONB
);

CREATE INDEX IF NOT EXISTS idx_analyses_location ON analyses USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON analyses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_country ON analyses(country_code);

-- Category scores per analysis
CREATE TABLE IF NOT EXISTS category_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id UUID REFERENCES analyses(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    score NUMERIC(5,2),
    count INTEGER,
    weight NUMERIC(4,3),
    closest_name TEXT,
    closest_distance_meters INTEGER,
    closest_walking_minutes INTEGER
);

CREATE INDEX IF NOT EXISTS idx_scores_analysis ON category_scores(analysis_id);

-- Cached amenities
CREATE TABLE IF NOT EXISTS amenity_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    osm_id TEXT,
    name TEXT NOT NULL,
    category VARCHAR(50),
    type VARCHAR(100),
    location GEOGRAPHY(POINT, 4326),
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    tags JSONB,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days')
);

CREATE INDEX IF NOT EXISTS idx_amenity_location ON amenity_cache USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_amenity_category ON amenity_cache(category);
CREATE INDEX IF NOT EXISTS idx_amenity_expires ON amenity_cache(expires_at);

-- Search history (for analytics)
CREATE TABLE IF NOT EXISTS search_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    searched_at TIMESTAMPTZ DEFAULT NOW(),
    address_text TEXT,
    country_code CHAR(3),
    analysis_id UUID REFERENCES analyses(id) ON DELETE SET NULL,
    duration_ms INTEGER
);

CREATE INDEX IF NOT EXISTS idx_search_log_date ON search_log(searched_at DESC);

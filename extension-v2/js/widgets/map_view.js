// NeighborLens – Map View Widget
// Renders an interactive property intelligence map using MapLibre GL JS or Leaflet.

// ── Constants ───────────────────────────────────────────────────────────────────

const CAT_COLORS = {
  transportation: '#3B82F6',
  education:      '#8B5CF6',
  healthcare:     '#EF4444',
  shopping:       '#F59E0B',
  safety:         '#10B981',
  religion:       '#06B6D4',
  recreation:     '#22C55E',
};

const CAT_EMOJI = {
  transportation: '🚇',
  education:      '🎓',
  healthcare:     '🏥',
  shopping:       '🛍',
  safety:         '🛡',
  religion:       '⛪',
  recreation:     '🌳',
};

const CAT_LABELS = {
  transportation: 'Transit',
  education:      'Schools',
  healthcare:     'Health',
  shopping:       'Shopping',
  safety:         'Safety',
  religion:       'Community',
  recreation:     'Parks',
};

const MODES = {
  all:          ['transportation','education','healthcare','shopping','safety','religion','recreation'],
  family:       ['education','healthcare','recreation','shopping'],
  investor:     ['transportation','shopping','recreation'],
  professional: ['transportation','recreation','shopping'],
  nature:       ['recreation'],
};

const KEY_CATS = [
  { id: 'education',      emoji: '🎓', label: 'Nearest School' },
  { id: 'transportation', emoji: '🚇', label: 'Nearest Transit' },
  { id: 'healthcare',     emoji: '🏥', label: 'Nearest Hospital' },
  { id: 'recreation',     emoji: '🌳', label: 'Nearest Park' },
];

// ── Public API ──────────────────────────────────────────────────────────────────

/**
 * Renders the interactive property intelligence map into `container`.
 * @param {HTMLElement} container
 * @param {object} result  – API result object
 */
export function renderMapView(container, result) {
  const lat = result?.address?.lat;
  const lng = result?.address?.lng;

  // No coordinates — show empty state
  if (!lat || !lng) {
    container.innerHTML = `
      <div class="mv-screen">
        <div class="mv-no-loc">
          <div style="font-size:32px;margin-bottom:10px">📍</div>
          <div style="font-size:14px;font-weight:600;color:var(--text2)">No location data</div>
          <div style="font-size:12px;color:var(--text3);margin-top:4px">GPS coordinates were not returned for this address.</div>
        </div>
      </div>
    `;
    return;
  }

  let activeMode   = 'all';
  let activeRadius = 500;
  let allMarkers   = [];   // { markerObj, amenity, isLeaflet }
  let circleLayer  = null; // MapLibre source/layer or Leaflet circle
  let mapInstance  = null;
  let isLeaflet    = false;

  // ── Render shell HTML ────────────────────────────────────────────────────────
  container.innerHTML = `
    <div class="mv-screen">
      <div class="mv-modes" id="mv-modes">
        <button class="mv-mode active" data-mode="all">All</button>
        <button class="mv-mode" data-mode="family">🏠 Family</button>
        <button class="mv-mode" data-mode="investor">📈 Investor</button>
        <button class="mv-mode" data-mode="professional">☕ Pro</button>
        <button class="mv-mode" data-mode="nature">🌳 Nature</button>
      </div>
      <div class="mv-radius-row" id="mv-radius-row">
        <span class="mv-radius-label">Show within</span>
        <button class="mv-radius-btn active" data-r="500">500m</button>
        <button class="mv-radius-btn" data-r="1000">1 km</button>
        <button class="mv-radius-btn" data-r="2000">2 km</button>
      </div>
      <div id="mv-map" class="mv-map"></div>
      <div class="mv-intel" id="mv-intel"></div>
    </div>
  `;

  // ── Detect library ───────────────────────────────────────────────────────────
  const hasMapLibre = typeof maplibregl !== 'undefined';
  const hasLeaflet  = typeof L !== 'undefined';
  isLeaflet = !hasMapLibre && hasLeaflet;

  if (!hasMapLibre && !hasLeaflet) {
    container.querySelector('#mv-map').innerHTML =
      '<div class="mv-no-loc">Map library not available.</div>';
    return;
  }

  // ── Init map ─────────────────────────────────────────────────────────────────
  if (hasMapLibre) {
    mapInstance = _initMapLibre(lat, lng);
  } else {
    mapInstance = _initLeaflet(lat, lng);
  }

  // ── Build initial intel panel ────────────────────────────────────────────────
  _renderIntel(container.querySelector('#mv-intel'), result, activeRadius);

  // ── Place markers after map loads ────────────────────────────────────────────
  if (hasMapLibre) {
    mapInstance.on('load', () => {
      _placeHomeMarkerMapLibre(mapInstance, lat, lng);
      allMarkers = _placeAmenityMarkersMapLibre(mapInstance, result, lat, lng);
      _drawRadiusMapLibre(mapInstance, lat, lng, activeRadius);
      _applyModeFilter(allMarkers, activeMode, false);
    });
  } else {
    // Leaflet is synchronous
    _placeHomeMarkerLeaflet(mapInstance, lat, lng);
    allMarkers = _placeAmenityMarkersLeaflet(mapInstance, result, lat, lng);
    circleLayer = _drawRadiusLeaflet(mapInstance, lat, lng, activeRadius);
  }

  // ── Resize after sidebar layout settles ─────────────────────────────────────
  setTimeout(() => {
    if (hasMapLibre) {
      mapInstance.resize();
    } else {
      mapInstance.invalidateSize();
    }
  }, 250);

  // ── Mode buttons ─────────────────────────────────────────────────────────────
  container.querySelector('#mv-modes').addEventListener('click', e => {
    const btn = e.target.closest('.mv-mode');
    if (!btn) return;
    activeMode = btn.dataset.mode;
    container.querySelectorAll('.mv-mode').forEach(b => b.classList.toggle('active', b === btn));
    _applyModeFilter(allMarkers, activeMode, isLeaflet);
  });

  // ── Radius buttons ───────────────────────────────────────────────────────────
  container.querySelector('#mv-radius-row').addEventListener('click', e => {
    const btn = e.target.closest('.mv-radius-btn');
    if (!btn) return;
    activeRadius = parseInt(btn.dataset.r, 10);
    container.querySelectorAll('.mv-radius-btn').forEach(b => b.classList.toggle('active', b === btn));

    if (hasMapLibre) {
      _updateRadiusMapLibre(mapInstance, lat, lng, activeRadius);
    } else {
      if (circleLayer) mapInstance.removeLayer(circleLayer);
      circleLayer = _drawRadiusLeaflet(mapInstance, lat, lng, activeRadius);
    }

    _renderIntel(container.querySelector('#mv-intel'), result, activeRadius);
  });
}

// ── MapLibre implementation ─────────────────────────────────────────────────────

function _initMapLibre(lat, lng) {
  // Tell MapLibre where to find its worker (required for MV3 extension)
  if (chrome?.runtime?.getURL) {
    maplibregl.workerUrl = chrome.runtime.getURL('lib/maplibre-gl.js');
  }

  return new maplibregl.Map({
    container: 'mv-map',
    style: 'https://tiles.openfreemap.org/styles/liberty',
    center: [lng, lat],
    zoom: 14,
  });
}

function _placeHomeMarkerMapLibre(map, lat, lng) {
  const el = document.createElement('div');
  el.className = 'mv-home-pin';
  el.innerHTML = '🏠';
  el.title = 'Your property';

  new maplibregl.Marker({ element: el, anchor: 'bottom' })
    .setLngLat([lng, lat])
    .setPopup(new maplibregl.Popup({ offset: 25 }).setHTML('<b>Your Property</b>'))
    .addTo(map);
}

function _placeAmenityMarkersMapLibre(map, result, homeLat, homeLng) {
  const amenities = (result.amenities || []).filter(a => a.lat && a.lng);
  return amenities.map(amenity => {
    const color = CAT_COLORS[amenity.category] || '#888';
    const emoji = CAT_EMOJI[amenity.category] || '📍';

    const el = document.createElement('div');
    el.className = 'mv-amenity-pin';
    el.style.setProperty('--pin-color', color);
    el.innerHTML = `<span class="mv-pin-dot" style="background:${color}"></span>`;
    el.title = amenity.name || amenity.type;

    const popup = new maplibregl.Popup({ offset: 15, closeButton: false })
      .setHTML(`<b>${amenity.name || amenity.type}</b><br>${amenity.distance_meters}m · ${amenity.walking_minutes} min walk`);

    const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
      .setLngLat([amenity.lng, amenity.lat])
      .setPopup(popup)
      .addTo(map);

    el.addEventListener('click', () => marker.togglePopup());

    return { markerObj: marker, amenity, element: el, isLeaflet: false };
  });
}

function _drawRadiusMapLibre(map, lat, lng, radiusMeters) {
  const geojson = _circleGeoJSON(lat, lng, radiusMeters);

  if (map.getSource('mv-radius')) {
    map.getSource('mv-radius').setData(geojson);
    return;
  }

  map.addSource('mv-radius', { type: 'geojson', data: geojson });

  map.addLayer({
    id: 'mv-radius-fill',
    type: 'fill',
    source: 'mv-radius',
    paint: {
      'fill-color': '#6C63FF',
      'fill-opacity': 0.08,
    },
  });

  map.addLayer({
    id: 'mv-radius-border',
    type: 'line',
    source: 'mv-radius',
    paint: {
      'line-color': '#6C63FF',
      'line-width': 1.5,
      'line-opacity': 0.5,
    },
  });
}

function _updateRadiusMapLibre(map, lat, lng, radiusMeters) {
  if (map.getSource('mv-radius')) {
    map.getSource('mv-radius').setData(_circleGeoJSON(lat, lng, radiusMeters));
  } else {
    // Map might still be loading; wait and retry
    map.once('idle', () => _drawRadiusMapLibre(map, lat, lng, radiusMeters));
  }
}

function _circleGeoJSON(lat, lng, radiusMeters) {
  const coords = [];
  for (let i = 0; i <= 64; i++) {
    const angle = (i / 64) * 2 * Math.PI;
    const dLat = (radiusMeters / 111320) * Math.cos(angle);
    const dLng = (radiusMeters / (111320 * Math.cos(lat * Math.PI / 180))) * Math.sin(angle);
    coords.push([lng + dLng, lat + dLat]);
  }
  return {
    type: 'Feature',
    geometry: { type: 'Polygon', coordinates: [coords] },
  };
}

// ── Leaflet implementation ──────────────────────────────────────────────────────

function _initLeaflet(lat, lng) {
  const map = L.map('mv-map').setView([lat, lng], 14);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 19,
  }).addTo(map);
  return map;
}

function _placeHomeMarkerLeaflet(map, lat, lng) {
  const homeIcon = L.divIcon({
    html: '<div class="mv-home-pin">🏠</div>',
    iconSize: [30, 30],
    iconAnchor: [15, 30],
    className: '',
  });
  L.marker([lat, lng], { icon: homeIcon })
    .addTo(map)
    .bindPopup('<b>Your Property</b>');
}

function _placeAmenityMarkersLeaflet(map, result, homeLat, homeLng) {
  const amenities = (result.amenities || []).filter(a => a.lat && a.lng);
  return amenities.map(amenity => {
    const color = CAT_COLORS[amenity.category] || '#888888';
    const marker = L.circleMarker([amenity.lat, amenity.lng], {
      radius: 7,
      fillColor: color,
      color: '#ffffff',
      weight: 1.5,
      opacity: 0.9,
      fillOpacity: 0.85,
    }).addTo(map)
      .bindPopup(`<b>${amenity.name || amenity.type}</b><br>${amenity.distance_meters}m · ${amenity.walking_minutes} min walk`);

    return { markerObj: marker, amenity, isLeaflet: true };
  });
}

function _drawRadiusLeaflet(map, lat, lng, radiusMeters) {
  return L.circle([lat, lng], {
    radius: radiusMeters,
    color: '#6C63FF',
    weight: 1.5,
    opacity: 0.5,
    fillColor: '#6C63FF',
    fillOpacity: 0.08,
  }).addTo(map);
}

// ── Shared helpers ──────────────────────────────────────────────────────────────

function _applyModeFilter(allMarkers, mode, isLeaflet) {
  const allowed = MODES[mode] || MODES.all;
  for (const { markerObj, amenity, element } of allMarkers) {
    const visible = allowed.includes(amenity.category);
    if (isLeaflet) {
      const el = markerObj.getElement?.();
      if (visible) {
        markerObj.setStyle({ opacity: 0.9, fillOpacity: 0.85 });
      } else {
        markerObj.setStyle({ opacity: 0, fillOpacity: 0 });
      }
    } else {
      // MapLibre custom HTML marker
      const el = markerObj.getElement();
      el.style.display = visible ? '' : 'none';
    }
  }
}

// ── Property Intelligence panel ─────────────────────────────────────────────────

function _renderIntel(intelEl, result, radiusMeters) {
  if (!intelEl) return;
  intelEl.innerHTML = _buildIntelPanel(result, radiusMeters);
}

function _buildIntelPanel(result, radiusMeters) {
  const amenities = result.amenities || [];
  const cats      = result.score?.categories || {};

  // Count amenities within selected radius
  const inRadius = amenities.filter(a => a.distance_meters <= radiusMeters);
  const radiusLabel = radiusMeters >= 1000
    ? `${(radiusMeters / 1000).toFixed(radiusMeters % 1000 === 0 ? 0 : 1)} km`
    : `${radiusMeters}m`;

  // Build key category cards
  const cards = KEY_CATS.map(({ id, emoji, label }) => {
    const cat     = cats[id];
    const closest = cat?.closest;
    if (!closest) {
      return `
        <div class="mv-intel-card">
          <div class="mv-intel-card-emoji">${emoji}</div>
          <div class="mv-intel-card-label">${label}</div>
          <div class="mv-intel-card-value" style="color:var(--text3)">—</div>
        </div>`;
    }
    const dist = closest.distance_meters < 1000
      ? `${closest.distance_meters}m`
      : `${(closest.distance_meters / 1000).toFixed(1)}km`;
    const walk = closest.walking_minutes != null ? `${closest.walking_minutes} min walk` : '';
    return `
      <div class="mv-intel-card">
        <div class="mv-intel-card-emoji">${emoji}</div>
        <div class="mv-intel-card-label">${label}</div>
        <div class="mv-intel-card-value" style="color:${CAT_COLORS[id]}">${dist}</div>
        ${walk ? `<div class="mv-intel-card-sub">${walk}</div>` : ''}
      </div>`;
  });

  // Radius count card
  const radiusCard = `
    <div class="mv-intel-card mv-intel-card--wide">
      <div class="mv-intel-card-emoji">📍</div>
      <div class="mv-intel-card-label">Within ${radiusLabel}</div>
      <div class="mv-intel-card-value" style="color:var(--accent2)">${inRadius.length} places</div>
    </div>`;

  return `
    <div class="mv-intel-grid">
      ${cards.join('')}
      ${radiusCard}
    </div>
  `;
}

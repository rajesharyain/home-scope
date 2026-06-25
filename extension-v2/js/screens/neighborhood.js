// NeighborLens – Neighbourhood Intelligence Screen (6 tabs: Map + 5 original)
// Map tab is first; all original tabs remain unchanged.

import { setState, getState } from '../state.js';
import { scoreColor, scoreLabel, streetViewUrl } from '../utils.js';
import { renderRadarChart } from '../widgets/radar_chart.js';
import { renderTimeMachine } from '../widgets/time_machine.js';
import { renderAiStory } from '../widgets/ai_story.js';
import { renderFutureScore } from '../widgets/future_score.js';
import { renderLifeRadius } from '../widgets/life_radius.js';
import { renderMapView } from '../widgets/map_view.js';
import { renderNeighborhoodExplorer } from '../widgets/neighborhood_explorer.js';
import { renderPropertyCompare } from '../widgets/property_compare.js';

const TABS = [
  { id: 'map',          label: 'Map',     emoji: '🗺' },
  { id: 'explore',      label: 'Explore', emoji: '🔍' },
  { id: 'dna',          label: 'DNA',     emoji: '🧬' },
  { id: 'life-radius',  label: 'Radius',  emoji: '📍' },
  { id: 'time-machine', label: 'Time',    emoji: '🕐' },
  { id: 'ai-story',     label: 'Story',   emoji: '✨' },
  { id: 'future-score', label: 'Future',  emoji: '🔮' },
  { id: 'compare',      label: 'Compare', emoji: '⚖️' },
];

export function renderNeighborhood(container, result) {
  container.innerHTML = `
    <div class="ni-screen">
      <!-- Tab navigation -->
      <div class="ni-tabs">
        ${TABS.map(tab => `
          <button class="ni-tab ${tab.id === (getState().niTab || 'map') ? 'active' : ''}"
            data-tab="${tab.id}">
            <span class="ni-tab-emoji">${tab.emoji}</span>
            <span class="ni-tab-label">${tab.label}</span>
          </button>
        `).join('')}
      </div>

      <!-- Tab content -->
      <div id="ni-content" class="ni-content"></div>
    </div>
  `;

  const content = container.querySelector('#ni-content');
  const tabs = container.querySelectorAll('.ni-tab');

  function activateTab(tabId) {
    setState({ niTab: tabId });
    tabs.forEach(t => t.classList.toggle('active', t.dataset.tab === tabId));
    renderTab(tabId, content, result);
  }

  tabs.forEach(btn => {
    btn.addEventListener('click', () => activateTab(btn.dataset.tab));
  });

  // Render initial tab – default to 'map' (most prominent)
  activateTab(getState().niTab || 'map');
}

function renderTab(tabId, content, result) {
  content.innerHTML = '';
  content.scrollTop = 0;

  switch (tabId) {
    case 'map':          renderMapView(content, result);               break;
    case 'explore':      renderNeighborhoodExplorer(content, result);  break;
    case 'dna':          renderDNA(content, result);                   break;
    case 'life-radius':  renderLifeRadius(content, result);            break;
    case 'time-machine': renderTimeMachine(content, result.score);     break;
    case 'ai-story':     renderAiStory(content, result);               break;
    case 'future-score': renderFutureScore(content, result.score);     break;
    case 'compare':      renderPropertyCompare(content, result);       break;
  }
}

function renderDNA(content, result) {
  const cats = result.score?.categories || {};
  const address = result.address;
  const overall = result.score?.overall ?? 0;
  const color = scoreColor(overall);
  const label = scoreLabel(overall);

  content.innerHTML = `
    <div class="dna-screen">
      <div class="dash-header" style="--accent:${color}">
        <div class="dash-score-ring">
          <svg viewBox="0 0 120 120" class="ring-svg">
            <circle cx="60" cy="60" r="50" class="ring-bg"/>
            <circle cx="60" cy="60" r="50" class="ring-fill"
              style="stroke:${color};stroke-dasharray:${Math.round(314 * overall / 100)} 314"/>
          </svg>
          <div class="ring-inner">
            <div class="ring-score" style="color:${color}">${Math.round(overall)}</div>
            <div class="ring-label">${label}</div>
          </div>
        </div>
        <div class="dash-address-block">
          <div class="dash-address">${address?.display_name || result._address || '—'}</div>
          ${address ? `<div class="dash-meta">${[address.district, address.city, address.postalCode || address.postal_code].filter(Boolean).join(' · ')}</div>` : ''}
          ${address?.lat ? `<a href="${streetViewUrl(address.lat, address.lng)}" target="_blank" class="street-view-link">📷 Street View</a>` : ''}
        </div>
      </div>

      <div class="section-label" style="color:rgba(255,255,255,0.5);margin-top:4px">CATEGORY DNA</div>

      <div class="dna-chart-wrap">
        <canvas id="radar-canvas" width="280" height="280"></canvas>
      </div>

      <div class="dna-legend">
        ${Object.values(cats).map(cat => `
          <div class="dna-legend-row">
            <div class="dna-legend-dot" style="background:${getCatColor(cat.id)}"></div>
            <span class="dna-legend-label">${cat.label}</span>
            <div class="dna-legend-bar-bg">
              <div class="dna-legend-bar"
                style="width:${cat.score}%;background:${getCatColor(cat.id)}"></div>
            </div>
            <span class="dna-legend-score" style="color:${getCatColor(cat.id)}">${Math.round(cat.score)}</span>
          </div>
        `).join('')}
      </div>
    </div>
  `;

  // Draw canvas radar chart
  requestAnimationFrame(() => {
    const canvas = content.querySelector('#radar-canvas');
    if (canvas) renderRadarChart(canvas, cats);
  });

  // Append DNA explained section
  _renderDNAExplained(content.querySelector('.dna-screen'), result);
}

// ── DNA Explained: expandable score cards ──────────────────────────────────────

function _renderDNAExplained(container, result) {
  if (!container) return;
  const cats      = result.score?.categories || {};
  const amenities = result.amenities || [];

  if (Object.keys(cats).length === 0) return;

  const CAT_EMOJI_MAP = {
    transportation: '🚇', education: '🎓', healthcare: '🏥',
    shopping: '🛍', safety: '🛡', religion: '⛪', recreation: '🌳',
  };
  const CAT_LABELS_MAP = {
    transportation: 'Transit', education: 'Schools', healthcare: 'Health',
    shopping: 'Shopping', safety: 'Safety', religion: 'Community', recreation: 'Parks',
  };

  const html = Object.entries(cats).map(([catId, cat]) => {
    const color  = getCatColor(catId);
    const emoji  = CAT_EMOJI_MAP[catId] || '📍';
    const label  = CAT_LABELS_MAP[catId] || cat.label || catId;
    const score  = cat.score ?? 0;

    const nearby = amenities
      .filter(a => a.category === catId)
      .sort((a, b) => a.distance_meters - b.distance_meters)
      .slice(0, 3);

    const poisHTML = nearby.length ? nearby.map(a => `
      <div class="dna-exp-poi">
        <span class="dna-exp-poi-name">${_escDNA(a.name || a.type || 'Place')}</span>
        <span class="dna-exp-poi-dist" style="color:${color}">${a.distance_meters}m</span>
        <span class="dna-exp-poi-walk">${a.walking_minutes != null ? a.walking_minutes + ' min' : '—'}</span>
      </div>`).join('')
      : '<div class="dna-exp-none">No nearby data available</div>';

    return `
      <div class="dna-exp-card" data-cat="${catId}">
        <div class="dna-exp-header">
          <span class="dna-exp-emoji">${emoji}</span>
          <span class="dna-exp-name">${label}</span>
          <div class="dna-exp-bar-wrap">
            <div class="dna-exp-bar" style="width:${score}%;background:${color}"></div>
          </div>
          <span class="dna-exp-score" style="color:${color}">${Math.round(score)}</span>
          <button class="dna-exp-toggle" aria-label="Toggle details">›</button>
        </div>
        <div class="dna-exp-body" style="display:none">
          ${poisHTML}
        </div>
      </div>`;
  }).join('');

  const section = document.createElement('div');
  section.className = 'dna-exp-section';
  section.innerHTML = `
    <div class="section-label" style="color:rgba(255,255,255,0.5);margin-top:16px;margin-bottom:8px">SCORE BREAKDOWN</div>
    ${html}`;
  container.appendChild(section);

  // Wire accordion toggle
  section.querySelectorAll('.dna-exp-header').forEach(header => {
    header.addEventListener('click', () => {
      const card = header.closest('.dna-exp-card');
      const body = card.querySelector('.dna-exp-body');
      const isOpen = card.classList.toggle('open');
      body.style.display = isOpen ? 'block' : 'none';
    });
  });
}

function _escDNA(str) {
  return String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Inline color lookup to avoid circular import in template literal
function getCatColor(catId) {
  const MAP = {
    transportation:'#29B6F6', education:'#66BB6A', healthcare:'#EF5350',
    shopping:'#FFA726', safety:'#AB47BC', religion:'#8D6E63', recreation:'#26C6DA',
  };
  return MAP[catId] || '#888';
}

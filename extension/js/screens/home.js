// HomeScope – Home Screen
import { setState, getState } from '../state.js';
import { validateAddress } from '../validation.js';
import { getHistory, getSettings } from '../storage.js';
import { scoreColor, scoreLabel } from '../utils.js';

export function renderHome(container) {
  container.innerHTML = homeHTML();
  bindHome(container);
  loadHistory(container);
}

function homeHTML() {
  return `
    <div class="home-screen">

      <!-- Minimal nav – no brand, just utility icons -->
      <div class="home-topbar">
        <button id="btn-nav-history" class="home-nav-btn" title="Recent searches">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
          </svg>
        </button>
        <button id="btn-nav-settings" class="home-nav-btn" title="Settings">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
            <line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
            <circle cx="8"  cy="6"  r="2.5" fill="currentColor" stroke="none"/>
            <circle cx="15" cy="12" r="2.5" fill="currentColor" stroke="none"/>
            <circle cx="10" cy="18" r="2.5" fill="currentColor" stroke="none"/>
          </svg>
        </button>
      </div>

      <!-- Hero -->
      <div class="home-hero">
        <h1 class="home-headline">Understand any<br>address with AI.</h1>
        <p class="home-sub">7 dimensions · AI narrative · Real-time data</p>
      </div>

      <!-- Primary action card -->
      <div class="search-card">
        <div class="search-row">
          <select id="country-select" class="country-select" title="Country">
            <option value="PT">🇵🇹 PT</option>
            <option value="ES">🇪🇸 ES</option>
            <option value="GB">🇬🇧 GB</option>
            <option value="FR">🇫🇷 FR</option>
            <option value="DE">🇩🇪 DE</option>
          </select>
          <input id="address-input" class="address-input" type="text"
            placeholder="Street, city or postcode…" autocomplete="off" />
        </div>
        <div id="address-error" class="field-error hidden"></div>

        <div class="profile-row">
          <span class="profile-label">Profile</span>
          <div class="profile-chips" id="profile-chips">
            <button class="chip active" data-profile="default">Default</button>
            <button class="chip" data-profile="family">Family</button>
            <button class="chip" data-profile="student">Student</button>
            <button class="chip" data-profile="professional">Professional</button>
            <button class="chip" data-profile="retired">Retired</button>
            <button class="chip" data-profile="investor">Investor</button>
          </div>
        </div>

        <button id="analyze-btn" class="btn-primary">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
          </svg>
          Analyze Address
        </button>
      </div>

      <div id="history-preview" class="history-preview hidden">
        <div class="section-label">RECENT</div>
        <div id="history-list" class="history-list"></div>
      </div>
    </div>
  `;
}

function bindHome(container) {
  const analyzeBtn   = container.querySelector('#analyze-btn');
  const addressInput = container.querySelector('#address-input');
  const addrError    = container.querySelector('#address-error');
  const profileChips = container.querySelectorAll('.chip[data-profile]');

  // Nav icons (now live inside the home screen, not the topbar)
  container.querySelector('#btn-nav-history')?.addEventListener('click', () => setState({ screen: 'history' }));
  container.querySelector('#btn-nav-settings')?.addEventListener('click', () => setState({ screen: 'settings' }));

  // Restore saved settings
  getSettings().then(settings => {
    const countrySelect = container.querySelector('#country-select');
    if (countrySelect) countrySelect.value = settings.defaultCountry || 'PT';

    const activeChip = container.querySelector(`.chip[data-profile="${settings.profile}"]`);
    if (activeChip) {
      profileChips.forEach(c => c.classList.remove('active'));
      activeChip.classList.add('active');
    }
  });

  profileChips.forEach(chip => {
    chip.addEventListener('click', () => {
      profileChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
    });
  });

  addressInput.addEventListener('input', () => {
    addrError.classList.add('hidden');
    addrError.textContent = '';
  });

  addressInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') analyzeBtn.click();
  });

  analyzeBtn.addEventListener('click', () => {
    const address = addressInput.value.trim();
    const error   = validateAddress(address);
    if (error) {
      addrError.textContent = error;
      addrError.classList.remove('hidden');
      return;
    }

    const countryCode = container.querySelector('#country-select').value;
    const profile     = container.querySelector('.chip.active')?.dataset.profile || 'default';

    setState({ address, analysisCountry: countryCode, analysisProfile: profile });
    document.dispatchEvent(new CustomEvent('homescope:analyze', {
      detail: { address, countryCode, profile }
    }));
  });
}

async function loadHistory(container) {
  const history = await getHistory();
  if (!history.length) return;

  const preview = container.querySelector('#history-preview');
  const list = container.querySelector('#history-list');
  preview.classList.remove('hidden');

  list.innerHTML = history.slice(0, 5).map(h => {
    const score = h.score?.overall ?? 0;
    const color = scoreColor(score);
    const label = scoreLabel(score);
    return `
      <div class="history-tile" data-id="${h.id}">
        <div class="history-tile-score" style="color:${color}">${Math.round(score)}</div>
        <div class="history-tile-info">
          <div class="history-tile-address">${h.address}</div>
          <div class="history-tile-meta">${label} · ${h.profile || 'default'}</div>
        </div>
        <div class="history-tile-arrow">›</div>
      </div>
    `;
  }).join('');

  list.querySelectorAll('.history-tile').forEach(tile => {
    tile.addEventListener('click', () => {
      const id = tile.dataset.id;
      const entry = history.find(h => h.id === id);
      if (entry) {
        document.dispatchEvent(new CustomEvent('homescope:load-history', { detail: entry }));
      }
    });
  });
}

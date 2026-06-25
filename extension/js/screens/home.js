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

      <!-- Marketing / onboarding section -->
      <div class="home-marketing">

        <div class="hm-divider"></div>

        <!-- Problem statement -->
        <div class="hm-headline">The problem</div>
        <p class="hm-problem-lead">Finding a home means researching a neighbourhood — but nobody makes that easy.</p>

        <div class="hm-problems">
          <div class="hm-problem-item">
            <span class="hm-problem-icon">😩</span>
            <div>
              <div class="hm-problem-title">Six tools, one decision</div>
              <div class="hm-problem-desc">To properly research a location you open Google Maps for walkability, a school ratings site, a crime map, a flood-risk checker, a price-trend chart, and Reddit. That's before you've even visited.</div>
            </div>
          </div>
          <div class="hm-problem-item">
            <span class="hm-problem-icon">🏠</span>
            <div>
              <div class="hm-problem-title">Property sites show the house, not the life</div>
              <div class="hm-problem-desc">Rightmove, Idealista and Zillow tell you the bedrooms and the price. None of them tell you whether you'll regret the location in 6 months.</div>
            </div>
          </div>
          <div class="hm-problem-item">
            <span class="hm-problem-icon">⏱</span>
            <div>
              <div class="hm-problem-title">Decisions made under pressure</div>
              <div class="hm-problem-desc">Good properties go fast. You have a weekend, not a month, to decide if a neighbourhood fits your life. Most people guess — and some get it wrong.</div>
            </div>
          </div>
          <div class="hm-problem-item">
            <span class="hm-problem-icon">🕳</span>
            <div>
              <div class="hm-problem-title">You don't know what you don't know</div>
              <div class="hm-problem-desc">The flight path overhead. The school that's outstanding but oversubscribed. The park that floods. The planned development 400m away. These surface after you've signed.</div>
            </div>
          </div>
        </div>

        <div class="hm-divider"></div>

        <!-- Value props -->
        <div class="hm-headline">How HomeScope solves it</div>
        <p class="hm-sub">One search. Every dimension of a location. Personalised to your life.</p>

        <div class="hm-props">
          <div class="hm-prop">
            <span class="hm-prop-icon">📍</span>
            <div>
              <div class="hm-prop-title">One search, 7 dimensions</div>
              <div class="hm-prop-desc">Schools, transit, healthcare, shops, safety, community and parks — all in one place, instantly.</div>
            </div>
          </div>
          <div class="hm-prop">
            <span class="hm-prop-icon">⚡</span>
            <div>
              <div class="hm-prop-title">AI insight in seconds</div>
              <div class="hm-prop-desc">No more 6-tab research sessions. Get a clear narrative and score for any address in under 20 seconds.</div>
            </div>
          </div>
          <div class="hm-prop">
            <span class="hm-prop-icon">🎯</span>
            <div>
              <div class="hm-prop-title">Personalised to your life</div>
              <div class="hm-prop-desc">Family, investor, student, professional — your profile re-weights every score around what actually matters to you.</div>
            </div>
          </div>
          <div class="hm-prop">
            <span class="hm-prop-icon">🗺</span>
            <div>
              <div class="hm-prop-title">Walk-time radar, not vague ratings</div>
              <div class="hm-prop-desc">The Life Radius shows exactly what is within a 5, 10, 20 and 30-minute walk — plotted on a real map.</div>
            </div>
          </div>
        </div>

        <div class="hm-divider"></div>

        <!-- FAQ accordion -->
        <div class="hm-headline">Common questions</div>
        <div class="hm-faq" id="hm-faq">

          <div class="faq-item">
            <button class="faq-q">Who is HomeScope for?</button>
            <div class="faq-a">Anyone making a location decision. Families checking school proximity. Professionals weighing up commute time. Investors sizing up rental potential. Retirees finding somewhere walkable. The profile selector adapts the score to your specific situation.</div>
          </div>

          <div class="faq-item">
            <button class="faq-q">How does the score work?</button>
            <div class="faq-a">We analyse 7 dimensions — transportation, education, healthcare, shopping, safety, community and recreation. Each is scored 0–100 based on what is physically nearby. Your chosen profile then applies weights (a family weights schools heavily; an investor weights transport and commerce). The overall score is the weighted average.</div>
          </div>

          <div class="faq-item">
            <button class="faq-q">How accurate is the data?</button>
            <div class="faq-a">Location data comes from OpenStreetMap — a global, continuously updated database with over 8 billion data points. It reflects what is physically on the ground right now, often more up-to-date than commercial alternatives.</div>
          </div>

          <div class="faq-item">
            <button class="faq-q">Can I use this for investment decisions?</button>
            <div class="faq-a">Yes. The Investor profile weights transport links, commercial access and future trajectory. The Life Radius and Within Reach stats give you a clear picture of walkable amenity density — a key driver of rental demand and resale value.</div>
          </div>

          <div class="faq-item">
            <button class="faq-q">What does the Life Radius show?</button>
            <div class="faq-a">A circular radar centred on the address. Each ring represents a walk time — 5, 10, 20 and 30 minutes. Coloured dots show every nearby amenity. Tap any dot for its name and walking time. Filter by category to focus on what matters to you.</div>
          </div>

          <div class="faq-item">
            <button class="faq-q">Which countries are supported?</button>
            <div class="faq-a">Currently Portugal, Spain, United Kingdom, France and Germany. Coverage follows OpenStreetMap data quality — these markets have the most complete datasets. More countries are being added.</div>
          </div>

          <div class="faq-item">
            <button class="faq-q">Is my data private?</button>
            <div class="faq-a">Addresses you search are sent to the HomeScope API to retrieve location data. Search history is stored locally in your browser only and never uploaded. No personal information is collected or shared.</div>
          </div>

        </div>
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

  // FAQ accordion
  container.querySelector('#hm-faq')?.addEventListener('click', e => {
    const btn = e.target.closest('.faq-q');
    if (!btn) return;
    const item = btn.closest('.faq-item');
    const isOpen = item.classList.contains('open');
    // close all
    container.querySelectorAll('.faq-item.open').forEach(el => el.classList.remove('open'));
    if (!isOpen) item.classList.add('open');
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

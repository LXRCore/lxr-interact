/* LXR-INTERACT — the interaction card | © 2026 iBoss21 / LXRCore */
(function () {
  const card = document.getElementById('card'), rows = document.getElementById('rows'), label = document.getElementById('label');
  let L = {};
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  function render(m) {
    label.textContent = m.label || L['ui.interact'] || 'Interact';
    card.dataset.anchor = m.anchor || 'right';
    rows.innerHTML = '';
    (m.options || []).forEach(o => {
      const r = document.createElement('div'); r.className = 'ia-row'; r.dataset.key = o.key || '';
      r.innerHTML = `<span class="lxr-key">${esc(o.key || '·')}</span><span class="ia-row__label">${esc(o.label)}</span>${m.hold > 0 ? '<span class="ia-row__fill"></span>' : ''}`;
      rows.appendChild(r);
    });
    card.classList.remove('lxr-hidden');
  }
  /* ── the eye: a cursor that lights up on a target; a click opens the options where it sits ── */
  const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-interact';
  const post = (name, body) => fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).catch(() => {});
  const eye = document.getElementById('eye'), menu = document.getElementById('menu'), menuRows = document.getElementById('menu-rows');
  let mx = innerWidth / 2, my = innerHeight / 2, eyeOn = false;
  document.addEventListener('mousemove', (e) => { mx = e.clientX; my = e.clientY; if (eyeOn && menu.classList.contains('lxr-hidden')) { eye.style.left = mx + 'px'; eye.style.top = my + 'px'; } });
  document.addEventListener('mousedown', (e) => { if (eyeOn && !menu.classList.contains('lxr-hidden') && !menu.contains(e.target)) { menu.classList.add('lxr-hidden'); post('eye:close'); } });
  function setEye(on) { eyeOn = on; eye.classList.toggle('lxr-hidden', !on); eye.classList.remove('is-on'); menu.classList.add('lxr-hidden'); if (on) { eye.style.left = mx + 'px'; eye.style.top = my + 'px'; } }
  function showMenu(m) {
    if (!m.options) { menu.classList.add('lxr-hidden'); return; }
    document.getElementById('menu-label').textContent = m.label || L['ui.interact'] || 'Interact';
    menuRows.innerHTML = '';
    m.options.forEach((o, i) => {
      const r = document.createElement('div'); r.className = 'ia-row ia-row--click';
      r.innerHTML = `<span class="ia-row__idx lxr-mono">${String(i + 1).padStart(2, '0')}</span><span class="ia-row__label">${esc(o.label)}</span>`;
      r.addEventListener('click', () => post('eye:pick', { index: i + 1 }));
      menuRows.appendChild(r);
    });
    const x = Math.min(mx + 14, innerWidth - 280), y = Math.min(my + 14, innerHeight - 40 * (m.options.length + 1));
    menu.style.left = x + 'px'; menu.style.top = y + 'px';
    menu.classList.remove('lxr-hidden');
  }

  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.brand && m.brand.theme) document.documentElement.dataset.theme = m.brand.theme;
    if (m.action === 'init') { L = m.locale || {}; document.body.classList.toggle('lang-ka', m.lang === 'ka'); }
    if (m.action === 'show' || m.action === 'update') render(m);
    if (m.action === 'hide') card.classList.add('lxr-hidden');
    if (m.action === 'eye') setEye(!!m.on);
    if (m.action === 'eyeTarget') { eye.classList.toggle('is-on', !!m.on); document.getElementById('eye-label').textContent = m.on ? (m.label || '') : ''; }
    if (m.action === 'menu') showMenu(m);
    if (m.action === 'hold') { const r = rows.querySelector(`.ia-row[data-key="${CSS.escape(m.key)}"] .ia-row__fill`); if (r) r.style.width = (m.f * 100) + '%'; }
  });
  if (window.__LXR_MOCK__) { for (const m of [].concat(window.__LXR_MOCK__)) window.postMessage(m, '*'); }
})();

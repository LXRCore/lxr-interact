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
  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.brand && m.brand.theme) document.documentElement.dataset.theme = m.brand.theme;
    if (m.action === 'init') { L = m.locale || {}; document.body.classList.toggle('lang-ka', m.lang === 'ka'); }
    if (m.action === 'show' || m.action === 'update') render(m);
    if (m.action === 'hide') card.classList.add('lxr-hidden');
    if (m.action === 'hold') { const r = rows.querySelector(`.ia-row[data-key="${CSS.escape(m.key)}"] .ia-row__fill`); if (r) r.style.width = (m.f * 100) + '%'; }
  });
  if (window.__LXR_MOCK__) { for (const m of [].concat(window.__LXR_MOCK__)) window.postMessage(m, '*'); }
})();

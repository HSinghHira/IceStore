/* Small icon set used by scripts (static icons are inlined in the HTML). */
(()=>{
  const ICE=window.ICE=window.ICE||{pages:{}};
  const P={
    copy:'<rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
    check:'<path d="M20 6 9 17l-5-5"/>',
    monitor:'<rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>'
  };
  ICE.icon=n=>`<svg class="i" viewBox="0 0 24 24" aria-hidden="true">${P[n]||''}</svg>`;
})();

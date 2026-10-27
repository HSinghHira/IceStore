/* App page: screenshot gallery + popup, tabs, compose highlighting. */
(()=>{
  const ICE=window.ICE,$=ICE.$,$$=ICE.$$;
  const esc=s=>s.replace(/&/g,'&amp;').replace(/</g,'&lt;');
  const yaml=l=>{
    l=esc(l);
    if(/^\s*#/.test(l))return `<span class="c">${l}</span>`;
    return l.replace(/("[^"]*")/g,'<span class="s">$1</span>').replace(/^(\s*(?:- )?)([\w.-]+)(:)/,'$1<span class="k">$2</span>$3');
  };
  const SHOT=/^#shot-(\d+)$/;
  // #shot-N opens that screenshot; the listener is added once and calls the current page's handler
  addEventListener('hashchange',()=>{if(ICE.shotHash)ICE.shotHash()});

  const gallery=main=>{
    const gal=$('.gal',main);ICE.shotHash=null;
    if(!gal)return;
    const items=$$('.gt',gal),n=items.length,smooth=ICE.reduced?'auto':'smooth';

    /* row: 3 in view, buttons and arrow keys move one view at a time */
    const page=d=>gal.scrollBy({left:d*gal.clientWidth,behavior:smooth});
    const prev=$('.gw>.prev',main),next=$('.gw>.next',main);
    if(prev){
      const upd=()=>{prev.disabled=gal.scrollLeft<4;next.disabled=gal.scrollLeft+gal.clientWidth>=gal.scrollWidth-4};
      prev.onclick=()=>page(-1);next.onclick=()=>page(1);
      gal.addEventListener('scroll',upd,{passive:true});upd();
    }
    gal.onkeydown=e=>{const d={ArrowRight:1,ArrowLeft:-1}[e.key];if(d){e.preventDefault();page(d)}};

    /* dots: one per screenshot, the ones in view are lit; a click scrolls that one into view */
    const dots=document.createElement('div');dots.className='gd';
    dots.innerHTML=items.map((_,k)=>`<button type="button" aria-label="Show screenshot ${k+1}"></button>`).join('');
    gal.closest('.gw').after(dots);
    const ds=$$('button',dots);
    const lit=()=>{
      const g=gal.getBoundingClientRect();
      items.forEach((a,k)=>{const r=a.getBoundingClientRect();ds[k].setAttribute('aria-current',r.left>=g.left-8&&r.right<=g.right+8)});
    };
    dots.onclick=e=>{const k=ds.indexOf(e.target.closest('button'));if(k>-1)gal.scrollTo({left:items[k].offsetLeft-items[0].offsetLeft,behavior:smooth})};
    let raf=0;
    gal.addEventListener('scroll',()=>{if(!raf)raf=requestAnimationFrame(()=>{raf=0;lit()})},{passive:true});
    addEventListener('resize',()=>{if(main.isConnected)lit()},{passive:true});
    lit();

    /* popup */
    const lb=document.createElement('dialog');
    lb.className='lb';lb.setAttribute('aria-label',main.querySelector('h1').textContent+' screenshots');
    const arrows=n>1?`<button class="nav prev" type="button" aria-label="Previous screenshot">${ICE.icon('arrow-left')}</button><button class="nav next" type="button" aria-label="Next screenshot">${ICE.icon('arrow-right')}</button>`:'';
    lb.innerHTML=`<figure><img alt=""><figcaption><span class="lc"></span><span class="ln"></span></figcaption></figure>${arrows}<button class="nav lx" type="button" aria-label="Close">${ICE.icon('x')}</button>`;
    main.append(lb);
    const img=$('img',lb),cap=$('.lc',lb),num=$('.ln',lb);
    let i=0;
    const show=k=>{
      i=(k+n)%n;const a=items[i];
      img.onerror=()=>{img.onerror=null;img.src=a.getAttribute('href')};   // wsrv failed: use the original
      img.src=a.dataset.full;img.alt=$('img',a).alt;
      cap.textContent=a.dataset.cap||'';cap.hidden=!a.dataset.cap;
      num.textContent=n>1?`${i+1} / ${n}`:'';
      history.replaceState(history.state,'','#shot-'+(i+1));
      if(n>1)new Image().src=items[(i+1)%n].dataset.full;                 // preload the next one
    };
    const open=k=>{show(k);if(!lb.open)lb.showModal()};
    lb.addEventListener('close',()=>{if(SHOT.test(location.hash))history.replaceState(history.state,'',location.pathname+location.search)});
    items.forEach((a,k)=>a.onclick=e=>{if(e.button||e.metaKey||e.ctrlKey||e.shiftKey||e.altKey)return;e.preventDefault();open(k)});
    lb.onclick=e=>{
      if(e.target===lb||e.target===$('figure',lb))return lb.close();     // backdrop / empty space
      const b=e.target.closest('button');if(!b)return;
      if(b.classList.contains('lx'))lb.close();else show(i+(b.classList.contains('next')?1:-1));
    };
    lb.onkeydown=e=>{const d={ArrowRight:1,ArrowLeft:-1}[e.key];if(d&&n>1){e.preventDefault();show(i+d)}};
    let x0=null;
    lb.onpointerdown=e=>{x0=e.clientX};
    lb.onpointerup=e=>{if(x0===null||n<2)return;const dx=e.clientX-x0;x0=null;if(Math.abs(dx)>40)show(i+(dx<0?1:-1))};

    const fromHash=()=>{
      if(!main.isConnected)return;
      const m=SHOT.exec(location.hash),k=m?+m[1]-1:-1;
      if(items[k])open(k);else if(lb.open&&!m)lb.close();
    };
    ICE.shotHash=fromHash;fromHash();
  };

  /* server address: saved in a cookie for the whole site, so every app page uses it */
  const KEY='ice-host';
  const getHost=()=>{try{const m=document.cookie.match(/(?:^|;\s*)ice-host=([^;]*)/);return m?decodeURIComponent(m[1]):''}catch(_){return ''}};
  const setHost=h=>{try{document.cookie=h?`${KEY}=${encodeURIComponent(h)};path=/;max-age=31536000;SameSite=Lax`:`${KEY}=;path=/;max-age=0`}catch(_){}};
  // "http://192.168.1.20:80/x" -> "192.168.1.20"; keep hostnames, IPv4 and [IPv6]
  const clean=v=>v.trim().replace(/^[a-z]+:\/\//i,'').replace(/[/?#].*$/,'').replace(/:\d*$/,'').replace(/[^\w.\-[\]:]/g,'');
  const services=main=>{
    const input=$('#host',main),cards=$$('.sv[data-port]',main);
    if(!input||!cards.length)return;
    const apply=h=>cards.forEach(c=>{
      const u=`http://${h||'localhost'}:${c.dataset.port}${c.dataset.path}`;
      $('code',c).textContent=u;$('a.ic',c).href=u;$('button.ic',c).dataset.copy=u;
    });
    input.value=getHost();apply(input.value);
    input.oninput=()=>{const h=clean(input.value);setHost(h);apply(h)};
    input.onchange=()=>{input.value=clean(input.value)};
  };

  ICE.pages.app=main=>{
    gallery(main);
    services(main);
    /* compose highlighting (plain text stays readable without JS) */
    const code=$('code.yml',main);
    if(code)code.innerHTML=code.textContent.split('\n').map(yaml).join('\n');
  };
})();

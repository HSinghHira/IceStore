/* IceStore core: cursor background, copy buttons, small-screen notice and the page router.
   Every page is a real HTML file (good for SEO and no-JS). The router only makes moving between
   them smoother: it fetches the next page, swaps #app, updates <head> and the URL. */
(()=>{
  'use strict';
  const ICE=window.ICE=window.ICE||{pages:{}};
  const $=(s,r=document)=>r.querySelector(s), $$=(s,r=document)=>[...r.querySelectorAll(s)];
  const reduced=matchMedia('(prefers-reduced-motion:reduce)').matches;
  ICE.$=$;ICE.$$=$$;ICE.reduced=reduced;

  /* ---- background that follows the cursor ---- */
  const bg=$('.bg');
  if(bg&&!reduced){
    let x=innerWidth*.7,y=innerHeight*.25,tx=x,ty=y,run=false;
    const tick=()=>{
      x+=(tx-x)*.09;y+=(ty-y)*.09;
      bg.style.setProperty('--mx',x.toFixed(1)+'px');bg.style.setProperty('--my',y.toFixed(1)+'px');
      if(Math.abs(tx-x)+Math.abs(ty-y)>.5)requestAnimationFrame(tick);else run=false;
    };
    addEventListener('pointermove',e=>{tx=e.clientX;ty=e.clientY;if(!run){run=true;requestAnimationFrame(tick)}},{passive:true});
  }

  /* ---- copy buttons: data-copy="text" or data-copy-from="#selector" ---- */
  document.addEventListener('click',async e=>{
    const b=e.target.closest('[data-copy],[data-copy-from]');if(!b)return;
    const text=b.dataset.copy!==undefined?b.dataset.copy:($(b.dataset.copyFrom)||{textContent:''}).textContent.trim();
    try{await navigator.clipboard.writeText(text)}
    catch(_){const t=document.createElement('textarea');t.value=text;t.style.cssText='position:fixed;opacity:0';document.body.append(t);t.select();try{document.execCommand('copy')}catch(_){}t.remove()}
    if(b._t)return;
    const old=b.innerHTML;b.innerHTML=ICE.icon('check')+(b.dataset.done||'');b.classList.add('ok');
    b._t=setTimeout(()=>{b.innerHTML=old;b.classList.remove('ok');b._t=0},1600);
  });

  /* ---- offline support: sw.js sits next to the manifest (the site root) ---- */
  if('serviceWorker' in navigator&&(location.protocol==='https:'||location.hostname==='localhost')){
    const m=$('link[rel=manifest]');
    if(m)addEventListener('load',()=>navigator.serviceWorker.register(new URL('sw.js',m.href)).catch(()=>{}));
  }

  /* ---- "/" jumps to the page's search box; Esc clears it ---- */
  document.addEventListener('keydown',e=>{
    const t=e.target;
    if(e.key==='/'&&!e.ctrlKey&&!e.metaKey&&!e.altKey&&!(t.closest&&t.closest('input,textarea,select,[contenteditable]'))){
      const q=$('#app main #q');if(!q)return;
      e.preventDefault();q.scrollIntoView({block:'center',behavior:reduced?'auto':'smooth'});q.focus({preventScroll:true});
    }else if(e.key==='Escape'&&t.id==='q'){
      if(t.value){t.value='';t.dispatchEvent(new Event('input'))}else t.blur();
    }
  });

  /* ---- "best viewed on desktop" notice, small phones only ---- */
  (()=>{
    let seen;try{seen=sessionStorage.getItem('ice-desk')}catch(_){}
    if(innerWidth>480||seen)return;
    const m=document.createElement('div');m.className='mob';m.setAttribute('role','dialog');m.setAttribute('aria-modal','true');m.setAttribute('aria-labelledby','mob-t');
    m.innerHTML=`<div>${ICE.icon('monitor')}<h2 id="mob-t">Best viewed on desktop</h2><p>This site works best on a larger screen. For the full experience, open it on a desktop or laptop.</p><button class="btn p" type="button">View Anyway</button></div>`;
    document.body.append(m);document.body.style.overflow='hidden';
    const b=$('button',m);b.focus();
    b.onclick=()=>{m.remove();document.body.style.overflow='';try{sessionStorage.setItem('ice-desk','1')}catch(_){}};
  })();

  /* ---- router ---- */
  const bar=$('#loadbar'),live=$('#live'),cache=new Map();
  const prog={
    start(){bar.className='load go'},
    done(){bar.className='load end';setTimeout(()=>{bar.className='load'},500)}
  };
  const here=()=>location.pathname+location.search;
  let cur=here(),token=0;
  history.scrollRestoration='manual';

  const target=a=>{
    if(!a||(a.target&&a.target!=='_self')||a.hasAttribute('download')||a.hasAttribute('data-no-route'))return null;
    const u=new URL(a.href,location.href);
    if(u.origin!==location.origin||!/(\.html?|\/)$/.test(u.pathname))return null;
    if(u.pathname+u.search===cur)return null;            // same page: normal hash scroll
    return u;
  };
  const fetchPage=u=>{
    const k=u.pathname+u.search;
    if(!cache.has(k))cache.set(k,fetch(u.pathname+u.search,{credentials:'same-origin'}).then(r=>{if(!r.ok)throw new Error(r.status);return r.text()}).catch(e=>{cache.delete(k);throw e}));
    return cache.get(k);
  };
  const swapHead=doc=>{
    $$('head [data-route]').forEach(n=>n.remove());
    $$('head [data-route]',doc).forEach(n=>document.head.append(n.cloneNode(true)));
    document.title=doc.title;
  };
  const tabs=main=>{
    $$('[role=tablist]',main).forEach(list=>{
      const ts=$$('[role=tab]',list),ps=ts.map(t=>document.getElementById(t.getAttribute('aria-controls')));
      const show=i=>ts.forEach((t,j)=>{t.setAttribute('aria-selected',j===i);t.tabIndex=j===i?0:-1;ps[j].hidden=j!==i});
      ts.forEach((t,i)=>{
        t.onclick=()=>show(i);
        t.onkeydown=e=>{const d={ArrowRight:1,ArrowLeft:-1}[e.key];if(!d)return;e.preventDefault();const j=(i+d+ts.length)%ts.length;show(j);ts[j].focus()};
      });
      const h=ts.findIndex(t=>t.dataset.hash&&'#'+t.dataset.hash===location.hash);
      show(h>-1?h:0);
      if(h>-1)setTimeout(()=>ts[h].scrollIntoView({block:'center'}),60);
    });
  };
  const init=()=>{const m=$('#app main'),f=m&&ICE.pages[m.dataset.page];tabs(m||document);if(f)f(m)};
  ICE.init=init;

  async function go(u,push){
    const mine=++token;prog.start();
    let doc,next;
    try{
      doc=new DOMParser().parseFromString(await fetchPage(u),'text/html');
      next=$('#app',doc);if(!next||!$('main',next))throw new Error('no app');
    }catch(_){location.href=u.href;return}       // anything odd: do a normal page load
    if(mine!==token)return;
    const app=$('#app');
    const apply=()=>{
      if(push){history.replaceState({y:scrollY},'');history.pushState({y:0},'',u.href)}
      cur=here();swapHead(doc);app.innerHTML=next.innerHTML;init();
      const el=u.hash&&document.getElementById(decodeURIComponent(u.hash.slice(1)));
      if(el)el.scrollIntoView({behavior:'auto'});else scrollTo(0,push?0:((history.state||{}).y||0));
      $('#main').focus({preventScroll:true});live.textContent=document.title;
    };
    try{
      if(document.startViewTransition&&!reduced)await document.startViewTransition(apply).updateCallbackDone;
      else{apply();if(!reduced){app.classList.add('enter');setTimeout(()=>app.classList.remove('enter'),400)}}
    }catch(_){location.href=u.href;return}
    prog.done();
  }

  document.addEventListener('click',e=>{
    if(e.defaultPrevented||e.button||e.metaKey||e.ctrlKey||e.shiftKey||e.altKey)return;
    const u=target(e.target.closest('a[href]'));if(!u)return;
    e.preventDefault();go(u,true);
  });
  const warm=e=>{const u=target(e.target.closest&&e.target.closest('a[href]'));if(u)fetchPage(u).catch(()=>{})};
  document.addEventListener('pointerover',warm,{passive:true});
  document.addEventListener('focusin',warm);
  addEventListener('popstate',()=>{if(here()!==cur)go(new URL(location.href),false)});

  // deferred scripts all run before DOMContentLoaded, so wait for it: every page module has registered by then
  if(document.readyState==='complete')init();else addEventListener('DOMContentLoaded',init);
})();

/* App page: screenshot slider, tabs, compose highlighting. */
(()=>{
  const ICE=window.ICE,$=ICE.$,$$=ICE.$$;
  const esc=s=>s.replace(/&/g,'&amp;').replace(/</g,'&lt;');
  const yaml=l=>{
    l=esc(l);
    if(/^\s*#/.test(l))return `<span class="c">${l}</span>`;
    return l.replace(/("[^"]*")/g,'<span class="s">$1</span>').replace(/^(\s*(?:- )?)([\w.-]+)(:)/,'$1<span class="k">$2</span>$3');
  };
  ICE.pages.app=main=>{
    /* slider */
    const sl=$('.sl',main);
    if(sl){
      const n=sl.children.length,dots=$('.dots',main),cnt=$('.cnt',main);
      dots.innerHTML=Array.from({length:n},(_,i)=>`<button type="button" aria-label="Go to screenshot ${i+1}"></button>`).join('');
      const cur=()=>Math.round(sl.scrollLeft/sl.clientWidth);
      const go=i=>sl.scrollTo({left:sl.clientWidth*((i+n)%n),behavior:ICE.reduced?'auto':'smooth'});
      const upd=()=>{const c=cur();$$('button',dots).forEach((b,i)=>b.setAttribute('aria-current',i===c));cnt.textContent=`${c+1} / ${n}`};
      sl.addEventListener('scroll',upd,{passive:true});upd();
      dots.onclick=e=>{const b=e.target.closest('button');if(b)go($$('button',dots).indexOf(b))};
      $('.prev',main).onclick=()=>go(cur()-1);$('.next',main).onclick=()=>go(cur()+1);
      sl.onkeydown=e=>{if(e.key==='ArrowRight'||e.key==='ArrowLeft'){e.preventDefault();go(cur()+(e.key==='ArrowRight'?1:-1))}};
    }
    /* compose highlighting (plain text stays readable without JS) */
    const code=$('code.yml',main);
    if(code)code.innerHTML=code.textContent.split('\n').map(yaml).join('\n');
  };
})();

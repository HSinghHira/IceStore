/* Home page: category filter + live search over the app grid (name, tagline and category). */
(()=>{
  const ICE=window.ICE;
  ICE.pages.home=main=>{
    const q=ICE.$('#q',main),cards=ICE.$$('.card',main),none=ICE.$('#none',main),count=ICE.$('#count',main);
    if(!q)return;
    const chips=ICE.$$('.cat',main),total=cards.length;
    let cat='';
    const run=()=>{
      const v=q.value.trim().toLowerCase(),words=v.split(/\s+/).filter(Boolean);
      let n=0;
      cards.forEach(c=>{
        const hit=(!cat||c.dataset.cat===cat)&&words.every(w=>c.dataset.q.includes(w));
        c.hidden=!hit;if(hit)n++;
      });
      none.hidden=n>0;
      ICE.$('#none-t',main).textContent=cat&&!v?`No apps in ${cat} yet.`:`No app matches that search${cat?` in ${cat}`:''}.`;
      /* "Request it" opens the request form with the search filled in */
      const req=ICE.$('#none-req',main);
      if(req){const u=new URL(req.href);u.searchParams.set('app',q.value.trim());u.searchParams.set('title',`[App request] ${q.value.trim()}`);req.href=u}
      count.textContent=v||cat?`${n} of ${total} apps`:`${total} apps and counting.`;
    };
    chips.forEach(b=>b.onclick=()=>{
      cat=b.dataset.cat;
      chips.forEach(x=>x.setAttribute('aria-pressed',x===b));
      run();
    });
    q.addEventListener('input',run);
    /* ?cat=Media (the "See all" link on app pages) starts with that category picked */
    const want=new URLSearchParams(location.search).get('cat');
    const pre=want&&chips.find(b=>b.dataset.cat.toLowerCase()===want.toLowerCase());
    if(pre)pre.click();
    /* sort: a custom dropdown (button + listbox). A–Z is the built order; the rest sort by a
       data-* number, biggest first, and ties stay A–Z. Keyboard: arrows, Home/End, Enter, Esc. */
    const so=ICE.$('#sort',main),grid=cards[0]&&cards[0].parentNode,az=cards.slice();
    if(so&&grid){
      const btn=ICE.$('.so-b',so),menu=ICE.$('.so-m',so),val=ICE.$('#sort-v',so),opts=ICE.$$('[role=option]',so);
      let cur=0;
      const focus=i=>{cur=(i+opts.length)%opts.length;opts.forEach((o,j)=>o.classList.toggle('on',j===cur));menu.setAttribute('aria-activedescendant',opts[cur].id)};
      opts.forEach((o,i)=>{o.id='sort-o'+i;o.onmousemove=()=>focus(i);o.onclick=()=>pick(i)});
      const open=on=>{
        menu.hidden=!on;btn.setAttribute('aria-expanded',on);so.classList.toggle('open',on);
        if(on){focus(opts.findIndex(o=>o.getAttribute('aria-selected')==='true'));menu.focus()}
      };
      const pick=i=>{
        const o=opts[i],k=o.dataset.v;
        opts.forEach(x=>x.setAttribute('aria-selected',x===o));
        val.textContent=o.textContent;open(false);btn.focus();
        const list=k==='name'?az:k==='name-desc'?az.slice().reverse()
          :az.slice().sort((a,b)=>(+b.dataset[k]||0)-(+a.dataset[k]||0));
        grid.append(...list);
      };
      btn.onmousedown=ev=>{if(!menu.hidden)ev.preventDefault()}; /* keep focus so the click below can close it */
      btn.onclick=()=>open(menu.hidden);
      btn.onkeydown=ev=>{if(ev.key==='ArrowDown'||ev.key==='ArrowUp'){ev.preventDefault();open(true)}};
      menu.onkeydown=ev=>{
        const k=ev.key;
        if(k==='ArrowDown'||k==='ArrowUp'){ev.preventDefault();focus(cur+(k==='ArrowDown'?1:-1))}
        else if(k==='Home'||k==='End'){ev.preventDefault();focus(k==='Home'?0:opts.length-1)}
        else if(k==='Enter'||k===' '){ev.preventDefault();pick(cur)}
        else if(k==='Escape'){ev.preventDefault();open(false);btn.focus()}
        else if(k==='Tab')open(false);
      };
      /* close when focus or a click leaves the dropdown */
      so.addEventListener('focusout',ev=>{if(!so.contains(ev.relatedTarget))open(false)});
    }
  };
})();

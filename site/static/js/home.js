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
    /* sort: A–Z (the built order), Newest or Recently updated; ties stay A–Z */
    const sort=ICE.$('#sort',main),grid=cards[0]&&cards[0].parentNode,az=cards.slice();
    if(sort&&grid)sort.onchange=()=>{
      const k=sort.value,list=k==='name'?az:az.slice().sort((a,b)=>(+b.dataset[k]||0)-(+a.dataset[k]||0));
      grid.append(...list);
    };
  };
})();

/* Home page: the search box opens apps/?q=… (a plain GET form without JS).
   Apps page: category filter, live search (name, tagline, category, bundle), sort, and a loader
   that reveals the matching cards a few rows at a time as you scroll. Every card is in the HTML,
   so without JS (and for search engines) they all show. ?q=, ?cat= and ?sort= set the start state. */
(()=>{
  const ICE=window.ICE;
  /* search.json, fetched once the first time the home search box gets focus */
  let index;
  const loadIndex=()=>index||(index=fetch(new URL('search.json',document.querySelector('link[rel=manifest]').href))
    .then(r=>r.ok?r.json():[]).then(d=>d.map(a=>({...a,q:[a.n,a.d,a.c,...(a.b||[])].join(' ').toLowerCase()}))).catch(()=>{index=null;return []}));
  /* the same resized WebP icon URL the build uses (wsrv() in build.py), so it is already cached */
  const cdn=u=>'https://wsrv.nl/?'+new URLSearchParams({url:u,w:192,h:192,output:'webp',q:85});
  const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'})[c]);
  /* Search matching, shared by both pages. matcher(query) returns a function of (name, text) that
     gives how well an app matches, lower is better, or -1 for no match:
       0 the name starts with the search     1 a word in the name starts with it
       2 the name has it anywhere            3 every word is in the name, tagline, category or bundle
       4-5 the name is a near miss: a typo like "aar" for "arr", "jelyfin" or "gost". For 3-4 letters
         the first and last letters must match, with one letter changed (4), or added or swapped (5)
         inside; longer searches allow 1 edit (2 from 8 letters). */
  const norm=s=>s.toLowerCase().replace(/[^a-z0-9]/g,'');
  const within=(q,t,k)=>{  /* is q within k edits of some part of t? (Sellers' algorithm) */
    let prev=new Array(t.length+1).fill(0);
    for(let i=1;i<=q.length;i++){
      const row=[i];
      for(let j=1;j<=t.length;j++)row[j]=Math.min(prev[j]+1,row[j-1]+1,prev[j-1]+(q[i-1]!==t[j-1]));
      prev=row;
    }
    return Math.min(...prev)<=k;
  };
  const matcher=raw=>{
    const v=raw.trim().toLowerCase(),words=v.split(/\s+/).filter(Boolean),nq=norm(v);
    let near=()=>-1;
    if(nq.length>=3&&nq.length<5){
      /* a changed letter ("aar" in "sonarr") ranks above an added or swapped one ("aar" in "garage") */
      const sub=[],other=[];
      for(let i=1;i<nq.length;i++){other.push(nq.slice(0,i)+'.'+nq.slice(i));if(i<nq.length-1)sub.push(nq.slice(0,i)+'.'+nq.slice(i+1))}
      for(let i=0;i<nq.length-1;i++)other.push(nq.slice(0,i)+nq[i+1]+nq[i]+nq.slice(i+2));
      const r1=new RegExp(sub.join('|')),r2=new RegExp(other.join('|'));
      near=n=>r1.test(n)?4:r2.test(n)?5:-1;
    }else if(nq.length>=5)near=n=>within(nq,n,nq.length<8?1:2)?4:-1;
    return (name,text)=>{
      if(!v)return 0;
      name=name.toLowerCase();
      if(name.startsWith(v))return 0;
      if(name.split(/[^a-z0-9]+/).some(w=>w&&w.startsWith(v)))return 1;
      const nn=norm(name);
      if(nq&&nn.includes(nq))return 2;
      if(words.every(w=>text.includes(w)))return 3;
      return near(nn);
    };
  };
  ICE.matcher=matcher;
  /* wrap the first match of each word in <mark> */
  const hl=(s,words)=>{let o=esc(s);words.forEach(w=>{const i=o.toLowerCase().indexOf(esc(w));if(i>=0)o=o.slice(0,i)+'<mark>'+o.slice(i,i+esc(w).length)+'</mark>'+o.slice(i+esc(w).length)});return o};

  ICE.pages.home=main=>{
    const f=ICE.$('#hq',main);if(!f)return;
    const q=ICE.$('#q',f),list=ICE.$('#fs-list',f);
    let items=[],cur=-1,seq=0;
    const go=href=>{const u=new URL(href,location.href);ICE.go?ICE.go(u):location.href=u.href};
    const all=()=>{const u=new URL(f.getAttribute('action'),location.href),v=q.value.trim();if(v)u.searchParams.set('q',v);return u.href};
    const close=()=>{list.hidden=true;q.setAttribute('aria-expanded','false');q.removeAttribute('aria-activedescendant');cur=-1};
    const mark=i=>{
      items=ICE.$$('li[role=option]',list);if(!items.length)return;
      cur=(i+items.length)%items.length;
      items.forEach((x,j)=>{x.classList.toggle('on',j===cur);x.setAttribute('aria-selected',j===cur)});
      q.setAttribute('aria-activedescendant',items[cur].id);
      items[cur].scrollIntoView({block:'nearest'});
    };
    /* best matches first (see matcher), then the most GitHub stars */
    const show=async()=>{
      const v=q.value.trim().toLowerCase(),mine=++seq;
      if(!v){close();return}
      const data=await loadIndex();if(mine!==seq)return;
      const words=v.split(/\s+/).filter(Boolean),m=matcher(v);
      const hits=data.map(a=>[m(a.n,a.q),-a.k,a]).filter(x=>x[0]>=0)
        .sort((x,y)=>x[0]-y[0]||x[1]-y[1]).map(x=>x[2]);
      const root=new URL('./',document.querySelector('link[rel=manifest]').href).href;
      list.innerHTML=hits.length
        ?hits.slice(0,6).map((a,i)=>`<li role="option" id="fs-o${i}" aria-selected="false" style="--i:${i}"><a href="${root}app/${esc(a.s)}/" tabindex="-1">`
          +`<span class="ph" style="--h:${[...a.n].reduce((s,c)=>s+c.charCodeAt(0),0)%40}" aria-hidden="true">${esc(a.n[0].toUpperCase())}`
          +(a.f?`<img src="${esc(a.w?cdn(f.dataset.base+a.f):root+a.f)}" data-f="${esc(root+a.f)}" alt="" onerror="if(this.dataset.f&&this.src!==this.dataset.f){this.src=this.dataset.f;this.removeAttribute('data-f')}else this.remove()">`:'')+'</span>'
          +`<span class="t"><b>${hl(a.n,words)}</b><small>${esc(a.d)}</small></span><em>${esc(a.c)}</em></a></li>`).join('')
          +`<li role="option" id="fs-o${Math.min(hits.length,6)}" class="all" aria-selected="false"><a href="${esc(all())}" tabindex="-1">See all ${hits.length} result${hits.length>1?'s':''} for “${esc(q.value.trim())}” →</a></li>`
        :`<li class="nil">No app matches “${esc(q.value.trim())}”. <a href="${esc(all())}">Browse all apps</a></li>`;
      list.hidden=false;q.setAttribute('aria-expanded','true');cur=-1;items=ICE.$$('li[role=option]',list);
    };
    q.addEventListener('focus',()=>{loadIndex();if(q.value.trim())show()});
    q.addEventListener('input',show);
    q.addEventListener('keydown',ev=>{
      if(list.hidden)return;
      if(ev.key==='ArrowDown'||ev.key==='ArrowUp'){ev.preventDefault();mark(cur+(ev.key==='ArrowDown'?1:-1))}
      else if(ev.key==='Escape'&&q.value){ev.stopPropagation();close()}
    });
    f.addEventListener('submit',ev=>{
      ev.preventDefault();
      const a=cur>=0&&items[cur]&&ICE.$('a',items[cur]);
      close();go(a?a.href:all());
    });
    f.addEventListener('focusout',ev=>{if(!f.contains(ev.relatedTarget))setTimeout(close,120)});
    list.addEventListener('mousedown',ev=>ev.preventDefault()); /* keep focus in the box while clicking a result */

    if(ICE.reduced)return;
    /* the placeholder types out example searches while the box is empty and not in use */
    const ideas=['photos','notes','Jellyfin','budget','backups','AI chat','recipes','PDF'],base=q.placeholder;
    let k=0;
    const type=(word,i,back)=>{
      if(!q.isConnected)return;                      /* the router left the page */
      if(document.activeElement===q||q.value){q.placeholder=base;q.classList.remove('typing');setTimeout(()=>type(ideas[k],0,false),1500);return}
      q.classList.add('typing');
      q.placeholder=`Try “${word.slice(0,i)}”`;
      if(!back&&i<word.length)setTimeout(()=>type(word,i+1,false),75);
      else if(!back)setTimeout(()=>type(word,i,true),1700);
      else if(i>0)setTimeout(()=>type(word,i-1,true),35);
      else{k=(k+1)%ideas.length;setTimeout(()=>type(ideas[k],0,false),300)}
    };
    setTimeout(()=>type(ideas[0],0,false),1200);

    /* the numbers in the stats line count up the first time they come into view */
    const nums=ICE.$$('.finder .sub b',main);
    if(nums.length&&'IntersectionObserver' in window){
      const io=new IntersectionObserver(es=>{
        if(!es.some(x=>x.isIntersecting))return;
        io.disconnect();
        nums.forEach(b=>{
          const to=+b.textContent,t0=performance.now();if(!to)return;
          const step=t=>{const p=Math.min(1,(t-t0)/900);b.textContent=Math.round(to*(1-Math.pow(1-p,3)));if(p<1)requestAnimationFrame(step)};
          b.textContent='0';requestAnimationFrame(step);
        });
      });
      io.observe(nums[0]);
    }
  };

  let io;  /* one scroll observer at a time: the router can open the apps page again */
  ICE.pages.apps=main=>{
    const q=ICE.$('#q',main),grid=ICE.$('#grid',main),more=ICE.$('#more',main),none=ICE.$('#none',main),count=ICE.$('#count',main);
    if(!q||!grid)return;
    if(io)io.disconnect();
    const cards=ICE.$$('.card',grid),chips=ICE.$$('.cat',main),total=cards.length,az=cards.slice();
    const BATCH=24,params=new URLSearchParams(location.search);
    let cat='',shown=BATCH,seen=new Set(),sorted=az;

    /* which cards match; while searching, the best matches go first (in the chosen sort within each
       level), then show the first `shown` of them */
    const render=reset=>{
      if(reset){shown=BATCH;seen=new Set()}
      const v=q.value.trim().toLowerCase(),m=matcher(v);
      const lvl=new Map(sorted.map(c=>[c,(!cat||c.dataset.cat===cat)?m(c.dataset.name,c.dataset.q):-1]));
      if(reset)grid.append(...(v?sorted.slice().sort((a,b)=>((lvl.get(a)+1)||99)-((lvl.get(b)+1)||99)):sorted));
      let n=0,fresh=0;
      ICE.$$('.card',grid).forEach(c=>{
        const hit=lvl.get(c)>=0;
        const show=hit&&n<shown;
        if(hit)n++;
        c.hidden=!show;
        if(show&&!seen.has(c)){
          seen.add(c);
          if(!reset&&!ICE.reduced){c.style.setProperty('--d',(fresh++%BATCH)*18+'ms');c.classList.remove('in');void c.offsetWidth;c.classList.add('in')}
        }
      });
      more.hidden=n<=shown;
      none.hidden=n>0;
      ICE.$('#none-t',main).textContent=cat&&!v?`No apps in ${cat} yet.`:`No app matches that search${cat?` in ${cat}`:''}.`;
      /* "Request it" opens the request form with the search filled in */
      const req=ICE.$('#none-req',main);
      if(req){const u=new URL(req.href);u.searchParams.set('app',q.value.trim());u.searchParams.set('title',`[App request] ${q.value.trim()}`);req.href=u}
      count.textContent=v||cat?`${n} of ${total} apps`:`${total} apps`;
      /* keep the address in step, so a filtered list can be shared or reloaded */
      const u=new URL(location.href);
      v?u.searchParams.set('q',q.value.trim()):u.searchParams.delete('q');
      cat?u.searchParams.set('cat',cat):u.searchParams.delete('cat');
      if(u.href!==location.href)history.replaceState(history.state,'',u.href);
      if(!more.hidden&&io){io.unobserve(more);io.observe(more)}  /* still on screen? load the next batch */
    };

    /* the loader: when the skeleton row comes near the viewport, reveal the next batch */
    if('IntersectionObserver' in window){
      io=new IntersectionObserver(es=>{if(es.some(x=>x.isIntersecting)&&!more.hidden){shown+=BATCH;render(false)}},{rootMargin:'0px 0px 600px 0px'});
      io.observe(more);
    }else shown=Infinity;

    chips.forEach(b=>b.onclick=()=>{
      cat=b.dataset.cat;
      chips.forEach(x=>x.setAttribute('aria-pressed',x===b));
      render(true);
    });
    q.addEventListener('input',()=>render(true));

    /* sort: a custom dropdown (button + listbox). A–Z is the built order; the rest sort by a
       data-* number, biggest first, and ties stay A–Z. Keyboard: arrows, Home/End, Enter, Esc. */
    const so=ICE.$('#sort',main);
    const btn=ICE.$('.so-b',so),menu=ICE.$('.so-m',so),val=ICE.$('#sort-v',so),opts=ICE.$$('[role=option]',so);
    let cur=0;
    const focus=i=>{cur=(i+opts.length)%opts.length;opts.forEach((o,j)=>o.classList.toggle('on',j===cur));menu.setAttribute('aria-activedescendant',opts[cur].id)};
    const open=on=>{
      menu.hidden=!on;btn.setAttribute('aria-expanded',on);so.classList.toggle('open',on);
      if(on){focus(opts.findIndex(o=>o.getAttribute('aria-selected')==='true'));menu.focus()}
    };
    const pick=(i,user)=>{
      const o=opts[i],k=o.dataset.v;
      opts.forEach(x=>x.setAttribute('aria-selected',x===o));
      val.textContent=o.textContent;
      if(user){
        open(false);btn.focus();ICE.cookie('ice-sort',k);  /* remember the choice for next visit */
        const u=new URL(location.href);u.searchParams.delete('sort');history.replaceState(history.state,'',u.href);
      }
      sorted=k==='name'?az:k==='name-desc'?az.slice().reverse()
        :az.slice().sort((a,b)=>(+b.dataset[k]||0)-(+a.dataset[k]||0));
      render(true);
    };
    opts.forEach((o,i)=>{o.id='sort-o'+i;o.onmousemove=()=>focus(i);o.onclick=()=>pick(i,true)});
    btn.onmousedown=ev=>{if(!menu.hidden)ev.preventDefault()}; /* keep focus so the click below can close it */
    btn.onclick=()=>open(menu.hidden);
    btn.onkeydown=ev=>{if(ev.key==='ArrowDown'||ev.key==='ArrowUp'){ev.preventDefault();open(true)}};
    menu.onkeydown=ev=>{
      const k=ev.key;
      if(k==='ArrowDown'||k==='ArrowUp'){ev.preventDefault();focus(cur+(k==='ArrowDown'?1:-1))}
      else if(k==='Home'||k==='End'){ev.preventDefault();focus(k==='Home'?0:opts.length-1)}
      else if(k==='Enter'||k===' '){ev.preventDefault();pick(cur,true)}
      else if(k==='Escape'){ev.preventDefault();open(false);btn.focus()}
      else if(k==='Tab')open(false);
    };
    so.addEventListener('focusout',ev=>{if(!so.contains(ev.relatedTarget))open(false)});

    /* start state: ?q= and ?cat= from the link, then the sort from ?sort=, the ice-sort cookie, or Most stars */
    if(params.get('q'))q.value=params.get('q');
    const want=(params.get('cat')||'').toLowerCase();
    const pre=want&&chips.find(b=>b.dataset.cat.toLowerCase()===want);
    if(pre){cat=pre.dataset.cat;chips.forEach(x=>x.setAttribute('aria-pressed',x===pre))}
    const by=v=>opts.findIndex(o=>o.dataset.v===v);
    const start=[by(params.get('sort')),by(ICE.cookie('ice-sort')),by('stars')].find(i=>i>=0);
    pick(start>=0?start:0,false);
  };
})();

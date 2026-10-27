/* Badge page: show the badge picked in the query (?=affine, ?app=affine or ?affine), and search the app list. */
(()=>{
  const ICE=window.ICE,$=ICE.$,$$=ICE.$$;
  const pick=()=>{
    const p=new URLSearchParams(location.search);
    const v=p.get('')||p.get('app')||[...p.keys()][0]||'';
    return v.trim().toLowerCase();
  };
  ICE.pages.badge=main=>{
    const data=JSON.parse($('#bdata',main).textContent);
    const slug=pick(),name=data.apps[slug],sel=$('#bsel',main),none=$('#bnone',main);
    if(name){
      const img=`${data.base}app-badge/${slug}.svg`,page=`${data.base}app/${slug}/`,alt=`${name} on ${data.site}`;
      const a=$('#bimg',main);a.href=`../app/${slug}/`;
      Object.assign($('img',a),{src:`${slug}.svg`,alt});
      $('#b-md code',main).textContent=`[![${alt}](${img})](${page})`;
      $('#b-html code',main).textContent=`<a href="${page}"><img src="${img}" alt="${alt}" height="80"></a>`;
      $('#b-url code',main).textContent=img;
      sel.hidden=false;none.hidden=true;
      $$('.card',main).forEach(c=>c.toggleAttribute('aria-current',c.getAttribute('href')==='?='+slug));
      document.title=`${name} badge – ${data.site}`;
    }else{
      sel.hidden=true;
      none.hidden=!slug;
      if(slug)none.textContent=`No app called "${slug}". Pick one below.`;
    }
    /* search */
    const q=$('#q',main),cards=$$('.card',main),empty=$('#none',main);
    q.addEventListener('input',()=>{
      const v=q.value.trim().toLowerCase();let n=0;
      cards.forEach(c=>{const hit=!v||c.dataset.name.includes(v);c.hidden=!hit;if(hit)n++});
      empty.hidden=n>0;
    });
  };
})();

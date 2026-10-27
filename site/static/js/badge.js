/* Badge page: show the badge picked in the query (?=affine, ?app=affine or ?affine), and search the app list.
   Themes: dark (app-badge/<slug>.svg), light (app-badge/light/<slug>.svg), auto (follows the reader's theme). */
(()=>{
  const ICE=window.ICE,$=ICE.$,$$=ICE.$$;
  const pick=()=>{
    const p=new URLSearchParams(location.search);
    const v=p.get('')||p.get('app')||[...p.keys()][0]||'';
    return v.trim().toLowerCase();
  };
  const NOTES={
    dark:'For READMEs and pages with a dark background.',
    light:'For READMEs and pages with a white background.',
    auto:'Switches with the reader\'s theme. The Markdown works on GitHub; the HTML works anywhere.'
  };
  let theme='dark';
  try{theme=localStorage.getItem('ice-badge-theme')||'dark'}catch(_){}
  ICE.pages.badge=main=>{
    const data=JSON.parse($('#bdata',main).textContent);
    const slug=pick(),name=data.apps[slug],sel=$('#bsel',main),prev=$('#bprev',main),none=$('#bnone',main);
    if(name){
      const dark=`${data.base}app-badge/${slug}.svg`,light=`${data.base}app-badge/light/${slug}.svg`;
      const page=`${data.base}app/${slug}/`,alt=`${name} on ${data.site}`;
      const a=$('#bimg',main);a.href=`../app/${slug}/`;a.setAttribute('aria-label',alt);
      Object.assign($('.bs-d',a),{src:`${slug}.svg`,alt:''});
      Object.assign($('.bs-l',a),{src:`light/${slug}.svg`,alt:''});
      const md=(img,suffix='')=>`[![${alt}](${img}${suffix})](${page})`;
      const html=img=>`<a href="${page}"><img src="${img}" alt="${alt}" height="80"></a>`;
      const show=t=>{
        theme=NOTES[t]?t:'dark';
        try{localStorage.setItem('ice-badge-theme',theme)}catch(_){}
        prev.dataset.theme=theme;$('#bnote',main).textContent=NOTES[theme];
        $$('.bthm button',main).forEach(b=>b.setAttribute('aria-checked',b.dataset.t===theme));
        const img=theme==='light'?light:dark;
        $('#b-md code',main).textContent=theme==='auto'?md(dark,'#gh-dark-mode-only')+'\n'+md(light,'#gh-light-mode-only'):md(img);
        $('#b-html code',main).textContent=theme==='auto'
          ?`<a href="${page}"><picture><source media="(prefers-color-scheme: light)" srcset="${light}"><img src="${dark}" alt="${alt}" height="80"></picture></a>`
          :html(img);
        $('#b-url code',main).textContent=theme==='auto'?dark+'\n'+light:img;
      };
      $('.bthm',main).onclick=e=>{const b=e.target.closest('button');if(b)show(b.dataset.t)};
      $('.bthm',main).onkeydown=e=>{
        const d={ArrowRight:1,ArrowLeft:-1}[e.key];if(!d)return;e.preventDefault();
        const bs=$$('.bthm button',main),j=(bs.findIndex(b=>b.dataset.t===theme)+d+bs.length)%bs.length;
        show(bs[j].dataset.t);bs[j].focus();
      };
      show(theme);
      sel.hidden=prev.hidden=false;none.hidden=true;
      $$('.card',main).forEach(c=>c.toggleAttribute('aria-current',c.getAttribute('href')==='?='+slug));
      document.title=`${name} badge – ${data.site}`;
    }else{
      sel.hidden=prev.hidden=true;
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

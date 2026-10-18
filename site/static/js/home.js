/* Home page: live search over the app grid. */
(()=>{
  const ICE=window.ICE;
  ICE.pages.home=main=>{
    const q=ICE.$('#q',main),cards=ICE.$$('.card',main),none=ICE.$('#none',main),count=ICE.$('#count',main);
    if(!q)return;
    const total=cards.length;
    q.addEventListener('input',()=>{
      const v=q.value.trim().toLowerCase();let n=0;
      cards.forEach(c=>{const hit=!v||c.dataset.name.includes(v);c.hidden=!hit;if(hit)n++});
      none.hidden=n>0;count.textContent=v?`${n} of ${total} apps`:`${total} apps and counting.`;
    });
  };
})();

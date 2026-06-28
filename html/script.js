/* ============================================================
   lr_properties NUI — dark navy theme. SVG icons, dashboard,
   bottom decoration bar. If you rename the folder, change RESOURCE.
   ============================================================ */
const RESOURCE = 'lr_properties';
const $  = (s) => document.querySelector(s);
const el = (t, c) => { const e = document.createElement(t); if (c) e.className = c; return e; };
const post = (n, b) => fetch(`https://${RESOURCE}/${n}`, {
    method:'POST', headers:{'Content-Type':'application/json; charset=UTF-8'}, body:JSON.stringify(b||{})
}).catch(()=>{});

/* ---------------- SVG icon library ---------------- */
const S = (i) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${i}</svg>`;
const ICONS = {
    chair:S('<path d="M7 4v8h10V4M7 12v7M17 12v7M5 12h14"/>'),
    table:S('<path d="M3 9h18M5 9v10M19 9v10M4 9l2-4h12l2 4"/>'),
    couch:S('<path d="M4 11V8a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3M3 11a2 2 0 0 1 2 2v3h14v-3a2 2 0 0 1 2-2M5 16v2M19 16v2"/>'),
    bed:S('<path d="M3 7v12M3 12h18v7M21 12V9a2 2 0 0 0-2-2H9v5M6 10.5h.01"/>'),
    lamp:S('<path d="M9 2h6l2 7H7zM12 9v8M8 21h8"/>'),
    tv:S('<rect x="3" y="5" width="18" height="12" rx="2"/><path d="M8 21h8M12 17v4"/>'),
    pc:S('<rect x="2" y="4" width="20" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>'),
    speaker:S('<rect x="6" y="3" width="12" height="18" rx="2"/><circle cx="12" cy="14" r="3"/><path d="M12 7h.01"/>'),
    plant:S('<path d="M12 21V11M12 11C12 7 9 5 6 5c0 4 3 6 6 6M12 11c0-3 2-5 5-5 0 3-2 5-5 5M8 21h8"/>'),
    tree:S('<path d="M12 22v-5M12 17l-4-3h2.5L7 10h2L7 6h10l-2 4h2l-3.5 4H16z"/>'),
    fridge:S('<rect x="6" y="2" width="12" height="20" rx="2"/><path d="M6 10h12M9 5v2M9 13v3"/>'),
    pot:S('<path d="M5 10h14v6a3 3 0 0 1-3 3H8a3 3 0 0 1-3-3zM3 10h18M8 7c0-1 1-1 1-2M12 7c0-1 1-1 1-2"/>'),
    sink:S('<path d="M4 11h16M6 11v5a3 3 0 0 0 3 3h6a3 3 0 0 0 3-3v-5M12 11V6a2 2 0 0 1 2-2h3"/>'),
    barrel:S('<path d="M7 3h10v18H7zM5 8h14M5 16h14M7 3c-1 6-1 12 0 18M17 3c1 6 1 12 0 18"/>'),
    crate:S('<rect x="4" y="4" width="16" height="16" rx="1"/><path d="M4 9h16M4 15h16M9 4v16M15 4v16"/>'),
    fence:S('<path d="M5 21V7l2-3 2 3v14M15 21V7l2-3 2 3v14M3 11h18M3 15h18"/>'),
    sign:S('<rect x="3" y="4" width="18" height="11" rx="2"/><path d="M12 15v6M8 21h8M7 8h10M7 11h6"/>'),
    camera:S('<rect x="3" y="7" width="18" height="13" rx="2"/><circle cx="12" cy="13" r="3.5"/><path d="M8 7l1.5-3h5L16 7"/>'),
    books:S('<path d="M5 4h5v16H5zM10 6h5l1 14-6-1zM5 16h5"/>'),
    rug:S('<rect x="3" y="6" width="18" height="12" rx="1"/><path d="M6 6v12M18 6v12M3 9h3M18 9h3M3 15h3M18 15h3"/>'),
    mirror:S('<rect x="7" y="3" width="10" height="14" rx="5"/><path d="M9 21h6M12 17v4"/>'),
    clock:S('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),
    painting:S('<rect x="3" y="4" width="18" height="14" rx="1"/><path d="M7 14l3-4 3 3 2-2 2 3M12 18v3M9 21h6"/>'),
    cup:S('<path d="M5 8h11v6a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4zM16 9h2a2 2 0 0 1 0 6h-2M4 21h12"/>'),
    dumbbell:S('<path d="M4 9v6M7 7v10M17 7v10M20 9v6M7 12h10"/>'),
    car:S('<path d="M3 13l2-5h14l2 5v5h-2M3 13v5h2M3 13h18M7 18a1.5 1.5 0 1 0 .01 0M17 18a1.5 1.5 0 1 0 .01 0"/>'),
    fan:S('<circle cx="12" cy="12" r="2"/><path d="M12 10c0-4 4-5 4-2s-2 4-4 4M12 14c0 4-4 5-4 2s2-4 4-4M14 12c4 0 5 4 2 4s-4-2-4-4M10 12c-4 0-5-4-2-4s4 2 4 4"/>'),
    safe:S('<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="11" cy="12" r="3.5"/><path d="M11 12h.01M18 9v6"/>'),
    shirt:S('<path d="M8 3l4 2 4-2 4 4-3 2v10H7V9L4 7z"/>'),
    bin:S('<path d="M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13M10 11v6M14 11v6"/>'),
    cone:S('<path d="M10 4h4l3 16H7zM8.5 11h7M7.5 16h9M4 20h16"/>'),
    floor:S('<rect x="3" y="3" width="18" height="18" rx="1"/><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/>'),
    brief:S('<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M3 13h18"/>'),
    bulb:S('<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-4 10c1 1 1 2 1 3h6c0-1 0-2 1-3a6 6 0 0 0-4-10z"/>'),
    box:S('<path d="M21 8l-9-5-9 5 9 5 9-5zM3 8v8l9 5 9-5V8M12 13v8"/>'),
    plus:S('<path d="M12 5v14M5 12h14"/>'),
    info:S('<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>'),
    check:S('<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>'),
    warn:S('<path d="M12 3l9 16H3zM12 10v4M12 17h.01"/>'),
    cog:S('<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4 12H2M22 12h-2M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"/>'),
    key:S('<circle cx="8" cy="8" r="4"/><path d="M11 11l8 8M16 16l2-2M19 19l2-2"/>'),
    users:S('<circle cx="9" cy="8" r="3"/><path d="M3 20c0-3 3-5 6-5s6 2 6 5M16 6a3 3 0 0 1 0 6M18 20c0-2-1-3-2-4"/>'),
    ticket:S('<path d="M3 8a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2 2 2 0 0 0 0 4 2 2 0 0 1-2 2H5a2 2 0 0 1-2-2 2 2 0 0 0 0-4zM13 6v12"/>'),
    door:S('<path d="M5 21V4a1 1 0 0 1 1-1h9a1 1 0 0 1 1 1v17M5 21h13M14 12h.01"/>'),
    lock:S('<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>'),
    unlock:S('<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 7.5-2"/>'),
    money:S('<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/><path d="M6 12h.01M18 12h.01"/>'),
    enter:S('<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3"/>'),
    tag:S('<path d="M3 12V5a2 2 0 0 1 2-2h7l9 9-9 9zM8 8h.01"/>'),
    paint:S('<path d="M3 9h18V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2zM7 9v3a2 2 0 0 0 2 2h2v3a2 2 0 0 0 4 0v-2"/>'),
    trash:S('<path d="M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13"/>'),
    pin:S('<path d="M12 21s7-6 7-11a7 7 0 1 0-14 0c0 5 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>'),
    mask:S('<path d="M4 6h16v6a8 8 0 0 1-16 0zM9 12h.01M15 12h.01M9 16c1 1 5 1 6 0"/>'),
    music:S('<circle cx="7" cy="18" r="2"/><circle cx="18" cy="16" r="2"/><path d="M9 18V6l11-2v12"/>'),
};
const CAT_ICON = { barrier:'fence', floor:'floor', table:'table', seating:'chair', decor:'painting',
    light:'lamp', bar:'cup', kitchen:'pot', electronics:'tv', home:'bed', office:'brief',
    gym:'dumbbell', warehouse:'crate', outdoor:'tree', qbshell:'door', shell:'box', custom:'paint',
    apartment:'door', garage:'car', clubhouse:'users', illegal:'mask', entertainment:'music', workshop:'cog' };
const KEYWORDS = [
    [['couch','sofa','armchair','bean'],'couch'],[['chair','stool','seat'],'chair'],
    [['table','desk','workbench','bench'],'table'],[['bed','mattress'],'bed'],
    [['lamp','neon','lantern','ceiling','light','bulb'],'lamp'],[['tv','television','screen'],'tv'],
    [['pc','laptop','computer','keyboard','monitor','printer'],'pc'],[['speaker','boombox','dj','radio'],'speaker'],
    [['plant','flower'],'plant'],[['tree','parasol','umbrella'],'tree'],[['fridge','freezer'],'fridge'],
    [['oven','pot','pan','stove','kitch','microwave','toaster','blender'],'pot'],[['sink','bath','shower','toilet','towel'],'sink'],
    [['barrel','canister','gas'],'barrel'],[['crate','pallet','container'],'crate'],[['box','cardbox'],'box'],
    [['fence','wall','barrier','gate','railing','scaffold','sheeting'],'fence'],[['sign','menu','board','whiteboard'],'sign'],
    [['camera','cctv'],'camera'],[['book'],'books'],[['rug','mat'],'rug'],[['mirror'],'mirror'],[['clock'],'clock'],
    [['paint','statue','vase','candle'],'painting'],[['cup','mug','coffee','beer','bar','bottle','till','register'],'cup'],
    [['weight','dumbbell','barbell','treadmill','bike','muscle','boxing','yoga','gym'],'dumbbell'],
    [['car','forklift','engine','hoist','lift','jack','generator','compressor'],'car'],[['fan','aircon'],'fan'],
    [['safe','locker','vault'],'safe'],[['ward','dressing','drawer'],'shirt'],[['bin','dumpster','trash'],'bin'],[['cone','arrow barrier'],'cone'],
];
function iconKeyFor(item){
    const t=((item.name||'')+' '+(item.model||'')+' '+(item.cat||'')).toLowerCase();
    for (const [keys,ic] of KEYWORDS){ for (const k of keys){ if (t.includes(k)) return ic; } }
    return CAT_ICON[item.cat] || 'box';
}
const iconSVG = (k) => ICONS[k] || ICONS.box;

/* ---------------- prop thumbnails (image pack / CDN -> SVG fallback) ---------------- */
let THUMBS = { enabled:false, localPack:true, cdn:'' };
function joaat(str){ let h=0; str=(str||'').toLowerCase();
    for(let i=0;i<str.length;i++){ h=(h+str.charCodeAt(i))>>>0; h=(h+(h<<10))>>>0; h=(h^(h>>>6))>>>0; }
    h=(h+(h<<3))>>>0; h=(h^(h>>>11))>>>0; h=(h+(h<<15))>>>0; return h>>>0; }
function thumbUrls(model, folder){
    if(!THUMBS.enabled || !model) return [];
    folder = folder || 'catalog';
    const urls=[];
    if(THUMBS.localPack){ ['png','jpg','jpeg','webp'].forEach(x=>urls.push(`img/${folder}/${model}.${x}`)); }
    if(THUMBS.cdn && folder==='catalog'){ urls.push(THUMBS.cdn.replace(/{model}/g,model).replace(/{hash}/g,joaat(model))); }
    return urls;
}
// returns an <img> that walks candidate urls, else a span with the SVG icon
function thumbNode(model, svgKey, cls, folder){
    const urls=thumbUrls(model, folder);
    const wrap=el('span',cls); wrap.innerHTML=iconSVG(svgKey);
    if(!urls.length) return wrap;
    const img=el('img'); let i=0;
    const next=()=>{ if(i>=urls.length){ img.remove(); return; } img.src=urls[i++]; };
    img.onerror=next; img.onload=()=>{ wrap.innerHTML=''; wrap.appendChild(img); };
    next(); return wrap;
}

/* ---------------- modal infra ---------------- */
const root=$('#root'), titleEl=$('#title'), bodyEl=$('#body'), footEl=$('#foot'),
      toolbar=$('#toolbar'), catsEl=$('#cats'), searchEl=$('#search'), toasts=$('#toasts'),
      dash=$('#dash');
let CB=null, activeCat=null;

function submit(value){ if(CB==null){ closeModal(); return; } post('submit',{id:CB,value}); CB=null; hideModal(); }
function closeModal(){ CB=null; post('close',{}); hideModal(); }
function hideModal(){ root.classList.add('hidden'); dash.classList.add('hidden'); toolbar.classList.add('hidden');
    footEl.classList.add('hidden'); bodyEl.innerHTML=''; catsEl.innerHTML=''; activeCat=null; }
function chev(){ const s=el('span','chev'); s.innerHTML=S('<path d="M9 6l6 6-6 6"/>'); return s; }
function menuIcon(id){ const map={ buy:'money',rent:'ticket',enter:'enter',lock:'lock',rdelete:'trash',
    place_storage:'box',place_wardrobe:'shirt',place_safe:'safe',decorate:'paint',setexit:'door',
    keys:'key',employees:'users',fee:'ticket',sell:'tag',dep:'money',wd:'money',house:'door',business:'brief' };
    return map[id]||'cog'; }

function renderMenu(d){
    const list=el('div','btnlist');
    (d.buttons||[]).forEach((b)=>{
        const danger=b.id==='sell'||b.id==='rdelete';
        const row=el('button','row'+(danger?' danger':''));
        const ic=el('span','ic'); ic.innerHTML=iconSVG(menuIcon(b.id));
        const label=el('span','label'); label.textContent=b.label;
        row.append(ic,label,chev()); row.onclick=()=>submit({id:b.id}); list.appendChild(row);
    });
    bodyEl.appendChild(list);
}
function renderInput(d){
    const form=el('div','form'); const inputs={};
    (d.fields||[]).forEach((f)=>{ const fl=el('div','field'); const lab=el('label'); lab.textContent=f.label;
        const inp=el('input'); inp.type=f.type==='number'?'number':'text'; if(f.default!=null) inp.value=f.default;
        inputs[f.id]=inp; fl.append(lab,inp); form.appendChild(fl); });
    bodyEl.appendChild(form);
    footEl.classList.remove('hidden'); footEl.innerHTML='';
    const c=el('button','fbtn'); c.textContent='İptal'; c.onclick=closeModal;
    const ok=el('button','fbtn primary'); ok.textContent='Onayla';
    ok.onclick=()=>{ const o={}; Object.keys(inputs).forEach(k=>o[k]=inputs[k].value); submit(o); };
    footEl.append(c,ok); const first=form.querySelector('input'); if(first) setTimeout(()=>first.focus(),40);
}
function renderList(d){
    if(!(d.items||[]).length){ const e=el('div','empty'); e.textContent='Liste boş.'; bodyEl.appendChild(e); return; }
    const list=el('div','btnlist');
    (d.items||[]).forEach((it)=>{
        const danger=it.action==='fire'||it.action==='remove';
        const add=it.action==='add'||it.action==='hire';
        const row=el('button','row'+(danger?' danger':'')+(add?' add':''));
        if(!add){ const ic=el('span','ic'); ic.innerHTML=iconSVG(danger?'trash':'users'); row.appendChild(ic); }
        const label=el('span','label'); label.textContent=it.label; row.appendChild(label);
        if(it.sub){ const s=el('span','sub'); s.textContent=it.sub; row.appendChild(s); }
        if(it.actionLabel){ const a=el('span','act'); a.textContent=it.actionLabel; row.appendChild(a); }
        row.onclick=()=>submit(it); list.appendChild(row);
    });
    bodyEl.appendChild(list);
}
function renderGrid(d){
    THUMBS = d.thumbs || THUMBS;
    toolbar.classList.remove('hidden'); searchEl.value=''; searchEl.placeholder=d.searchPlaceholder||'Ara...';
    catsEl.innerHTML=''; activeCat=null;
    const allB=el('button','cat on'); allB.textContent='Hepsi'; allB.onclick=()=>{activeCat=null;setCat(allB);draw();}; catsEl.appendChild(allB);
    (d.categories||[]).forEach((c)=>{ const b=el('button','cat'); b.textContent=c.label;
        b.onclick=()=>{activeCat=c.id;setCat(b);draw();}; catsEl.appendChild(b); });
    function setCat(a){ catsEl.querySelectorAll('.cat').forEach(x=>x.classList.toggle('on',x===a)); }
    function draw(){
        const q=(searchEl.value||'').toLowerCase().trim(); const grid=el('div','grid'); let n=0;
        (d.items||[]).forEach((it)=>{
            if(activeCat && it.cat!==activeCat) return;
            if(q && !(it.label||'').toLowerCase().includes(q) && !(it.id||'').toLowerCase().includes(q)) return;
            n++; const card=el('div','card'); card.tabIndex=0;
            const t=thumbNode(it.id, CAT_ICON[it.cat]||'door', 'thumb', 'interiors');
            const meta=el('div','meta'); const nm=el('div','name'); nm.textContent=it.label;
            const tag=el('div','tag'); tag.textContent=it.kind||it.cat||''; meta.append(nm,tag); card.append(t,meta);
            card.onclick=()=>submit({id:it.id}); card.onkeydown=e=>{if(e.key==='Enter')submit({id:it.id});};
            grid.appendChild(card);
        });
        bodyEl.innerHTML='';
        if(n===0){ const e=el('div','empty'); e.textContent='Sonuç yok.'; bodyEl.appendChild(e); } else bodyEl.appendChild(grid);
    }
    searchEl.oninput=draw; draw(); setTimeout(()=>searchEl.focus(),40);
}

/* dashboard */
function renderDashboard(d){
    $('#dash-sub').textContent=d.subtitle||'YÖNETİM';
    $('#dash-name').textContent=d.title||'Mülk';
    $('#dash-ghost').textContent=(d.title||'').toUpperCase();
    const lock=$('#dash-lock');
    lock.className='badge '+(d.locked?'locked':'open');
    lock.innerHTML='<span class="bdot"></span>'+(d.locked?'KİLİTLİ':'AÇIK');

    const main=$('#dash-main'); main.innerHTML='';
    (d.sections||[]).forEach((sec)=>{
        const s=el('div','sec'); const h=el('div','sec-h'); h.textContent=sec.title; s.appendChild(h);
        const items=el('div','sec-items');
        (sec.items||[]).forEach((it)=>{
            const c=el('button','act-card '+(it.kind||'default'));
            const ic=el('span','ac-ic'); ic.innerHTML=iconSVG(it.icon||menuIcon(it.id));
            const tx=el('div'); const t=el('div','ac-t'); t.textContent=it.label;
            tx.appendChild(t); if(it.desc){ const dd=el('div','ac-d'); dd.textContent=it.desc; tx.appendChild(dd); }
            c.append(ic,tx); c.onclick=()=>submit({id:it.id}); items.appendChild(c);
        });
        s.appendChild(items); main.appendChild(s);
    });

    const side=$('#dash-side'); side.innerHTML='';
    const panel=el('div','panel');
    const ph=el('div','panel-h'); ph.innerHTML='<span class="ph-ic">'+iconSVG('bulb')+'</span> IŞIKLAR';
    panel.appendChild(ph);
    if(!(d.lights||[]).length){ const e=el('div','empty'); e.textContent='Henüz ışık yerleştirilmemiş.'; panel.appendChild(e); }
    (d.lights||[]).forEach((lt)=>{
        const r=el('div','light-row');
        const ic=el('span','lr-ic'); ic.innerHTML=iconSVG('bulb');
        const tx=el('div'); tx.style.flex='1';
        const t=el('div','lr-t'); t.textContent=lt.label||'Işık';
        const s=el('div','lr-s'); s.textContent=lt.on?'Açık':'Kapalı'; tx.append(t,s);
        const sw=el('button','switch'+(lt.on?' on':''));
        sw.onclick=()=>{ const on=!sw.classList.contains('on'); sw.classList.toggle('on',on);
            s.textContent=on?'Açık':'Kapalı'; post('lightToggle',{objId:lt.objId}); };
        r.append(ic,tx,sw); panel.appendChild(r);
    });
    side.appendChild(panel);
    dash.classList.remove('hidden');
}

function openModal(d){
    CB = d.callbackId!=null ? d.callbackId : CB;
    if(d.view==='dashboard'){ renderDashboard(d); return; }
    titleEl.textContent=d.title||'Menü'; bodyEl.innerHTML=''; footEl.classList.add('hidden'); toolbar.classList.add('hidden');
    root.classList.remove('hidden');
    switch(d.view){ case 'menu':renderMenu(d);break; case 'input':renderInput(d);break;
        case 'list':renderList(d);break; case 'interiors':renderGrid(d);break; default:renderMenu(d); }
}

/* notifications */
function notify(d){
    toasts.className='toasts '+(d.position||'top-right');
    const ki={info:'info',success:'check',error:'warn',warn:'warn'}[d.kind]||'info';
    const t=el('div','toast '+(d.kind||'info'));
    const ic=el('div','ticon'); ic.innerHTML=iconSVG(ki);
    const m=el('div','tmsg'); m.textContent=d.message||''; t.append(ic,m); toasts.appendChild(t);
    setTimeout(()=>{ t.classList.add('out'); setTimeout(()=>t.remove(),240); }, d.duration||4000);
}

/* ============================================================
   DECORATION BOTTOM BAR
   ============================================================ */
const dock=$('#dock'), dockRail=$('#dock-rail'), dockCats=$('#dock-cats'),
      dockFunc=$('#dock-func'), dockSearch=$('#dock-search');
let decoData=null, decoCat=null;

function openDecorator(d){
    decoData=d; decoCat=null; THUMBS=d.thumbs||THUMBS; dock.classList.remove('hidden'); dock.classList.remove('build'); dockSearch.value='';
    dockFunc.innerHTML='';
    [['storage','box','Depo'],['wardrobe','shirt','Dolap'],['safe','safe','Kasa']].forEach(([kind,ic,lbl])=>{
        const b=el('button','func'); const i=el('span','fic'); i.innerHTML=iconSVG(ic);
        const s=el('span'); s.textContent=lbl; b.append(i,s);
        b.onclick=()=>post('decoratorTool',{action:'functional',kind}); dockFunc.appendChild(b);
    });
    dockCats.innerHTML='';
    const allB=el('button','cat on'); allB.textContent='Hepsi'; allB.onclick=()=>{decoCat=null;setDC(allB);decoDraw();}; dockCats.appendChild(allB);
    (d.categories||[]).forEach((c)=>{ const b=el('button','cat'); b.textContent=c.label;
        b.onclick=()=>{decoCat=c.id;setDC(b);decoDraw();}; dockCats.appendChild(b); });
    function setDC(a){ dockCats.querySelectorAll('.cat').forEach(x=>x.classList.toggle('on',x===a)); }
    dockSearch.oninput=decoDraw; decoDraw();
    dock.querySelectorAll('.tool').forEach(btn=>{ btn.onclick=()=>post('decoratorTool',{action:btn.dataset.tool}); });
    $('#dock-done').onclick=()=>post('decoratorTool',{action:'done'});
}
function decoDraw(){
    const raw=(dockSearch.value||'').trim(); const q=raw.toLowerCase(); dockRail.innerHTML=''; let n=0;
    if(raw.length>=3){
        const c=el('div','pcard manual'); const pic=el('span','pic'); pic.innerHTML=iconSVG('plus');
        const pn=el('div','pn'); pn.textContent=raw; c.append(pic,pn);
        c.onclick=()=>post('decoratorPick',{model:raw,manual:true}); dockRail.appendChild(c);
    }
    (decoData.items||[]).forEach((it)=>{
        if(decoCat && it.cat!==decoCat) return;
        if(q && !(it.name||'').toLowerCase().includes(q) && !(it.model||'').toLowerCase().includes(q)) return;
        n++; const c=el('div','pcard'); c.tabIndex=0; c.title=it.model||it.name;
        const pic=thumbNode(it.model, iconKeyFor(it), 'pic', 'catalog');
        const pn=el('div','pn'); pn.textContent=it.name; c.append(pic,pn);
        c.onclick=()=>post('decoratorPick',{model:it.model}); dockRail.appendChild(c);
    });
    if(n===0 && raw.length<3){ const e=el('div','empty'); e.textContent='Sonuç yok. Model adı yazıp ekleyebilirsin.'; dockRail.appendChild(e); }
}
function decoratorState(d){
    dock.querySelector('[data-tool="surface"]').classList.toggle('on', !!d.surface);
    dock.querySelector('[data-tool="grid"]').classList.toggle('on', !!d.grid);
    dock.classList.toggle('build', !d.cursor);
}

/* message bus */
window.addEventListener('message',(ev)=>{
    const d=ev.data||{};
    switch(d.action){
        case 'notify': return notify(d);
        case 'open': return openModal(d.data||{});
        case 'close': return hideModal();
        case 'decorator': return openDecorator(d.data||{});
        case 'decoratorState': return decoratorState(d);
        case 'decoratorClose': return dock.classList.add('hidden');
    }
});
document.addEventListener('keydown',(e)=>{ if(e.key==='Escape' && (!root.classList.contains('hidden')||!dash.classList.contains('hidden'))) closeModal(); });
$('#close').onclick=closeModal;
$('#dash-close').onclick=closeModal;

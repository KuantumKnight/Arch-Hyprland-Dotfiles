/// knight-glass.js
/// world isolated
(function(){
'use strict';
if (/(^|\.)(chatgpt\.com|chat\.openai\.com|youtube\.com)$/.test(location.hostname)) return;
if (window.top !== window || !/^https?:$/.test(location.protocol) || window.__knightGlass) return;
window.__knightGlass = true;
const VERSION='5.3.0';
const sheet=document.createElement('style');
sheet.id='knight-glass-style';sheet.className='knight-glass stylus';
const owned=new Map();let serial=0,timer=0,lastRun=0,runs=0,retainedDarkAlpha=.88,lastTheme=null;
const skip='img,video,canvas,svg,picture,iframe,object,embed,a,summary,button,[role="button"],input,textarea,select,[contenteditable]:not([contenteditable="false"]),pre,code,dialog,[role="dialog"],[role="alertdialog"],[role="tooltip"],[role="menu"],[role="listbox"],[aria-modal="true"],[popover],.monaco-editor,.CodeMirror,.cm-editor,.ace_editor,script,style';
const colorCache=new Map();let colorContext;
function rgb(s){
 if(colorCache.has(s))return colorCache.get(s);
 let c=null,m=s.match(/^rgba?\(([^)]+)\)/);
 if(m){const v=m[1].split(/[\s,\/]+/).map(Number);c={r:v[0],g:v[1],b:v[2],a:v[3]??1};}
 else if((m=s.match(/^color\(srgb\s+([^)]+)\)$/))){const v=m[1].split(/[\s\/]+/).map(Number),channel=x=>Math.max(0,Math.min(255,x*255));c={r:channel(v[0]),g:channel(v[1]),b:channel(v[2]),a:v[3]??1};}
 else if(CSS.supports('color',s)){
  try{colorContext??=document.createElement('canvas').getContext('2d',{willReadFrequently:true});colorContext.clearRect(0,0,1,1);colorContext.fillStyle=s;colorContext.fillRect(0,0,1,1);const v=colorContext.getImageData(0,0,1,1).data;c={r:v[0],g:v[1],b:v[2],a:v[3]/255};}catch{}
 }
 if(c&&![c.r,c.g,c.b,c.a].every(Number.isFinite))c=null;
 colorCache.set(s,c);return c;
}
const neutral=c=>c&&Math.max(c.r,c.g,c.b)-Math.min(c.r,c.g,c.b)<=32;
function luminance(c){const f=v=>{v/=255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4;};return .2126*f(c.r)+.7152*f(c.g)+.0722*f(c.b);}
function contrast(a,b){const x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);}
const dark=c=>Math.max(c.r,c.g,c.b)<130;
const distance=(a,b)=>Math.max(Math.abs(a.r-b.r),Math.abs(a.g-b.g),Math.abs(a.b-b.b));
function plainImage(s){if(s==='none')return true;if(!s.startsWith('linear-gradient(')||/url\(|var\(/.test(s))return false;const colors=[...s.matchAll(/rgba?\([^)]+\)/g)].map(m=>rgb(m[0]));return colors.length>=2&&colors.every(c=>neutral(c)&&c.a>=.98&&distance(c,colors[0])<=32);}
function restore(){sheet.disabled=true;for(const [el,old]of owned){if(old===null)el.removeAttribute('data-knight-glass-id');else el.setAttribute('data-knight-glass-id',old);}owned.clear();}
function apply(){
 timer=0;lastRun=performance.now();if(!document.body)return;
 observer.disconnect();
 try {
 if(!sheet.isConnected)(document.head||document.documentElement).append(sheet);
 restore();
 const html=document.documentElement,body=document.body,cache=new Map(),rules=[];
 function style(e){if(cache.has(e))return cache.get(e);const s=getComputedStyle(e);const v={color:rgb(s.color),size:parseFloat(s.fontSize),weight:parseInt(s.fontWeight)||400,display:s.display,bg:rgb(s.backgroundColor),image:s.backgroundImage,position:s.position,filter:s.filter,blend:s.mixBlendMode,opacity:+s.opacity,visibility:s.visibility,backdrop:s.backdropFilter,shadow:s.boxShadow,radius:parseFloat(s.borderTopLeftRadius)||0};cache.set(e,v);return v;}
 function put(el,value){const id=String(++serial);owned.set(el,el.getAttribute('data-knight-glass-id'));el.setAttribute('data-knight-glass-id',id);rules.push(`:is(#knight-glass-specificity,[data-knight-glass-id="${id}"]){background-color:${value}!important;${style(el).image!=='none'?'background-image:none!important;':''}}`);if(el===html)rules.push(`html[data-knight-glass-id="${id}"]{--knight-glass-root-color:${value}}`);}
 function safe(e){const s=style(e);return plainImage(s.image)&&s.filter==='none'&&s.blend==='normal'&&s.opacity>=.99&&s.visibility==='visible'&&s.backdrop==='none';}
 const hs=style(html),bs=style(body);
 if(hs.filter!=='none'||bs.filter!=='none'||!plainImage(hs.image)||!plainImage(bs.image)){
  sheet.textContent='';sheet.disabled=false;html.setAttribute('data-knight-glass','original');observe();return;
 }
 const elements=[html,body,...body.querySelectorAll('*')];
 let base=[bs.bg,hs.bg].find(c=>neutral(c)&&c.a>=.5);
 // A site may put its real theme on a full-size app wrapper, over a stale html colour.
 const probes=[document.querySelector('main'),document.querySelector('[role=main]'),...elements.slice(2,70)].filter(Boolean);
 for(const el of probes){
  if(el.closest(skip)||!safe(el))continue;const c=style(el).bg;if(!neutral(c)||c.a<.98)continue;
  const r=el.getBoundingClientRect();
  if(r.width>=innerWidth*.70&&r.height>=innerHeight*.75&&r.top<=innerHeight*.25){base=c;break;}
 }
 if(!base){
  // Native apps often put their canvas on an app wrapper instead of body.
  for(const el of elements.slice(2,100)){
   if(el.closest(skip)||!safe(el))continue;const c=style(el).bg;
   if(!neutral(c)||c.a<.98)continue;
   const r=el.getBoundingClientRect();
   if(r.width>=innerWidth*.7&&r.height>=innerHeight*.6){base=c;break;}
  }
 }
 if(!base){const probe=document.createElement('span');probe.style.backgroundColor='Canvas';html.append(probe);base=rgb(getComputedStyle(probe).backgroundColor);probe.remove();}
 if(!neutral(base)){sheet.textContent='';sheet.disabled=false;observe();return;}
 const isDark=dark(base);
 // A single canvas keeps its tint from the top to the bottom of a document.
 if(lastTheme!==isDark){retainedDarkAlpha=.88;lastTheme=isDark;}
 const layers=new Map([[html,{canvas:true,overlay:false}]]);
 for(const el of elements.slice(1)){
  if(el.closest(skip)||!safe(el))continue;
  const s=style(el),c=s.bg;if(!neutral(c)||c.a<(el===body?.5:.98))continue;
  // Preserve floating panels, badges, editor surfaces and table cell distinctions.
  if(el!==body&&el.matches('td,th'))continue;
  if(el!==body&&(s.shadow!=='none'||s.radius>3)){const r=el.getBoundingClientRect();if(r.width<innerWidth*.65||r.height<innerHeight*.7)continue;}
  // Preserve alternate colour sections and intentionally distinct panels.
  let parent=el.parentElement,blocked=false,overlay=s.position==='fixed'||s.position==='sticky';
  while(parent&&parent!==html){
   const p=style(parent),layer=layers.get(parent);
   if(p.position==='fixed'||p.position==='sticky')overlay=true;
   if(!plainImage(p.image)||p.filter!=='none'||p.opacity<.99||p.blend!=='normal'){blocked=true;break;}
   if(layer){if(!layer.canvas)blocked=true;break;}
   if(p.bg&&p.bg.a>.05){blocked=true;break;}
   parent=parent.parentElement;
  }
  if(blocked)continue;
  let canvas=el===body||dark(c)===isDark&&distance(c,base)<=8;
  if(!canvas&&dark(c)===isDark&&distance(c,base)<=26){const r=el.getBoundingClientRect();canvas=r.width>=innerWidth*.65&&r.height>=innerHeight*.7;}
  if(canvas&&!overlay){put(el,'transparent');layers.set(el,{canvas:true,overlay:false});}
  else if(canvas&&overlay){
   // An overlay needs its own background so scrolled text cannot show through.
   put(el,`rgba(${c.r},${c.g},${c.b},.97)`);layers.set(el,{canvas:false,overlay:true});
  }
 }
 let alpha=retainedDarkAlpha;
 if(isDark){
  const eligibility=new Map(),seen=new Set(),samples=[];
  function onCanvas(e){
   if(!e)return false;if(eligibility.has(e))return eligibility.get(e);
   const s=style(e);let ok=false;
   if(s.display!=='none'&&s.visibility==='visible'){
    if(layers.has(e))ok=layers.get(e).canvas;
    else if((!s.bg||s.bg.a<.01)&&s.image==='none'&&s.filter==='none'&&s.opacity>=.99)ok=onCanvas(e.parentElement);
   }
   eligibility.set(e,ok);return ok;
  }
  const walk=document.createTreeWalker(body,NodeFilter.SHOW_TEXT);let node;
  while((node=walk.nextNode())){
   if(!node.textContent.trim())continue;const e=node.parentElement;
   if(!e||e.closest('script,style,svg,canvas,video,iframe')||!onCanvas(e))continue;
   const s=style(e),fg=s.color;if(!fg||fg.a<.05)continue;
   const large=s.size>=24||s.size>=18.66&&s.weight>=700;
   const key=[fg.r,fg.g,fg.b,fg.a,large].join(',');if(seen.has(key))continue;seen.add(key);
   const original={r:fg.r*fg.a+base.r*(1-fg.a),g:fg.g*fg.a+base.g*(1-fg.a),b:fg.b*fg.a+base.b*(1-fg.a)};
   samples.push({fg,need:Math.min(large?3:4.5,contrast(original,base))});
  }
  const readable=a=>samples.every(({fg,need})=>[0,255*(1-a)].every(v=>{
   const bg={r:v,g:v,b:v},text={r:fg.r*fg.a+v*(1-fg.a),g:fg.g*fg.a+v*(1-fg.a),b:fg.b*fg.a+v*(1-fg.a)};
   return contrast(text,bg)+.025>=need;
  }));
  while(alpha<1&&!readable(alpha))alpha=Math.min(1,Math.round((alpha+.01)*100)/100);
  retainedDarkAlpha=alpha;
  html.setAttribute('data-knight-glass-text-colors',String(samples.length));
 }
 put(html,isDark?`rgba(0,0,0,${alpha})`:'transparent');
 html.setAttribute('data-knight-glass-alpha',String(isDark?alpha:0));
 sheet.textContent=rules.join('\n');sheet.disabled=false;
 html.setAttribute('data-knight-glass-version',VERSION);
 html.setAttribute('data-knight-glass-palette',html.hasAttribute('data-darkreader-mode')?'darkreader':'native');
 html.setAttribute('data-knight-glass',isDark?'dark':'light');
 html.setAttribute('data-knight-glass-surfaces',String(owned.size));
 html.setAttribute('data-knight-glass-runs',String(++runs));
 html.setAttribute('data-knight-glass-ms',String(Math.round(performance.now()-lastRun)));
 } catch(error) {
  restore();sheet.textContent='';sheet.disabled=false;
  document.documentElement.setAttribute('data-knight-glass','original');
 } finally {observe();}
}
function schedule(){if(timer)return;timer=setTimeout(apply,Math.max(160,650-(performance.now()-lastRun)));}
const observer=new MutationObserver(records=>{
 if(!sheet.isConnected){schedule();return;}
 records=records.filter(r=>{if(r.type==='characterData')return r.target.parentElement?.tagName==='STYLE';if(r.type==='childList'&&r.target.nodeName!=='STYLE'&&[...r.addedNodes,...r.removedNodes].every(n=>n.nodeType===Node.TEXT_NODE))return false;return true;});
 if(records.every(r=>r.target===sheet||sheet.contains(r.target)||r.type==='attributes'&&r.attributeName?.startsWith('data-knight-')||r.type==='childList'&&[...r.addedNodes,...r.removedNodes].every(n=>n===sheet)))return;
 schedule();
});
function observe(){observer.observe(document,{subtree:true,childList:true,characterData:true,attributes:true,attributeFilter:['class','style','data-theme','data-color-mode','dark','data-darkreader-mode','data-darkreader-scheme','hidden','open','role','aria-modal','data-state','data-bs-theme','data-color-scheme','href','media','disabled']});}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',schedule,{once:true});else schedule();
for(const event of ['pageshow','resize','popstate','hashchange'])addEventListener(event,schedule);
matchMedia('(prefers-color-scheme: dark)').addEventListener('change',schedule);
window.navigation?.addEventListener('navigatesuccess',schedule);
document.addEventListener('__darkreader__updateSheet',schedule,true);
document.addEventListener('load',e=>{if(e.target instanceof HTMLLinkElement)schedule();},true);
})();

/// knight-glass.js
/// world isolated
(function(){
'use strict';
const youtube=/(^|\.)youtube\.com$/.test(location.hostname);
const chatgpt=/(^|\.)chatgpt\.com$/.test(location.hostname)||/(^|\.)chat\.openai\.com$/.test(location.hostname);
if(youtube||chatgpt)return;
if(window.top!==window||!/^https?:$/.test(location.protocol)||window.__knightGlass)return;
window.__knightGlass=true;
const VERSION='4.2.0', owned=new Map();
const sheet=document.createElement('style');sheet.id='knight-glass-style';sheet.className='knight-glass stylus';
let rules=[],serial=0;
function mount(){if(!sheet.isConnected)(document.head||document.documentElement).append(sheet);}
let observer,timer,intersection;
const excluded='img,video,canvas,svg,picture,iframe,object,embed,button,[role="button"],input[type="checkbox"],input[type="radio"],input[type="range"],input[type="color"],script,style';
function rgb(s){const m=s.match(/^rgba?\(([^)]+)\)/);if(!m)return null;const a=m[1].split(/[\s,\/]+/).map(Number);return {r:a[0],g:a[1],b:a[2],a:a[3]??1};}
const neutral=c=>c&&Math.max(c.r,c.g,c.b)-Math.min(c.r,c.g,c.b)<=24;
const same=(a,b)=>a&&b&&Math.max(Math.abs(a.r-b.r),Math.abs(a.g-b.g),Math.abs(a.b-b.b))<4;
function lum(c){const f=v=>(v/=255)<=.04045?v/12.92:((v+.055)/1.055)**2.4;return .2126*f(c.r)+.7152*f(c.g)+.0722*f(c.b);}
function contrast(a,b){let x=lum(a),y=lum(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);}
function put(el,prop,value){
 if(!owned.has(el)){owned.set(el,el.getAttribute('data-knight-glass-id'));el.setAttribute('data-knight-glass-id',String(++serial));}
 const id=el.getAttribute('data-knight-glass-id');
 rules.push(`:is(#knight-glass-specificity,[data-knight-glass-id="${id}"]){${prop}:${value}!important}`);
 if(el===document.documentElement&&prop==='background-color')rules.push(`html[data-knight-glass-id="${id}"]{--knight-glass-root-color:${value}}`);
}
function restore(){sheet.disabled=true;if(youtube)document.documentElement.removeAttribute('data-knight-glass-yt-header');for(const [el,old]of owned){if(old===null)el.removeAttribute('data-knight-glass-id');else el.setAttribute('data-knight-glass-id',old);}owned.clear();rules=[];}
function schedule(){clearTimeout(timer);timer=setTimeout(apply,220);}
function apply(){
 if(!document.body)return;
 observer?.disconnect();intersection?.disconnect();mount();restore();
 const html=document.documentElement,body=document.body,cache=new Map(),styles=e=>{if(!cache.has(e))cache.set(e,getComputedStyle(e));return cache.get(e);};
 const all=[html,body],walk=document.createTreeWalker(body,NodeFilter.SHOW_ELEMENT);
 let e,count=0,truncated=false;
 while((e=walk.nextNode())){if(++count>1800){truncated=true;break;}const r=e.getBoundingClientRect();if(r.bottom>=0&&r.top<=innerHeight+100&&r.width&&r.height)all.push(e);}
 const surfaces=new Map();
 const unsupported=styles(html).filter!=='none'||styles(body).filter!=='none';
 function complex(el,s){if(s.backgroundImage!=='none'||s.mixBlendMode!=='normal'||s.filter!=='none'||Number(s.opacity)<.99||el.shadowRoot)return true;for(const pseudo of ['::before','::after']){const p=getComputedStyle(el,pseudo);if(p.content!=='none'&&p.content!=='normal'&&(p.backgroundImage!=='none'||(rgb(p.backgroundColor)?.a??0)>0))return true;}return false;}
 for(const el of all){
  if(unsupported)break;
  if(el.closest(excluded)||el.matches('[contenteditable="true"]'))continue;
  const s=styles(el),bg=rgb(s.backgroundColor);
  if(!neutral(bg)||bg.a<.98||s.visibility!=='visible'||complex(el,s))continue;
  surfaces.set(el,{el,bg,dark:lum(bg)<.18,samples:[],unsafe:false,alpha:1});
 }
 if(!unsupported&&!surfaces.has(html)&&!surfaces.has(body)&&styles(html).backgroundImage==='none'&&styles(body).backgroundImage==='none'){
  const probe=document.createElement('span');probe.style.backgroundColor='Canvas';html.append(probe);const bg=rgb(getComputedStyle(probe).backgroundColor);probe.remove();
  if(neutral(bg))surfaces.set(html,{el:html,bg,dark:lum(bg)<.18,samples:[],unsafe:truncated,alpha:1});
 }
 function owner(el){for(let p=el;p;p=p.parentElement){if(surfaces.has(p))return surfaces.get(p);const s=styles(p),bg=rgb(s.backgroundColor);if(s.backgroundImage!=='none'||bg&&bg.a>0)return null;}return null;}
 function sample(el,value,pseudo){const o=owner(el);if(!o)return;const s=pseudo?getComputedStyle(el,pseudo):styles(el),fg=rgb(s.color);if(!fg||fg.a<.98){o.unsafe=true;return;}const size=parseFloat(s.fontSize),large=size>=24||size>=18.66&&parseInt(s.fontWeight)>=700;const original=contrast(fg,o.bg);if(original<2.8){o.unsafe=true;return;}o.samples.push({fg,need:Math.min(large?3:4.5,original)});}
 const text=document.createTreeWalker(body,NodeFilter.SHOW_TEXT);let n,visited=0;
 while((n=text.nextNode())){if(++visited>2400){truncated=true;break;}if(!n.textContent.trim())continue;const el=n.parentElement;if(!el||el.closest('script,style,svg,canvas,video,iframe'))continue;const r=el.getBoundingClientRect();if(!r.width||!r.height||r.bottom<0||r.top>innerHeight+100||styles(el).visibility!=='visible')continue;sample(el,n.textContent);}
 for(const el of all)if(el.matches('input:not([type="checkbox"]):not([type="radio"]),textarea,select')){sample(el,el.value);if(el.hasAttribute('placeholder'))sample(el,el.getAttribute('placeholder'),'::placeholder');}
 for(const o of surfaces.values()){
  if(truncated&&(o.el===html||o.el===body))o.unsafe=true;
  o.tint=o.bg;
  let alpha=o.dark?.65:.8;
  const readable=a=>o.samples.every(({fg,need})=>[0,255].every(w=>contrast(fg,{r:o.tint.r*a+w*(1-a),g:o.tint.g*a+w*(1-a),b:o.tint.b*a+w*(1-a)})+.025>=need));
  while(alpha<1&&!readable(alpha))alpha=Math.min(1,Math.round((alpha+.05)*100)/100);
  if(!o.unsafe&&readable(alpha))o.alpha=alpha;
 }
 // Equal-colour wrappers share a single glass layer. Their text constrains that layer.
 for(const o of surfaces.values()){
  let p=o.el.parentElement,parent=null;
  while(p){if(surfaces.has(p)){parent=surfaces.get(p);break;}const s=styles(p);if(s.backgroundImage!=='none'||(rgb(s.backgroundColor)?.a??0)>0)break;p=p.parentElement;}
  if(parent&&same(o.bg,parent.bg)&&o.alpha<1&&parent.alpha<1){o.parent=parent;parent.alpha=Math.max(parent.alpha,o.alpha);}
 }
 // Propagate opacity requirements from nested wrappers up to their shared owner.
 for(const o of [...surfaces.values()].reverse())if(o.parent)o.parent.alpha=Math.max(o.parent.alpha,o.alpha);
 let changed=0;
 for(const o of surfaces.values()){
  if(o.alpha>=1)continue;
  let p=o.parent;while(p?.parent)p=p.parent;
  if(p&&p.alpha<1)put(o.el,'background-color','transparent');
  else put(o.el,'background-color',`rgba(${o.tint.r},${o.tint.g},${o.tint.b},${o.alpha})`);
  changed++;
 }
 sheet.textContent=rules.join('\n');sheet.disabled=false;
 html.setAttribute('data-knight-glass-version',VERSION);html.setAttribute('data-knight-glass-palette',html.hasAttribute('data-darkreader-mode')?'darkreader':'native');html.setAttribute('data-knight-glass',changed?'adaptive':'original');html.setAttribute('data-knight-glass-surfaces',String(changed));
 observer=new MutationObserver(records=>{if(records.every(r=>r.target===sheet||sheet.contains(r.target)||r.type==='attributes'&&r.attributeName?.startsWith('data-knight-')||r.type==='childList'&&[...r.addedNodes,...r.removedNodes].every(n=>n===sheet)))return;schedule();});
 observer.observe(html,{subtree:true,childList:true,attributes:true,attributeFilter:['class','style','data-theme','data-color-mode','dark','placeholder','data-darkreader-mode','data-darkreader-scheme']});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',schedule,{once:true});else schedule();
for(const event of ['pageshow','resize','popstate','hashchange'])addEventListener(event,schedule);
let lastScroll=0;addEventListener('scroll',()=>{if(Math.abs(scrollY-lastScroll)>innerHeight*.5){lastScroll=scrollY;schedule();}},{passive:true});
matchMedia('(prefers-color-scheme: dark)').addEventListener('change',schedule);
window.navigation?.addEventListener('navigatesuccess',schedule);
document.addEventListener('__darkreader__updateSheet',schedule,true);
document.addEventListener('load',e=>{if(e.target instanceof HTMLLinkElement)schedule();},true);
})();

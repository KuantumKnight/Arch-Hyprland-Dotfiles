pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id: layout
 property var data: ({version:1,pins:["systemsettings","firefox","kitty","thunar"],order:["systemsettings","firefox","kitty","thunar"]})
 readonly property var pins: data.pins
 readonly property var order: data.order
 readonly property bool autoHide: data.autoHide===true
 function key(id) {return Tasks.key(id);}
 function isPinned(id) {return pins.some(p=>key(p)===key(id));}
 function save(pins,order) {
  data=Object.assign({},data,{version:1,pins:pins,order:order});
  storage.setText(JSON.stringify(data,null,2)+"\n");
 }
 function setAutoHide(enabled) {
  data=Object.assign({},data,{autoHide:enabled});
  save(pins,order);
 }
 function load() {
  try {
   const value=JSON.parse(storage.text());
   if(Array.isArray(value.pins)&&Array.isArray(value.order))data={version:1,pins:value.pins,order:value.order.map(key),autoHide:value.autoHide===true};
  } catch(e) {console.warn("Dock layout:",e);}
 }
 function togglePin(id,visibleIds) {
  let next=pins.filter(p=>key(p)!==key(id));
  if(!isPinned(id))next.push(id);
  let nextOrder=order.slice();
  for(const v of visibleIds)if(!nextOrder.includes(key(v)))nextOrder.push(key(v));
  save(next,nextOrder);
 }
 function move(id,toIndex,visibleIds) {
  let next=visibleIds.map(key),from=next.indexOf(key(id));
  if(from<0)return;
  next.splice(from,1);next.splice(Math.max(0,Math.min(next.length,toIndex)),0,key(id));
  // Keep remembered positions for apps that are not currently running.
  const result=order.slice();
  let j=0;
  for(let i=0;i<result.length;i++)if(next.includes(result[i]))result[i]=next[j++];
  while(j<next.length)result.push(next[j++]);
  const nextPins=pins.slice().sort((a,b)=>result.indexOf(key(a))-result.indexOf(key(b)));
  save(nextPins,result);
 }
 FileView {
  id:storage
  path:Quickshell.env("HOME")+"/.config/quickshell/dragon/dock-layout.json"
  blockLoading:true;blockWrites:true;atomicWrites:true;printErrors:true
 }
 Component.onCompleted:load()
}

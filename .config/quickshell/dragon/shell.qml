//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
 id: root
 property var state: ({})
 property string page: ""
 onPageChanged: if(page===""&&!hover.containsMouse)hideTimer.restart()
 property var pins: DockLayout.pins
 property var apps: {
  DesktopEntries.applications.values.length;
  let ids=pins.slice();
  for(let k of Object.keys(Tasks.apps)) if(k!=="org.quickshell" && !ids.some(id=>Tasks.key(id)===k)) ids.push(k);
  const entries=ids.map(id=>DesktopEntries.byId(id)||Tasks.resolveEntry(id)).filter(e=>e);
  return entries.sort((a,b)=>{
   let x=DockLayout.order.indexOf(Tasks.key(a.id)),y=DockLayout.order.indexOf(Tasks.key(b.id));
   return (x<0?99999:x)-(y<0?99999:y);
  });
 }
 function act(action,value,extra) { let a={action:action,value:value}; if(extra)a.service=extra; backend.write(JSON.stringify(a)+"\n"); }
 Process {
  id: backend
  command: ["python", Quickshell.env("HOME")+"/.config/quickshell/dragon/backend.py"]
  running: true
  stdinEnabled: true
  stdout: SplitParser { onRead: data=> { try { root.state=Object.assign({},root.state,JSON.parse(data)); } catch(e) { console.warn(e); } } }
  stderr: SplitParser { onRead: data=>console.warn("Services: "+data) }
 }
 SystemClock { id: clock; precision: SystemClock.Minutes }
 IpcHandler {
  target:"dock"
  function settings(): void {root.togglePage("settings");}
  function calendar(): void {root.togglePage("calendar");}
  function toggleHidden(): void {root.closePopup();dock.revealed=false;hideTimer.stop();DockLayout.setAutoHide(!DockLayout.autoHide);}
  function close(): void {root.closePopup();}
  function appMenu(app:string): void {let i=root.apps.findIndex(e=>Tasks.key(e.id)===Tasks.key(app));if(i>=0)root.showAppMenu(root.apps[i],i);}
  function diagnostics(): string {return JSON.stringify({apps:root.apps.map(e=>e.id),pins:DockLayout.pins,order:DockLayout.order,page:root.page,menuItems:root.menuItems.map(i=>i.text),running:Object.keys(Tasks.apps),fullscreen:Tasks.fullscreen,autoHide:DockLayout.autoHide,hidden:dock.hidden,revealed:dock.revealed,dragging:dock.dragging,state:root.state});}
 }
 function togglePage(next) {
  if(page===next){closePopup();return;}
  appMenuRise.stop();appMenuFall.stop();appMenuClosing=false;
  page=next;dock.revealed=true;hideTimer.stop();
 }

 property var menuEntry:null
 property int menuIndex:0
 property real menuOriginX:0
 property bool appMenuClosing:false
 readonly property var menuItems: {
  if(!menuEntry)return [];
  let result=[],key=Tasks.key(menuEntry.id);
  if(key==="firefox")result.push({id:"new-window",text:"New Window",icon:"󰖯"},{id:"new-private-window",text:"New Private Window",icon:"󰗹"});
  if(key==="kitty")result.push({id:"new-window",text:"New Window",icon:"󰆍"});
  result.push({id:"pin",text:DockLayout.isPinned(menuEntry.id)?"Unpin from Dock":"Pin to Dock",icon:DockLayout.isPinned(menuEntry.id)?"󰐃":"󰐅"});
  return result;
 }
 function showAppMenu(entry,index) {
  if(page==="app"&&menuEntry&&Tasks.key(menuEntry.id)===Tasks.key(entry.id)&&!appMenuClosing){closePopup();return;}
  appMenuFall.stop();appMenuClosing=false;
  menuEntry=entry;menuIndex=index;menuOriginX=dock.startX+index*50+25;
  popup.riseProgress=0;page="app";dock.revealed=true;appMenuRise.restart();
 }
 function closePopup() {
  if(page!=="app"){page="";return;}
  if(appMenuClosing)return;
  appMenuClosing=true;appMenuRise.stop();
  appMenuFall.from=popup.riseProgress;appMenuFall.restart();
 }
 function runAppAction(id) {
  const entry=menuEntry;if(!entry)return;
  closePopup();
  if(id==="pin"){DockLayout.togglePin(entry.id,root.apps.map(e=>e.id));return;}
  const action=Array.from(entry.actions||[]).find(a=>a.id===id);
  if(action){action.execute();return;}
  if(id==="new-window")entry.execute();
 }

 component LabelText: Text { color: "#c5c9c5"; font.pixelSize: 13; font.family: "Noto Sans"; elide: Text.ElideRight }
 component Action: Button {
  id: control
  font.family: "Noto Sans"
  implicitHeight: 36
  contentItem: Text { text: control.text; color: control.enabled ? "#c5c9c5" : "#625e5a"; font.pixelSize: 13; font.family: control.font.family; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
  background: Rectangle { radius: 9; color: control.down ? "#624139" : control.hovered ? "#39332d" : "#292724"; border.color: "#42625e5a" }
 }
 component DragonSlider: Slider {
  id: slider
  property real serviceValue: from
  property bool pending: false
  property string glyph: ""
  signal commit(real amount)
  implicitHeight: 40
  implicitWidth: 280
  leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
  hoverEnabled: true
  Binding { target: slider; property: "value"; value: slider.serviceValue; when: !slider.pressed && !slider.pending }
  onMoved: { pending=true; if(!throttle.running) throttle.start(); }
  onPressedChanged: if(!pressed && pending) { throttle.stop(); commit(value); settle.restart(); }
  onServiceValueChanged: if(pending && Math.abs(serviceValue-value)<(to-from)*0.015) { pending=false; settle.stop(); }
  Timer { id: throttle; interval: 70; onTriggered: { slider.commit(slider.value); settle.restart(); } }
  Timer { id: settle; interval: 2200; onTriggered: slider.pending=false }
  background: Rectangle {
   implicitHeight: 40
   x: slider.leftPadding; y: slider.topPadding
   width: slider.availableWidth; height: slider.availableHeight
   radius: 11; color: "#33302c"
   border.color: slider.hovered ? "#706b6258" : "#306b6258"
   Rectangle {
    width: Math.max(0,slider.visualPosition*parent.width); height: parent.height; radius: 11
    gradient: Gradient { orientation:Gradient.Horizontal; GradientStop{position:0;color:"#b09a7b"} GradientStop{position:1;color:"#ddc7a4"} }
   }
   Text { x:13;anchors.verticalCenter:parent.verticalCenter;text:slider.glyph;font.family:"JetBrainsMono Nerd Font";font.pixelSize:19;color:slider.visualPosition>0.07?"#29231d":"#bcb3a6" }
  }
  handle: Rectangle {
   implicitWidth: 4; implicitHeight: 18
   x: slider.leftPadding+slider.visualPosition*(slider.availableWidth-width-14)+7
   y: slider.topPadding+(slider.availableHeight-height)/2
   width:4;height:18;radius:2
   color:slider.pressed?"#fff0d6":"#f0e0c6";opacity:slider.hovered||slider.pressed?1:0.65
   Behavior on opacity {NumberAnimation{duration:120}}
  }
 }
 component DragonCombo: ComboBox {
  id: combo
  font.family:"Noto Sans"
  implicitHeight: 38
  leftPadding:12;rightPadding:28
  contentItem: Text {text:combo.displayText;color:"#c5c9c5";font.pixelSize:12;font.family:"Noto Sans";verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
  indicator: Text { x:combo.width-23;anchors.verticalCenter:parent.verticalCenter;text:"⌄";font.pixelSize:16;color:"#b69269" }
  background: Rectangle {implicitHeight:38;radius:10;color:combo.hovered?"#34302a":"#262320";border.color:"#38625e5a"}
  delegate: ItemDelegate {
   required property int index
   required property var modelData
   width:combo.width;height:38
   highlighted:combo.highlightedIndex===index
   contentItem: Text {text:combo.textRole?modelData[combo.textRole]:modelData;color:"#dcd7ba";font.family:"Noto Sans";font.pixelSize:12;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
   background: Rectangle {radius:7;color:parent.highlighted?"#494034":"transparent"}
  }
  popup: Popup {
   y:combo.height+5;width:combo.width;padding:5
   implicitHeight:Math.min(240,contentItem.implicitHeight+10)
   contentItem: ListView {clip:true;implicitHeight:contentHeight;model:combo.popup.visible?combo.delegateModel:null;currentIndex:combo.highlightedIndex;ScrollIndicator.vertical:ScrollIndicator{}}
   background: Rectangle {radius:12;color:"#f0201d1a";border.color:"#59625e5a"}
  }
 }
 component Glass: Rectangle {
  // Glass construction adapted from kde-quickshell-dock/Dock.qml:
  // https://github.com/IFtiger-hu-hub/kde-quickshell-dock/blob/main/Dock.qml
  // Use only achromatic reflection layers; the compositor supplies the backdrop.
  property bool glassPopupSurface: false
  radius: 19; color: "transparent"; border.color: glassPopupSurface?"#28ffffff":"#5cffffff"; border.width: 1
  gradient: Gradient {
   GradientStop {position:0;color:glassPopupSurface?"#08ffffff":"#36ffffff"}
   GradientStop {position:0.3;color:glassPopupSurface?"#02ffffff":"#22ffffff"}
   GradientStop {position:1;color:glassPopupSurface?"#04ffffff":"#2cffffff"}
  }
  RectangularShadow {
   anchors.fill:parent;radius:parent.radius;offset:Qt.vector2d(0,7)
   color:glassPopupSurface?"#30000000":"#4a000000";blur:26;spread:0;z:-2
  }
  RectangularShadow {
   anchors.fill:parent;radius:parent.radius;offset:Qt.vector2d(0,2)
   color:glassPopupSurface?"#24000000":"#30000000";blur:10;spread:0;z:-1
  }
  Rectangle {
   anchors.fill:parent;anchors.margins:1;radius:parent.radius-1
   color:"transparent";border.color:glassPopupSurface?"#06ffffff":"#14ffffff";border.width:1
  }
  Rectangle {
   x:parent.radius;y:1;width:parent.width-2*parent.radius;height:1
   gradient:Gradient {
    orientation:Gradient.Horizontal
    GradientStop {position:0;color:"transparent"}
    GradientStop {position:0.25;color:glassPopupSurface?"#20ffffff":"#40ffffff"}
    GradientStop {position:0.5;color:glassPopupSurface?"#48ffffff":"#70ffffff"}
    GradientStop {position:0.75;color:glassPopupSurface?"#20ffffff":"#40ffffff"}
    GradientStop {position:1;color:"transparent"}
   }
  }
 }
 PanelWindow {
  id: dock
  anchors { bottom: true; left: true; right: true }
  implicitHeight: 108; color: "transparent"; exclusiveZone: 0
  WlrLayershell.namespace: "dragon-dock"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  property bool revealed: false
  Connections {target:Tasks;function onFullscreenChanged(){if(Tasks.fullscreen)dock.revealed=false;}}
  readonly property bool hidden: (DockLayout.autoHide || Tasks.fullscreen) && !revealed && root.page==="" && !dragging
  property bool dragging:false
  property string dragKey:""
  property int dragFrom:-1
  property int dropIndex:-1
  property real dragX:0
  property real dragOffset:0
  function finishDrag() {
   if(!dragging)return;
   const key=dragKey,to=dropIndex,ids=root.apps.map(e=>e.id);
   dragging=false;dragKey="";dragFrom=-1;dropIndex=-1;
   DockLayout.move(key,to,ids);
   if(!hover.containsMouse)hideTimer.restart();
  }
  function cancelDrag() {dragging=false;dragKey="";dragFrom=-1;dropIndex=-1;if(!hover.containsMouse)hideTimer.restart();}
  readonly property real appsWidth: root.apps.length*50
  readonly property real startX: plate.x+15
  readonly property int hoveredIndex: hover.containsMouse && !hidden && !dragging && root.page!=="app" && hover.pointerX>=startX && hover.pointerX<startX+appsWidth ? Math.floor((hover.pointerX-startX)/50) : -1
  mask: Region { x: plate.x; y: dock.hidden ? dock.height-2 : 20; width: plate.width; height: dock.hidden ? 2 : dock.height-20 }
  BackgroundEffect.blurRegion: Region { item: plate; radius: 18 }
  Timer { id: hideTimer; interval: 650; onTriggered: if(!hover.containsMouse && !dock.dragging && root.page==="") dock.revealed=false }
  Glass {
   id: plate
   x: (dock.width-width)/2; y: dock.hidden ? dock.height+3 : dock.height-70
   width: dock.appsWidth+190; height: 58; radius: 18
   Behavior on y { NumberAnimation {duration:220; easing.type:Easing.OutCubic} }
  }
  MouseArea {
   id: hover
   x: plate.x; y: dock.hidden ? dock.height-2 : 20
   width: plate.width; height: dock.height-y
   hoverEnabled: true
   acceptedButtons: Qt.NoButton
   onEntered: { dock.revealed=true; hideTimer.stop(); }
   onExited: hideTimer.restart()
   property real pointerX: mouseX+ x
   Item {
    id: appRow
    x: 15; y: plate.y-hover.y+5
    width:dock.appsWidth;height:48
    Repeater {
     id: appsRepeater
     model: root.apps
     Item {
      id: cell
      required property var modelData
      required property int index
      width: 50; height: 48
      readonly property bool isDragged:dock.dragging&&dock.dragKey===key
      readonly property int visualIndex: {
       if(!dock.dragging||isDragged)return index;
       if(dock.dragFrom<dock.dropIndex&&index>dock.dragFrom&&index<=dock.dropIndex)return index-1;
       if(dock.dragFrom>dock.dropIndex&&index>=dock.dropIndex&&index<dock.dragFrom)return index+1;
       return index;
      }
      x:isDragged?dock.dragX-dock.startX-dock.dragOffset:visualIndex*50
      z:isDragged?20:0
      Behavior on x {enabled:!cell.isDragged;NumberAnimation{duration:130;easing.type:Easing.OutCubic}}
      readonly property string key: Tasks.key(modelData.id)
      property real wave: dock.hoveredIndex<0 ? 0 : Math.abs(index-dock.hoveredIndex)===0 ? 1 : Math.abs(index-dock.hoveredIndex)===1 ? 0.34 : Math.abs(index-dock.hoveredIndex)===2 ? 0.06 : 0
      Behavior on wave { NumberAnimation { duration:190; easing.type:Easing.OutCubic } }
      Image {
       anchors.horizontalCenter: parent.horizontalCenter
       y: cell.isDragged?-3:4-6*cell.wave; width: 38; height: 38
       source: {
        // Keep Firefox's vendor artwork; resolve other app icons from their
        // desktop entries so user-selected icons (such as Kitty's) are honored.
        if(cell.key==="firefox")return "file:///usr/share/icons/hicolor/scalable/apps/firefox.svg";
        return IconResolver.candidates(cell.modelData)[0]||"";
       }
       fillMode: Image.PreserveAspectFit
       sourceSize: Qt.size(128,128)
       scale: cell.isDragged?1.12:1+0.34*cell.wave
       transformOrigin: Item.Bottom
      }
      Row {
       anchors.horizontalCenter: parent.horizontalCenter
       y: 46
       spacing: 3
       Repeater {
        model: Math.min(Tasks.windowCount(cell.key), 8)
        Rectangle {
         required property int index
         width: 3; height: 3; radius: 1.5
         color: Tasks.isActive(cell.key) ? "#c4746e" : "#c5c9c5"
        }
       }
      }
      MouseArea {
       id:appPointer
       anchors.fill:parent;hoverEnabled:true
       acceptedButtons:Qt.LeftButton|Qt.MiddleButton|Qt.RightButton
       property real pressX:0
       property real pressY:0
       onPressed: mouse=> {
        const point=mapToItem(dock.contentItem,mouse.x,mouse.y);
        pressX=point.x;pressY=point.y;
       }
       onPositionChanged: mouse=> {
        if(!(pressedButtons&Qt.LeftButton))return;
        const point=mapToItem(dock.contentItem,mouse.x,mouse.y);
        if(!dock.dragging&&Math.hypot(point.x-pressX,point.y-pressY)>7){
         root.closePopup();dock.dragKey=cell.key;dock.dragFrom=cell.index;
         dock.dragOffset=pressX-(dock.startX+cell.index*50);dock.dragX=point.x;dock.dragging=true;
        }
        if(dock.dragging){dock.dragX=point.x;dock.dropIndex=Math.max(0,Math.min(root.apps.length-1,Math.floor((point.x-dock.startX)/50)));}
       }
       onReleased: mouse=> {
        if(dock.dragging){dock.finishDrag();return;}
        if(!containsMouse)return;
        if(mouse.button===Qt.RightButton){root.showAppMenu(cell.modelData,cell.index);return;}
        root.closePopup();
        if(mouse.button===Qt.MiddleButton||!Tasks.activate(cell.key))cell.modelData.execute();
       }
       onCanceled:dock.cancelDrag()
      }
      ToolTip.visible: appMouse.hovered && !dock.dragging && root.page===""
      ToolTip.text: modelData.name
      ToolTip.delay: 800
      HoverHandler { id: appMouse }
     }
    }
   }
   Row {
    x: 15+dock.appsWidth+10; y: plate.y-hover.y+13; spacing: 12
    Rectangle {width:1;height:28;color:"#59625e5a"}
    Button {
     id: statusButton
     width:62;height:32;padding:0
     onClicked:root.togglePage("settings")
     background:Rectangle{radius:10;color:statusButton.hovered?"#163e3830":"transparent";Behavior on color{ColorAnimation{duration:120}}}
     contentItem: BatteryIndicator {
      id:batteryIndicator
      battery:root.state.battery||null
      lowPower:root.state.profile==="power-saver"
      active:dock.visible&&!dock.hidden
     }
     ToolTip.visible:hovered;ToolTip.text:batteryIndicator.description+"\nClick for quick settings";ToolTip.delay:500
    }
    Button {
     id: clockButton
     width:60;height:32;padding:0
     onClicked:root.togglePage("calendar")
     background:Item{}
     contentItem:Text {text:Qt.formatDateTime(clock.date,"HH:mm");font.family:"Noto Sans";font.pixelSize:18;font.weight:Font.Medium;font.letterSpacing:0.3;color:clockButton.hovered?"#e6c384":"#dcd7c5";verticalAlignment:Text.AlignVCenter;horizontalAlignment:Text.AlignHCenter;Behavior on color{ColorAnimation{duration:150}}}
     ToolTip.visible:hovered;ToolTip.text:Qt.formatDateTime(clock.date,"dddd, d MMMM");ToolTip.delay:700
    }
   }
  }
 }
 PanelWindow {
  id: overlay
  visible: root.page!==""
  screen: dock.screen
  anchors {top:true;bottom:true;left:true;right:true}
  color:"transparent";exclusiveZone:0
  WlrLayershell.namespace:"dragon-quick-settings"
  WlrLayershell.layer:WlrLayer.Overlay
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive
  // Let the real dock receive its own clicks and drags while a popup is open.
  mask: Region {
   width:overlay.width;height:overlay.height
   Region {
    intersection:Intersection.Subtract
    x:plate.x;y:overlay.height-dock.height+20
    width:plate.width;height:dock.height-20
   }
  }
  BackgroundEffect.blurRegion: Region {
   x:Math.round(popup.x);y:Math.round(popup.y);width:Math.round(popup.width)
   height:Math.max(0,Math.round(root.page==="app"?Math.min(popup.height,menuViewport.height-popup.y):popup.height))
   radius:19
  }
  MouseArea {
   anchors.fill:parent
   acceptedButtons:Qt.LeftButton|Qt.MiddleButton|Qt.RightButton
   onClicked:root.closePopup()
  }
  Item {
   anchors.fill:parent;focus:true;Keys.onEscapePressed:root.closePopup()
  }
  Item {
   id:menuViewport
   width:overlay.width
   height:root.page==="app"?overlay.height-dock.height+plate.y:overlay.height
   clip:root.page==="app"
  Glass {
   id: popup
   glassPopupSurface: true
   property real riseProgress:1
   opacity:root.page==="app"?riseProgress:1
   NumberAnimation {id:appMenuRise;target:popup;property:"riseProgress";from:0;to:1;duration:160;easing.type:Easing.OutCubic}
   NumberAnimation {
    id:appMenuFall;target:popup;property:"riseProgress";to:0;duration:140;easing.type:Easing.InCubic
    onFinished: {root.appMenuClosing=false;root.page="";}
   }
   Keys.onEscapePressed: root.closePopup()
   x: Math.max(16, Math.min(parent.width-width-16,root.page==="app"?root.menuOriginX-width/2:dock.startX+dock.appsWidth-110))
   y: overlay.height-height-84+(root.page==="app"?(1-riseProgress)*(height+84):0)
   width:root.page==="app"?216:420; height:root.page==="app"?appMenuColumn.implicitHeight+12:root.page==="calendar"?365:Math.min(settingsContent.implicitHeight+88,overlay.height-130)
   MouseArea { anchors.fill:parent;onClicked:{} }
   Column {
    id:appMenuColumn
    enabled:!root.appMenuClosing
    visible:root.page==="app"
    anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.margins:6
    spacing:2
    Repeater {
     id:appMenuRepeater
     model:root.menuItems
     Button {
      id:menuButton
      required property var modelData
      width:appMenuColumn.width;height:34;leftPadding:12;rightPadding:12
      onClicked:root.runAppAction(modelData.id)
      contentItem:RowLayout {
       spacing:10
       Text {text:menuButton.modelData.icon;font.family:"JetBrainsMono Nerd Font";font.pixelSize:15;color:"#b9aa90"}
       LabelText {text:menuButton.modelData.text;Layout.fillWidth:true;font.pixelSize:12;color:"#dcd7c5"}
      }
      background:Rectangle {radius:8;color:menuButton.down?"#594136":menuButton.hovered?"#373029":"transparent"}
     }
    }
   }
   ColumnLayout {
    visible:root.page!=="app"
    anchors.fill:parent;anchors.margins:20;spacing:14
    RowLayout {
     Layout.fillWidth:true
     LabelText {text:root.page==="calendar" ? Qt.formatDateTime(clock.date,"dddd, d MMMM") : "Quick settings";font.pixelSize:18;font.weight:Font.DemiBold;Layout.fillWidth:true}
     Action {text:"×";implicitWidth:30;onClicked:root.closePopup()}
    }
    ScrollView {
     visible:root.page==="settings";Layout.fillWidth:true;Layout.fillHeight:true;clip:true
     contentWidth:availableWidth
     ColumnLayout {
      id: settingsContent
      width:parent.width;spacing:9
      RowLayout {
       Layout.fillWidth:true;spacing:10
       ColumnLayout {
        Layout.fillWidth:true;Layout.preferredWidth:1;spacing:4
        ToggleTile {heading:"Wi-Fi";glyph:"󰤨";active:root.state.wifi||false;detail:active ? ((root.state.networks||[]).find(n=>n.active)||{name:"Not connected"}).name : "Off";Layout.fillWidth:true;onClicked:root.act('wifi',!root.state.wifi)}
        Action {text:"Networks  ›";Layout.fillWidth:true;implicitHeight:27;onClicked:{networkList.visible=!networkList.visible;root.act('scan')}}
       }
       ColumnLayout {
        Layout.fillWidth:true;Layout.preferredWidth:1;spacing:4
        ToggleTile {heading:"Bluetooth";glyph:"󰂯";active:root.state.bluetooth||false;detail:active?"Available":"Off";Layout.fillWidth:true;enabled:root.state.bluetoothAvailable||false;onClicked:root.act('bluetooth',!root.state.bluetooth)}
        Action {text:"Devices  ›";Layout.fillWidth:true;implicitHeight:27;onClicked:{deviceList.visible=!deviceList.visible;if(root.state.bluetooth)root.act('btscan')}}
       }
      }
      ColumnLayout {
       id:networkList;visible:false;Layout.fillWidth:true
       Repeater {model:(root.state.networks||[]).slice(0,7);Action {required property var modelData;Layout.fillWidth:true;text:(modelData.active?"✓ ":"")+modelData.name+"  "+modelData.signal+"%";onClicked:root.act('connect',modelData.name)}}
      }
      ColumnLayout {
       id:deviceList;visible:false;Layout.fillWidth:true
       Repeater {model:root.state.devices||[];Action {required property var modelData;Layout.fillWidth:true;text:(modelData.connected?"✓ ":"")+modelData.name;onClicked:root.act(modelData.connected?'btdisconnect':'btconnect',modelData.address)}}
       Action {text:"Pair a new device…";Layout.fillWidth:true;onClicked:root.act('btsetup')}
      }
      Rectangle {Layout.fillWidth:true;implicitHeight:1;color:"#28625e5a";Layout.topMargin:4;Layout.bottomMargin:4}
      RowLayout {
       Layout.fillWidth:true
       LabelText {text:"Sound";font.weight:Font.DemiBold;Layout.fillWidth:true}
       Action {text:root.state.mute?"Unmute":"Mute";implicitHeight:27;implicitWidth:62;onClicked:root.act('mute')}
       LabelText {text:Math.round(volumeSlider.value*100)+"%";font.pixelSize:12;color:"#b6aa94";Layout.preferredWidth:36;horizontalAlignment:Text.AlignRight}
      }
      DragonSlider {
       id:volumeSlider
       objectName:"volumeSlider"
       Layout.fillWidth:true;from:0;to:1;stepSize:0.01
       glyph:root.state.mute?"󰝟":"󰕾"
       serviceValue:root.state.volume||0
       onCommit:amount=>root.act('volume',amount)
      }
      DragonCombo {
       Layout.fillWidth:true;model:root.state.sinks||[];textRole:"name";currentIndex:Math.max(0,model.findIndex(x=>x.id===root.state.defaultSink));displayText:"Output · "+currentText
       onActivated:root.act('output',model[currentIndex].id)
      }
      RowLayout {
       visible:root.state.brightness>=0;Layout.fillWidth:true;Layout.topMargin:5
       LabelText {text:"Display brightness";font.weight:Font.DemiBold;Layout.fillWidth:true}
       LabelText {text:Math.round(brightnessSlider.value)+"%";font.pixelSize:12;color:"#b6aa94"}
      }
      DragonSlider {
       id:brightnessSlider
       objectName:"brightnessSlider"
       visible:root.state.brightness>=0
       Layout.fillWidth:true;from:1;to:100;stepSize:1;glyph:"󰃠"
       serviceValue:root.state.brightness>=0?root.state.brightness:1
       onCommit:amount=>root.act('brightness',amount)
      }
      Rectangle {Layout.fillWidth:true;implicitHeight:1;color:"#28625e5a";Layout.topMargin:6;Layout.bottomMargin:6}
      LabelText {text:batteryIndicator.description;Layout.fillWidth:true;wrapMode:Text.Wrap}
      DragonCombo {Layout.fillWidth:true;model:root.state.profiles||[];currentIndex:Math.max(0,model.indexOf(root.state.profile));displayText:"Power: "+currentText;onActivated:root.act('profile',currentText)}
      RowLayout {
       Action {visible:root.state.nightAvailable||false;Layout.fillWidth:true;text:root.state.night?"Night Light · On":"Night Light · Off";onClicked:root.act('night',!root.state.night)}
       Action {visible:root.state.dndAvailable||false;Layout.fillWidth:true;text:root.state.dnd?"DND · On":"DND · Off";onClicked:root.act('dnd',!root.state.dnd)}
      }
      Repeater {
       model:root.state.players||[]
       ColumnLayout {
        required property var modelData
        Layout.fillWidth:true
        LabelText {text:modelData.title;Layout.fillWidth:true}
        RowLayout {
         Action {text:"⏮";enabled:modelData.control;onClicked:root.act('media','Previous',modelData.service)}
         Action {text:modelData.playing?"Pause":"Play";enabled:modelData.control;onClicked:root.act('media','PlayPause',modelData.service)}
         Action {text:"⏭";enabled:modelData.control;onClicked:root.act('media','Next',modelData.service)}
        }
       }
      }
      LabelText {visible:text!=="";text:root.state.message||"";color:"#c4746e";wrapMode:Text.Wrap;Layout.fillWidth:true}
     }
    }
    ColumnLayout {
     visible:root.page==="calendar";Layout.fillWidth:true;Layout.fillHeight:true
     property date month: new Date(clock.date.getFullYear(),clock.date.getMonth(),1)
     id:calendar
     RowLayout {
      Action {text:"‹";onClicked:calendar.month=new Date(calendar.month.getFullYear(),calendar.month.getMonth()-1,1)}
      LabelText {text:Qt.formatDateTime(calendar.month,"MMMM yyyy");Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter}
      Action {text:"›";onClicked:calendar.month=new Date(calendar.month.getFullYear(),calendar.month.getMonth()+1,1)}
     }
     GridLayout {
      columns:7;Layout.fillWidth:true;Layout.fillHeight:true
      Repeater {model:["Mo","Tu","We","Th","Fr","Sa","Su"];LabelText {required property string modelData;text:modelData;Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;color:"#a6a69c"}}
      Repeater {
       model:42
       Rectangle {
        required property int index
        property int day: index-((calendar.month.getDay()+6)%7)+1
        property bool validDay:day>0&&day<=new Date(calendar.month.getFullYear(),calendar.month.getMonth()+1,0).getDate()
        property bool today:validDay&&day===clock.date.getDate()&&calendar.month.getMonth()===clock.date.getMonth()&&calendar.month.getFullYear()===clock.date.getFullYear()
        Layout.fillWidth:true;Layout.fillHeight:true;radius:6;color:today?"#67413b":"transparent"
        LabelText {anchors.centerIn:parent;text:parent.validDay?parent.day:"";color:parent.today?"#e6c384":"#c5c9c5"}
       }
      }
     }
    }
   }
  }
  }
 }
}

// SPDX-License-Identifier: MPL-2.0
// Battery geometry and bolt path adapted from render-title.swift:
// Copyright (c) 2026 Nicholas Smith
// https://github.com/nicholaspsmith/battery-time-menubar/blob/main/render-title.swift
// QML port: Linux power state, native-sized vectors and brief state transitions.
// This Source Code Form is subject to the Mozilla Public License, v. 2.0.
// https://mozilla.org/MPL/2.0/
import QtQuick
import QtQuick.Shapes

Item {
 id: indicator
 property var battery: null
 property bool active: true
 property bool lowPower: false
 readonly property bool hasBattery: battery!==null && battery!==undefined
 readonly property int level: hasBattery?Math.max(0,Math.min(100,Math.round(battery.level))):0
 readonly property bool externalPower: !hasBattery || battery.externalPower===true
 readonly property bool charging: hasBattery && battery.status==="Charging"
 readonly property bool full: hasBattery && (level>=100 || battery.status==="Full")
 readonly property bool needsCharge: hasBattery && level<=20 && !externalPower && !charging
 readonly property string mode: charging?"charging":full?"full":externalPower?"wall":needsCharge?"low":"battery"
 readonly property color accent: needsCharge?"#ff453a":lowPower?"#ffd60a":charging?"#32d74b":"#f2f2f2"
 readonly property string description: (hasBattery?"Battery · "+level+"%":"Power")+"\n"+(charging?"Charging":full?"Fully charged":externalPower?"Battery Is Not Charging":needsCharge?"Low Battery":"On Battery")+"\nPower Source: "+(externalPower?"Power Adapter":"Battery")+(lowPower?"\nLow Power Mode":"")
 readonly property bool animating: active && visible
 readonly property bool showPower: charging || externalPower
 readonly property real fillWidth: (26-2*1.3)*(hasBattery?level/100:1)
 implicitWidth: 62
 implicitHeight: 32
 property real stateReveal: 1
 function animatePowerTransition() {
  if(!reveal)return;
  reveal.stop();stateReveal=1;
  if(animating)reveal.restart();
 }
 onModeChanged:animatePowerTransition()
 onExternalPowerChanged:animatePowerTransition()
 Component.onCompleted:animatePowerTransition()
 NumberAnimation {id:reveal;target:indicator;property:"stateReveal";from:0.6;to:1;duration:180;easing.type:Easing.OutCubic}
 onAnimatingChanged:if(!animating){reveal.stop();stateReveal=1;}

 // The published renderer places the percentage beside the 26x13 battery.
 Text {
  x:0;width:29;height:indicator.height
  text:indicator.hasBattery?indicator.level+"%":"AC"
  font.family:"Noto Sans";font.pixelSize:11;font.weight:Font.Medium
  color:"#f2f2f2";horizontalAlignment:Text.AlignRight;verticalAlignment:Text.AlignVCenter
 }
 Item {
  id:glyph
  x:33;y:(indicator.height-height)/2;width:28;height:13
  opacity:indicator.stateReveal
  Rectangle {
   width:26;height:13;radius:3.2;color:"transparent"
   border.width:1.2;border.color:"#b8ffffff"
  }
  Rectangle {
   x:1.3;y:1.3;width:indicator.fillWidth;height:10.4;radius:1.9
   color:indicator.accent
   Behavior on width {NumberAnimation {duration:200;easing.type:Easing.OutCubic}}
   Behavior on color {ColorAnimation {duration:160}}
  }
  Rectangle {x:26;y:3.75;width:2;height:5.5;radius:0.9;color:"#a6ffffff"}
  Shape {
   id:powerSymbol
   visible:indicator.showPower
   x:indicator.charging?8.75:8;y:indicator.charging?-1.5:1.5
   width:indicator.charging?8.5:10;height:indicator.charging?16:10
   preferredRendererType:Shape.CurveRenderer
   ShapePath {
    strokeWidth:2.3;strokeColor:"#161616";fillColor:"#161616"
    capStyle:ShapePath.RoundCap;joinStyle:ShapePath.RoundJoin
    PathSvg {path:indicator.charging?"M 4.765 0 L 0 9.557 L 3.735 9.557 L 2.64 16 L 8.5 5.64 L 4.765 5.64 Z":"M 2 3 L 2 5.6 Q 2 8 4 8.4 L 4 10 L 6 10 L 6 8.4 Q 8 8 8 5.6 L 8 3 Z M 3 0 L 3 3 M 7 0 L 7 3"}
   }
   ShapePath {
    strokeWidth:0.8;strokeColor:"#f5f5f5";fillColor:"#f5f5f5"
    capStyle:ShapePath.RoundCap;joinStyle:ShapePath.RoundJoin
    PathSvg {path:indicator.charging?"M 4.765 0 L 0 9.557 L 3.735 9.557 L 2.64 16 L 8.5 5.64 L 4.765 5.64 Z":"M 2 3 L 2 5.6 Q 2 8 4 8.4 L 4 10 L 6 10 L 6 8.4 Q 8 8 8 5.6 L 8 3 Z M 3 0 L 3 3 M 7 0 L 7 3"}
   }
  }
 }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Button {
  id: tile
  property string heading: ""
  property string detail: ""
  property string glyph: ""
  property bool active: false
  implicitHeight: 72
  padding: 12
  contentItem: RowLayout {
   spacing:11
   Rectangle {
    width:34;height:34;radius:11;color:tile.active?"#d2b58b":"#3a352f"
    Text {anchors.centerIn:parent;text:tile.glyph;font.family:"JetBrainsMono Nerd Font";font.pixelSize:20;color:tile.active?"#231e19":"#aaa497"}
   }
   ColumnLayout {
    spacing:3;Layout.fillWidth:true
    Text {font.family:"Noto Sans";elide:Text.ElideRight;text:tile.heading;font.weight:Font.DemiBold;Layout.fillWidth:true;color:"#dfd9c9"}
    Text {font.family:"Noto Sans";elide:Text.ElideRight;text:tile.detail;font.pixelSize:11;color:tile.active?"#c2ac8a":"#88867d";Layout.fillWidth:true}
   }
  }
  background: Rectangle {radius:13;color:tile.down?"#473b2e":tile.hovered?"#383129":tile.active?"#302a23":"#25221f";border.color:tile.active?"#646e5a43":"#28625e5a";Behavior on color{ColorAnimation{duration:140}}}
 }

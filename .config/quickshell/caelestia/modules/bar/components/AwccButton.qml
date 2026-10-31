import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Images
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root
    implicitWidth: 24
    implicitHeight: 26

    Image {
        anchors.centerIn: parent
        width: 20
        height: 20
        source: "file://" + Quickshell.shellPath("assets/awcc-alien.png")
        sourceClipRect: Qt.rect(640, 0, 1280, 1280)
        fillMode: Image.PreserveAspectFit
        smooth: true
        // Filter the large source during reduction and render the tint at display resolution.
        mipmap: true
        layer.enabled: true
        layer.smooth: true
        layer.mipmap: true
        layer.textureSize: Qt.size(Math.ceil(width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1) * 2),
                                  Math.ceil(height * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1) * 2))
        layer.effect: Colouriser {
            sourceColor: "#1e1e1f"
            colorizationColor: Colours.palette.m3primary
        }
        scale: hit.containsMouse ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: 140 } }
    }

    StateLayer {
        id: hit
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/awcc-launch"])
    }
}

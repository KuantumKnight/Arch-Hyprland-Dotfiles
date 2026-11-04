// Adapted from 43PR/dotfiles hyprquickpaper; MIT license in LICENSE.
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Wayland

PanelWindow {
    id: main
    readonly property real ui: Screen.height / 1080
    readonly property real refWidth: 1920
    readonly property real refHeight: 500
    property int speed: 4200
    property int animDuration: 240
    property real zoomScale: 1.15
    property real edgeScale: 0.86
    property real skewFactor: 0
    property real baseSpacing: 0
    property real edgeSpacing: 0
    property int startPosition: 0
    readonly property bool previewOnly: Quickshell.env("WALLPAPER_PICKER_PREVIEW") === "1"
    property bool shadowEnabled: true
    property color shadowColor: "#000000"
    property real shadowOpacity: 0.4
    property real shadowBlur: 0.45
    property real shadowX: 6
    property real shadowY: 6
    property string wallpaperPath: configs.wallpaper_path.replace("$HOME", Quickshell.env("HOME"))
    property string cachePath: configs.cache_path.replace("$HOME", Quickshell.env("HOME"))

    property bool showEmpty: false
    readonly property bool looksEmpty: wallpaperPath !== ""
                                       && folderModel.status === FolderListModel.Ready
                                       && folderModel.count === 0

    onLooksEmptyChanged: {
        if (looksEmpty) {
            emptyDelay.restart()
        } else {
            emptyDelay.stop()
            showEmpty = false
        }
    }

    implicitHeight: Screen.height
    implicitWidth: Screen.width
    color: "transparent"
    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 1
    WlrLayershell.namespace: "personal-wallpaper-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: Quickshell.execDetached(["bash", Quickshell.shellPath("cache.sh"), Quickshell.shellDir])

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures
            property string border_color
        }
    }

    FileView {
        id: currentWallpaper
        path: Quickshell.env("HOME") + "/.config/hypr/wallpaper"
        blockLoading: true
        printErrors: false
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + main.wallpaperPath
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif", "*.mp4", "*.mkv", "*.webm", "*.mov"]
        caseSensitive: false
        sortField: FolderListModel.Name
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        onClicked: Qt.quit()
        onWheel: function(wheel) {
            list.userMoved = true
            const delta = wheel.angleDelta.y || wheel.angleDelta.x
            if (delta !== 0) list.moveSelection(delta > 0 ? -1 : 1, 1)
            wheel.accepted = true
        }
    }

    Timer {
        id: emptyDelay
        interval: 300
        onTriggered: main.showEmpty = main.looksEmpty
    }

    Column {
        id: emptyState
        anchors.centerIn: parent
        spacing: 10 * main.ui
        z: 2
        visible: main.showEmpty

        Text {
            text: "No wallpapers found"
            color: "#ffffff"
            font.pixelSize: 22 * main.ui
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Add images or live wallpapers to:"
            color: "#aaaaaa"
            font.pixelSize: 13 * main.ui
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TextEdit {
            id: pathText
            text: main.wallpaperPath
            color: "#dddddd"
            font.pixelSize: 14 * main.ui
            readOnly: true
            selectByMouse: true
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ListView {
        id: list
        width: parent.width
        height: tileHeight * main.zoomScale
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        z: 1
        focus: true
        model: folderModel
        orientation: ListView.Horizontal
        spacing: 0
        clip: true
        cacheBuffer: tileWidth * 2
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds

        property int selectedIndex: main.startPosition
        // Follow selection even when scrolling reaches either end of the list.
        property real magnifiedIndex: selectedIndex
        Behavior on magnifiedIndex {
            enabled: list.ready
            NumberAnimation {
                duration: main.animDuration
                easing.type: Easing.OutCubic
            }
        }

        readonly property real tileHeight: Math.min(340 * main.ui, main.height * 0.42)
        readonly property real tileWidth: width / Math.max(1, configs.number_of_pictures)

        readonly property real viewportCenterX: width / 2
        readonly property real falloffRadius: (main.refWidth / 2) * main.ui

        readonly property real step: tileWidth + main.baseSpacing * main.ui
        readonly property real sideMargin: Math.max(0, viewportCenterX - tileWidth / 2)
        property bool ready: false
        property bool userMoved: false
        property real lastMouseX: -1
        property real lastMouseY: -1

        leftMargin: 0
        rightMargin: 0

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }
        // contentX that puts tile i exactly in the middle of the viewport.
        // Uses the real delegate position when it exists, else the margin-based formula.
        function centerX(i) {
            const it = itemAtIndex(i)
            const target = it ? it.x + tileWidth / 2 - width / 2 : i * step - sideMargin
            return Math.max(0, Math.min(target, Math.max(0, contentWidth - width)))
        }
        function ensureVisibleAnimated(i) { contentX = centerX(i) }

        function centerOnStart() {
            if (userMoved || count <= 0 || configs.number_of_pictures <= 0) return
            let desired = main.startPosition
            const current = currentWallpaper.text().trim()
            for (let i = 0; i < count; i++) {
                if (folderModel.get(i, "filePath") === current) { desired = i; break }
            }
            selectedIndex = clampIndex(desired)
            contentX = centerX(selectedIndex)
            ready = true
        }

        function activateCurrent() {
            if (count <= 0) return
            if (main.previewOnly) {
                ensureVisibleAnimated(selectedIndex)
                return
            }
            Quickshell.execDetached(["bash", Quickshell.shellPath("commands.sh"), folderModel.get(selectedIndex, "filePath")])
            Qt.quit()
        }

        function moveSelection(delta, speedMultiplier) {
            selectedIndex = clampIndex(selectedIndex + delta)
            ensureVisibleAnimated(selectedIndex)
        }

        onCountChanged: centerOnStart()
        onWidthChanged: centerOnStart()
        onTileWidthChanged: centerOnStart()

        Connections {
            target: configs
            function onNumber_of_picturesChanged() { list.centerOnStart() }
        }

        Behavior on contentX {
            enabled: list.ready
            NumberAnimation {
                duration: main.animDuration
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: delegateItem
            width: list.tileWidth
            height: list.height

            z: scaleFactor
            property bool active: index === list.selectedIndex
            readonly property bool isGif: fileName.toLowerCase().endsWith(".gif")
            readonly property bool isVideo: /\.(mp4|mkv|webm|mov)$/i.test(fileName)
            readonly property real baseWidth: list.tileWidth
            readonly property real baseCenterX: x - list.contentX + baseWidth / 2
            readonly property real distance: Math.abs(index - list.magnifiedIndex) * list.step
            // Continuous easing keeps magnification fluid between card positions.
            readonly property real scaleFactor: {
                const d = Math.min(2, distance / list.step)
                const t = d < 1 ? d : d - 1
                const eased = t * t * (3 - 2 * t)
                return d < 1 ? main.zoomScale + (0.88 - main.zoomScale) * eased
                             : 0.88 + (0.74 - 0.88) * eased
            }
            readonly property real edgeOffset: 0
            // Selection also moves this focal point at the ends, where contentX stops.
            readonly property real parallax: Math.max(-1, Math.min(1,
                (index - list.magnifiedIndex) / 3))

            Item {
                id: content
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                width: delegateItem.baseWidth * delegateItem.scaleFactor
                height: list.tileHeight * delegateItem.scaleFactor
                x: (delegateItem.baseWidth - width) / 2 + delegateItem.edgeOffset
                scale: 1.0
                opacity: delegateItem.active || cardMouse.containsMouse ? 1.0 : 0.84
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120 } }


                Rectangle {
                    anchors.fill: parent
                    color: "#242432"
                }

                Text {
                    id: alt
                    text: ""
                    color: configs.border_color
                    anchors.centerIn: parent
                    font.pixelSize: 16 * main.ui
                    transform: Shear { xFactor: main.skewFactor }
                }

                Image {
                    id: img
                    // Keep the landscape image behind the portrait viewport instead of
                    // cropping away its sides before the pan can reveal them.
                    width: Math.max(parent.width * 1.8,
                        height * (implicitWidth > 0 && implicitHeight > 0 ? implicitWidth / implicitHeight : 1.78))
                    height: parent.height * 1.04
                    x: (parent.width - width) / 2 - delegateItem.parallax * (width - parent.width) / 2
                    y: (parent.height - height) / 2
                    opacity: 1
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    source: "file://" + main.cachePath + fileName + ".png"
                    sourceSize.width: 960
                    sourceSize.height: 600
                    transform: Shear { xFactor: main.skewFactor }

                    Timer {
                        id: retryTimer
                        interval: 1000
                        repeat: false
                        onTriggered: { const s = img.source; img.source = ""; img.source = s }
                    }

                    onStatusChanged: {
                        if (status === Image.Error) { alt.text = "Preparing…"; retryTimer.start() }
                        else if (status === Image.Ready) { alt.text = ""; retryTimer.stop() }
                    }
                }
                Rectangle {
                    z: 11
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8 * main.ui
                    width: liveLabel.implicitWidth + 14 * main.ui
                    height: liveLabel.implicitHeight + 8 * main.ui
                    radius: 5 * main.ui
                    color: "#cc1e1e2e"
                    visible: delegateItem.isVideo || delegateItem.isGif
                    Text {
                        id: liveLabel
                        anchors.centerIn: parent
                        text: "LIVE"
                        color: "#cdd6f4"
                        font.pixelSize: 10 * main.ui
                        font.bold: true
                    }
                }
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: list.ready
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: function(mouse) {
                    const p = mapToItem(null, mouse.x, mouse.y)
                    if (p.x === list.lastMouseX && p.y === list.lastMouseY) return
                    list.lastMouseX = p.x
                    list.lastMouseY = p.y
                    list.userMoved = true
                    list.selectedIndex = index
                }
                onClicked: {
                    list.userMoved = true
                    list.selectedIndex = index
                    list.activateCurrent()
                }
                onWheel: function(wheel) {
                    list.userMoved = true
                    const delta = wheel.angleDelta.y || wheel.angleDelta.x
                    if (delta !== 0) list.moveSelection(delta > 0 ? -1 : 1, 1)
                    wheel.accepted = true
                }
            }
        }

        Keys.onPressed: function(event) {
            const fast = event.isAutoRepeat ? 2 : 1
            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_A:
                userMoved = true
                moveSelection(-1, fast)
                break
            case Qt.Key_Right:
            case Qt.Key_D:
                userMoved = true
                moveSelection(1, fast)
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                if (count > 0) activateCurrent()
                break
            case Qt.Key_W:
            case Qt.Key_Escape:
                Qt.quit()
                break
            default:
                return
            }
            event.accepted = true
        }
    }
}

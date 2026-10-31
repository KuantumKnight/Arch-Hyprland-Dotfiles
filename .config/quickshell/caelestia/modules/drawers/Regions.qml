pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    // A zero-width frame must not reserve an invisible strip that intercepts window controls.

    x: bar.clampedWidth + win.dragMaskPadding
    y: borderThickness + win.dragMaskPadding
    width: win.width - bar.clampedWidth - borderThickness - win.dragMaskPadding * 2
    height: win.height - borderThickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        // Reserve the top edge only across the dashboard's own hover target.
        height: Math.max(panel.height * (1 - root.panels.dashboard.offsetScale) + root.borderThickness,
                         root.win.contentItem.Config.dashboard.enabled && root.win.contentItem.Config.dashboard.showOnHover
                         ? root.win.contentItem.Config.border.minThickness : 0)
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        // Match Interactions.withinPanelHeight even before the OSD content is loaded.
        y: panel.y + root.borderThickness - root.win.contentItem.Config.border.rounding
        height: panel.height + root.win.contentItem.Config.border.rounding * 2
        width: Math.max(panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness + sessionRegion.width,
                        root.win.contentItem.Config.osd.enabled ? root.win.contentItem.Config.border.minThickness : 0)
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.borderThickness
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.popoutsWrapper
        width: panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.bar.implicitWidth
        y: panel.y + root.borderThickness
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}

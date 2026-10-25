// RibOS dark mode toggle: a panel button that runs `ribos-theme toggle`.
// Structured like Plasma's own "Show Desktop" button: the root item is the
// button itself and declares its size, so panels always give it room.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    // The panel's own background tells us which mode is active, so the icon
    // stays correct however the theme was changed.
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: dark ? "weather-clear-night" : "weather-clear"
    Plasmoid.onActivated: runner.connectSource("ribos-theme toggle")

    toolTipMainText: dark ? i18n("Dark mode is on") : i18n("Light mode is on")
    toolTipSubText: i18n("Click to switch to %1 mode", dark ? i18n("light") : i18n("dark"))

    Layout.minimumWidth: Kirigami.Units.iconSizes.medium
    Layout.minimumHeight: Kirigami.Units.iconSizes.medium
    Layout.maximumWidth: Layout.minimumWidth
    Layout.maximumHeight: Layout.minimumHeight
    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Plasmoid.activated()

        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            source: Plasmoid.icon
            active: mouseArea.containsMouse
        }
    }
}

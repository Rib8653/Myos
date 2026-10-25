// RibOS dark mode toggle: a panel button that runs `ribos-theme toggle`.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    // The panel's own background tells us which mode is active, so the icon
    // stays correct however the theme was changed.
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5

    preferredRepresentation: compactRepresentation
    toolTipMainText: dark ? i18n("Dark mode is on") : i18n("Light mode is on")
    toolTipSubText: i18n("Click to switch to %1 mode", dark ? i18n("light") : i18n("dark"))

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }

    compactRepresentation: MouseArea {
        hoverEnabled: true
        onClicked: runner.connectSource("ribos-theme toggle")

        Kirigami.Icon {
            anchors.fill: parent
            source: root.dark ? "weather-clear-night" : "weather-clear"
            active: parent.containsMouse
        }
    }
}

/*
    RibOS start menu: a Windows 11 style launcher (search box, pinned apps grid,
    recommended files, all apps list, user and power buttons).
    Built on the same models as Plasma's Kickoff (org.kde.plasma.private.kicker).
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: startMenu

    //BEGIN Models
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false
        appletInterface: startMenu
        appNameFormat: 0              // just the app name, like Windows
        flat: true
        sorted: true
        showSeparators: false
        showTopLevelItems: true
        showAllApps: true             // row 1 = "All Applications"
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: true

        Component.onCompleted: {
            favoritesModel.initForClient("org.ribos.startmenu.favorites.instance-" + Plasmoid.id)
            // First login: copy the default pins (contents/config/main.xml).
            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favorites)
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true
            }
        }
    }

    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        appletInterface: startMenu
        mergeResults: true
        favoritesModel: startMenu.rootModel.favoritesModel
    }

    readonly property Kicker.RecentUsageModel recentDocsModel: Kicker.RecentUsageModel {
        favoritesModel: startMenu.rootModel.favoritesModel
        shownItems: Kicker.RecentUsageModel.OnlyDocs
    }

    //END

    Plasmoid.icon: Plasmoid.configuration.icon
    toolTipMainText: i18n("Start")
    toolTipSubText: ""
    preferredRepresentation: compactRepresentation
    fullRepresentation: FullRepresentation {}

    // Taskbar button: just the icon, square, filling the panel height.
    compactRepresentation: MouseArea {
        id: button
        property bool wasExpanded: false

        Layout.minimumWidth: Kirigami.Units.iconSizes.medium
        Layout.minimumHeight: Kirigami.Units.iconSizes.medium
        Layout.preferredWidth: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : height
        Layout.preferredHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : height

        hoverEnabled: true
        Accessible.name: i18n("Start")
        Accessible.role: Accessible.Button

        onPressed: wasExpanded = startMenu.expanded
        onClicked: startMenu.expanded = !wasExpanded

        Kirigami.Icon {
            // Same visual size as the taskbar's app icons next to it.
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.width, parent.height) * 0.8)
            height: width
            roundToIconSize: false
            source: Plasmoid.icon
            active: button.containsMouse || startMenu.expanded
        }
    }

    Kicker.ProcessRunner { id: processRunner }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        // Make the Super key (activateLauncherMenu) toggle the menu.
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = true
        }
    }
}

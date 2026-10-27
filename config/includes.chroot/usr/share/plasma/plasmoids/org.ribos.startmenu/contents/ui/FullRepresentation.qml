/*
    The start menu popup, laid out like Windows 11:

        [ Search for apps, settings and documents       ]
        Pinned                                 All apps >
        [] [] [] [] [] []
        [] [] [] [] [] []
        [] [] [] [] [] []
        Recommended
        [doc]  name              [doc]  name
        ------------------------------------------------
        (avatar) User name                          (power)

    "All apps" and search results replace the middle part.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

Item {
    id: root

    readonly property int columns: 6
    readonly property int tileWidth: Kirigami.Units.gridUnit * 5
    readonly property int tileHeight: Kirigami.Units.gridUnit * 5
    readonly property int pad: Kirigami.Units.gridUnit

    Layout.minimumWidth: columns * tileWidth + 2 * pad
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: Kirigami.Units.gridUnit * 34
    Layout.preferredHeight: Layout.minimumHeight
    Layout.maximumHeight: Layout.minimumHeight

    property string page: "home"            // "home" or "apps"
    property var appsModel: null             // rootModel row 1 = all applications
    readonly property bool searching: searchField.text.length > 0
    readonly property var favorites: startMenu.rootModel.favoritesModel
    readonly property var searchResults: startMenu.runnerModel.count > 0 ? startMenu.runnerModel.modelForRow(0) : null

    function close() {
        startMenu.expanded = false
    }

    // Start the item at `index` of a Kicker model, then close the menu.
    function launch(model, index) {
        if (model && index >= 0) {
            model.trigger(index, "", null)
        }
        close()
    }

    // Any printable key typed while browsing goes to the search box.
    function forwardToSearch(event) {
        if (event.text.length > 0 && event.text.trim().length > 0 && !(event.modifiers & Qt.ControlModifier)) {
            searchField.forceActiveFocus()
            searchField.text += event.text
            event.accepted = true
        }
    }

    Binding {
        target: startMenu.runnerModel
        property: "query"
        value: searchField.text
    }

    Connections {
        target: startMenu.rootModel
        function onRefreshed() {
            root.appsModel = startMenu.rootModel.modelForRow(1)
        }
    }

    Connections {
        target: startMenu
        function onExpandedChanged() {
            if (startMenu.expanded) {
                root.page = "home"
                powerFlyout.visible = false
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: {
        startMenu.rootModel.refresh()
        root.appsModel = startMenu.rootModel.modelForRow(1)
        searchField.forceActiveFocus()
    }

    ContextMenu { id: contextMenu }

    KCoreAddons.KUser { id: kuser }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: root.pad
            spacing: Kirigami.Units.largeSpacing

            PlasmaExtras.SearchField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Search for apps, settings and documents")
                focus: true

                Keys.onReturnPressed: root.launch(root.searchResults, searchList.currentIndex >= 0 ? searchList.currentIndex : 0)
                Keys.onEnterPressed: root.launch(root.searchResults, searchList.currentIndex >= 0 ? searchList.currentIndex : 0)
                Keys.onDownPressed: {
                    const view = root.searching ? searchList : (root.page === "apps" ? appsList : pinnedGrid)
                    view.currentIndex = 0
                    view.forceActiveFocus()
                }
                Keys.onEscapePressed: event => {
                    if (root.searching) {
                        text = ""
                    } else if (root.page === "apps") {
                        root.page = "home"
                    } else {
                        root.close()
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.searching ? 2 : (root.page === "apps" ? 1 : 0)

                //BEGIN Home: pinned + recommended
                ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Kirigami.Heading {
                            level: 4
                            font.weight: Font.DemiBold
                            text: i18n("Pinned")
                        }
                        Item { Layout.fillWidth: true }
                        PC3.Button {
                            text: i18n("All apps") + "  ›"
                            onClicked: root.page = "apps"
                        }
                    }

                    GridView {
                        id: pinnedGrid
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.tileHeight * 3
                        cellWidth: root.tileWidth
                        cellHeight: root.tileHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationEnabled: true
                        currentIndex: -1
                        model: root.favorites

                        delegate: Tile {
                            required property int index
                            required property var model
                            width: GridView.view.cellWidth
                            height: GridView.view.cellHeight
                            label: model.display
                            iconSource: model.decoration
                            current: GridView.isCurrentItem && GridView.view.activeFocus
                            onActivated: root.launch(root.favorites, index)
                            onMenuRequested: (x, y) => contextMenu.show(this, x, y, root.favorites, index,
                                root.favorites, model.favoriteId, model.actionList)
                        }

                        Keys.onReturnPressed: root.launch(root.favorites, currentIndex)
                        Keys.onPressed: event => root.forwardToSearch(event)

                        PC3.ScrollBar.vertical: PC3.ScrollBar {}
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.largeSpacing
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Kirigami.Heading {
                            level: 4
                            font.weight: Font.DemiBold
                            text: i18n("Recommended")
                        }
                    }

                    GridView {
                        id: recentGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: count > 0
                        cellWidth: width / 2
                        cellHeight: Kirigami.Units.gridUnit * 3
                        clip: true
                        interactive: false
                        model: startMenu.recentDocsModel

                        delegate: EntryRow {
                            required property int index
                            required property var model
                            width: GridView.view.cellWidth
                            height: GridView.view.cellHeight
                            label: model.display
                            subtitle: model.description ?? ""
                            iconSource: model.decoration
                            onActivated: root.launch(startMenu.recentDocsModel, index)
                            onMenuRequested: (x, y) => contextMenu.show(this, x, y, startMenu.recentDocsModel, index,
                                null, "", model.actionList)
                        }
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: recentGrid.count === 0
                        text: i18n("The files you open will show up here.")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: 0.6
                        wrapMode: Text.Wrap
                    }
                }
                //END

                //BEGIN All apps (A–Z)
                ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Kirigami.Heading {
                            level: 4
                            font.weight: Font.DemiBold
                            text: i18n("All apps")
                        }
                        Item { Layout.fillWidth: true }
                        PC3.Button {
                            text: "‹  " + i18n("Back")
                            onClicked: root.page = "home"
                        }
                    }

                    PC3.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: appsList
                            model: root.appsModel
                            clip: true
                            currentIndex: -1
                            keyNavigationEnabled: true
                            boundsBehavior: Flickable.StopAtBounds
                            section.property: "display"
                            section.criteria: ViewSection.FirstCharacter
                            section.delegate: Kirigami.Heading {
                                required property string section
                                level: 5
                                text: section.toUpperCase()
                                leftPadding: Kirigami.Units.largeSpacing
                                topPadding: Kirigami.Units.largeSpacing
                                bottomPadding: Kirigami.Units.smallSpacing
                            }

                            delegate: EntryRow {
                                required property int index
                                required property var model
                                width: ListView.view.width
                                iconSize: Kirigami.Units.iconSizes.smallMedium
                                label: model.display
                                iconSource: model.decoration
                                current: ListView.isCurrentItem && ListView.view.activeFocus
                                onActivated: root.launch(root.appsModel, index)
                                onMenuRequested: (x, y) => contextMenu.show(this, x, y, root.appsModel, index,
                                    root.favorites, model.favoriteId, model.actionList)
                            }

                            Keys.onReturnPressed: root.launch(root.appsModel, currentIndex)
                            Keys.onPressed: event => root.forwardToSearch(event)
                        }
                    }
                }
                //END

                //BEGIN Search results
                ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Heading {
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        level: 4
                        text: i18n("Best matches")
                        visible: searchList.count > 0
                    }

                    PC3.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: searchList
                            model: root.searchResults
                            clip: true
                            keyNavigationEnabled: true
                            boundsBehavior: Flickable.StopAtBounds
                            highlightMoveDuration: 0

                            delegate: EntryRow {
                                required property int index
                                required property var model
                                width: ListView.view.width
                                label: model.display
                                subtitle: model.description ?? ""
                                iconSource: model.decoration
                                // The first result is what Enter in the search box opens.
                                current: ListView.isCurrentItem || (index === 0 && !ListView.view.activeFocus)
                                onActivated: root.launch(root.searchResults, index)
                                onMenuRequested: (x, y) => contextMenu.show(this, x, y, root.searchResults, index,
                                    root.favorites, model.favoriteId ?? "", model.actionList)
                            }

                            Keys.onReturnPressed: root.launch(root.searchResults, currentIndex)
                            Keys.onPressed: event => root.forwardToSearch(event)
                        }
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: searchList.count === 0
                        text: i18n("No results for “%1”", searchField.text)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: 0.6
                    }
                }
                //END
            }
        }

        //BEGIN Footer: user and power
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            radius: Kirigami.Units.cornerRadius

            Rectangle {   // thin divider line on top
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: Kirigami.Theme.textColor
                opacity: 0.1
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.pad
                anchors.rightMargin: root.pad

                MouseArea {
                    id: userButton
                    Layout.fillHeight: true
                    Layout.preferredWidth: userRow.implicitWidth + Kirigami.Units.largeSpacing * 2
                    hoverEnabled: true
                    onClicked: {
                        KCM.KCMLauncher.openSystemSettings("kcm_users")
                        root.close()
                    }
                    Accessible.name: kuser.fullName
                    Accessible.role: Accessible.Button

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        radius: Kirigami.Units.cornerRadius
                        color: Kirigami.Theme.textColor
                        opacity: userButton.containsMouse ? 0.07 : 0
                    }
                    RowLayout {
                        id: userRow
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.largeSpacing
                        KirigamiComponents.Avatar {
                            implicitWidth: Kirigami.Units.iconSizes.medium
                            implicitHeight: Kirigami.Units.iconSizes.medium
                            name: kuser.fullName
                            source: kuser.faceIconUrl
                        }
                        PC3.Label {
                            text: kuser.fullName || kuser.loginName
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                PC3.ToolButton {
                    id: powerButton
                    icon.name: "system-shutdown"
                    display: PC3.AbstractButton.IconOnly
                    text: i18n("Power")
                    PC3.ToolTip.text: text
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: powerFlyout.visible = !powerFlyout.visible
                }
            }
        }
        //END
    }

    // Power flyout (Windows 11 style), drawn inside the menu above the power
    // button. Uses the standard system interfaces directly.
    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }

    function power(command) {
        powerFlyout.visible = false
        root.close()
        runner.connectSource(command)
    }

    MouseArea {   // click anywhere else to dismiss the flyout
        anchors.fill: parent
        visible: powerFlyout.visible
        onClicked: powerFlyout.visible = false
    }

    Rectangle {
        id: powerFlyout
        visible: false
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.pad / 2
        anchors.bottomMargin: Kirigami.Units.gridUnit * 3
        width: Kirigami.Units.gridUnit * 10
        height: powerColumn.implicitHeight + Kirigami.Units.smallSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

        ColumnLayout {
            id: powerColumn
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: 0

            Repeater {
                model: [
                    { text: i18n("Lock"),      icon: "system-lock-screen", cmd: "loginctl lock-session" },
                    { text: i18n("Sign out"),  icon: "system-log-out",     cmd: "dbus-send --session --type=method_call --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logout" },
                    { text: i18n("Sleep"),     icon: "system-suspend",     cmd: "systemctl suspend" },
                    { text: i18n("Restart"),   icon: "system-reboot",      cmd: "dbus-send --session --type=method_call --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot" },
                    { text: i18n("Shut down"), icon: "system-shutdown",    cmd: "dbus-send --session --type=method_call --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndShutdown" }
                ]
                delegate: PC3.ToolButton {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.text
                    icon.name: modelData.icon
                    display: PC3.AbstractButton.TextBesideIcon
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                            source: modelData.icon
                        }
                        PC3.Label {
                            Layout.fillWidth: true
                            text: modelData.text
                        }
                    }
                    onClicked: root.power(modelData.cmd)
                }
            }
        }
    }
}

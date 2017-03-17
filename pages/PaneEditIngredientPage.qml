import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtQuick.Controls.Material 2.1
import Gooseberry 1.0
import "../components"
import "../toolbars"
import "../"

Page {
    id: page
    anchors.fill: parent
    enabled: m.ready

    header: DynamicToolBar {
        component: RowLayout {
            IconToolButton {
                iconName: "back"
                ToolTip.text: "Back"
                onClicked: closeRightPane()
            }
            HeaderLabel {
                text: m.editMode ? m.name : "New Ingredient"
            }
            IconToolButton {
                iconName: "delete"
                ToolTip.text: "Delete"
                visible: m.editMode
                onClicked: deleteDialog.open()
            }
            IconToolButton {
                iconName: "refresh"
                ToolTip.text: "Refresh"
                visible: m.editMode
                onClicked: m.revertChanges()
            }
            IconToolButton {
                iconName: "tick"
                ToolTip.text: "Done"
                enabled: m.name != ""
                onClicked: {m.submitChanges(); if (!twoPanePossible) closeRightPane()}
            }
        }
    }

    ListView {
        id: flickable
        anchors.fill: parent
        clip: true
        ScrollBar.vertical: ScrollBar {}
        model: VisualItemModel {
            ColumnLayout {
                width: parent.width
                GridLayout {
                    id: layoutFields
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Layout.Center
                    Layout.maximumWidth: maxWidth

                    property int maxWidth1: 670
                    property int maxWidth2: rows === 2 ? maxWidth*2/6 : maxWidth1
                    property int switchWidth: 210
                    rows: parent.width > maxWidth - switchWidth ? 2 : -1

                    flow: GridLayout.TopToBottom

                    DynamicFrame {
                        id: nameGroup
                        Layout.maximumWidth: parent.maxWidth1
                        content: nameGroupComponent
                    }

                    DynamicFrame {
                        id: tagsGroup
                        Layout.fillWidth: true
                        Layout.maximumWidth: parent.maxWidth1
                        content: tagsGroupComponent
                    }

                    DynamicFrame {
                        id: conversionGroup
                        Layout.fillWidth: true
                        Layout.maximumWidth: parent.maxWidth2
                        content: conversionGroupComponent
                    }
                }
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: !m.ready
        z: layoutFields.z + 100
    }

    Component {
        id: nameGroupComponent
        ColumnLayout {
            property alias nameInput: name_input.text
            property alias descInput: desc_input.text

            Label {text: "Name"; font.bold: true; visible: !m.editMode}

            TitleTextField {
                id: name_input
                placeholderText: "Name"
                visible: !m.editMode
            }

            Label {text: "\nDescription"; font.bold: true;}

            TextArea {
                id: desc_input
                placeholderText: "Enter description"
                Layout.fillWidth: true
                wrapMode: TextArea.Wrap
            }
        }
    }

    Component {
        id: tagsGroupComponent
        ColumnLayout {
            Label {text: "Tags\n"; font.bold: true}

            ListView {
                id: tagsView
                Layout.fillWidth: true
                height: contentHeight
                width: parent.width
                contentHeight: 40
                spacing: 10
                orientation: ListView.Horizontal
                clip: true
                model: m.tags
                delegate: TagItem {
                    text: modelData
                    xButton.onClicked: m.removeTag(modelData)
                }
                ScrollBar.horizontal: ScrollBar {}
            }

            RowLayout {
                Layout.fillWidth: true

                TextField {
                    id: addTagField
                    placeholderText: "Add tag..."
                    Layout.fillWidth: true
                    validator: RegExpValidator {regExp: /^[a-z]+$/}
                    inputMethodHints: Qt.ImhLowercaseOnly
                    onAccepted: {m.addTag(text); clear()}
                }

                IconToolButton {
                    id: addButton
                    iconName: "add"
                    iconColor: Material.primary
                    ToolTip.text: "Add tag"
                    onClicked: {m.addTag(addTagField.text); addTagField.clear()}
                }
            }
        }
    }

    Component {
        id: conversionGroupComponent
        ColumnLayout {
            Label {text: "Conversions\n"; font.bold: true}

            GridLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 330
                columns: 3
                Label {text: "Weight/Volume:"; /*font.bold: true; */Layout.fillWidth: true}
                Label {text: ("%1 kg/cup").arg(m.kgPCup); Layout.fillWidth: true}
                IconToolButton {iconName: "edit"; onClicked: conversionDialog.open()}
            }
        }
    }

    Dialog {
        id: conversionDialog
        x: parent.width/2 - width/2
        y: parent.height/3 - width/3
        modal: true
        onRejected: close()
        onAccepted: {
            m.changeConversion(
                        weight_value_input.text,
                        weight_unit_input.currentIndex,
                        volume_value_input.text,
                        volume_unit_input.currentIndex)
            weight_value_input.clear()
            volume_value_input.clear()
        }
        footer: DialogButtonBox {
            Button {
                text: qsTr("Cancel")
                DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
                flat: true
                onClicked: conversionDialog.close()
            }
            Button {
                text: qsTr("Change conversion")
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                enabled: parseFloat(weight_value_input.text) >= 0 &&
                         parseFloat(volume_value_input.text) >= 0
                flat: true
            }
        }

        GridLayout {
            id: dialogGrid
            columns: 3
            Layout.fillWidth: true

            DoubleTextField {
                id: weight_value_input
                placeholderText: "Weight"
                Layout.fillWidth: true
            }
            Label {
                text: "<h1>  =  </h1>"
                Layout.minimumWidth: 30
                horizontalAlignment: Label.AlignHCenter
                Layout.rowSpan: 2
            }
            DoubleTextField {
                id: volume_value_input
                placeholderText: "Volume"
                Layout.fillWidth: true
            }
            ComboBox {
                id: weight_unit_input
                Layout.fillWidth: true
                textRole: "symbol"
                displayText: currentIndex === -1 ? "" : model[currentIndex].symbol
                model: m.weights
                Material.elevation: 1
            }
            ComboBox {
                id: volume_unit_input
                Layout.fillWidth: true
                textRole: "symbol"
                displayText: currentIndex === -1 ? "" : model[currentIndex].symbol
                model: m.volumes
                Material.elevation: 1
            }
        }
    }

    Dialog {
        id: deleteDialog
        x: parent.width/2 - width/2
        y: parent.height/3 - width/3
        title: ("Delete ingredient '%1'?").arg(m.name)
        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {m.deleteIngredient(); closeRightPane()}
    }

    IngredientEditWindowModel {
        id: m
        name: nameGroup.item.nameInput
        desc: nameGroup.item.descInput
        onQmlUpdateNeeded: {
            nameGroup.item.nameInput = name
            name = Qt.binding(function() {return nameGroup.item.nameInput})

            nameGroup.item.descInput = desc
            desc = Qt.binding(function() {return nameGroup.item.descInput})

            mainSelectedIngredient = name
        }
    }


    function open(name) {
        m.linkUp(name, NetworkManager, mainMeasurementsModel, mainIngredientsModel)
    }
}

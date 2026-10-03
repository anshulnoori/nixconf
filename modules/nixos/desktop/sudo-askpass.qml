// sudo askpass prompt, styled like the polkit prompt (hyprpolkitagent.qml) and mako.
// The askpass process prints the password on stdout when accepted and exits
// non-zero when cancelled. Placeholders are filled by sudo-askpass.nix.
import QtQuick
import QtQuick.Window

Window {
    id: window

    readonly property int borderWidth: 2
    readonly property int paddingX: 10
    readonly property int paddingY: 8
    readonly property string fontFamily: "@fontFamily@"
    readonly property int fittedHeight: content.implicitHeight + 2 * (paddingY + borderWidth)

    // Size from the laid-out content before mapping; floating windows keep
    // the size they map with.
    width: 320
    height: fittedHeight
    minimumWidth: 320
    maximumWidth: 320
    minimumHeight: fittedHeight
    maximumHeight: fittedHeight
    title: "sudo"
    color: "@background@"
    visible: false
    onClosing: askpass.cancel()
    Component.onCompleted: {
        show();
        password.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "@border@"
        border.width: window.borderWidth
    }

    Column {
        id: content

        x: window.borderWidth + window.paddingX
        y: window.borderWidth + window.paddingY
        width: window.width - 2 * x
        spacing: 4

        Text {
            width: parent.width
            text: "sudo for " + askpass.requester
            color: "@text@"
            font.family: window.fontFamily
            font.pointSize: 10
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: askpass.command
            visible: text.length > 0
            color: "@text@"
            font.family: window.fontFamily
            font.pointSize: 10
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: askpass.prompt
            color: "@muted@"
            font.family: window.fontFamily
            font.pointSize: 9
            elide: Text.ElideRight
        }

        Rectangle {
            width: parent.width
            height: password.implicitHeight + 8
            color: "@field@"
            border.color: password.activeFocus ? "@border@" : "@muted@"
            border.width: 1

            TextInput {
                id: password

                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: "@text@"
                selectionColor: "@border@"
                selectedTextColor: "@background@"
                font.family: window.fontFamily
                font.pointSize: 10
                focus: true
                clip: true
                Keys.onReturnPressed: askpass.accept(text)
                Keys.onEnterPressed: askpass.accept(text)
                Keys.onEscapePressed: askpass.cancel()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text.length === 0
                    text: "Password"
                    color: "@muted@"
                    font: password.font
                }
            }
        }

        Row {
            spacing: 12

            Text {
                text: "Enter authenticate"
                color: "@muted@"
                font.family: window.fontFamily
                font.pointSize: 9

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: askpass.accept(password.text)
                }
            }

            Text {
                text: "Esc cancel"
                color: "@muted@"
                font.family: window.fontFamily
                font.pointSize: 9

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: askpass.cancel()
                }
            }
        }
    }
}

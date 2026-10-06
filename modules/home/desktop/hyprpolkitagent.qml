import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    readonly property int borderWidth: 2
    readonly property int paddingX: 10
    readonly property int paddingY: 8
    readonly property string fontFamily: "@fontFamily@"

    function submit() {
        hpa.setResult("auth:" + password.text);
    }

    function cancel() {
        hpa.setResult("fail");
    }

    readonly property int fittedHeight: content.implicitHeight + 2 * (paddingY + borderWidth)

    width: 320
    height: fittedHeight
    minimumWidth: 320
    maximumWidth: 320
    minimumHeight: fittedHeight
    maximumHeight: fittedHeight
    visible: false
    color: "@background@"
    onClosing: cancel()
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
            text: "Authenticating for " + hpa.getUser()
            color: "@text@"
            font.family: window.fontFamily
            font.pointSize: 10
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: hpa.getMessage()
            color: "@text@"
            font.family: window.fontFamily
            font.pointSize: 10
            wrapMode: Text.Wrap
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
                Keys.onReturnPressed: window.submit()
                Keys.onEnterPressed: window.submit()
                Keys.onEscapePressed: window.cancel()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text.length === 0
                    text: "Password"
                    color: "@muted@"
                    font: password.font
                }

                Connections {
                    target: hpa

                    function onFocusField() {
                        password.forceActiveFocus();
                    }

                    function onBlockInput(block) {
                        password.readOnly = block;
                        if (!block) {
                            password.forceActiveFocus();
                            password.selectAll();
                        }
                    }

                    function onSetErrorString(error) {
                        errorText.text = error;
                    }
                }
            }
        }

        Text {
            id: errorText

            width: parent.width
            color: "@error@"
            font.family: window.fontFamily
            font.pointSize: 10
            elide: Text.ElideRight
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
                    onClicked: window.submit()
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
                    onClicked: window.cancel()
                }
            }
        }
    }
}

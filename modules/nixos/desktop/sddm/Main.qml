import QtQuick

Rectangle {
    id: root
    width: 1280
    height: 720
    color: config.BackgroundColor

    property int sessionIndex: -1
    property bool busy: false
    property string errorMessage: ""

    function login() {
        if (busy || password.text.length === 0 || sessionIndex < 0)
            return;
        busy = true;
        errorMessage = "";
        sddm.login(config.User, password.text, sessionIndex);
    }

    Component.onCompleted: {
        for (let i = 0; i < sessionModel.count; ++i) {
            // SDDM's FileRole is Qt.UserRole + 2 and contains an absolute path.
            const file = sessionModel.data(sessionModel.index(i, 0), Qt.UserRole + 2);
            if (file.split("/").pop() === config.Session) {
                sessionIndex = i;
                break;
            }
        }
        if (sessionIndex < 0)
            errorMessage = "Hyprland session unavailable";
    }

    Image {
        anchors.fill: parent
        source: config.Background
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        id: field
        anchors.centerIn: parent
        width: 400
        height: 60
        color: config.FieldColor
        border.width: 4
        border.color: root.busy ? config.CheckingColor : root.errorMessage ? config.FailureColor : config.Foreground

        TextInput {
            id: password
            objectName: "password"
            anchors.fill: parent
            anchors.margins: 8
            color: config.Foreground
            selectionColor: config.CheckingColor
            selectedTextColor: config.BackgroundColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            readOnly: root.busy || root.sessionIndex < 0
            focus: primaryScreen
            clip: true
            selectByMouse: true
            Accessible.name: "Password for " + config.User
            onAccepted: root.login()
            Keys.onEscapePressed: clear()
        }

        Text {
            anchors.centerIn: parent
            text: "Enter Password"
            color: config.Foreground
            font.family: password.font.family
            font.pixelSize: password.font.pixelSize
            visible: password.text.length === 0
        }
    }

    Text {
        anchors.top: field.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: field.horizontalCenter
        text: root.busy ? "Checking…" : root.errorMessage
        color: root.busy ? config.CheckingColor : config.FailureColor
        font.family: password.font.family
        font.pixelSize: 16
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.busy = false;
            root.errorMessage = "Login failed. Try again.";
            password.clear();
            password.forceActiveFocus();
        }

        function onLoginSucceeded() {
            root.busy = true;
            password.clear();
        }
    }
}

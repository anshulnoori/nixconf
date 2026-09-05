import QtQuick
import QtTest
import "../modules/nixos/desktop/sddm" as Theme

Item {
    id: harness
    width: 1280
    height: 720
    property bool primaryScreen: true
    property var config: ({
            Background: "",
            BackgroundColor: "#1d2021",
            FieldColor: "#cc1d2021",
            Foreground: "#d5c4a1",
            CheckingColor: "#83a598",
            FailureColor: "#fb4934",
            User: "mvs",
            Session: "hyprland-uwsm.desktop"
        })

    QtObject {
        id: sessionModel
        property var files: []
        readonly property int count: files.length
        function index(row, column) {
            return row;
        }
        function data(row, role) {
            return role === Qt.UserRole + 2 ? files[row] : "";
        }
    }

    QtObject {
        id: sddm
        property var calls: []
        signal loginFailed
        signal loginSucceeded
        function login(user, password, session) {
            calls.push({
                user: user,
                password: password,
                session: session
            });
        }
    }

    Component {
        id: theme
        Theme.Main {}
    }

    TestCase {
        name: "SingleUserLogin"
        when: windowShown
        property var view
        property var password

        function init() {
            sddm.calls = [];
            sessionModel.files = ["/run/current-system/sw/share/wayland-sessions/hyprland.desktop", "/run/current-system/sw/share/wayland-sessions/hyprland-uwsm.desktop"];
            view = createTemporaryObject(theme, harness);
            verify(view !== null);
            password = findChild(view, "password");
            verify(password !== null);
            password.forceActiveFocus();
        }

        function test_initial_state() {
            compare(view.sessionIndex, 1);
            compare(view.errorMessage, "");
            compare(password.text, "");
            compare(password.echoMode, TextInput.Password);
            compare(password.parent.width, 400);
            compare(password.parent.height, 60);
            compare(password.parent.border.width, 4);
            verify(password.activeFocus);
        }

        function test_empty_password_is_ignored() {
            keyClick(Qt.Key_Return);
            compare(sddm.calls.length, 0);
            verify(!view.busy);
        }

        function test_submit_failure_and_retry() {
            password.text = "test-only-not-a-real-password";
            keyClick(Qt.Key_Return);
            compare(sddm.calls.length, 1);
            compare(sddm.calls[0].user, "mvs");
            compare(sddm.calls[0].session, 1);
            compare(sddm.calls[0].password, "test-only-not-a-real-password");
            verify(view.busy);
            verify(password.readOnly);
            view.login();
            compare(sddm.calls.length, 1);

            sddm.loginFailed();
            verify(!view.busy);
            verify(!password.readOnly);
            compare(password.text, "");
            compare(view.errorMessage, "Login failed. Try again.");
            verify(password.activeFocus);

            password.text = "retry-test-only";
            keyClick(Qt.Key_Return);
            compare(sddm.calls.length, 2);
            compare(sddm.calls[1].user, "mvs");
            compare(view.errorMessage, "");
            sddm.loginSucceeded();
            verify(view.busy);
            compare(password.text, "");
        }

        function test_escape_clears_password() {
            password.text = "test-only";
            keyClick(Qt.Key_Escape);
            compare(password.text, "");
            compare(sddm.calls.length, 0);
        }

        function test_missing_session_blocks_login() {
            sessionModel.files = ["hyprland.desktop"];
            const missing = createTemporaryObject(theme, harness);
            compare(missing.sessionIndex, -1);
            compare(missing.errorMessage, "Hyprland session unavailable");
            const input = findChild(missing, "password");
            verify(input.readOnly);
            input.text = "test-only";
            missing.login();
            compare(sddm.calls.length, 0);
        }
    }
}

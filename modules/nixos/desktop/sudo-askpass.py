"""sudo askpass helper: show the mako-styled prompt and print the password.

sudo runs this as the invoking user with the prompt as argv[1] and reads one
line from stdout. A non-zero exit cancels, like Ctrl-C at a terminal prompt.
"""

import os
import sys

from PySide6.QtCore import Property, QObject, QTimer, QUrl, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


TIMEOUT_MS = 5 * 60 * 1000  # sudo's default passwd_timeout


def describe_requester():
    """Show the full sudo command line, so the user sees exactly what they approve."""
    try:
        with open(f"/proc/{os.getppid()}/cmdline", "rb") as cmdline:
            argv = cmdline.read().split(b"\0")[:-1]
    except OSError:
        argv = []
    words = [arg.decode(errors="replace") for arg in argv]
    if words:
        words[0] = os.path.basename(words[0])
    return os.environ.get("USER", "this user"), " ".join(words)


class Askpass(QObject):
    def __init__(self, prompt):
        super().__init__()
        self._prompt = prompt
        self._requester, self._command = describe_requester()
        self.status = 1

    @Property(str, constant=True)
    def prompt(self):
        return self._prompt

    @Property(str, constant=True)
    def requester(self):
        return self._requester

    @Property(str, constant=True)
    def command(self):
        return self._command

    @Slot(str)
    def accept(self, password):
        sys.stdout.write(password + "\n")
        sys.stdout.flush()
        self.status = 0
        QGuiApplication.quit()

    @Slot()
    def cancel(self):
        QGuiApplication.quit()


def main():
    app = QGuiApplication(sys.argv[:1])
    app.setApplicationName("sudo-askpass")
    app.setDesktopFileName("sudo-askpass")
    askpass = Askpass(sys.argv[1] if len(sys.argv) > 1 else "Password:")
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("askpass", askpass)
    engine.load(QUrl.fromLocalFile(os.environ["SUDO_ASKPASS_QML"]))
    if not engine.rootObjects():
        return 1
    # Never leave a background caller waiting forever on an unattended prompt.
    QTimer.singleShot(TIMEOUT_MS, askpass.cancel)
    app.exec()
    return askpass.status


if __name__ == "__main__":
    sys.exit(main())

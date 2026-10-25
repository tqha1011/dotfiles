// SDDM theme — cùng ngôn ngữ với hyprlock: nền blur + phủ TokyoNight, đồng hồ giờ đậm / phút mảnh,
// ô mật khẩu viền gradient xanh → tím. Test: sddm-greeter-qt6 --test-mode --theme <thư mục này>
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: bg

    readonly property color bg: "#1a1b26"
    readonly property color surface: "#292e42"
    readonly property color fg: "#c0caf5"
    readonly property color muted: "#565f89"
    readonly property color blue: "#7aa2f7"
    readonly property color purple: "#bb9af7"
    readonly property color red: "#f7768e"
    readonly property color yellow: "#e0af68"

    readonly property string display: "Inter Display"
    readonly property string sans: "Inter"
    readonly property string mono: "JetBrainsMono Nerd Font Propo"

    property date now: new Date()
    property bool failed: false
    property bool busy: false

    // ---- Dữ liệu user/session (ListView vô hình để đọc role của phần tử hiện tại) ----
    // Không dùng visible: false / kích thước 0 — khi đó ListView không tạo delegate, currentItem = null

    ListView {
        id: users
        width: 1
        height: 1
        opacity: 0
        interactive: false
        model: userModel
        currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
        delegate: Item {
            width: 1
            height: 1
            property string userName: model.name
            property string realName: model.realName
            property string icon: model.icon
        }
    }

    ListView {
        id: sessions
        width: 1
        height: 1
        opacity: 0
        interactive: false
        model: sessionModel
        currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
        delegate: Item {
            width: 1
            height: 1
            property string sessionName: model.name
        }
    }

    readonly property string userName: users.currentItem ? users.currentItem.userName : userModel.lastUser
    readonly property string firstName: {
        const real = users.currentItem ? users.currentItem.realName : ""
        const parts = real.trim().split(/\s+/)
        return parts.length && parts[0] ? parts[parts.length - 1] : userName
    }

    function login() {
        if (busy || password.text.length === 0)
            return
        busy = true
        failed = false
        sddm.login(userName, password.text, sessions.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.failed = true
            password.text = ""
            password.forceActiveFocus()
            shake.start()
        }
        function onLoginSucceeded() {
            fadeOut.start()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ---- Nền ----

    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: -0.1
        saturation: 0.1
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg
        opacity: Number(config.dimOpacity) || 0.45
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        NumberAnimation on opacity {
            id: fadeIn
            to: 1
            duration: 400
            easing.type: Easing.OutQuint
        }

        NumberAnimation {
            id: fadeOut
            target: content
            property: "opacity"
            to: 0
            duration: 250
            easing.type: Easing.OutQuint
        }

        // ---- Đồng hồ: điểm nhấn duy nhất ----

        Text {
            id: hours
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.205 - height / 2
            text: Qt.formatTime(root.now, "HH")
            color: root.fg
            font.family: root.display
            font.weight: Font.Black
            font.pixelSize: root.height * 0.235
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#59000000"
                shadowBlur: 0.6
            }
        }

        Text {
            id: minutes
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.398 - height / 2
            text: Qt.formatTime(root.now, "mm")
            color: root.blue
            font.family: root.display
            font.weight: Font.Thin
            font.pixelSize: root.height * 0.235
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#59000000"
                shadowBlur: 0.6
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.532 - height / 2
            text: {
                const s = root.now.toLocaleDateString(Qt.locale("vi_VN"), "dddd, dd MMMM")
                return s.charAt(0).toUpperCase() + s.slice(1)
            }
            color: root.fg
            font.family: root.sans
            font.pixelSize: root.height * 0.025
        }

        // ---- Người dùng ----

        Item {
            id: avatar
            width: 96
            height: 96
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.63 - height / 2

            // viền gradient = vòng tròn gradient phía sau, ảnh tròn nhỏ hơn 4px phía trước
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.blue }
                    GradientStop { position: 1; color: root.purple }
                }
            }

            Rectangle {
                id: avatarMask
                anchors.fill: parent
                anchors.margins: 2
                radius: width / 2
                color: root.surface
                visible: !face.visible

                Text {
                    anchors.centerIn: parent
                    text: root.firstName.charAt(0).toUpperCase()
                    color: root.fg
                    font.family: root.display
                    font.weight: Font.DemiBold
                    font.pixelSize: 40
                }
            }

            Image {
                id: faceSource
                anchors.fill: parent
                anchors.margins: 2
                source: users.currentItem ? users.currentItem.icon : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            GE.OpacityMask {
                id: face
                anchors.fill: faceSource
                source: faceSource
                maskSource: avatarMask
                visible: faceSource.status === Image.Ready
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.708 - height / 2
            text: {
                const h = root.now.getHours()
                const part = h >= 5 && h < 12 ? "sáng" : h >= 12 && h < 18 ? "chiều" : "tối"
                return "Chào buổi " + part + ", " + root.firstName
            }
            color: root.fg
            font.family: root.sans
            font.pixelSize: root.height * 0.019
        }

        // ---- Ô mật khẩu: cùng gradient với viền cửa sổ Hyprland ----

        Item {
            id: field
            width: 300
            height: 48
            x: (parent.width - width) / 2
            y: root.height * 0.773 - height / 2

            readonly property color from: root.failed ? root.red : root.busy || keyboard.capsLock ? root.yellow : root.blue
            readonly property color to: root.failed ? root.purple : root.busy || keyboard.capsLock ? "#ff9e64" : root.purple

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: field.from; Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutQuint } } }
                    GradientStop { position: 1; color: field.to; Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutQuint } } }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: height / 2
                color: "#e61a1b26"
            }

            TextField {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                focus: true
                enabled: !root.busy
                echoMode: TextInput.Password
                passwordCharacter: "•"
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                color: root.fg
                font.family: root.mono
                font.pixelSize: 15
                font.letterSpacing: 4
                background: Item {}
                onTextEdited: root.failed = false
                onAccepted: root.login()
                Keys.onEscapePressed: text = ""
            }

            // Placeholder tự vẽ: TextField Basic ẩn placeholder khi đang focus + căn giữa
            Text {
                anchors.centerIn: parent
                visible: password.text.length === 0
                text: "Nhập mật khẩu"
                color: root.muted
                font.family: root.mono
                font.pixelSize: 14
                font.letterSpacing: 1
            }

            SequentialAnimation {
                id: shake
                property real base: (field.parent.width - field.width) / 2
                NumberAnimation { target: field; property: "x"; to: shake.base - 12; duration: 50 }
                NumberAnimation { target: field; property: "x"; to: shake.base + 10; duration: 70 }
                NumberAnimation { target: field; property: "x"; to: shake.base - 6; duration: 70 }
                NumberAnimation { target: field; property: "x"; to: shake.base; duration: 120; easing.type: Easing.OutQuint }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: field.bottom
            anchors.topMargin: 14
            text: root.failed ? "Sai mật khẩu, thử lại" : keyboard.capsLock ? "Caps Lock đang bật" : ""
            color: root.failed ? root.red : root.yellow
            font.family: root.sans
            font.pixelSize: 13
        }

        // ---- Góc dưới: session (trái), nguồn (phải) — nhỏ, im lặng ----

        Text {
            id: sessionButton
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 40
            text: "󰍹  " + (sessions.currentItem ? sessions.currentItem.sessionName : "")
            color: sessionArea.containsMouse ? root.fg : root.muted
            font.family: root.mono
            font.pixelSize: 14
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: sessionArea
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sessions.currentIndex = (sessions.currentIndex + 1) % sessions.count
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 40
            spacing: 28

            Repeater {
                model: [
                    { glyph: "󰜉", action: "reboot", enabled: sddm.canReboot, danger: false },
                    { glyph: "󰐥", action: "powerOff", enabled: sddm.canPowerOff, danger: true }
                ]

                Text {
                    required property var modelData
                    visible: modelData.enabled
                    text: modelData.glyph
                    color: area.containsMouse ? (modelData.danger ? root.red : root.fg) : root.muted
                    font.family: root.mono
                    font.pixelSize: 20
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.action === "reboot" ? sddm.reboot() : sddm.powerOff()
                    }
                }
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}

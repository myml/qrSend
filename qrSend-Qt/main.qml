import QtQuick 2.8
import QtQuick.Window 2.2

Window {
    visible: true
    width: 640
    height: 480
    minimumWidth: width
    minimumHeight: height
    maximumWidth: width
    maximumHeight: height
    title: qsTr("QR SEND")
    flags: Qt.WindowCloseButtonHint
    property string url: "http://127.0.0.1:4000/"
    property string select: ""

    function refList() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function () {
            if (xhr.readyState == xhr.DONE) {
                console.log(xhr.responseText)
                var ls = JSON.parse(xhr.responseText)
                list.clear()
                for (var i in ls) {
                    list.append(ls[i])
                }
            }
        }
        xhr.send()
    }

    Rectangle {
        id: file
        anchors.left: parent.left
        width: parent.width * 0.4
        height: parent.height
        border.color: "#999"
        border.width: 1
        ListModel {
            id: list
        }
        Image {
            id: drop
            fillMode: Image.Stretch
            anchors.centerIn: parent
            source: "qrc:/img/drop.png"
        }
        Column {
            id: files
            anchors.fill: parent
            spacing: 5
            Rectangle {
                width: parent.width
                height: 50
                Text {
                    anchors.centerIn: parent
                    text: "FILES"
                }
            }
            Repeater {
                model: list
                Rectangle {
                    width: parent.width * 0.9
                    height: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: select == hash ? "#2f2" : "#9f9"
                    Text {
                        anchors.centerIn: parent
                        text: name.substring(name.lastIndexOf("/"))
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log(hash)
                            select = hash
                            qrShow.state = "qr"
                        }
                    }
                    Rectangle {
                        width: 20
                        height: parent.height
                        anchors.right: parent.right
                        color: "#ff9"
                        Text {
                            id: del
                            anchors.centerIn: parent
                            text: qsTr("X")
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var xhr = new XMLHttpRequest()
                                xhr.open("DELETE", url + hash)
                                xhr.onreadystatechange = function () {
                                    if (xhr.readyState == xhr.DONE) {
                                        refList()
                                    }
                                }
                                xhr.send()
                            }
                        }
                    }
                }
            }
        }
        DropArea {
            anchors.fill: parent
            onDropped: function (e) {
                console.log("drop")
                if (e.hasUrls) {
                    var xhr = new XMLHttpRequest()
                    xhr.open("POST", url)
                    xhr.onreadystatechange = function () {
                        if (xhr.readyState == xhr.DONE) {
                            refList()
                        }
                    }
                    var data = e.urls.map(function (a) {
                        return a.slice(7)
                    }).join(":")
                    xhr.send(data)
                }
            }
        }
    }
    Rectangle {
        id: qrShow
        anchors.left: file.right
        width: parent.width * 0.6
        height: parent.height
        Image {
            anchors.centerIn: parent
            source: url + "qr/" + select
        }
    }
}

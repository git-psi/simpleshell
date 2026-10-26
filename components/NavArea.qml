// Mouse back/forward buttons (side buttons of a G502 and others): lay it over an area, other
// clicks go through. Depending on the mouse, the kernel sends BTN_SIDE/BTN_EXTRA (ExtraButton1/2,
// aka Back/Forward) or BTN_BACK/BTN_FORWARD (ExtraButton4/3).
import QtQuick

MouseArea {
    signal back()
    signal forward()

    anchors.fill: parent
    acceptedButtons: Qt.BackButton | Qt.ForwardButton | Qt.ExtraButton3 | Qt.ExtraButton4
    onClicked: (mouse) => {
        if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton4) back();
        else forward();
    }
}

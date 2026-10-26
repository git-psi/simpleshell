// Animation for something appearing or disappearing (fade, slide): entering picks the duration,
// drawer the values of a panel sliding in from an edge. In a Behavior, rely on its targetValue
// (not on the state that triggered it, which may not be up to date when the animation starts).
import QtQuick
import ".."

NumberAnimation {
    property bool entering: true
    property bool drawer: false
    duration: drawer ? (entering ? Theme.durDrawer : Theme.durDrawerOut) : (entering ? Theme.durIn : Theme.durOut)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: drawer ? Theme.curveDrawer : Theme.curveOut
}

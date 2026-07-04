import qs.modules.common
import QtQuick

/**
 * A bright, glossy magazine-page surface — the left sidebar's identity, deliberately opposite
 * the walnut shell (it's "the magazine on the desk"). Warm coated-stock cream with a diagonal
 * gloss sweep, and a booklet "crest" along the bottom edge: the open page bowing up off the
 * table with a stack of page edges and a lift shadow. Always light (does not follow dark mode).
 */
Item {
    id: root
    property real radius: 0
    property bool gloss: true
    property bool crest: true
    property int crestHeight: 22

    // Coated-stock palette.
    readonly property color paperTop:    "#F7F1E5"
    readonly property color paperBottom: "#ECE2CC"
    readonly property color paperEdge:   "#D6C6A2"
    readonly property color pageLight:   "#FCF7ED"
    readonly property color pageMid:     "#DFD0AE"
    readonly property color pageShadow:  "#B39F73"

    // Paper body (clipped so the gloss sweep and crest stay inside the rounded page).
    Rectangle {
        id: page
        anchors.fill: parent
        radius: root.radius
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.paperTop }
            GradientStop { position: 1.0; color: root.paperBottom }
        }

        // Diagonal gloss sweep — an oversized rotated band, cropped by the page clip.
        Rectangle {
            visible: root.gloss
            width: parent.width * 2.4
            height: parent.height * 1.3
            x: -parent.width * 0.5
            y: -parent.height * 0.85
            rotation: 20
            transformOrigin: Item.Center
            gradient: Gradient {
                GradientStop { position: 0.00; color: "transparent" }
                GradientStop { position: 0.42; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.45) }
                GradientStop { position: 0.58; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.00; color: "transparent" }
            }
        }

        // Booklet crest — bowed page edges rising in the centre, over a soft lift shadow.
        Canvas {
            id: crestCanvas
            visible: root.crest
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: root.crestHeight
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const bow = height * 0.6;            // how far the centre lifts
                const layers = 4;
                const gap = 3.4;                     // page thickness

                // Soft lift shadow beneath the whole stack (the booklet off the table).
                const sg = ctx.createLinearGradient(0, height - 9, 0, height);
                sg.addColorStop(0.0, Qt.rgba(0, 0, 0, 0.0));
                sg.addColorStop(1.0, Qt.rgba(0, 0, 0, 0.30));
                ctx.fillStyle = sg;
                ctx.beginPath();
                ctx.moveTo(0, height);
                ctx.lineTo(0, height - 6);
                ctx.quadraticCurveTo(width / 2, height - 6 - bow, width, height - 6);
                ctx.lineTo(width, height);
                ctx.closePath();
                ctx.fill();

                // Stacked page edges, each a light lip over a darker crease, bowing up centre.
                for (let i = layers - 1; i >= 0; i--) {
                    const base = height - 3 - i * gap;
                    // crease (the visible gap between pages — this is what reads as a stack)
                    ctx.beginPath();
                    ctx.moveTo(0, base + 1.4);
                    ctx.quadraticCurveTo(width / 2, base + 1.4 - bow, width, base + 1.4);
                    ctx.lineWidth = 1.4;
                    ctx.strokeStyle = root.pageShadow;
                    ctx.globalAlpha = 0.75;
                    ctx.stroke();
                    // light lip on top of the page edge
                    ctx.beginPath();
                    ctx.moveTo(0, base);
                    ctx.quadraticCurveTo(width / 2, base - bow, width, base);
                    ctx.lineWidth = 1.6;
                    ctx.globalAlpha = 1.0;
                    ctx.strokeStyle = root.pageLight;
                    ctx.stroke();
                }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
    }

    // Warm paper edge.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: root.paperEdge
    }
}

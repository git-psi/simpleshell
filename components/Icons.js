// Lucide icons (https://lucide.dev) — ISC license, see LICENSE-lucide.
// The files come from lucide-static 1.52.0 (components/lucide/<name>.svg); we keep the content
// of the <svg> and inject the color and stroke width when rendering (see Icon.qml).
.pragma library


var B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// Base64 encoding of an ASCII string (the SVGs generated here always are).
function base64(str) {
    var out = "";
    for (var i = 0; i < str.length; i += 3) {
        var a = str.charCodeAt(i), b = str.charCodeAt(i + 1), c = str.charCodeAt(i + 2);
        var n = (a << 16) | ((b || 0) << 8) | (c || 0);
        out += B64[(n >> 18) & 63] + B64[(n >> 12) & 63]
            + (i + 1 < str.length ? B64[(n >> 6) & 63] : "=")
            + (i + 2 < str.length ? B64[n & 63] : "=");
    }
    return out;
}

// Content of a Lucide .svg file, without the surrounding <svg> tag.
function body(file) {
    var open = file.indexOf("<svg");
    if (open < 0) return "";
    var start = file.indexOf(">", open) + 1, end = file.lastIndexOf("</svg>");
    return end > start ? file.slice(start, end).trim() : "";
}

function url(body, r, g, b, a, strokeWidth, filled) {
    var s = svg(body, r, g, b, a, strokeWidth, filled);
    return s === "" ? "" : "data:image/svg+xml;base64," + base64(s);
}

function svg(body, r, g, b, a, strokeWidth, filled) {
    if (body === "") return "";
    var c = "rgb(" + Math.round(r * 255) + "," + Math.round(g * 255) + "," + Math.round(b * 255) + ")";
    return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"'
        + ' fill="' + (filled ? c : "none") + '" fill-opacity="' + a + '"'
        + ' stroke="' + c + '" stroke-opacity="' + a + '" stroke-width="' + strokeWidth + '"'
        + ' stroke-linecap="round" stroke-linejoin="round">' + body + '</svg>';
}

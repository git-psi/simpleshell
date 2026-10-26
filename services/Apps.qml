pragma Singleton
// Installed apps (.desktop files), search for the launcher, and web search in the default browser.
import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Singleton {
    id: root
    readonly property var all: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    // Main freedesktop category → label, when the app has no generic name.
    readonly property var categoryNames: ({
        AudioVideo: "Multimedia", Audio: "Audio", Video: "Video", Development: "Development",
        Education: "Education", Game: "Game", Graphics: "Graphics", Network: "Internet",
        Office: "Office", Science: "Science", Settings: "Settings", System: "System",
        Utility: "Utility"
    })

    function list(v) { return Array.from(v ?? []); }
    function kind(a) {
        if (a.genericName !== "") return a.genericName;
        const cat = list(a.categories).find(c => categoryNames[c]);
        return cat ? categoryNames[cat] : "";
    }

    // Without accents or capitals, so that "cafe" finds "Café".
    function fold(s) { return (s ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase(); }

    // Best first: start of the name, start of a word of the name, generic name or keywords, then
    // the name's letters in order ("ffx" → Firefox).
    function score(a, q) {
        const name = fold(a.name);
        if (name.startsWith(q)) return 0;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 1;
        if (name.includes(q)) return 2;
        const extra = fold([a.genericName, a.comment].concat(list(a.keywords), list(a.categories)).join(" "));
        if (extra.includes(q)) return 3;
        let i = 0;
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 4 : -1;
    }
    function search(query) {
        const q = fold(query.trim());
        if (q === "") return [];
        return all.map(a => ({ a, s: score(a, q) }))
            .filter(r => r.s >= 0)
            .sort((x, y) => x.s - y.s || x.a.name.localeCompare(y.a.name))
            .map(r => r.a);
    }

    // Default browser (xdg-mime), for web search.
    property var browser: null
    Process {
        running: true
        command: ["xdg-mime", "query", "default", "x-scheme-handler/https"]
        stdout: StdioCollector {
            onStreamFinished: root.browser = DesktopEntries.byId(text.trim().replace(/\.desktop$/, ""))
        }
    }
    // Just open the link: the system sends it to the default browser, in a tab if it's already open.
    function webSearch(text) {
        Quickshell.execDetached(["xdg-open", Config.searchUrl + encodeURIComponent(text)]);
    }
}

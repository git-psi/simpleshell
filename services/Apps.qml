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

    // Quickshell only watches the app folders that exist at startup: the first flatpak (or the
    // first app in a new folder) creates its folder, and its apps would stay invisible. So we wait
    // for a missing folder to appear, then restart the shell once to read it.
    readonly property var appDirs: [Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"]
        .concat((Quickshell.env("XDG_DATA_DIRS") || "/usr/local/share:/usr/share").split(":"))
        .filter(d => d !== "")
        .map(d => d + "/applications")
    Process {
        running: true
        // Exit 0 when a folder missing at startup appears, 1 if none was missing.
        command: ["sh", "-c", "n=$#; for d; do [ -d \"$d\" ] || set -- \"$@\" \"$d\"; done; shift $n\n"
            + "[ $# -gt 0 ] || exit 1\n"
            + "while :; do for d; do [ -d \"$d\" ] && exit 0; done; sleep 10; done", "sh"].concat(root.appDirs)
        onExited: code => {
            if (code === 0) Quickshell.execDetached(["sh", "-c",
                "pkill -x qs; pkill -x quickshell; sleep 0.5; qs -c simpleshell -n -d"]);
        }
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

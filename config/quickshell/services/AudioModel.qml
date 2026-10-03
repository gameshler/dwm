import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: root.sink !== null && root.sink.audio !== null
    readonly property int volumePercent: root.available ? Math.round(root.sink.audio.volume * 100) : 0
    readonly property bool muted: root.available && root.sink.audio.muted
    readonly property string statusText: !root.available ? "No audio sink"
        : root.muted ? "Muted" : "Volume " + root.volumePercent + "%"

    function setVolume(percent) {
        if (!root.available) {
            return;
        }

        root.sink.audio.volume = Math.max(0, Math.min(100, percent)) / 100;
    }

    function volumeUp() {
        root.setVolume(root.volumePercent + 5);
    }

    function volumeDown() {
        root.setVolume(root.volumePercent - 5);
    }

    function toggleMute() {
        if (root.available) {
            root.sink.audio.muted = !root.sink.audio.muted;
        }
    }

    function openMixer() {
        /* detached so the mixer outlives a bar restart */
        mixerProcess.startDetached();
    }

    /* volume/muted only report real values once the node is bound. */
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Process {
        id: mixerProcess

        command: ["pavucontrol"]
        running: false
    }
}

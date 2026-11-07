#!/usr/bin/env python3
"""Ternux Recorder: on-demand Android microphone recording for Debian PRoot."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import threading
from datetime import datetime

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gio, Gtk, GLib

TERMUX_API = "/data/data/com.termux/files/usr/bin/termux-microphone-record"
TERMUX_HOME = Path("/data/data/com.termux/files/home")
STAGING = TERMUX_HOME / ".cache" / "ternux-recorder"
OUTPUT = Path.home() / "Music" / "Ternux"


class Recorder(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ternux Sound Recorder")
        self.set_default_size(440, 360)
        self.set_border_width(22)
        self.set_icon_name("ternux-recorder")
        self.set_position(Gtk.WindowPosition.CENTER)
        self.recording = False
        self.starting = False
        self.target = None
        self.partial = None

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.add(box)
        title = Gtk.Label()
        title.set_markup('<span size="xx-large" weight="bold">Sound Recorder</span>')
        title.set_xalign(0)
        box.pack_start(title, False, False, 0)
        intro = Gtk.Label(label="Record from your Android microphone when you choose; permission is requested during installation when available.")
        intro.set_xalign(0)
        intro.set_line_wrap(True)
        box.pack_start(intro, False, False, 0)

        self.status = Gtk.Label(label="Ready · microphone is off")
        self.status.set_xalign(0)
        self.status.set_line_wrap(True)
        box.pack_start(self.status, True, True, 0)

        self.record_button = Gtk.Button(label="Start recording")
        self.record_button.get_style_context().add_class("suggested-action")
        self.record_button.connect("clicked", self.toggle_recording)
        self.connect("delete-event", self.confirm_close)
        box.pack_start(self.record_button, False, False, 0)

        row = Gtk.Box(spacing=10)
        self.play_button = Gtk.Button(label="Play latest")
        self.play_button.set_sensitive(False)
        self.play_button.connect("clicked", self.play_latest)
        row.pack_start(self.play_button, True, True, 0)
        self.folder_button = Gtk.Button(label="Open recordings")
        self.folder_button.connect("clicked", self.open_folder)
        row.pack_start(self.folder_button, True, True, 0)
        box.pack_start(row, False, False, 0)

        hint = Gtk.Label(label="Saved inside Debian · Music / Ternux · AAC audio")
        hint.set_xalign(0)
        hint.get_style_context().add_class("dim-label")
        box.pack_start(hint, False, False, 0)
        try:
            OUTPUT.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            self.status.set_text(f"Cannot create recording folder: {exc}")
        self.show_all()

    def toggle_recording(self, *_):
        if self.recording:
            self.stop_recording()
        else:
            self.start_recording()

    def start_recording(self):
        if not Path(TERMUX_API).is_file():
            self.status.set_text("Termux:API command is missing. Install the Termux:API app and run `pkg install termux-api` in Termux.")
            return
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        self.target = OUTPUT / f"Ternux-{stamp}.m4a"
        self.partial = STAGING / f".Ternux-{stamp}.recording.m4a"
        self.starting = True
        self.record_button.set_sensitive(False)
        self.status.set_text("Requesting Android microphone access… recording starts only after you press this button.")

        def work():
            try:
                STAGING.mkdir(parents=True, exist_ok=True)
                result = subprocess.run([TERMUX_API, "-f", str(self.partial), "-e", "aac", "-c", "1"],
                                        check=True, capture_output=True, text=True, timeout=20)
                threading.Event().wait(0.3)
                info = subprocess.run([TERMUX_API, "-i"], check=True, capture_output=True,
                                      text=True, timeout=15)
                try:
                    state = json.loads(info.stdout)
                    recording = (state.get("isRecording") is True and
                                 state.get("outputFile") == str(self.partial))
                    other_recording = (state.get("isRecording") is True and not recording)
                except (json.JSONDecodeError, AttributeError):
                    recording = False
                    other_recording = False
                if other_recording:
                    raise RuntimeError("Termux:API is already recording to another file; that recording was left untouched.")
                if not recording:
                    raise RuntimeError(info.stderr.strip() or result.stderr.strip() or
                                       "Microphone permission may be missing or Android declined recording.")
                GLib.idle_add(self.recording_started)
            except (OSError, subprocess.SubprocessError, RuntimeError) as exc:
                detail = getattr(exc, "stderr", "") or str(exc)
                if self.partial:
                    self.partial.unlink(missing_ok=True)
                GLib.idle_add(self.recording_failed, f"Could not start recording: {detail[:240]}")
        threading.Thread(target=work, daemon=True).start()

    def recording_started(self):
        self.starting = False
        self.recording = True
        self.record_button.set_label("Stop and save")
        self.record_button.set_sensitive(True)
        self.status.set_text("Recording from Android microphone… tap Stop and save when finished.")
        return GLib.SOURCE_REMOVE

    def stop_recording(self):
        self.record_button.set_sensitive(False)
        self.status.set_text("Finishing and saving recording…")

        def work():
            try:
                if not self.partial or not self.target:
                    raise RuntimeError("Recording state was lost.")
                current = subprocess.run([TERMUX_API, "-i"], check=True, capture_output=True,
                                         text=True, timeout=15)
                try:
                    state = json.loads(current.stdout)
                except json.JSONDecodeError as exc:
                    raise RuntimeError("Could not verify which recording is active; left it untouched.") from exc
                if state.get("isRecording") is True:
                    if state.get("outputFile") != str(self.partial):
                        raise RuntimeError("Another recording is active; it was left untouched.")
                    subprocess.run([TERMUX_API, "-q"], check=True, capture_output=True,
                                   text=True, timeout=20)
                if not self.partial or not self.target:
                    raise RuntimeError("Recording state was lost.")
                # MediaRecorder finalizes the container asynchronously after quit.
                for _ in range(50):
                    if self.partial.is_file() and self.partial.stat().st_size >= 1024:
                        break
                    threading.Event().wait(0.1)
                if not self.partial.is_file() or self.partial.stat().st_size < 1024:
                    raise RuntimeError("Android returned no complete audio file.")
                with self.partial.open("rb") as audio:
                    if audio.read(8)[4:8] != b"ftyp":
                        raise RuntimeError("Android output is not a valid MPEG-4/AAC audio file.")
                OUTPUT.mkdir(parents=True, exist_ok=True)
                temporary = self.target.with_suffix(".partial.m4a")
                with self.partial.open("rb") as source, temporary.open("xb") as dest:
                    shutil.copyfileobj(source, dest, 1024 * 1024)
                    dest.flush()
                    os.fsync(dest.fileno())
                os.chmod(temporary, 0o644)
                os.replace(temporary, self.target)
                self.partial.unlink(missing_ok=True)
                GLib.idle_add(self.recording_saved, self.target)
            except (OSError, subprocess.SubprocessError, RuntimeError) as exc:
                detail = getattr(exc, "stderr", "") or str(exc)
                if self.partial:
                    self.partial.unlink(missing_ok=True)
                GLib.idle_add(self.recording_failed, f"Recording could not be saved: {detail[:240]}")
        threading.Thread(target=work, daemon=True).start()

    def recording_saved(self, path):
        self.recording = False
        self.record_button.set_label("Start recording")
        self.record_button.set_sensitive(True)
        self.play_button.set_sensitive(True)
        self.status.set_text(f"Saved: {path}\nFind it in Home → Music → Ternux.")
        return GLib.SOURCE_REMOVE

    def recording_failed(self, message):
        self.starting = False
        self.recording = False
        self.record_button.set_label("Start recording")
        self.record_button.set_sensitive(True)
        self.status.set_text(message)
        return GLib.SOURCE_REMOVE

    def play_latest(self, *_):
        if not self.target or not self.target.is_file():
            return
        try:
            subprocess.Popen(["vlc", str(self.target)], stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
        except OSError as exc:
            self.status.set_text(f"Could not open VLC: {exc}")

    def confirm_close(self, *_):
        if self.recording or self.starting:
            message = "Recording is active. Stop and save it before closing the recorder." if self.recording else "Microphone access is being checked. Wait for that request to finish before closing."
            dialog = Gtk.MessageDialog(
                transient_for=self, modal=True, message_type=Gtk.MessageType.WARNING,
                buttons=Gtk.ButtonsType.CLOSE,
                text=message)
            dialog.run()
            dialog.destroy()
            return True
        return False

    def open_folder(self, *_):
        try:
            OUTPUT.mkdir(parents=True, exist_ok=True)
            Gio.AppInfo.launch_default_for_uri(OUTPUT.as_uri(), None)
        except (OSError, GLib.Error) as exc:
            self.status.set_text(f"Could not open {OUTPUT}: {exc}")


if __name__ == "__main__":
    window = Recorder()
    window.connect("destroy", Gtk.main_quit)
    Gtk.main()

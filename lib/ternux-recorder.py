#!/usr/bin/env python3
"""Ternux Recorder: on-demand Android microphone recording for Debian PRoot."""
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import threading
import time
from datetime import datetime

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gio, Gtk, GLib

TERMUX_API = "/data/data/com.termux/files/usr/bin/termux-microphone-record"

def termux_api_environment():
    """Run Android-side Termux:API binaries without the guest's ELF preload."""
    env = os.environ.copy()
    env.pop("LD_PRELOAD", None)
    return env

FFMPEG = "/usr/bin/ffmpeg"
FFPROBE = "/usr/bin/ffprobe"
TERMUX_HOME = Path("/data/data/com.termux/files/home")
STAGING = TERMUX_HOME / ".cache" / "ternux-recorder"
OUTPUT = Path.home() / "Music" / "Ternux"


def probe_audio(path, expected_codec, timeout=5):
    """Return metadata only after ffprobe can read a finalized audio file."""
    result = subprocess.run(
        [FFPROBE, "-v", "error", "-select_streams", "a:0",
         "-show_entries", "stream=codec_name:format=duration", "-of", "json", str(path)],
        check=True, capture_output=True, text=True, timeout=timeout)
    data = json.loads(result.stdout)
    streams = data.get("streams", [])
    duration = float(data.get("format", {}).get("duration", 0))
    if not streams or streams[0].get("codec_name") != expected_codec or not math.isfinite(duration) or duration <= 0:
        raise RuntimeError(f"Audio verification failed (expected {expected_codec}, positive duration).")
    return duration


def wait_for_audio(path, expected_codec, deadline=20):
    """Wait for Android MediaRecorder to finalize the container after stop."""
    end = time.monotonic() + deadline
    last_error = "file is not ready"
    while time.monotonic() < end:
        try:
            if Path(path).is_file() and Path(path).stat().st_size >= 1024:
                return probe_audio(path, expected_codec, timeout=3)
        except (OSError, subprocess.SubprocessError, ValueError, json.JSONDecodeError, RuntimeError) as exc:
            last_error = str(exc) or type(exc).__name__
        time.sleep(0.25)
    raise RuntimeError(f"Android recording did not finalize as {expected_codec}: {last_error[:160]}")


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

        format_row = Gtk.Box(spacing=12)
        format_label = Gtk.Label(label="Save format")
        format_label.set_xalign(0)
        format_row.pack_start(format_label, True, True, 0)
        self.format_combo = Gtk.ComboBoxText()
        self.format_combo.append("aac", "AAC · M4A")
        self.format_combo.append("mp3", "MP3 · 128 kbps")
        self.format_combo.set_active_id("aac")
        format_row.pack_end(self.format_combo, False, False, 0)
        box.pack_start(format_row, False, False, 0)

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

        hint = Gtk.Label(label="Saved inside Debian · Music / Ternux · AAC or MP3")
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
        output_format = self.format_combo.get_active_id() or "aac"
        if output_format == "mp3" and (not Path(FFMPEG).is_file() or not Path(FFPROBE).is_file()):
            self.status.set_text("MP3 export needs FFmpeg. Install with sudo apt install ffmpeg, or choose AAC · M4A.")
            return
        suffix = ".mp3" if output_format == "mp3" else ".m4a"
        self.target = OUTPUT / f"Ternux-{stamp}{suffix}"
        self.partial = STAGING / f".Ternux-{stamp}.recording.m4a"
        self.starting = True
        self.format_combo.set_sensitive(False)
        self.record_button.set_sensitive(False)
        self.status.set_text("Requesting Android microphone access… recording starts only after you press this button.")

        def work():
            try:
                STAGING.mkdir(parents=True, exist_ok=True)
                result = subprocess.run([TERMUX_API, "-f", str(self.partial), "-e", "aac", "-c", "1"],
                                        check=True, capture_output=True, text=True, timeout=20,
                                        env=termux_api_environment())
                threading.Event().wait(0.3)
                info = subprocess.run([TERMUX_API, "-i"], check=True, capture_output=True,
                                      text=True, timeout=15, env=termux_api_environment())
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
                # Preserve any bytes captured before an API/start failure for recovery.
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
                                         text=True, timeout=15, env=termux_api_environment())
                try:
                    state = json.loads(current.stdout)
                except json.JSONDecodeError as exc:
                    raise RuntimeError("Could not verify which recording is active; left it untouched.") from exc
                if state.get("isRecording") is True:
                    if state.get("outputFile") != str(self.partial):
                        raise RuntimeError("Another recording is active; it was left untouched.")
                    subprocess.run([TERMUX_API, "-q"], check=True, capture_output=True,
                                   text=True, timeout=20, env=termux_api_environment())
                if not self.partial or not self.target:
                    raise RuntimeError("Recording state was lost.")
                # Termux:API returns before Android writes the MP4 moov atom.
                wait_for_audio(self.partial, "aac", deadline=20)
                OUTPUT.mkdir(parents=True, exist_ok=True)
                temporary = self.target.with_suffix(".partial" + self.target.suffix)
                if self.target.suffix == ".mp3":
                    try:
                        subprocess.run([FFMPEG, "-nostdin", "-hide_banner", "-loglevel", "error",
                                        "-n", "-i", str(self.partial), "-map_metadata", "-1", "-vn",
                                        "-codec:a", "libmp3lame", "-b:a", "128k", str(temporary)],
                                       check=True, capture_output=True, text=True, timeout=1800)
                        if not temporary.is_file() or temporary.stat().st_size < 1024:
                            raise RuntimeError("FFmpeg did not produce a complete MP3 file.")
                        probe_audio(temporary, "mp3", timeout=30)
                    except (OSError, subprocess.SubprocessError, RuntimeError) as exc:
                        temporary.unlink(missing_ok=True)
                        fallback = self.target.with_suffix(".m4a")
                        fallback_tmp = fallback.with_suffix(".partial.m4a")
                        with self.partial.open("rb") as source, fallback_tmp.open("xb") as dest:
                            shutil.copyfileobj(source, dest, 1024 * 1024)
                            dest.flush()
                            os.fsync(dest.fileno())
                        os.chmod(fallback_tmp, 0o644)
                        wait_for_audio(fallback_tmp, "aac", deadline=1)
                        os.replace(fallback_tmp, fallback)
                        self.partial.unlink(missing_ok=True)
                        GLib.idle_add(self.recording_saved, fallback,
                                      f"MP3 export failed; the original AAC recording was saved instead. {str(exc)[:160]}")
                        return
                else:
                    with self.partial.open("rb") as source, temporary.open("xb") as dest:
                        shutil.copyfileobj(source, dest, 1024 * 1024)
                        dest.flush()
                        os.fsync(dest.fileno())
                    wait_for_audio(temporary, "aac", deadline=1)
                os.chmod(temporary, 0o644)
                os.replace(temporary, self.target)
                self.partial.unlink(missing_ok=True)
                GLib.idle_add(self.recording_saved, self.target)
            except (OSError, subprocess.SubprocessError, RuntimeError) as exc:
                detail = getattr(exc, "stderr", "") or str(exc)
                if self.target:
                    self.target.with_suffix(".partial" + self.target.suffix).unlink(missing_ok=True)
                recovery = f" Recovery copy remains in {self.partial}." if self.partial and self.partial.exists() else ""
                GLib.idle_add(self.recording_failed, f"Recording could not be verified/saved: {detail[:200]}.{recovery}")
        threading.Thread(target=work, daemon=True).start()

    def recording_saved(self, path, note=None):
        self.recording = False
        self.record_button.set_label("Start recording")
        self.record_button.set_sensitive(True)
        self.format_combo.set_sensitive(True)
        self.play_button.set_sensitive(True)
        detail = f"\n{note}" if note else ""
        self.status.set_text(f"Saved: {path}\nFind it in Home → Music → Ternux.{detail}")
        return GLib.SOURCE_REMOVE

    def recording_failed(self, message):
        self.starting = False
        self.recording = False
        self.record_button.set_label("Start recording")
        self.record_button.set_sensitive(True)
        self.format_combo.set_sensitive(True)
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

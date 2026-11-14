#!/usr/bin/env python3
"""Ternux Camera: Android camera capture bridge for the Debian desktop."""
import json
import os
from pathlib import Path
import subprocess
import threading
from datetime import datetime

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GdkPixbuf, Gio, Gtk, GLib

CAMERA_INFO = "/data/data/com.termux/files/usr/bin/termux-camera-info"
CAMERA_PHOTO = "/data/data/com.termux/files/usr/bin/termux-camera-photo"
FLASHLIGHT = "/usr/local/bin/ternux-flashlight"
FLASHLIGHT_STATE = Path.home() / ".cache" / "ternux" / "flashlight.json"
TERMUX_HOME = Path("/data/data/com.termux/files/home")
API_CAPTURE_DIR = TERMUX_HOME / ".cache" / "ternux-camera"

def termux_api_environment():
    """Run Android-side Termux:API binaries without the guest's ELF preload."""
    env = os.environ.copy()
    env.pop("LD_PRELOAD", None)
    return env

OUTPUT_DIR = Path.home() / "Pictures" / "Ternux"
LEGACY_SHARED_DIR = Path("/sdcard/Pictures/Ternux")


class TernuxCamera(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ternux Camera")
        self.set_default_size(520, 610)
        self.set_border_width(16)
        self.set_icon_name("ternux-camera")
        self.set_position(Gtk.WindowPosition.CENTER)
        self.last_photo = None
        self.torch_busy = False
        self.torch_on = self.flashlight_state_is_on()

        # Keep the photo library inside the Debian home. Termux:API can only
        # write to Termux-accessible storage, so captures stage in Termux home
        # and are copied into this PRoot folder after validation.
        try:
            if OUTPUT_DIR.is_symlink() and os.readlink(OUTPUT_DIR) in {
                str(LEGACY_SHARED_DIR), "/storage/emulated/0/Pictures/Ternux",
                "/mnt/sdcard/Pictures/Ternux",
            }:
                OUTPUT_DIR.unlink()
            OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        except OSError:
            pass

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(root)
        css = Gtk.CssProvider()
        css.load_from_data(b"""
            button.ternux-compact { padding: 4px 9px; min-height: 28px; }
            button.ternux-primary { padding: 6px 12px; min-height: 34px; }
        """)
        screen = Gdk.Screen.get_default()
        if screen:
            Gtk.StyleContext.add_provider_for_screen(
                screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        self._css_provider = css

        hero = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        title = Gtk.Label()
        title.set_markup('<span size="xx-large" weight="bold">Ternux Camera</span>')
        title.set_xalign(0)
        hero.pack_start(title, False, False, 0)
        subtitle = Gtk.Label(label="Capture a photo with your Android front or rear camera")
        subtitle.set_xalign(0)
        hero.pack_start(subtitle, False, False, 0)
        root.pack_start(hero, False, False, 0)

        self.preview = Gtk.Image.new_from_icon_name("camera-photo-symbolic", Gtk.IconSize.DIALOG)
        self.preview.set_pixel_size(72)
        preview_frame = Gtk.Frame()
        preview_frame.set_shadow_type(Gtk.ShadowType.IN)
        preview_frame.set_size_request(-1, 220)
        preview_frame.add(self.preview)
        root.pack_start(preview_frame, True, True, 0)
        self.preview_hint = Gtk.Label(label="Capture a photo to preview it here")
        self.preview_hint.get_style_context().add_class("dim-label")
        root.pack_start(self.preview_hint, False, False, 0)

        self.camera = Gtk.ComboBoxText()
        self.camera.set_hexpand(True)
        camera_row = Gtk.Box(spacing=10)
        camera_row.pack_start(Gtk.Label(label="Camera"), False, False, 0)
        camera_row.pack_start(self.camera, True, True, 0)
        self.refresh = Gtk.Button(label="Refresh")
        self.refresh.connect("clicked", lambda *_: self.load_cameras())
        camera_row.pack_start(self.refresh, False, False, 0)
        root.pack_start(camera_row, False, False, 0)

        self.flashlight = Gtk.ToggleButton(label="Flashlight on" if self.torch_on else "Flashlight off")
        self.flashlight.set_active(self.torch_on)
        self.flashlight.set_tooltip_text("Toggle the Android camera flashlight")
        self.flashlight_handler = self.flashlight.connect("toggled", self.toggle_flashlight)
        root.pack_start(self.flashlight, False, False, 0)

        location = Gtk.Label(label="Saved inside Debian: Home → Pictures → Ternux")
        location.set_xalign(0)
        location.set_line_wrap(True)
        root.pack_start(location, False, False, 0)

        self.status = Gtk.Label(label="Checking Android cameras…")
        self.status.set_xalign(0)
        self.status.set_line_wrap(True)
        root.pack_start(self.status, False, False, 0)

        self.capture = Gtk.Button(label="Take photo")
        self.capture.get_style_context().add_class("suggested-action")
        self.capture.get_style_context().add_class("ternux-primary")
        self.capture.set_hexpand(True)
        self.capture.set_tooltip_text("Capture with the selected Android camera")
        self.capture.connect("clicked", self.take_photo)
        root.pack_start(self.capture, False, False, 0)

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        actions.set_homogeneous(True)
        self.open_photo = Gtk.Button(label="View photo")
        self.open_photo.set_sensitive(False)
        self.open_photo.set_tooltip_text("Open the latest photo")
        self.open_photo.connect("clicked", self.open_last_photo)
        self.open_folder = Gtk.Button(label="Photos")
        self.open_folder.set_tooltip_text("Open Ternux photo folder")
        self.open_folder.connect("clicked", self.open_save_folder)
        for button in (self.open_photo, self.open_folder):
            button.get_style_context().add_class("ternux-compact")
            actions.pack_start(button, True, True, 0)
        root.pack_start(actions, False, False, 0)

        self.show_all()
        self.load_cameras()

    def set_busy(self, busy, message=None):
        self.capture.set_sensitive(not busy)
        self.refresh.set_sensitive(not busy)
        if message:
            self.status.set_text(message)

    @staticmethod
    def flashlight_state_is_on():
        try:
            return json.loads(FLASHLIGHT_STATE.read_text()).get("on") is True
        except (OSError, ValueError, AttributeError):
            return False

    @staticmethod
    def api_error_text(*outputs):
        for output in outputs:
            detail = (output or "").strip()
            if not detail:
                continue
            try:
                payload = json.loads(detail)
                if isinstance(payload, dict):
                    detail = str(payload.get("error") or payload.get("message") or detail)
            except json.JSONDecodeError:
                pass
            if "android.permission.CAMERA" in detail or "Please grant" in detail:
                return ("Termux:API needs Android Camera permission. Open Android Settings → Apps → "
                        "Termux:API → Permissions → Camera, allow access, then retry.")
            return detail
        return ""

    def toggle_flashlight(self, button):
        if self.torch_busy:
            return
        requested = button.get_active()
        self.torch_busy = True
        button.set_sensitive(False)

        def work():
            error = ""
            try:
                result = subprocess.run([FLASHLIGHT, "on" if requested else "off"],
                                        check=True, capture_output=True, text=True,
                                        timeout=15, env=termux_api_environment())
                error = self.api_error_text(result.stderr)
            except (OSError, subprocess.SubprocessError) as exc:
                error = self.api_error_text(getattr(exc, "stderr", ""),
                                            getattr(exc, "stdout", ""), str(exc))
            GLib.idle_add(self.flashlight_ready, button, requested, error)

        threading.Thread(target=work, daemon=True).start()

    def flashlight_ready(self, button, requested, error):
        self.torch_busy = False
        button.set_sensitive(True)
        if error:
            button.handler_block(self.flashlight_handler)
            button.set_active(False)
            button.set_label("Flashlight off")
            button.handler_unblock(self.flashlight_handler)
            self.status.set_text(error)
        else:
            self.torch_on = requested
            button.set_label("Flashlight on" if requested else "Flashlight off")
            self.status.set_text("Flashlight command sent to Android." if requested else
                                 "Flashlight off command sent to Android.")
        return GLib.SOURCE_REMOVE

    def switch_flashlight_off_on_close(self, *_):
        if self.torch_on or self.flashlight_state_is_on():
            try:
                subprocess.Popen([FLASHLIGHT, "off"], env=termux_api_environment(),
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                 start_new_session=True)
            except OSError:
                pass

    def load_cameras(self):
        self.camera.remove_all()
        self.set_busy(True, "Looking for Android cameras…")

        def work():
            try:
                result = subprocess.run([CAMERA_INFO], check=True, capture_output=True,
                                        text=True, timeout=30, env=termux_api_environment())
                data = json.loads(result.stdout)
                entries = data if isinstance(data, list) else data.get("cameras", [])
                cameras = []
                for item in entries:
                    if not isinstance(item, dict):
                        continue
                    cid = str(item.get("id", item.get("camera_id", "")))
                    if not cid:
                        continue
                    facing = str(item.get("facing", item.get("lens_facing", ""))).lower()
                    label = "Front camera" if "front" in facing else "Back camera" if "back" in facing else "Camera"
                    cameras.append((cid, f"{label} · ID {cid}"))
                GLib.idle_add(self.cameras_ready, cameras,
                              None if cameras else "No Android cameras were reported.")
            except FileNotFoundError:
                GLib.idle_add(self.cameras_ready, [],
                    "Termux:API is missing. Install the Termux:API app and `pkg install termux-api` in Termux.")
            except subprocess.TimeoutExpired:
                GLib.idle_add(self.cameras_ready, [],
                    "Camera service timed out. Unlock the phone and check Termux:API camera permission.")
            except (subprocess.CalledProcessError, json.JSONDecodeError, OSError) as exc:
                detail = getattr(exc, "stderr", "") or str(exc)
                GLib.idle_add(self.cameras_ready, [],
                    f"Camera access failed. Check Termux:API and Android camera permission. {detail[:240]}")
        threading.Thread(target=work, daemon=True).start()

    def cameras_ready(self, cameras, error):
        for cid, label in cameras:
            self.camera.append(cid, label)
        if cameras:
            # Camera ID 0 is normally the rear lens; start there and keep the
            # selector available for devices whose IDs differ.
            back = next((cid for cid, label in cameras if "Back" in label), cameras[0][0])
            self.camera.set_active_id(back)
            self.status.set_text(f"{len(cameras)} Android camera(s) ready. Back camera selected; captures save inside Debian.")
        else:
            self.status.set_text(error or "No camera found.")
        self.set_busy(False)
        return GLib.SOURCE_REMOVE

    @staticmethod
    def api_path_for(target):
        """Return the native Termux path accepted by Termux:API."""
        target = Path(target).resolve()
        home = TERMUX_HOME.resolve()
        try:
            target.relative_to(home)
        except ValueError as exc:
            raise ValueError("Termux:API staging files must stay inside Termux home.") from exc
        return str(target)

    def take_photo(self, *_):
        cid = self.camera.get_active_id()
        if not cid:
            self.status.set_text("Select a camera first, then use Refresh if needed.")
            return
        self.set_busy(True, f"Capturing with camera ID {cid}… Android may ask for camera permission.")

        def work():
            api_partial = None
            local_partial = None
            photo_note = ""
            try:
                if self.torch_on or self.flashlight_state_is_on():
                    torch_result = subprocess.run([FLASHLIGHT, "off"], check=True,
                                                  capture_output=True, text=True, timeout=15,
                                                  env=termux_api_environment())
                    torch_error = self.api_error_text(torch_result.stderr)
                    if torch_error:
                        raise RuntimeError(torch_error)
                    self.torch_on = False
                    photo_note = ("Flashlight was turned off for this photo. Termux:API still-photo "
                                  "capture does not provide a flash setting.")
                    GLib.idle_add(self.reset_flashlight_after_capture)
                OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
                API_CAPTURE_DIR.mkdir(parents=True, exist_ok=True)
                stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
                target = OUTPUT_DIR / ("Ternux-" + stamp + ".jpg")
                api_partial = API_CAPTURE_DIR / (".Ternux-" + stamp + ".capture.jpg")
                local_partial = OUTPUT_DIR / (".Ternux-" + stamp + ".capture.jpg")
                result = subprocess.run([CAMERA_PHOTO, "-c", cid, self.api_path_for(api_partial)],
                                        check=True, capture_output=True, text=True, timeout=90,
                                        env=termux_api_environment())
                api_error = self.api_error_text(result.stderr, result.stdout)
                if api_error:
                    raise RuntimeError(api_error)
                if not api_partial.is_file():
                    raise RuntimeError("Termux:API returned without creating the photo file.")
                with api_partial.open("rb") as photo:
                    signature = photo.read(3)
                if api_partial.stat().st_size < 1024 or signature != b"\xff\xd8\xff":
                    raise RuntimeError("Capture finished, but the output is not a complete JPEG photo.")
                # Copy across the app-private Termux area into Debian, then
                # atomically reveal the finished file in the user's photo folder.
                with api_partial.open("rb") as source, local_partial.open("xb") as destination:
                    while True:
                        chunk = source.read(1024 * 1024)
                        if not chunk:
                            break
                        destination.write(chunk)
                    destination.flush()
                    os.fsync(destination.fileno())
                os.chmod(local_partial, 0o644)
                os.replace(local_partial, target)
                GLib.idle_add(self.capture_ready, target, photo_note)
            except (OSError, ValueError, subprocess.SubprocessError, RuntimeError) as exc:
                if local_partial is not None:
                    try:
                        local_partial.unlink(missing_ok=True)
                    except OSError:
                        pass
                detail = (self.api_error_text(getattr(exc, "stderr", ""),
                                              getattr(exc, "stdout", "")) or str(exc))
                GLib.idle_add(self.capture_failed, f"Capture failed: {detail[:320]}")
            finally:
                if api_partial is not None:
                    try:
                        api_partial.unlink(missing_ok=True)
                    except OSError:
                        pass
        threading.Thread(target=work, daemon=True).start()

    def reset_flashlight_after_capture(self):
        self.flashlight.handler_block(self.flashlight_handler)
        self.flashlight.set_active(False)
        self.flashlight.set_label("Flashlight off")
        self.flashlight.handler_unblock(self.flashlight_handler)
        return GLib.SOURCE_REMOVE

    def capture_ready(self, target, photo_note):
        self.last_photo = target
        self.open_photo.set_sensitive(True)
        try:
            # Decode to a small square first so either orientation fits the
            # preview without loading the camera's full-resolution image.
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(target), 480, 480, True)
            # Android cameras commonly store portrait orientation in EXIF while
            # keeping the JPEG pixels landscape. Rotate before the final fit.
            pixbuf = pixbuf.apply_embedded_orientation()
            scale = min(480 / pixbuf.get_width(), 210 / pixbuf.get_height(), 1.0)
            width = max(1, round(pixbuf.get_width() * scale))
            height = max(1, round(pixbuf.get_height() * scale))
            pixbuf = pixbuf.scale_simple(width, height, GdkPixbuf.InterpType.BILINEAR)
            self.preview.set_from_pixbuf(pixbuf)
            self.preview_hint.set_text(target.name)
            note = f"\n{photo_note}" if photo_note else ""
            self.status.set_text(f"Photo saved: {target}\nFind it in Home → Pictures → Ternux.{note}")
        except GLib.Error as exc:
            self.status.set_text(f"Photo saved at {target}, but preview failed: {exc.message}")
        self.set_busy(False)
        return GLib.SOURCE_REMOVE

    def capture_failed(self, message):
        self.status.set_text(message)
        self.set_busy(False)
        return GLib.SOURCE_REMOVE

    def open_last_photo(self, *_):
        if not self.last_photo or not self.last_photo.is_file():
            self.status.set_text("Capture a photo first; the saved file will appear here.")
            return
        try:
            subprocess.Popen(["ristretto", str(self.last_photo)],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
        except OSError as exc:
            self.status.set_text(f"Could not open the photo viewer: {exc}")

    def open_save_folder(self, *_):
        try:
            folder = Path(OUTPUT_DIR)
            folder.mkdir(parents=True, exist_ok=True)
            Gio.AppInfo.launch_default_for_uri(folder.as_uri(), None)
        except (OSError, GLib.Error) as exc:
            self.status.set_text(f"Could not open {OUTPUT_DIR}: {exc}")


if __name__ == "__main__":
    win = TernuxCamera()
    win.connect("destroy", win.switch_flashlight_off_on_close)
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()

import os
import struct
import time
import threading
import queue
import traceback

import glfw
import moderngl


VERTEX_SHADER = """
#version 330 core

in vec2 in_position;

out vec2 v_uv;

void main()
{
    v_uv = in_position * 0.5 + 0.5;
    gl_Position = vec4(in_position, 0.0, 1.0);
}
"""


class Renderer:
    """
    NebulaWall renderer.

    IMPORTANT:
    The render thread owns ALL GLFW/OpenGL operations.

    The Tkinter/UI thread communicates with this object through
    thread-safe command queues only.
    """

    def __init__(
        self,
        width=1920,
        height=1080,
        shader_path=None,
        target_fps=60,
        *args,
        **kwargs
    ):
        self.width = int(width)
        self.height = int(height)

        self.shader_path = (
            os.path.abspath(str(shader_path))
            if shader_path
            else None
        )

        self.target_fps = max(1, int(target_fps or 60))

        # -----------------------------------------------------
        # Render-thread state
        # -----------------------------------------------------

        self.window = None
        self.ctx = None
        self.program = None
        self.vao = None
        self.vbo = None

        self.last_width = self.width
        self.last_height = self.height

        self.start_time = time.perf_counter()
        self.frame_count = 0

        # -----------------------------------------------------
        # Thread state
        # -----------------------------------------------------

        self._thread = None
        self._thread_started = threading.Event()
        self._thread_ready = threading.Event()
        self._thread_stopped = threading.Event()

        self._stop_event = threading.Event()

        # Commands sent from Tkinter -> render thread
        self._commands = queue.Queue()

        # Result/error reporting
        self._error = None
        self._error_lock = threading.Lock()

        # State accessible from UI
        self._state_lock = threading.Lock()

        self.running = False
        self.desktop_attached = False
        self.current_shader = self.shader_path

        self.fps = 0.0

        # FPS measurement
        self._fps_time = time.perf_counter()
        self._fps_frames = 0

    # =========================================================
    # PUBLIC THREAD-SAFE API
    # =========================================================

    def start(self, timeout=10.0):
        """
        Start the renderer thread.

        All GLFW/OpenGL initialization happens inside that thread.
        """

        if self._thread and self._thread.is_alive():
            return True

        self._stop_event.clear()
        self._thread_started.clear()
        self._thread_ready.clear()
        self._thread_stopped.clear()

        self._error = None

        self._thread = threading.Thread(
            target=self._render_thread_main,
            name="NebulaWall-Renderer",
            daemon=True,
        )

        self._thread.start()

        if not self._thread_ready.wait(timeout):
            raise RuntimeError(
                "NebulaWall renderer thread did not initialize "
                "within the expected time."
            )

        self._raise_thread_error()

        return True

    def stop(self, timeout=5.0):
        """
        Stop the render thread cleanly.
        """

        self._stop_event.set()

        # Wake the renderer immediately.
        self._commands.put(("stop", None))

        thread = self._thread

        if thread and thread.is_alive():
            thread.join(timeout)

        self._thread = None
        self.running = False

    def set_wallpaper(self, shader_path):
        """
        Thread-safe wallpaper change.

        The actual shader compilation occurs on the render thread.
        """

        shader_path = os.path.abspath(str(shader_path))

        if not os.path.isfile(shader_path):
            raise FileNotFoundError(
                f"Wallpaper shader not found:\n{shader_path}"
            )

        self._commands.put(
            ("load_shader", shader_path)
        )

    load_wallpaper = set_wallpaper

    def load_shader(self, shader_path):
        """
        Compatibility alias.

        UI code can still call renderer.load_shader(...).
        """

        self.set_wallpaper(shader_path)

    def resize(self, width, height):
        """
        Thread-safe resize request.
        """

        self._commands.put(
            (
                "resize",
                (
                    int(width),
                    int(height),
                ),
            )
        )

    def pause(self):
        """
        Pause rendering without destroying the OpenGL context.
        """

        self._commands.put(("pause", None))

    def resume(self):
        """
        Resume rendering.
        """

        self._commands.put(("resume", None))

    def toggle_pause(self):
        self._commands.put(("toggle_pause", None))

    def is_alive(self):
        return (
            self._thread is not None
            and self._thread.is_alive()
        )

    def get_error(self):
        with self._error_lock:
            return self._error

    def get_fps(self):
        with self._state_lock:
            return self.fps

    def get_current_shader(self):
        with self._state_lock:
            return self.current_shader

    # =========================================================
    # RENDER THREAD
    # =========================================================

    def _render_thread_main(self):
        """
        EVERYTHING involving GLFW/OpenGL happens here.
        """

        self._thread_started.set()

        try:
            self._create_window_internal()

            if self.shader_path:
                shader = self.shader_path
                self.shader_path = None
                self._load_shader_internal(shader)

            self._attach_to_desktop_internal()

            self.running = True
            self._thread_ready.set()

            print(
                "[renderer] render thread started"
            )

            self._render_loop()

        except Exception as exc:
            with self._error_lock:
                self._error = exc

            print("=" * 70)
            print("[renderer] RENDER THREAD ERROR")
            print("=" * 70)
            traceback.print_exc()
            print("=" * 70)

            self._thread_ready.set()

        finally:
            try:
                self._cleanup_internal()
            except Exception:
                traceback.print_exc()

            self.running = False
            self._thread_stopped.set()

            print(
                "[renderer] render thread stopped"
            )

    # =========================================================
    # GLFW INITIALIZATION
    # =========================================================

    def _create_window_internal(self):
        if self.window is not None:
            return

        if not glfw.init():
            raise RuntimeError(
                "GLFW initialization failed."
            )

        glfw.window_hint(
            glfw.CONTEXT_VERSION_MAJOR,
            3
        )

        glfw.window_hint(
            glfw.CONTEXT_VERSION_MINOR,
            3
        )

        glfw.window_hint(
            glfw.OPENGL_PROFILE,
            glfw.OPENGL_CORE_PROFILE
        )

        glfw.window_hint(
            glfw.VISIBLE,
            glfw.FALSE
        )

        glfw.window_hint(
            glfw.RESIZABLE,
            glfw.TRUE
        )

        self.window = glfw.create_window(
            self.width,
            self.height,
            "NebulaWall Renderer",
            None,
            None,
        )

        if not self.window:
            glfw.terminate()

            raise RuntimeError(
                "Could not create GLFW window."
            )

        # Context becomes current ON THIS THREAD.
        glfw.make_context_current(
            self.window
        )

        # Wallpaper should not be limited by monitor VSync.
        glfw.swap_interval(0)

        try:
            self.ctx = moderngl.create_context()
        except Exception:
            glfw.destroy_window(
                self.window
            )

            self.window = None

            glfw.terminate()

            raise

        print(
            "[renderer] OpenGL initialized"
        )

        print(
            "[renderer] OpenGL:",
            self.ctx.version_code
        )

        print(
            "[renderer] Renderer:",
            self.ctx.info.get(
                "GL_RENDERER",
                "Unknown"
            )
        )

        self._create_quad()

    # =========================================================
    # QUAD
    # =========================================================

    def _create_quad(self):
        vertex_data = struct.pack(
            "8f",
            -1.0,
            -1.0,

            1.0,
            -1.0,

            -1.0,
            1.0,

            1.0,
            1.0,
        )

        self.vbo = self.ctx.buffer(
            vertex_data
        )

    # =========================================================
    # SHADER LOADING
    # =========================================================

    def _load_shader_internal(
        self,
        shader_path
    ):
        shader_path = os.path.abspath(
            str(shader_path)
        )

        if not os.path.isfile(shader_path):
            raise FileNotFoundError(
                f"Wallpaper shader not found:\n"
                f"{shader_path}"
            )

        with open(
            shader_path,
            "r",
            encoding="utf-8"
        ) as f:
            fragment_source = f.read()

        if not fragment_source.strip():
            raise RuntimeError(
                f"Wallpaper shader is empty:\n"
                f"{shader_path}"
            )

        if not self.window:
            raise RuntimeError(
                "Renderer GLFW window no longer exists."
            )

        glfw.make_context_current(
            self.window
        )

        try:
            new_program = self.ctx.program(
                vertex_shader=VERTEX_SHADER,
                fragment_shader=fragment_source,
            )

            new_vao = self.ctx.vertex_array(
                new_program,
                [
                    (
                        self.vbo,
                        "2f",
                        "in_position"
                    )
                ],
            )

        except Exception as exc:

            print("=" * 70)
            print(
                "[renderer] SHADER COMPILATION ERROR"
            )
            print("=" * 70)

            print(shader_path)
            print(exc)

            print("=" * 70)

            raise

        # Replace only after compilation succeeded.
        old_vao = self.vao
        old_program = self.program

        self.program = new_program
        self.vao = new_vao

        with self._state_lock:
            self.current_shader = shader_path

        self.start_time = time.perf_counter()
        self.frame_count = 0

        print(
            "[renderer] loaded:",
            shader_path
        )

        # Release old resources after new shader is ready.
        if old_vao is not None:
            try:
                old_vao.release()
            except Exception:
                pass

        if old_program is not None:
            try:
                old_program.release()
            except Exception:
                pass

    # =========================================================
    # DESKTOP ATTACHMENT
    # =========================================================

    def _attach_to_desktop_internal(self):
        if not self.window:
            raise RuntimeError(
                "Renderer window has not been created."
            )

        hwnd = glfw.get_win32_window(
            self.window
        )

        if not hwnd:
            raise RuntimeError(
                "Could not obtain GLFW Windows HWND."
            )

        # IMPORTANT:
        # desktop.py is called from the render thread.
        #
        # It only manipulates the native HWND.
        from desktop import prepare_window

        prepare_window(
            hwnd,
            self.width,
            self.height
        )

        glfw.make_context_current(
            self.window
        )

        fb_width, fb_height = (
            glfw.get_framebuffer_size(
                self.window
            )
        )

        if fb_width <= 0:
            fb_width = self.width

        if fb_height <= 0:
            fb_height = self.height

        self.ctx.viewport = (
            0,
            0,
            fb_width,
            fb_height
        )

        self.last_width = fb_width
        self.last_height = fb_height

        self.desktop_attached = True

        glfw.show_window(
            self.window
        )

        print(
            "[renderer] attached HWND:",
            hwnd
        )

        print(
            "[renderer] framebuffer:",
            fb_width,
            "x",
            fb_height
        )

    # =========================================================
    # COMMAND PROCESSING
    # =========================================================

    def _process_commands(self):
        while True:
            try:
                command, value = (
                    self._commands.get_nowait()
                )
            except queue.Empty:
                break

            if command == "stop":
                self._stop_event.set()

            elif command == "load_shader":
                try:
                    self._load_shader_internal(
                        value
                    )

                except Exception as exc:
                    with self._error_lock:
                        self._error = exc

                    print(
                        "[renderer] shader load failed:",
                        exc
                    )

            elif command == "resize":

                width, height = value

                self.width = width
                self.height = height

                self.last_width = width
                self.last_height = height

                if self.ctx:
                    self.ctx.viewport = (
                        0,
                        0,
                        width,
                        height
                    )

            elif command == "pause":
                self._paused = True

            elif command == "resume":
                self._paused = False

            elif command == "toggle_pause":
                self._paused = not self._paused

    # =========================================================
    # RENDER LOOP
    # =========================================================

    def _render_loop(self):

        self._paused = False

        frame_interval = (
            1.0 /
            max(
                1,
                self.target_fps
            )
        )

        next_frame = time.perf_counter()

        while not self._stop_event.is_set():

            self._process_commands()

            if not self.window:
                break

            if glfw.window_should_close(
                self.window
            ):
                print(
                    "[renderer] GLFW requested close."
                )

                break

            now = time.perf_counter()

            if not self._paused:

                self._render_frame()

            # -------------------------------------------------
            # Frame limiter
            # -------------------------------------------------

            next_frame += frame_interval

            sleep_time = (
                next_frame
                -
                time.perf_counter()
            )

            if sleep_time > 0:
                time.sleep(
                    sleep_time
                )

            else:
                # Renderer fell behind.
                # Don't accumulate an enormous delay.
                next_frame = (
                    time.perf_counter()
                )

        self.running = False

    # =========================================================
    # FRAME
    # =========================================================

    def _render_frame(self):

        if not self.window:
            return

        if not self.ctx:
            return

        if not self.program:
            return

        if not self.vao:
            return

        glfw.make_context_current(
            self.window
        )

        glfw.poll_events()

        width, height = (
            glfw.get_framebuffer_size(
                self.window
            )
        )

        if width <= 0:
            width = self.last_width

        if height <= 0:
            height = self.last_height

        if (
            width != self.last_width
            or
            height != self.last_height
        ):
            self.last_width = width
            self.last_height = height

        self.ctx.viewport = (
            0,
            0,
            width,
            height
        )

        self._update_uniforms(
            width,
            height
        )

        self.ctx.clear(
            0.0,
            0.0,
            0.0,
            1.0
        )

        self.vao.render(
            mode=moderngl.TRIANGLE_STRIP
        )

        glfw.swap_buffers(
            self.window
        )

        self.frame_count += 1

        # -----------------------------------------------------
        # FPS counter
        # -----------------------------------------------------

        self._fps_frames += 1

        now = time.perf_counter()

        elapsed = (
            now -
            self._fps_time
        )

        if elapsed >= 0.5:

            fps = (
                self._fps_frames /
                elapsed
            )

            with self._state_lock:
                self.fps = fps

            self._fps_frames = 0
            self._fps_time = now

    # =========================================================
    # UNIFORMS
    # =========================================================

    def _set_uniform(
        self,
        name,
        value
    ):
        if self.program is None:
            return

        try:
            self.program[name].value = value

        except (
            KeyError,
            TypeError,
            ValueError,
        ):
            pass

        except Exception:
            pass

    def _update_uniforms(
        self,
        width,
        height
    ):
        elapsed = (
            time.perf_counter()
            -
            self.start_time
        )

        self._set_uniform(
            "iTime",
            float(elapsed)
        )

        self._set_uniform(
            "iResolution",
            (
                float(width),
                float(height),
                1.0
            )
        )

        self._set_uniform(
            "iFrame",
            int(self.frame_count)
        )

        self._set_uniform(
            "u_time",
            float(elapsed)
        )

        self._set_uniform(
            "u_resolution",
            (
                float(width),
                float(height)
            )
        )

        self._set_uniform(
            "u_frame",
            int(self.frame_count)
        )

        self._set_uniform(
            "time",
            float(elapsed)
        )

        self._set_uniform(
            "resolution",
            (
                float(width),
                float(height)
            )
        )

    # =========================================================
    # CLEANUP
    # =========================================================

    def _cleanup_internal(self):

        # This method is ONLY called from the render thread.

        if self.vao:
            try:
                self.vao.release()
            except Exception:
                pass

        self.vao = None

        if self.vbo:
            try:
                self.vbo.release()
            except Exception:
                pass

        self.vbo = None

        if self.program:
            try:
                self.program.release()
            except Exception:
                pass

        self.program = None

        if self.window:

            try:
                glfw.destroy_window(
                    self.window
                )
            except Exception:
                pass

        self.window = None

        try:
            glfw.terminate()
        except Exception:
            pass

        self.ctx = None
        self.desktop_attached = False

    # =========================================================
    # COMPATIBILITY
    # =========================================================

    def create_window(self):
        """
        Compatibility method.

        The new architecture initializes automatically when
        start() is called.
        """

        if not self.is_alive():
            self.start()

        return self.window

    def attach_to_desktop(self):
        """
        Compatibility method.

        Desktop attachment now happens automatically inside
        the renderer thread.
        """

        if not self.is_alive():
            self.start()

        return True

    def render(self):
        """
        Compatibility method.

        Rendering is now continuous on the render thread.
        """

        return None

    def cleanup(self):
        self.stop()

    destroy = cleanup

    def __enter__(self):
        self.start()
        return self

    def __exit__(
        self,
        exc_type,
        exc_value,
        traceback_obj
    ):
        self.stop()


WallpaperRenderer = Renderer
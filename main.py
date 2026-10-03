import json
import os
import tkinter as tk
from tkinter import ttk, messagebox

from renderer import WallpaperRenderer


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
WALLPAPER_DIR = os.path.join(BASE_DIR, "wallpapers")


class NebulaWallApp:
    def __init__(self, root):
        self.root = root

        self.root.title("NebulaWall")
        self.root.geometry("1050x680")
        self.root.minsize(900, 600)
        self.root.configure(bg="#090b10")

        self.wallpapers = []
        self.selected_wallpaper = None
        self.renderer = None
        self.paused = False
        self._closing = False

        # Used to detect folders/files added externally.
        self._wallpaper_signature = None

        self._configure_style()
        self._build_ui()

        self.refresh_wallpapers()

        self.root.after(100, self.start_renderer)
        self.root.after(250, self.update_status)

        # Automatically notice new wallpapers added to the folder.
        self.root.after(2000, self.auto_refresh_check)

        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    # ---------------------------------------------------------
    # STYLE
    # ---------------------------------------------------------

    def _configure_style(self):
        style = ttk.Style()

        try:
            style.theme_use("clam")
        except tk.TclError:
            pass

        style.configure(
            "Treeview",
            background="#10141c",
            foreground="#d7dce5",
            fieldbackground="#10141c",
            rowheight=34,
            borderwidth=0,
            font=("Segoe UI", 10),
        )

        style.configure(
            "Treeview.Heading",
            background="#151a24",
            foreground="#8f9bad",
            relief="flat",
            font=("Segoe UI Semibold", 9),
        )

        style.map(
            "Treeview",
            background=[("selected", "#263b5e")],
            foreground=[("selected", "#ffffff")],
        )

        style.configure(
            "TButton",
            background="#151a24",
            foreground="#e7ebf2",
            borderwidth=0,
            padding=(12, 8),
            font=("Segoe UI Semibold", 9),
        )

        style.map(
            "TButton",
            background=[
                ("active", "#263246"),
                ("pressed", "#1d2738"),
            ],
            foreground=[
                ("active", "#ffffff"),
            ],
        )

    # ---------------------------------------------------------
    # UI
    # ---------------------------------------------------------

    def _build_ui(self):
        # Header
        header = tk.Frame(
            self.root,
            bg="#090b10",
            height=80,
        )
        header.pack(fill="x", padx=28, pady=(22, 8))

        title = tk.Label(
            header,
            text="NEBULA WALL",
            bg="#090b10",
            fg="#ffffff",
            font=("Segoe UI Semibold", 22),
        )
        title.pack(anchor="w")

        subtitle = tk.Label(
            header,
            text="GPU WALLPAPER ENGINE",
            bg="#090b10",
            fg="#657085",
            font=("Segoe UI", 9),
        )
        subtitle.pack(anchor="w", pady=(2, 0))

        # Main content
        content = tk.Frame(
            self.root,
            bg="#090b10",
        )
        content.pack(
            fill="both",
            expand=True,
            padx=28,
            pady=(8, 20),
        )

        # -----------------------------------------------------
        # LEFT: LIBRARY
        # -----------------------------------------------------

        left = tk.Frame(
            content,
            bg="#0d1118",
            highlightthickness=1,
            highlightbackground="#1b2330",
        )
        left.pack(
            side="left",
            fill="both",
            expand=True,
        )

        library_header = tk.Frame(
            left,
            bg="#0d1118",
        )
        library_header.pack(
            fill="x",
            padx=18,
            pady=(16, 10),
        )

        library_title = tk.Label(
            library_header,
            text="Wallpaper Library",
            bg="#0d1118",
            fg="#ffffff",
            font=("Segoe UI Semibold", 12),
        )
        library_title.pack(side="left")

        # NEW: Refresh button
        refresh_button = ttk.Button(
            library_header,
            text="⟳  Refresh Local",
            command=self.refresh_wallpapers,
        )
        refresh_button.pack(
            side="right",
        )

        # Treeview
        tree_frame = tk.Frame(
            left,
            bg="#0d1118",
        )
        tree_frame.pack(
            fill="both",
            expand=True,
            padx=14,
            pady=(0, 14),
        )

        self.tree = ttk.Treeview(
            tree_frame,
            columns=("description",),
            show="tree headings",
            selectmode="browse",
        )

        self.tree.heading(
            "#0",
            text="Wallpaper",
            anchor="w",
        )

        self.tree.heading(
            "description",
            text="Description",
            anchor="w",
        )

        self.tree.column(
            "#0",
            width=210,
            minwidth=160,
            stretch=True,
        )

        self.tree.column(
            "description",
            width=360,
            minwidth=220,
            stretch=True,
        )

        scrollbar = ttk.Scrollbar(
            tree_frame,
            orient="vertical",
            command=self.tree.yview,
        )

        self.tree.configure(
            yscrollcommand=scrollbar.set,
        )

        self.tree.pack(
            side="left",
            fill="both",
            expand=True,
        )

        scrollbar.pack(
            side="right",
            fill="y",
        )

        self.tree.bind(
            "<<TreeviewSelect>>",
            self.on_wallpaper_selected,
        )

        # -----------------------------------------------------
        # RIGHT: CONTROLS
        # -----------------------------------------------------

        right = tk.Frame(
            content,
            bg="#0d1118",
            width=280,
            highlightthickness=1,
            highlightbackground="#1b2330",
        )
        right.pack(
            side="right",
            fill="y",
            padx=(18, 0),
        )

        right.pack_propagate(False)

        controls_title = tk.Label(
            right,
            text="Controls",
            bg="#0d1118",
            fg="#ffffff",
            font=("Segoe UI Semibold", 12),
        )
        controls_title.pack(
            anchor="w",
            padx=20,
            pady=(18, 16),
        )

        # Selected wallpaper
        tk.Label(
            right,
            text="SELECTED WALLPAPER",
            bg="#0d1118",
            fg="#657085",
            font=("Segoe UI Semibold", 8),
        ).pack(
            anchor="w",
            padx=20,
        )

        self.selected_label = tk.Label(
            right,
            text="None",
            bg="#0d1118",
            fg="#dce3ef",
            font=("Segoe UI", 10),
            wraplength=235,
            justify="left",
        )
        self.selected_label.pack(
            anchor="w",
            padx=20,
            pady=(5, 18),
        )

        # Apply
        self.apply_button = ttk.Button(
            right,
            text="Apply Wallpaper",
            command=self.apply_selected,
        )
        self.apply_button.pack(
            fill="x",
            padx=20,
            pady=(0, 8),
        )

        # Pause
        self.pause_button = ttk.Button(
            right,
            text="Pause",
            command=self.toggle_pause,
        )
        self.pause_button.pack(
            fill="x",
            padx=20,
            pady=(0, 20),
        )

        # -----------------------------------------------------
        # STATUS
        # -----------------------------------------------------

        separator = tk.Frame(
            right,
            bg="#1b2330",
            height=1,
        )
        separator.pack(
            fill="x",
            padx=20,
            pady=(0, 18),
        )

        status_title = tk.Label(
            right,
            text="ENGINE STATUS",
            bg="#0d1118",
            fg="#657085",
            font=("Segoe UI Semibold", 8),
        )
        status_title.pack(
            anchor="w",
            padx=20,
        )

        self.status_label = tk.Label(
            right,
            text="Starting...",
            bg="#0d1118",
            fg="#6ee7b7",
            font=("Segoe UI Semibold", 10),
        )
        self.status_label.pack(
            anchor="w",
            padx=20,
            pady=(5, 14),
        )

        self.fps_label = tk.Label(
            right,
            text="FPS: --",
            bg="#0d1118",
            fg="#aab3c2",
            font=("Segoe UI", 9),
        )
        self.fps_label.pack(
            anchor="w",
            padx=20,
        )

        self.library_count_label = tk.Label(
            right,
            text="Wallpapers: 0",
            bg="#0d1118",
            fg="#aab3c2",
            font=("Segoe UI", 9),
        )
        self.library_count_label.pack(
            anchor="w",
            padx=20,
            pady=(4, 0),
        )

        self.folder_label = tk.Label(
            right,
            text="Folder: wallpapers/",
            bg="#0d1118",
            fg="#566174",
            font=("Segoe UI", 8),
        )
        self.folder_label.pack(
            anchor="w",
            padx=20,
            pady=(18, 0),
        )

    # ---------------------------------------------------------
    # WALLPAPER DISCOVERY
    # ---------------------------------------------------------

    def _calculate_wallpaper_signature(self):
        """
        Creates a lightweight signature of the wallpapers folder.

        This lets us detect a newly added wallpaper without
        constantly rebuilding the Treeview.
        """

        if not os.path.isdir(WALLPAPER_DIR):
            return ()

        entries = []

        try:
            for folder_name in sorted(os.listdir(WALLPAPER_DIR)):
                folder_path = os.path.join(
                    WALLPAPER_DIR,
                    folder_name,
                )

                if not os.path.isdir(folder_path):
                    continue

                try:
                    folder_mtime = os.path.getmtime(folder_path)
                except OSError:
                    folder_mtime = 0

                entries.append(
                    (
                        folder_name,
                        folder_mtime,
                    )
                )

        except OSError:
            return ()

        return tuple(entries)

    def refresh_wallpapers(self):
        """
        Rescan wallpapers/ and rebuild the library.

        The current wallpaper is preserved if it still exists.
        """

        previous_path = None

        if self.selected_wallpaper:
            previous_path = self.selected_wallpaper.get("path")

        os.makedirs(
            WALLPAPER_DIR,
            exist_ok=True,
        )

        discovered = []

        try:
            folder_names = sorted(
                os.listdir(WALLPAPER_DIR),
                key=str.lower,
            )
        except OSError as exc:
            self.status_label.config(
                text="Library error",
                fg="#f87171",
            )
            print(
                "[library] Failed to scan wallpapers:",
                exc,
            )
            return

        for folder_name in folder_names:
            folder_path = os.path.join(
                WALLPAPER_DIR,
                folder_name,
            )

            if not os.path.isdir(folder_path):
                continue

            metadata_path = os.path.join(
                folder_path,
                "wallpaper.json",
            )

            if not os.path.isfile(metadata_path):
                continue

            try:
                with open(
                    metadata_path,
                    "r",
                    encoding="utf-8",
                ) as f:
                    metadata = json.load(f)

            except Exception as exc:
                print(
                    f"[library] Invalid {metadata_path}: {exc}"
                )
                continue

            shader_name = metadata.get("shader")

            if not shader_name:
                continue

            shader_path = os.path.join(
                folder_path,
                shader_name,
            )

            if not os.path.isfile(shader_path):
                print(
                    f"[library] Missing shader: {shader_path}"
                )
                continue

            wallpaper = {
                "name": metadata.get(
                    "name",
                    folder_name,
                ),
                "description": metadata.get(
                    "description",
                    "No description",
                ),
                "folder": folder_name,
                "path": folder_path,
                "shader": shader_path,
                "metadata": metadata,
            }

            discovered.append(wallpaper)

        self.wallpapers = discovered

        # Rebuild Treeview.
        for item in self.tree.get_children():
            self.tree.delete(item)

        item_to_select = None

        for index, wallpaper in enumerate(
            self.wallpapers
        ):
            item_id = self.tree.insert(
                "",
                "end",
                text=wallpaper["name"],
                values=(
                    wallpaper["description"],
                ),
            )

            # Store folder path directly on Treeview item.
            self.tree.item(
                item_id,
                tags=(wallpaper["path"],),
            )

            if (
                previous_path
                and wallpaper["path"] == previous_path
            ):
                item_to_select = item_id

        # Restore previous selection.
        if item_to_select:
            self.tree.selection_set(
                item_to_select
            )
            self.tree.focus(
                item_to_select
            )

        elif self.wallpapers:
            first_item = self.tree.get_children()[0]

            self.tree.selection_set(
                first_item
            )
            self.tree.focus(
                first_item
            )

        else:
            self.selected_wallpaper = None
            self.selected_label.config(
                text="No wallpapers found"
            )

        self.library_count_label.config(
            text=f"Wallpapers: {len(self.wallpapers)}"
        )

        self._wallpaper_signature = (
            self._calculate_wallpaper_signature()
        )

        print(
            f"[library] Refreshed: "
            f"{len(self.wallpapers)} wallpaper(s)"
        )

    # ---------------------------------------------------------
    # AUTOMATIC LOCAL FOLDER DETECTION
    # ---------------------------------------------------------

    def auto_refresh_check(self):
        """
        Periodically checks whether wallpapers/ changed.

        This means you can create:

            wallpapers/My_New_Wallpaper/

        while NebulaWall is running and it will appear
        automatically without restarting the application.
        """

        if self._closing:
            return

        try:
            new_signature = (
                self._calculate_wallpaper_signature()
            )

            if (
                self._wallpaper_signature is not None
                and new_signature != self._wallpaper_signature
            ):
                print(
                    "[library] Change detected - refreshing..."
                )

                self.refresh_wallpapers()

        except Exception as exc:
            print(
                "[library] Auto-refresh error:",
                exc,
            )

        self.root.after(
            2000,
            self.auto_refresh_check,
        )

    # ---------------------------------------------------------
    # RENDERER
    # ---------------------------------------------------------

    def start_renderer(self):
        if self._closing:
            return

        try:
            width = self.root.winfo_screenwidth()
            height = self.root.winfo_screenheight()

            self.renderer = WallpaperRenderer(
                width=width,
                height=height,
                shader_path=None,
                target_fps=60,
            )

            self.renderer.start()

            self.status_label.config(
                text="Renderer running",
                fg="#6ee7b7",
            )

            # Apply selected wallpaper.
            if self.selected_wallpaper:
                self.apply_selected()

        except Exception as exc:
            print("[renderer] Startup error:", exc)

            self.status_label.config(
                text="Renderer error",
                fg="#f87171",
            )

            messagebox.showerror(
                "NebulaWall",
                f"Could not start renderer:\n\n{exc}",
            )

    # ---------------------------------------------------------
    # SELECTION
    # ---------------------------------------------------------

    def on_wallpaper_selected(self, event=None):
        selection = self.tree.selection()

        if not selection:
            return

        item_id = selection[0]

        wallpaper_path = None

        tags = self.tree.item(
            item_id,
            "tags",
        )

        if tags:
            wallpaper_path = tags[0]

        if not wallpaper_path:
            return

        for wallpaper in self.wallpapers:
            if wallpaper["path"] == wallpaper_path:
                self.selected_wallpaper = wallpaper

                self.selected_label.config(
                    text=wallpaper["name"]
                )

                break

    def select_wallpaper(self, wallpaper):
        if not wallpaper:
            return

        self.selected_wallpaper = wallpaper

        self.selected_label.config(
            text=wallpaper["name"]
        )

        # Find matching Treeview item.
        for item_id in self.tree.get_children():
            tags = self.tree.item(
                item_id,
                "tags",
            )

            if (
                tags
                and tags[0] == wallpaper["path"]
            ):
                self.tree.selection_set(
                    item_id
                )
                self.tree.focus(
                    item_id
                )
                break

    # ---------------------------------------------------------
    # APPLY
    # ---------------------------------------------------------

    def apply_selected(self):
        if not self.selected_wallpaper:
            return

        if not self.renderer:
            return

        shader_path = self.selected_wallpaper["shader"]

        print(
            "[app] Applying:",
            self.selected_wallpaper["name"],
        )

        try:
            self.renderer.set_wallpaper(
                shader_path
            )

            self.status_label.config(
                text="Wallpaper applied",
                fg="#6ee7b7",
            )

        except Exception as exc:
            print(
                "[renderer] Apply error:",
                exc,
            )

            self.status_label.config(
                text="Shader error",
                fg="#f87171",
            )

    # ---------------------------------------------------------
    # PAUSE
    # ---------------------------------------------------------

    def toggle_pause(self):
        if not self.renderer:
            return

        try:
            if self.paused:
                self.renderer.resume()

                self.paused = False

                self.pause_button.config(
                    text="Pause"
                )

            else:
                self.renderer.pause()

                self.paused = True

                self.pause_button.config(
                    text="Resume"
                )

        except Exception as exc:
            print(
                "[renderer] Pause error:",
                exc,
            )

    # ---------------------------------------------------------
    # STATUS
    # ---------------------------------------------------------

    def update_status(self):
        if self._closing:
            return

        try:
            if self.renderer:
                fps = self.renderer.get_fps()

                self.fps_label.config(
                    text=f"FPS: {fps:.0f}"
                )

                if self.renderer.is_alive():
                    if self.paused:
                        self.status_label.config(
                            text="Paused",
                            fg="#fbbf24",
                        )
                    else:
                        self.status_label.config(
                            text="Rendering",
                            fg="#6ee7b7",
                        )

                error = self.renderer.get_error()

                if error:
                    print(
                        "[renderer]",
                        error,
                    )

                    self.status_label.config(
                        text="Renderer error",
                        fg="#f87171",
                    )

        except Exception as exc:
            print(
                "[app] Status update error:",
                exc,
            )

        self.root.after(
            250,
            self.update_status,
        )

    # ---------------------------------------------------------
    # CLOSE
    # ---------------------------------------------------------

    def on_close(self):
        if self._closing:
            return

        self._closing = True

        try:
            if self.renderer:
                self.renderer.stop()

        except Exception as exc:
            print(
                "[renderer] Shutdown error:",
                exc,
            )

        self.root.destroy()


def main():
    root = tk.Tk()

    app = NebulaWallApp(root)

    root.mainloop()


if __name__ == "__main__":
    main()
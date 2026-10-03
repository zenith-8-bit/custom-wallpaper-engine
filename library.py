import json
from pathlib import Path

class Wallpaper:
    def __init__(self, name, description, category, author, shader, folder):
        self.name = name; self.description = description; self.category = category
        self.author = author; self.shader = shader; self.folder = folder
    @property
    def shader_path(self): return str(Path(self.folder) / self.shader)
    def __repr__(self): return f"Wallpaper({self.name!r})"

def discover_wallpapers(root="wallpapers"):
    root = Path(root); results = []
    if not root.exists(): return results
    for folder in sorted(root.iterdir()):
        if not folder.is_dir(): continue
        meta = folder / "wallpaper.json"
        if not meta.exists(): continue
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
            shader = data.get("shader")
            if not shader or not (folder / shader).exists(): continue
            results.append(Wallpaper(data.get("name", folder.name), data.get("description", ""), data.get("category", "Other"), data.get("author", "NebulaWall"), shader, str(folder)))
        except Exception as exc: print("[library] failed to load", meta, ":", exc)
    return results

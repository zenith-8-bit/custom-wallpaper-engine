import ctypes
from ctypes import wintypes

user32 = ctypes.windll.user32

WM_SPAWN_WORKER = 0x052C

GWL_STYLE = -16
GWL_EXSTYLE = -20

WS_POPUP = 0x80000000
WS_CAPTION = 0x00C00000
WS_THICKFRAME = 0x00040000
WS_SYSMENU = 0x00080000
WS_MINIMIZEBOX = 0x00020000
WS_MAXIMIZEBOX = 0x00010000

WS_EX_TOOLWINDOW = 0x00000080
WS_EX_NOACTIVATE = 0x08000000

SW_SHOW = 5

SWP_NOACTIVATE = 0x0010
SWP_SHOWWINDOW = 0x0040
SWP_FRAMECHANGED = 0x0020
SWP_NOSENDCHANGING = 0x0400

HWND_BOTTOM = 1

MONITOR_DEFAULTTONEAREST = 2

SM_XVIRTUALSCREEN = 76
SM_YVIRTUALSCREEN = 77
SM_CXVIRTUALSCREEN = 78
SM_CYVIRTUALSCREEN = 79


class MONITORINFO(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.DWORD),
        ("rcMonitor", wintypes.RECT),
        ("rcWork", wintypes.RECT),
        ("dwFlags", wintypes.DWORD),
    ]


def class_name(hwnd):
    if not hwnd:
        return ""

    buffer = ctypes.create_unicode_buffer(256)

    user32.GetClassNameW(
        hwnd,
        buffer,
        256,
    )

    return buffer.value


def window_text(hwnd):
    if not hwnd:
        return ""

    buffer = ctypes.create_unicode_buffer(512)

    user32.GetWindowTextW(
        hwnd,
        buffer,
        512,
    )

    return buffer.value


def enum_windows():
    result = []

    CALLBACK = ctypes.WINFUNCTYPE(
        wintypes.BOOL,
        wintypes.HWND,
        wintypes.LPARAM,
    )

    def callback(hwnd, _):
        result.append(hwnd)
        return True

    callback_ref = CALLBACK(callback)

    user32.EnumWindows(
        callback_ref,
        0,
    )

    return result


def find_progman():
    hwnd = user32.FindWindowW(
        "Progman",
        "Program Manager",
    )

    if not hwnd:
        hwnd = user32.FindWindowW(
            "Progman",
            None,
        )

    return hwnd


def spawn_worker_windows():
    progman = find_progman()

    if not progman:
        raise RuntimeError(
            "Could not find Windows Progman desktop."
        )

    # Classic WorkerW creation.
    user32.SendMessageTimeoutW(
        progman,
        WM_SPAWN_WORKER,
        0,
        0,
        0x0002,
        1000,
        None,
    )

    # Newer Windows layouts.
    user32.SendMessageTimeoutW(
        progman,
        WM_SPAWN_WORKER,
        0xD,
        1,
        0x0002,
        1000,
        None,
    )

    return progman


def find_desktop_shell():
    """
    Find the SHELLDLL_DefView that owns the desktop icons.
    """

    progman = find_progman()

    if progman:
        shell = user32.FindWindowExW(
            progman,
            0,
            "SHELLDLL_DefView",
            None,
        )

        if shell:
            return shell

    for hwnd in enum_windows():

        if class_name(hwnd) != "WorkerW":
            continue

        shell = user32.FindWindowExW(
            hwnd,
            0,
            "SHELLDLL_DefView",
            None,
        )

        if shell:
            return shell

    return 0


def find_icon_worker():
    """
    Find the WorkerW containing the desktop icon view.
    """

    shell = find_desktop_shell()

    if not shell:
        return 0

    parent = user32.GetParent(shell)

    if parent:
        print(
            "[desktop] icon WorkerW:",
            parent,
        )

        return parent

    return 0


def find_empty_worker():
    """
    Find a WorkerW that does NOT contain SHELLDLL_DefView.
    """

    spawn_worker_windows()

    for hwnd in enum_windows():

        if class_name(hwnd) != "WorkerW":
            continue

        shell = user32.FindWindowExW(
            hwnd,
            0,
            "SHELLDLL_DefView",
            None,
        )

        if not shell:
            return hwnd

    return 0


def find_workerw():
    """
    Compatibility wrapper.

    Prefer the empty WorkerW but retain the icon WorkerW separately
    because the renderer will use Z-order rather than SetParent.
    """

    empty = find_empty_worker()

    if empty:
        print(
            "[desktop] empty WorkerW:",
            empty,
        )

        return empty

    icon_worker = find_icon_worker()

    if icon_worker:
        print(
            "[desktop] icon WorkerW:",
            icon_worker,
        )

        return icon_worker

    progman = find_progman()

    print(
        "[desktop] fallback Progman:",
        progman,
    )

    return progman


def prepare_window(hwnd, width, height):
    """
    Prepare the GLFW/WGL window as a borderless desktop wallpaper.

    IMPORTANT:
    We deliberately DO NOT call SetParent here.

    Reparenting an already-created GLFW/WGL window can invalidate the
    window/DC relationship used by GLFW's WGL context. Instead, the
    renderer remains a normal top-level window and is placed behind
    the desktop icon WorkerW using SetWindowPos.
    """

    if not hwnd:
        raise RuntimeError(
            "Invalid renderer HWND."
        )

    spawn_worker_windows()

    icon_worker = find_icon_worker()

    empty_worker = find_empty_worker()

    if not icon_worker:
        raise RuntimeError(
            "Could not find the Windows desktop icon WorkerW."
        )

    print(
        "[desktop] renderer HWND:",
        hwnd,
    )

    print(
        "[desktop] icon WorkerW:",
        icon_worker,
    )

    print(
        "[desktop] empty WorkerW:",
        empty_worker,
    )

    print(
        "[desktop] icon WorkerW class:",
        class_name(icon_worker),
    )

    # --------------------------------------------------------------
    # Keep GLFW window as TOP-LEVEL.
    #
    # Do NOT set WS_CHILD.
    # Do NOT call SetParent.
    # --------------------------------------------------------------

    style = user32.GetWindowLongW(
        hwnd,
        GWL_STYLE,
    )

    style |= WS_POPUP

    style &= ~WS_CAPTION
    style &= ~WS_THICKFRAME
    style &= ~WS_SYSMENU
    style &= ~WS_MINIMIZEBOX
    style &= ~WS_MAXIMIZEBOX

    user32.SetWindowLongW(
        hwnd,
        GWL_STYLE,
        style,
    )

    exstyle = user32.GetWindowLongW(
        hwnd,
        GWL_EXSTYLE,
    )

    exstyle |= WS_EX_TOOLWINDOW
    exstyle |= WS_EX_NOACTIVATE

    user32.SetWindowLongW(
        hwnd,
        GWL_EXSTYLE,
        exstyle,
    )

    # --------------------------------------------------------------
    # Determine desktop dimensions.
    # --------------------------------------------------------------

    monitor = user32.MonitorFromWindow(
        icon_worker,
        MONITOR_DEFAULTTONEAREST,
    )

    monitor_info = MONITORINFO()

    monitor_info.cbSize = ctypes.sizeof(
        MONITORINFO
    )

    if monitor and user32.GetMonitorInfoW(
        monitor,
        ctypes.byref(monitor_info),
    ):
        rect = monitor_info.rcMonitor

        x = rect.left
        y = rect.top

        width = (
            rect.right -
            rect.left
        )

        height = (
            rect.bottom -
            rect.top
        )

    else:
        x = 0
        y = 0

        width = int(width)
        height = int(height)

    # --------------------------------------------------------------
    # Z-order.
    #
    # hWndInsertAfter specifies the window that should precede the
    # renderer in Z-order.
    #
    # Putting the renderer immediately AFTER the icon WorkerW puts
    # it behind that desktop layer while keeping the renderer as a
    # normal GLFW/WGL top-level window.
    # --------------------------------------------------------------

    # Put the wallpaper at the bottom of the normal window Z-order.
    # This keeps the Windows taskbar and applications above it.
    result = user32.SetWindowPos(
        hwnd,
        HWND_BOTTOM,
        x,
        y,
        width,
        height,
        SWP_NOACTIVATE |
        SWP_SHOWWINDOW |
        SWP_FRAMECHANGED |
        SWP_NOSENDCHANGING,
    )

    if not result:
        error = ctypes.get_last_error()

        raise ctypes.WinError(
            error
        )

    user32.ShowWindow(
        hwnd,
        SW_SHOW,
    )

    user32.UpdateWindow(
        hwnd,
    )

    print(
        "[desktop] wallpaper positioned behind icon layer"
    )

    print(
        "[desktop] wallpaper size:",
        width,
        "x",
        height,
    )

    print(
        "[desktop] z-order anchor:",
        icon_worker,
    )

    return icon_worker


def detach_window(hwnd):
    """
    Restore a renderer window without changing its parent.
    """

    if not hwnd:
        return

    user32.ShowWindow(
        hwnd,
        0,
    )


def is_fullscreen_app(excluded_hwnds=None):
    excluded_hwnds = set(
        excluded_hwnds or []
    )

    try:
        hwnd = user32.GetForegroundWindow()

        if not hwnd:
            return False

        if hwnd in excluded_hwnds:
            return False

        cls = class_name(hwnd)

        ignored = {
            "Progman",
            "WorkerW",
            "Shell_TrayWnd",
            "Shell_SecondaryTrayWnd",
        }

        if cls in ignored:
            return False

        rect = wintypes.RECT()

        if not user32.GetWindowRect(
            hwnd,
            ctypes.byref(rect),
        ):
            return False

        monitor = user32.MonitorFromWindow(
            hwnd,
            MONITOR_DEFAULTTONEAREST,
        )

        if not monitor:
            return False

        info = MONITORINFO()

        info.cbSize = ctypes.sizeof(
            MONITORINFO
        )

        if not user32.GetMonitorInfoW(
            monitor,
            ctypes.byref(info),
        ):
            return False

        monitor_rect = info.rcMonitor

        monitor_width = (
            monitor_rect.right -
            monitor_rect.left
        )

        monitor_height = (
            monitor_rect.bottom -
            monitor_rect.top
        )

        window_width = (
            rect.right -
            rect.left
        )

        window_height = (
            rect.bottom -
            rect.top
        )

        return (
            window_width >= monitor_width * 0.98
            and
            window_height >= monitor_height * 0.98
            and
            rect.left <= monitor_rect.left + 2
            and
            rect.top <= monitor_rect.top + 2
        )

    except Exception as exc:
        print(
            "[desktop] fullscreen detection error:",
            exc,
        )

        return False


fullscreen_app = is_fullscreen_app
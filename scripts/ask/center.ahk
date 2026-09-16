; Win+Shift+Z: center all windows, same wide size, each on its own monitor
#+z:: {
    widthPct := 0.50   ; fraction of the monitor's work-area width
    heightPct := 0.50  ; fraction of the height (lower = wider-looking rectangle)

    for hwnd in WinGetList() {
        if !DllCall("IsWindowVisible", "ptr", hwnd) || WinGetTitle(hwnd) = ""
            continue
        if (WinGetExStyle(hwnd) & 0x80)
            continue
        if WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$"
            continue
        cloaked := 0
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "int", 14, "int*", &cloaked, "int", 4)
        if cloaked || WinGetMinMax(hwnd) = -1
            continue

        WinGetPos &x, &y, &w, &h, hwnd
        if !MonitorAt(x + w // 2, y + h // 2, &L, &T, &R, &B)
            continue

        if (WinGetMinMax(hwnd) = 1)
            WinRestore hwnd
        nw := Round((R - L) * widthPct), nh := Round((B - T) * heightPct)
        WinMove L + (R - L - nw) // 2, T + (B - T - nh) // 2, nw, nh, hwnd
    }
}

; Returns the work area of the monitor containing point (px, py)
MonitorAt(px, py, &L, &T, &R, &B) {
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &L, &T, &R, &B)
        if (px >= L && px < R && py >= T && py < B)
            return true
    }
    return false
}
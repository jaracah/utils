#Requires AutoHotkey v2.0
#SingleInstance Force
DllCall("SetThreadDpiAwarenessContext", "ptr", -4)

#+d:: {  ; Win+Shift+D: debug dump
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    s := "Mouse: " mx ", " my "`n`n"
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &L, &T, &R, &B)
        s .= "Monitor " A_Index ": " L "," T " to " R "," B "`n"
    }
    MsgBox s
}
#+m:: {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    tL := tT := tR := tB := 0
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &L, &T, &R, &B)
        if (mx >= L && mx < R && my >= T && my < B)
            tL := L, tT := T, tR := R, tB := B
    }
    if (tR = 0 && tL = 0) {
        MsgBox "No target monitor found"
        return
    }
    log := "Target: " tL "," tT " to " tR "," tB "`n`n"

    for hwnd in WinGetList() {
        title := WinGetTitle(hwnd)
        if !DllCall("IsWindowVisible", "ptr", hwnd) || title = ""
            continue
        if (WinGetExStyle(hwnd) & 0x80)
            continue
        if WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$"
            continue
        cloaked := 0
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "int", 14, "int*", &cloaked, "int", 4)
        if cloaked
            continue
        state := WinGetMinMax(hwnd)
        if (state = -1) {
            log .= "SKIP minimized: " SubStr(title, 1, 40) "`n"
            continue
        }
        WinGetPos &x, &y, &w, &h, hwnd
        cx := x + w // 2, cy := y + h // 2
        if (cx >= tL && cx < tR && cy >= tT && cy < tB) {
            log .= "SKIP on target: " SubStr(title, 1, 40) "`n"
            continue
        }
        if (state = 1)
            WinRestore hwnd
        nw := Min(w, tR - tL), nh := Min(h, tB - tT)
        nx := tL + (tR - tL - nw) // 2, ny := tT + (tB - tT - nh) // 2
        WinMove nx, ny, nw, nh, hwnd
        if (state = 1)
            WinMaximize hwnd
        WinGetPos &ax, &ay, &aw, &ah, hwnd
        log .= "MOVED " SubStr(title, 1, 40) " from " x "," y " to " nx "," ny " (actual " ax "," ay " " aw "x" ah ")`n"
    }
}
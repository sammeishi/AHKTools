; ============================================================
;  Countdown Timer  —  AutoHotkey v2.0
;  快捷键说明：
;    Alt+1~5  开始/累加对应分钟倒计时（1秒内连按可叠加）
;    Alt+0    取消当前倒计时
;    Alt+-    当前倒计时 -1 秒
;    Alt++    当前倒计时 +1 秒
;    点击倒计时框  终止倒计时
;    点击提醒弹窗  关闭弹窗
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force


; 检查并设置自启动
SetAutoStart()

SetAutoStart() {
	lnkPath := A_Startup "\" A_ScriptName ".lnk"
	scriptPath := A_ScriptFullPath

	; 已存在且路径一致则跳过
	if FileExist(lnkPath) {
		shell := ComObject("WScript.Shell")
		shortcut := shell.CreateShortcut(lnkPath)
		if (shortcut.TargetPath = scriptPath)
			return
	}

	; 创建或更新快捷方式
	shell := ComObject("WScript.Shell")
	shortcut := shell.CreateShortcut(lnkPath)
	shortcut.TargetPath := scriptPath
	shortcut.WorkingDirectory := A_ScriptDir
	shortcut.Save()
}


VERSION := "1.12"

; ---------- 全局状态 ----------
global g_remainSec   := 0
global g_running     := false
global g_lastKeyTime := 0
global g_timerGui    := ""
global g_label       := ""
global g_guiHwnd     := 0
global g_showOpt     := ""
global g_alertGui    := ""
global g_alertHwnd   := 0

; ---------- 初始化 ----------
CreateTimerGui()
CreateAlertGui()

; ============================================================
;  创建倒计时显示 Gui（左下角透明浮层）
; ============================================================
CreateTimerGui() {
    global g_timerGui, g_label, g_guiHwnd, g_showOpt

    g_timerGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "CountdownTimer")
    g_timerGui.BackColor := "000001"

    g_timerGui.SetFont("s28 bold cFF8C00 q5", "Consolas")
    g_label := g_timerGui.AddText("x10 y0 w260 h80", "00:00")

    g_guiHwnd := g_timerGui.Hwnd
    WinSetTransColor("000001", g_timerGui)

    screenH   := SysGet(17)
    posY      := screenH - 45
    g_showOpt := "NoActivate x0 y" . posY . " w150 h45"

    OnMessage(0x0201, OnWMLButtonDown)
}

; ============================================================
;  创建提醒弹窗 Gui（点击才消失）
; ============================================================
CreateAlertGui() {
    global g_alertGui, g_alertHwnd

    g_alertGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "AlertGui")
    g_alertGui.BackColor := "1C1C1C"

    g_alertGui.SetFont("s22 bold cFF8C00", "Consolas")
    g_alertGui.AddText("x0 y18 w300 h40 Center", "⏰ 倒计时结束！")

    g_alertGui.SetFont("s11 cAAAAAA", "Consolas")
    g_alertGui.AddText("x0 y68 w300 h24 Center", "单击任意处关闭")

    g_alertHwnd := g_alertGui.Hwnd
}

; ============================================================
;  WM_LBUTTONDOWN 统一回调
; ============================================================
OnWMLButtonDown(wParam, lParam, msg, hwnd) {
    global g_guiHwnd, g_running, g_alertHwnd, g_alertGui

    ; 点击倒计时框 → 终止倒计时
    if (hwnd = g_guiHwnd || DllCall("GetParent", "Ptr", hwnd, "Ptr") = g_guiHwnd) {
        if g_running
            StopCountdown()
        return
    }

    ; 点击提醒弹窗 → 关闭弹窗
    if (hwnd = g_alertHwnd || DllCall("GetParent", "Ptr", hwnd, "Ptr") = g_alertHwnd) {
        g_alertGui.Hide()
        return
    }
}

; ============================================================
;  显示提醒弹窗（屏幕居中）
; ============================================================
ShowAlert() {
    global g_alertGui
    screenW := SysGet(16)
    screenH := SysGet(17)
    x := (screenW - 300) // 2
    y := (screenH - 110) // 2
    g_alertGui.Show("NoActivate w300 h110 x" . x . " y" . y)
	 WinSetAlwaysOnTop(1, g_alertGui)
}

; ============================================================
;  格式化 MM:SS
; ============================================================
FormatRemain(sec) {
    m := sec // 60
    s := Mod(sec, 60)
    return Format("{:02d}:{:02d}", m, s)
}

; ============================================================
;  启动/叠加倒计时
; ============================================================
StartCountdown(addSec) {
    global g_remainSec, g_running, g_timerGui, g_label, g_showOpt

    g_remainSec += addSec

    if !g_running {
        g_running := true
        g_timerGui.Show(g_showOpt)
        SetTimer(TickDown, 1000)
    }
    g_label.Value := FormatRemain(g_remainSec)
}

; ============================================================
;  每秒 Tick
; ============================================================
TickDown() {
    global g_remainSec, g_label

    g_remainSec--
    if g_remainSec <= 0 {
        g_remainSec := 0
        StopCountdown()
        SoundPlay(A_ScriptDir . "\alarm.mp3")
        ShowAlert()
        return
    }
    g_label.Value := FormatRemain(g_remainSec)
}

; ============================================================
;  停止并隐藏倒计时框
; ============================================================
StopCountdown() {
    global g_remainSec, g_running, g_timerGui

    SetTimer(TickDown, 0)
    g_running   := false
    g_remainSec := 0
    g_timerGui.Hide()
}

; ============================================================
;  处理数字键
; ============================================================
HandleNumKey(minutes) {
    global g_lastKeyTime, g_remainSec, g_running

    now := A_TickCount
    if (now - g_lastKeyTime <= 1000) {
        StartCountdown(minutes * 60)
    } else {
        if g_running {
            SetTimer(TickDown, 0)
            g_running := false
        }
        g_remainSec := 0
        StartCountdown(minutes * 60)
    }
    g_lastKeyTime := now
}

; ============================================================
;  快捷键
; ============================================================
!1:: HandleNumKey(1)
!2:: HandleNumKey(2)
!3:: HandleNumKey(3)
!4:: HandleNumKey(4)
!5:: HandleNumKey(5)

!0:: {
    global g_running
    if g_running
        StopCountdown()
}

!-:: {
    global g_remainSec, g_running, g_label
    if !g_running
        return
    g_remainSec := Max(1, g_remainSec - 1)
    g_label.Value := FormatRemain(g_remainSec)
}

!=:: {
    global g_remainSec, g_running, g_label
    if !g_running
        return
    g_remainSec++
    g_label.Value := FormatRemain(g_remainSec)
}

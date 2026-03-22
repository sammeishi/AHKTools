#SingleInstance force
#Requires AutoHotkey v2.0


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


; 每隔N秒beep一次防止音箱休眠

global beepCount := 0
global interval := 60 * 10 ; 间隔秒数
global nextBeepTime := 0

; 设置定时器（10秒后首次执行，之后每10秒执行）
SetTimer BeepTask, interval * 1000

; 执行蜂鸣任务
BeepTask() {
    global
    SoundBeep 37, 100
    beepCount += 1
    ; 更新下一次蜂鸣时间
    nextBeepTime := A_Now + interval
}

; 计算初始下一次蜂鸣时间
nextBeepTime := A_Now + interval

; 创建热键 Ctrl+Alt+B
^!b:: {
    global
    ; 格式化下一次蜂鸣时间
    formattedTime := FormatTime(nextBeepTime, "HH:mm:ss")
    
    ; 创建GUI窗口
    myGui := Gui()
    myGui.Title := "蜂鸣信息"
    myGui.SetFont("s10", "Arial")
    
    ; 添加信息文本
    myGui.Add("Text", "w200", "蜂鸣次数: " . beepCount)
    myGui.Add("Text", "w200", "间隔秒数: " . interval)
    myGui.Add("Text", "w200", "下一次蜂鸣: " . formattedTime)
    
    ; 添加确定按钮
    myGui.Add("Button", "w80 Default", "确定").OnEvent("Click", (*) => myGui.Destroy())
    
    ; 显示窗口
    myGui.Show()
}
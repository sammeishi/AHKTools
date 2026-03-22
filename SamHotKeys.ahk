#SingleInstance force

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



; 睡眠
#Space::
{
    DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
}
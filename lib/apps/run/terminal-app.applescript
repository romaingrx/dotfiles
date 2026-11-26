-- Runs a shell command in a new Terminal.app window.
-- Usage: osascript terminal-app.applescript <working directory> <command>
on run {cwd, cmd}
	tell application "Terminal"
		do script "cd " & quoted form of cwd & " && " & cmd
		activate
	end tell
end run

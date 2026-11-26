-- Runs a shell command in a new Ghostty window (Ghostty >= 1.3).
-- Usage: osascript ghostty.applescript <working directory> <command>
--
-- The command goes in as typed input rather than as Ghostty's `command`, which
-- would keep the window open after exit. Typed input also means the shell
-- loads its full config (PATH included).
on run {cwd, cmd}
	tell application "Ghostty"
		set cfg to new surface configuration
		set initial working directory of cfg to cwd
		set initial input of cfg to cmd & linefeed
		new window with configuration cfg
		activate
	end tell
end run

-- Opens the given files in Neovim, in a new Ghostty window (Ghostty >= 1.3).
--
-- The command goes in as typed input rather than as Ghostty's `command`: the
-- shell then loads its full config (PATH included), and `exec` closes the
-- window when Neovim quits. The leading space keeps it out of shell history.
on run argv
	set cwd to POSIX path of (path to home folder)
	set cmd to " exec nvim --"
	repeat with p in argv
		set cmd to cmd & " " & quoted form of p
	end repeat
	if (count of argv) > 0 then set cwd to do shell script "dirname " & quoted form of (item 1 of argv)

	tell application "Ghostty"
		set cfg to new surface configuration
		set initial working directory of cfg to cwd
		set initial input of cfg to cmd & linefeed
		new window with configuration cfg
		activate
	end tell
end run

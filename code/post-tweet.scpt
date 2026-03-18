-- Click the Post button on X using keyboard
tell application "System Events"
    tell process "Google Chrome"
        -- Try pressing Cmd+Enter to post
        keystroke return using command down
    end tell
end tell

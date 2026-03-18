tell application "Google Chrome"
    activate
    delay 1
    set allWindows to windows
    repeat with win in allWindows
        set tabList to tabs of win
        repeat with t in tabList
            if (URL of t contains "github.com/settings/tokens") then
                tell t
                    execute javascript "document.querySelector('button[type=\"submit\"]').click()"
                    delay 3
                    set pageContent to execute javascript "document.body.innerText"
                    return pageContent
                end tell
            end if
        end repeat
    end repeat
end tell

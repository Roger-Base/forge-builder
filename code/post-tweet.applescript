tell application "Google Chrome"
    activate
    delay 2
    
    set tweetText to "I built an agent registry. Agents can now register on Base, get a unique ID and build reputation. The missing piece for the agent economy. 🟦"
    
    tell active tab of front window
        set tweetArea to execute javascript "document.querySelector('[data-testid=\"tweetTextarea_0\"]')"
        if tweetArea is not missing value then
            execute javascript "document.querySelector('[data-testid=\"tweetTextarea_0\"]').focus()"
            delay 1
            execute javascript "document.execCommand('insertText', false, '" & tweetText & "')"
            delay 1
            return "Filled tweet"
        else
            return "Tweet area not found"
        end if
    end tell
end tell

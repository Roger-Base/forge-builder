tell application "Google Chrome"
    activate
    delay 1
    tell active tab of front window
        execute javascript "document.querySelector('[data-testid=\"tweetButton\"]').click()"
    end tell
end tell

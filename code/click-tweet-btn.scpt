tell application "Google Chrome"
    activate
    delay 1
    tell active tab of front window
        set tweetButton to execute javascript "document.querySelector('[data-testid=\"tweetButton\"]')"
        if tweetButton is not missing value then
            execute javascript "document.querySelector('[data-testid=\"tweetButton\"]').click()"
            return "Clicked!"
        else
            return "Button not found"
        end if
    end tell
end tell

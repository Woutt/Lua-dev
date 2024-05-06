loadstring(game:HttpGet("https://raw.githubusercontent.com/NotDSF/HttpSpy/main/init.lua"))({
    AutoDecode = true, -- Automatically decodes JSON
    Highlighting = true, -- Highlights the output
    SaveLogs = true, -- Save logs to a text file
    CLICommands = true, -- Allows you to input commands into the console
    ShowResponse = true, -- Shows the request response
    API = true, -- Enables the script API
    BlockedURLs = {} -- Blocked urls
});
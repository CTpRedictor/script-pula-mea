-- BloxStrike Domination - Loader
-- Paste this into your executor to load the script from GitHub.
-- Replace YOUR_GITHUB_USERNAME and REPO_NAME below with your actual values.

local GITHUB_USER = "CTpRedictor"
local REPO_NAME = "script-pula-mea"

local url = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. REPO_NAME .. "/main/bloxstrike_hub.lua"

local ok, err = pcall(function()
    local code = game:HttpGet(url)
    if not code or code == "" then
        warn("[BS Loader] Failed to fetch script from GitHub. Check your URL.")
        warn("[BS Loader] URL: " .. url)
        return
    end
    local fn, compileErr = loadstring(code)
    if not fn then
        warn("[BS Loader] Failed to compile script: " .. tostring(compileErr))
        return
    end
    fn()
end)

if not ok then
    warn("[BS Loader] Error: " .. tostring(err))
    warn("[BS Loader] If you see 'attempt to call a nil value', make sure you updated GITHUB_USER and REPO_NAME in the loader!")
    -- Fallback: try running from local file
    pcall(function()
        warn("[BS Loader] Trying alternative load methods...")
    end)
end

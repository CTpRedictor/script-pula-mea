local GITHUB_USER = "CTpRedictor"
local REPO_NAME = "script-pula-mea"

local url = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. REPO_NAME .. "/main/bloxstrike_hub.lua"

local ok, err = pcall(function()
    local code = game:HttpGet(url)
    if not code or code == "" then
        warn("[Loader] Failed to fetch from GitHub")
        return
    end
    local fn, compileErr = loadstring(code)
    if not fn then
        warn("[Loader] Compile error: " .. tostring(compileErr))
        return
    end
    fn()
end)

if not ok then
    warn("[Loader] " .. tostring(err))
    pcall(function()
        warn("[Loader] Trying alternative methods...")
    end)
end

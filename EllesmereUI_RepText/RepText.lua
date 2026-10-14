-------------------------------------------------------------------------------
--  EllesmereUI_RepText \ RepText.lua   (standalone add-on)
--  Text Format for the EllesmereUI Action Bars reputation bar. No EllesmereUI
--  file is edited: the bar's own update (UpdateRepBar) stores the resolved
--  numbers on the holder (_tipCurrent / _tipMaximum / _tipStanding) right
--  before it calls SetText, so a hook on that FontString's SetText rewrites
--  the text in the chosen format. Settings ride the EllesmereUI profile:
--  EAB.db.profile.bars.RepBar.repTextFormat / repShowStanding.
--  Options: RepText_Options.lua.   Slash: /reptext
-------------------------------------------------------------------------------
local EllesmereUI = _G.EllesmereUI
local ns = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS["EllesmereUIActionBars"]
if not ns then return end  -- Action Bars module off: nothing to do

local RT = {}
ns.RepText = RT

RT.FORMATS = {
    pct       = "Percent",
    curmax    = "Current / Max",
    remaining = "Remaining",
    curmaxpct = "Current / Max  %",
    full      = "Current / Max (Left)  %",
}
RT.ORDER = { "pct", "curmax", "remaining", "curmaxpct", "full" }

local function L(s)
    local f = EllesmereUI.L
    if type(f) == "function" then
        local ok, r = pcall(f, s)
        if ok and type(r) == "string" then return r end
    end
    return s
end

function RT.Settings()
    local EAB = ns.EAB
    local p = EAB and EAB.db and EAB.db.profile
    return p and p.bars and p.bars.RepBar
end

local function GetFrame()
    local d = ns.dataBarFrames
    return (d and d.RepBar) or _G.EllesmereEAB_RepBar
end

-- The text body for one format (no name / standing).
function RT.Body(fmt, cur, mx, pct)
    local left = mx - cur
    if left < 0 then left = 0 end
    if fmt == "curmax" then
        return format("%d / %d", cur, mx)
    elseif fmt == "remaining" then
        return format("%d %s", left, L("left"))
    elseif fmt == "curmaxpct" then
        return format("%d / %d  %.1f%%", cur, mx, pct)
    elseif fmt == "full" then
        return format("%d / %d (%d %s) %.1f%%", cur, mx, left, L("left"), pct)
    end
    return format("%.0f%%", pct)
end

local busy

local function Rewrite(frame)
    local s = RT.Settings()
    if not s then return end
    local fmt = s.repTextFormat or "pct"
    local showStanding = s.repShowStanding ~= false
    -- Percent with standing is EllesmereUI's own text: leave it alone.
    if fmt == "pct" and showStanding then return end

    local cur, mx, standing = frame._tipCurrent, frame._tipMaximum, frame._tipStanding
    if type(cur) ~= "number" or type(mx) ~= "number" then return end
    if mx <= 0 then mx = 1 end
    local data = C_Reputation and C_Reputation.GetWatchedFactionData and C_Reputation.GetWatchedFactionData()
    local name = data and data.name
    if not name then return end

    local pct = (cur / mx) * 100
    cur, mx = math.floor(cur + 0.5), math.floor(mx + 0.5)
    local body = RT.Body(fmt, cur, mx, pct)
    local full
    if showStanding and type(standing) == "string" and standing ~= "" then
        full = format("%s: %s [%s]", name, body, standing)
    else
        full = format("%s: %s", name, body)
    end

    local text = frame._text
    busy = true
    text:SetText(full)
    -- Too long for the bar: drop the name / standing, then percent only.
    local room = (s.rotateText and s.orientation == "VERTICAL") and frame:GetHeight() or frame:GetWidth()
    if room and room > 0 and text:GetStringWidth() > room - 4 then
        text:SetText(body)
        if text:GetStringWidth() > room - 4 then
            text:SetText(format("%.0f%%", pct))
        end
    end
    busy = false
end

-- Re-runs the bar's own update (which ends in the hooked SetText).
function RT.Refresh()
    local f = GetFrame()
    if f and f._updateFunc then f._updateFunc() end
end

local function Attach()
    if RT.attached then return true end
    local f = GetFrame()
    if not (f and f._text and f._text.SetText) then return false end
    RT.attached = true
    hooksecurefunc(f._text, "SetText", function()
        if busy then return end
        local ok, err = pcall(Rewrite, f)
        busy = false
        if not ok then geterrorhandler()(err) end
    end)
    RT.Refresh()
    return true
end

-- The rep bar is built at login (only while Blizzard's bars are off); try a
-- few times after login in case it is built after this add-on's events.
local tries = 0
local function TryAttach()
    if Attach() then return end
    tries = tries + 1
    if tries < 15 then C_Timer.After(1, TryAttach) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0, TryAttach)
    elseif Attach() then
        self:UnregisterAllEvents()
    end
end)

-------------------------------------------------------------------------------
--  /reptext  [pct | curmax | remaining | curmaxpct | full | standing]
-------------------------------------------------------------------------------
SLASH_EUIREPTEXT1 = "/reptext"
SlashCmdList.EUIREPTEXT = function(msg)
    local s = RT.Settings()
    if not s then print("|cff0cd29fRep Text:|r EllesmereUI Action Bars profile not ready.") return end
    msg = strlower(strtrim(msg or ""))
    if RT.FORMATS[msg] then
        s.repTextFormat = msg
    elseif msg == "standing" then
        s.repShowStanding = (s.repShowStanding == false)
    else
        print("|cff0cd29fRep Text:|r /reptext pct | curmax | remaining | curmaxpct | full | standing")
    end
    print(format("|cff0cd29fRep Text:|r %s, standing %s",
        RT.FORMATS[s.repTextFormat or "pct"], (s.repShowStanding ~= false) and "on" or "off"))
    RT.Refresh()
end

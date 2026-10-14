-------------------------------------------------------------------------------
--  EllesmereUI_RepText \ RepText_Options.lua   (standalone add-on)
--  Adds "Text Format | Show Standing" to Action Bars > Menu, Bags & Rep Bars,
--  right under the REPUTATION BAR section. EllesmereUIOptions loads on demand;
--  once it has, the page builder ns.ABO_BuildMenuBagsRepPage is wrapped. While
--  it builds, W:Spacer / W:SectionHeader are watched: just before the
--  "VEHICLE BAR" header our row is drawn where the spacer after the rep
--  section began. If that header is not found (renamed in a later
--  EllesmereUI), the row is added at the end of the page under its own
--  header instead. No EllesmereUI file is edited.
-------------------------------------------------------------------------------
local EllesmereUI = _G.EllesmereUI
local ns = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS["EllesmereUIActionBars"]
if not (ns and ns.RepText) then return end
local RT = ns.RepText

local BLIZZ_DIS_TIP = "This option does not work with Blizzard Bars. Please use Blizzard Edit Mode."
local ANCHOR_HEADER = "VEHICLE BAR"

local function BlizzDis()
    local EAB = ns.EAB
    return EAB and EAB.db and EAB.db.profile and EAB.db.profile.useBlizzardDataBars and true or false
end

local function BuildRows(W, parent, y)
    local _, h = W:DualRow(parent, y,
        { type="dropdown", text="Text Format",
          tooltip="What the reputation bar's text shows.",
          values = RT.FORMATS, order = RT.ORDER,
          disabled=BlizzDis, disabledTooltip=BLIZZ_DIS_TIP, rawTooltip=true,
          getValue=function()
              local s = RT.Settings()
              return s and s.repTextFormat or "pct"
          end,
          setValue=function(v)
              local s = RT.Settings()
              if s then s.repTextFormat = v end
              RT.Refresh()
          end },
        { type="toggle", text="Show Standing",
          tooltip="Adds the standing, e.g. [Friendly], after the text.",
          disabled=BlizzDis, disabledTooltip=BLIZZ_DIS_TIP, rawTooltip=true,
          getValue=function()
              local s = RT.Settings()
              return not (s and s.repShowStanding == false)
          end,
          setValue=function(v)
              local s = RT.Settings()
              if s then s.repShowStanding = v and true or false end
              RT.Refresh()
          end })
    return y - h
end

local function Install()
    if RT.optHooked then return true end
    local orig = ns.ABO_BuildMenuBagsRepPage
    if type(orig) ~= "function" then return false end
    RT.optHooked = true

    ns.ABO_BuildMenuBagsRepPage = function(pageName, parent, yOffset, ...)
        local W = EllesmereUI.Widgets
        if not (W and type(W.SectionHeader) == "function" and type(W.Spacer) == "function"
                and type(W.DualRow) == "function") then
            return orig(pageName, parent, yOffset, ...)
        end
        local origHeader, origSpacer = W.SectionHeader, W.Spacer
        local inserted, spTop, spBottom = false, nil, nil

        W.Spacer = function(self, p, yy, hh, ...)
            local a, b = origSpacer(self, p, yy, hh, ...)
            if p == parent and type(yy) == "number" and type(b) == "number" then
                spTop, spBottom = yy, yy - b
            end
            return a, b
        end
        W.SectionHeader = function(self, p, title, yy, ...)
            if not inserted and p == parent and title == ANCHOR_HEADER and type(yy) == "number" then
                inserted = true
                local start = (spBottom and math.abs(spBottom - yy) < 0.01) and spTop or yy
                local ok, newY = pcall(BuildRows, W, parent, start)
                if ok and type(newY) == "number" then
                    local _, gap = origSpacer(self, parent, newY, 12)
                    newY = newY - (gap or 12)
                    local a, hh = origHeader(self, p, title, newY, ...)
                    -- The caller only steps by the height returned here.
                    return a, (yy - newY) + (hh or 0)
                elseif not ok then
                    geterrorhandler()(newY)
                end
            end
            return origHeader(self, p, title, yy, ...)
        end

        local ok, total = pcall(orig, pageName, parent, yOffset, ...)
        W.SectionHeader, W.Spacer = origHeader, origSpacer
        if not ok then error(total, 0) end

        if not inserted and type(total) == "number" then
            local ok2, res = pcall(function()
                local y = -total
                local _, h = W:Spacer(parent, y, 12);  y = y - h
                _, h = W:SectionHeader(parent, "REPUTATION TEXT", y);  y = y - h
                return math.abs(BuildRows(W, parent, y))
            end)
            if ok2 then total = res else geterrorhandler()(res) end
        end
        return total
    end
    return true
end

local IsLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
if not (IsLoaded and IsLoaded("EllesmereUIOptions") and Install()) then
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name == "EllesmereUIOptions" then
            Install()
            self:UnregisterAllEvents()
        end
    end)
end

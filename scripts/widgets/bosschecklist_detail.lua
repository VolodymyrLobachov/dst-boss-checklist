-- Boss Checklist - right page of the book: everything about one boss
-- (status, stats, how to find it, drops, tips), or a silhouette while the boss is locked.
--
-- Usage:
--   local detail = parent:AddChild(BossDetail(width, height, function(boss_id, is_defeated) ... end))
--   detail:ShowBoss(boss, { status = STATUS.NEXT, defeated_day = nil, can_mark = false,
--                           upcoming_names = { "Deerclops", "Moose/Goose" } })
-- The origin is the middle of the page's left edge. The page is built top to bottom: each
-- _Add* method that takes a y starts there and returns the y below what it added.

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"
local Drops = require "bosschecklist/drops"
local GameData = require "bosschecklist/gamedata"
local UI = require "bosschecklist/ui"
local STATUS = require("bosschecklist/progression").STATUS

local PORTRAIT_SIZE = 110
local LOCKED_PORTRAIT_SIZE = 220
local SECTION_SIZE = 24
local SECTION_GAP = 12
local ICON_SIZE, ICON_GAP = 50, 6
local ICONS_PER_ROW = 8
local MAX_DROP_ROWS = 2
local MARK_BUTTON_SIZE = { 150, 40 }

local STATUS_TEXT =
{
    [STATUS.OPTIONAL] = "Optional mini-boss",
    [STATUS.NEXT] = "Next boss to defeat",
    [STATUS.UPCOMING] = "Coming up (can be fought now)",
    [STATUS.PENDING] = "Not defeated yet",
}

local STATUS_COLOUR =
{
    [STATUS.DEFEATED] = UI.DEFEATED_COLOUR,
    [STATUS.OPTIONAL] = UI.OPTIONAL_COLOUR,
}

local function get_status_text(view)
    if view.status == STATUS.DEFEATED then
        local day = view.defeated_day or 0
        return day > 0 and string.format("Defeated (first on day %d)", day) or "Defeated"
    end
    return STATUS_TEXT[view.status] or STATUS_TEXT[STATUS.PENDING]
end

-- "Health: 4000     Damage: 75 (+10 planar)", or nil when the game has no numbers for this boss.
local function get_stats_line(boss)
    local stats = GameData.get_stats(boss)
    if stats == nil then
        return nil
    end
    local parts = {}
    if stats.health ~= nil then
        parts[#parts + 1] = "Health: " .. stats.health
    end
    if stats.damage ~= nil then
        local planar = stats.planardamage ~= nil and (" (+" .. stats.planardamage .. " planar)") or ""
        parts[#parts + 1] = "Damage: " .. stats.damage .. planar
    end
    return #parts > 0 and table.concat(parts, "     ") or nil
end

-------------------------------------------------------------------------------

local BossDetail = Class(Widget, function(self, width, height, on_mark)
    Widget._ctor(self, "BossChecklistDetail")
    self.page_w = width
    self.page_h = height
    self.on_mark = on_mark -- fn(boss_id, is_defeated), called by the mark button
end)

-- view: { status = STATUS.*, defeated_day = number or nil, can_mark = bool,
--         upcoming_names = array of boss titles shown in the hint of a locked boss }
function BossDetail:ShowBoss(boss, view)
    self:KillAllChildren()
    if view.status == STATUS.LOCKED then
        self:_BuildLocked(boss, view)
    else
        self:_BuildRevealed(boss, view)
    end
end

-------------------------------------------------------------------------------
-- Locked boss
-------------------------------------------------------------------------------

function BossDetail:_BuildLocked(boss, view)
    local center_x = self.page_w / 2

    local portrait = UI.add_portrait(self, boss, LOCKED_PORTRAIT_SIZE, true)
    portrait:SetPosition(center_x, 70)

    local title = self:AddChild(Text(HEADERFONT, 40, UI.LOCKED_NAME, UI.HEADER_COLOUR))
    title:SetPosition(center_x, -80)

    local names = view.upcoming_names or {}
    local hint = #names > 0
        and string.format("Defeat %s to reveal the next boss.", table.concat(names, " or "))
        or "Defeat earlier bosses to reveal this one."
    local text = self:AddChild(Text(CHATFONT, UI.BODY_SIZE + 2, "", UI.TEXT_COLOUR))
    text:SetMultilineTruncatedString(hint, 3, self.page_w - 40, nil, true)
    text:SetPosition(center_x, -130)

    self:_AddMarkButton(boss, view, center_x, -200)
end

-------------------------------------------------------------------------------
-- Revealed boss
-------------------------------------------------------------------------------

function BossDetail:_BuildRevealed(boss, view)
    local width = self.page_w - 20
    local y = self:_AddHeader(boss, view, width)
    y = self:_AddStats(boss, y, width)
    y = self:_AddSection("How to find / summon", boss.summon or "?", y, width, 7)
    y = self:_AddDrops(boss, y, width)
    if boss.tips ~= nil then
        self:_AddSection("Tips", boss.tips, y, width, 3)
    end
end

function BossDetail:_AddSection(title, body, y, width, max_lines)
    y = UI.add_paragraph(self, 0, y - SECTION_GAP, width, title, HEADERFONT, SECTION_SIZE, UI.HEADER_COLOUR, 1)
    if body ~= nil then
        y = UI.add_paragraph(self, 0, y - 4, width, body, CHATFONT, UI.BODY_SIZE, UI.TEXT_COLOUR, max_lines)
    end
    return y
end

function BossDetail:_AddHeader(boss, view, width)
    local top = self.page_h / 2 - 40

    local portrait = UI.add_portrait(self, boss, PORTRAIT_SIZE, false)
    portrait:SetPosition(PORTRAIT_SIZE / 2, top - PORTRAIT_SIZE / 2)

    local x = PORTRAIT_SIZE + 15
    local text_w = width - x - 40
    local y = top - 4
    y = UI.add_paragraph(self, x, y, text_w, GameData.get_boss_title(boss), HEADERFONT, 36, UI.HEADER_COLOUR, 1)
    y = UI.add_paragraph(self, x, y - 4, text_w,
        string.format("%s  -  %s", boss.category or "Boss", boss.location or "?"),
        CHATFONT, UI.BODY_SIZE, UI.TEXT_COLOUR, 2)
    y = UI.add_paragraph(self, x, y - 2, text_w, "When: " .. (boss.when or "?"),
        CHATFONT, UI.BODY_SIZE, UI.TEXT_COLOUR, 1)

    local status_bottom = UI.add_paragraph(self, x, y - 6, 260, get_status_text(view),
        CHATFONT, UI.BODY_SIZE, STATUS_COLOUR[view.status] or UI.HEADER_COLOUR, 1)
    self:_AddMarkButton(boss, view, width - 110, y - 16)

    -- Continue below whichever is lower: the text column or the portrait.
    return math.min(status_bottom, top - PORTRAIT_SIZE - 5) - 10
end

function BossDetail:_AddStats(boss, y, width)
    local stats = get_stats_line(boss)
    if stats ~= nil then
        y = UI.add_paragraph(self, 0, y, width, stats, CHATFONT, UI.BODY_SIZE, UI.TEXT_COLOUR, 1)
    end
    local respawn = GameData.get_respawn_text(boss)
    if respawn ~= nil then
        y = UI.add_paragraph(self, 0, y - 2, width, "Respawn: " .. respawn, CHATFONT, UI.BODY_SIZE, UI.TEXT_COLOUR, 2)
    end
    return y
end

function BossDetail:_AddMarkButton(boss, view, x, y)
    if not view.can_mark or self.on_mark == nil then
        return
    end
    local is_defeated = view.status == STATUS.DEFEATED
    local button = self:AddChild(TEMPLATES.StandardButton(function()
        self.on_mark(boss.id, not is_defeated)
    end, is_defeated and "Unmark" or "Mark defeated", MARK_BUTTON_SIZE))
    button:SetPosition(x, y)
end

-------------------------------------------------------------------------------
-- Drops
-------------------------------------------------------------------------------

function BossDetail:_AddDropSlot(drop, x, y)
    local slot = self:AddChild(Widget("drop"))
    slot:SetPosition(x, y)

    local bg = slot:AddChild(Image(UI.RECIPEBOOK_ATLAS, "ingredient_slot.tex"))
    bg:ScaleToSize(ICON_SIZE, ICON_SIZE)
    bg:SetHoverText(drop.name .. "\n" .. drop.details, { offset_y = 60 })

    local atlas, tex = GameData.get_item_icon(drop.prefab)
    if atlas ~= nil then
        local icon = slot:AddChild(Image(atlas, tex))
        icon:ScaleToSize(ICON_SIZE - 8, ICON_SIZE - 8)
        icon:SetClickable(false)
    else
        local label = slot:AddChild(Text(CHATFONT, 14, "", UI.TEXT_COLOUR))
        label:SetMultilineTruncatedString(drop.name, 3, ICON_SIZE - 4, nil, true)
        label:SetClickable(false)
    end

    local amount = slot:AddChild(Text(CHATFONT, 16, "", UI.TEXT_COLOUR))
    amount:SetTruncatedString(drop.amount, ICON_SIZE + ICON_GAP, nil, true)
    amount:SetPosition(0, -ICON_SIZE / 2 - 9)
    amount:SetClickable(false)
end

function BossDetail:_AddDrops(boss, y, width)
    y = self:_AddSection("Drops", nil, y, width)

    local drops = Drops.for_boss(boss)
    if #drops == 0 then
        y = UI.add_paragraph(self, 0, y - 6, width, "No drops.", CHATFONT, UI.BODY_SIZE, UI.TEXT_COLOUR, 1)
    else
        local top = y - 6
        local cell_w = ICON_SIZE + ICON_GAP
        local cell_h = ICON_SIZE + 22
        local shown = math.min(#drops, ICONS_PER_ROW * MAX_DROP_ROWS)
        for i = 1, shown do
            local column = (i - 1) % ICONS_PER_ROW
            local row = math.floor((i - 1) / ICONS_PER_ROW)
            self:_AddDropSlot(drops[i], column * cell_w + ICON_SIZE / 2, top - row * cell_h - ICON_SIZE / 2)
        end
        y = top - math.ceil(shown / ICONS_PER_ROW) * cell_h
        if #drops > shown then
            y = UI.add_paragraph(self, 0, y, width, string.format("...and %d more", #drops - shown),
                CHATFONT, UI.BODY_SIZE - 2, UI.TEXT_COLOUR, 1)
        end
    end

    if boss.drops_note ~= nil then
        y = UI.add_paragraph(self, 0, y - 2, width, boss.drops_note, CHATFONT, UI.BODY_SIZE - 2, UI.TEXT_COLOUR, 3)
    end
    return y
end

return BossDetail

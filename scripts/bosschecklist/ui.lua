-- Boss Checklist - look and small helpers shared by the book widgets.

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local GameData = require "bosschecklist/gamedata"
local STATUS = require("bosschecklist/progression").STATUS

local UI =
{
    RECIPEBOOK_ATLAS = "images/quagmire_recipebook.xml",
    GLOBAL_ATLAS = "images/global_redux.xml",

    BODY_SIZE = 20,
    LOCKED_NAME = "???",

    TEXT_COLOUR = UICOLOURS.BROWN_DARK,
    HEADER_COLOUR = { 0.45, 0.22, 0.12, 1 },
    DEFEATED_COLOUR = { 0.15, 0.45, 0.15, 1 },
    OPTIONAL_COLOUR = { 0.16, 0.3, 0.52, 1 },
    LOCKED_COLOUR = { 0.35, 0.3, 0.25, 1 },
}

local NAME_COLOURS =
{
    [STATUS.DEFEATED] = UI.DEFEATED_COLOUR,
    [STATUS.OPTIONAL] = UI.OPTIONAL_COLOUR,
    [STATUS.LOCKED] = UI.LOCKED_COLOUR,
}

function UI.get_name_colour(status)
    return NAME_COLOURS[status] or UI.TEXT_COLOUR
end

-- Adds the boss portrait to `parent`; when `locked`, a black silhouette with a question mark.
-- Returns the new widget.
function UI.add_portrait(parent, boss, size, locked)
    local portrait = parent:AddChild(Widget("portrait"))
    local atlas, tex = GameData.get_boss_portrait(boss)
    if atlas ~= nil then
        local image = portrait:AddChild(Image(atlas, tex))
        image:ScaleToSize(size, size)
        image:SetClickable(false)
        if locked then
            image:SetTint(0, 0, 0, 1)
        end
    end
    if locked then
        local mark = portrait:AddChild(Text(HEADERFONT, math.floor(size * 0.6), "?", { 1, 1, 1, 0.9 }))
        mark:SetClickable(false)
    end
    return portrait
end

-- Adds left-aligned, wrapped text whose top-left corner is at (x, y).
-- Returns the y of its bottom edge (where the next block can start) and the text widget.
function UI.add_paragraph(parent, x, y, width, str, font, size, colour, max_lines)
    local text = parent:AddChild(Text(font, size, "", colour))
    text:SetHAlign(ANCHOR_LEFT)
    text:SetMultilineTruncatedString(str, max_lines or 10, width, nil, true)
    local w, h = text:GetRegionSize()
    text:SetPosition(x + w / 2, y - h / 2)
    return y - h, text
end

return UI

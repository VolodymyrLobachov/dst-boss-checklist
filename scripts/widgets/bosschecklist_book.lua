-- Boss Checklist - the book: HUD button, book frame and the left page (boss list).
-- The right page is widgets/bosschecklist_detail. What is revealed is decided by
-- bosschecklist/progression; this widget only draws the result.

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"
local BossDetail = require "widgets/bosschecklist_detail"
local Codec = require "bosschecklist/codec"
local Config = require "bosschecklist/config"
local GameData = require "bosschecklist/gamedata"
local Progression = require "bosschecklist/progression"
local Registry = require "bosschecklist/registry"
local UI = require "bosschecklist/ui"

local STATUS = Progression.STATUS

local BOOK_W, BOOK_H = 880, 600
local PAGE_MARGIN = 30
local LIST_W = 290
local DETAIL_W = BOOK_W - LIST_W - 70
local SPINE_X = -BOOK_W / 2 + LIST_W + PAGE_MARGIN

local ROW_W, ROW_H = 260, 40
local ROW_ICON = 34
local VISIBLE_ROWS = 11

-- The button sits in the bottom-right corner, left of the map button and right of the
-- inventory bar, so it never overlaps the backpack. The book opens in the screen centre.
local BUTTON_TEX = "book_brimstone.tex"
local BUTTON_X, BUTTON_Y = -185, 55
local BUTTON_SIZE = 64

local BossChecklistBook = Class(Widget, function(self, owner, request_set_defeated)
    Widget._ctor(self, "BossChecklistBook")
    self.owner = owner
    self.request_set_defeated = request_set_defeated -- fn(boss_id, is_defeated): asks the server
    self.bosses = Registry.list
    self.defeated = {}  -- [boss_id] = day, as replicated by the server
    self.state = Progression.compute(self.bosses, self.defeated, Config)
    self.selected_index = 1

    self.button_root = self:_AddRoot("button_root", ANCHOR_RIGHT, ANCHOR_BOTTOM)
    self.book_root = self:_AddRoot("book_root", ANCHOR_MIDDLE, ANCHOR_MIDDLE)

    self:_BuildButton()
    self:_BuildBook()
    self:_BuildListPage()

    self.detail = self.book:AddChild(BossDetail(DETAIL_W, BOOK_H, function(id, is_defeated)
        if self.request_set_defeated ~= nil then
            self.request_set_defeated(id, is_defeated)
        end
    end))
    self.detail:SetPosition(SPINE_X + 20, 0)

    -- The server replicates the defeated list through a netvar on the world network entity.
    if TheWorld ~= nil and TheWorld.net ~= nil then
        self.inst:ListenForEvent("bosschecklist_dirty", function() self:OnDefeatedChanged() end, TheWorld.net)
    end
    self:OnDefeatedChanged()
end)

-------------------------------------------------------------------------------
-- Construction
-------------------------------------------------------------------------------

-- A root that keeps its place and scale on every screen size, like the rest of the HUD.
function BossChecklistBook:_AddRoot(name, h_anchor, v_anchor)
    local root = self:AddChild(Widget(name))
    root:SetHAnchor(h_anchor)
    root:SetVAnchor(v_anchor)
    root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    root:SetMaxPropUpscale(MAX_HUD_SCALE)
    return root
end

function BossChecklistBook:_BuildButton()
    self.button = self.button_root:AddChild(ImageButton(GetInventoryItemAtlas(BUTTON_TEX), BUTTON_TEX))
    self.button:ForceImageSize(BUTTON_SIZE, BUTTON_SIZE)
    self.button:SetNormalScale(1)
    self.button:SetFocusScale(1.12)
    self.button:SetPosition(BUTTON_X, BUTTON_Y)
    self.button:SetOnClick(function() self:Toggle() end)
    self.button:SetHoverText(string.format("Boss Checklist (%s)", tostring(Config.toggle_key)), { offset_y = 60 })
    if not Config.show_tab then
        self.button:Hide()
    end
end

function BossChecklistBook:_BuildBook()
    self.book = self.book_root:AddChild(Widget("book"))
    self.book:Hide()

    self.bg = self.book:AddChild(Image(UI.RECIPEBOOK_ATLAS, "quagmire_recipe_menu_bg.tex"))
    self.bg:SetSize(BOOK_W, BOOK_H)

    self.spine = self.book:AddChild(Image("images/global.xml", "square.tex"))
    self.spine:SetSize(2, BOOK_H - 80)
    self.spine:SetTint(0.31, 0.24, 0.15, 0.6)
    self.spine:SetPosition(SPINE_X, 0)

    self.close_btn = self.book:AddChild(ImageButton(UI.GLOBAL_ATLAS, "close.tex"))
    self.close_btn:SetPosition(BOOK_W / 2 - 30, BOOK_H / 2 - 30)
    self.close_btn:SetScale(0.6)
    self.close_btn:SetOnClick(function() self:Close() end)
    self.close_btn:SetHoverText("Close")
end

function BossChecklistBook:_BuildListPage()
    local page = self.book:AddChild(Widget("listpage"))
    page:SetPosition(-BOOK_W / 2 + PAGE_MARGIN + LIST_W / 2, 0)

    local title = page:AddChild(Text(HEADERFONT, 34, "Boss Checklist", UI.HEADER_COLOUR))
    title:SetPosition(0, BOOK_H / 2 - 50)

    self.progress = page:AddChild(Text(CHATFONT, 22, "", UI.TEXT_COLOUR))
    self.progress:SetPosition(0, BOOK_H / 2 - 82)

    self.list = page:AddChild(TEMPLATES.ScrollingGrid(self.bosses, {
        scroll_context = {},
        widget_width = ROW_W,
        widget_height = ROW_H + 2,
        num_visible_rows = VISIBLE_ROWS,
        num_columns = 1,
        item_ctor_fn = function() return self:_MakeRow() end,
        apply_fn = function(_, row, boss, index) self:_UpdateRow(row, boss, index) end,
        scrollbar_offset = 18,
        scrollbar_height_offset = -40,
        peek_percent = 0,
        end_offset = 1,
    }))
    self.list:SetPosition(-8, -45)
end

-------------------------------------------------------------------------------
-- List rows (reused by the scrolling grid as the list scrolls)
-------------------------------------------------------------------------------

function BossChecklistBook:_MakeRow()
    local row = Widget("bossrow")
    row.bg = row:AddChild(TEMPLATES.ListItemBackground(ROW_W, ROW_H, function()
        if row.data_index ~= nil then
            self:Select(row.data_index)
        end
    end))
    row.focus_forward = row.bg

    row.portrait_root = row:AddChild(Widget("portrait_root"))
    row.portrait_root:SetPosition(-ROW_W / 2 + 4 + ROW_ICON / 2, 0)

    row.name = row:AddChild(Text(CHATFONT, 22, "", UI.TEXT_COLOUR))
    row.name:SetClickable(false)

    row.check = row:AddChild(Image(UI.GLOBAL_ATLAS, "checkbox_normal_check.tex"))
    row.check:ScaleToSize(24, 24)
    row.check:SetPosition(ROW_W / 2 - 18, 0)
    row.check:SetClickable(false)
    return row
end

-- boss is nil for the empty rows the grid keeps past the end of the list.
function BossChecklistBook:_UpdateRow(row, boss, index)
    if boss == nil then
        row.data_index = nil
        row:Hide()
        return
    end
    row.data_index = index
    row:Show()

    local status = self.state.status[index]
    local locked = status == STATUS.LOCKED

    row.portrait_root:KillAllChildren()
    UI.add_portrait(row.portrait_root, boss, ROW_ICON, locked)

    local name = locked and UI.LOCKED_NAME or GameData.get_boss_title(boss)
    row.name:SetTruncatedString(name, ROW_W - ROW_ICON - 50, nil, true)
    local name_w = row.name:GetRegionSize()
    row.name:SetPosition(-ROW_W / 2 + ROW_ICON + 12 + name_w / 2, 0)
    row.name:SetColour(UI.get_name_colour(status))

    if status == STATUS.DEFEATED then
        row.check:Show()
    else
        row.check:Hide()
    end

    if index == self.selected_index then
        row.bg:Select()
    else
        row.bg:Unselect()
    end
end

-------------------------------------------------------------------------------
-- Open / close
-------------------------------------------------------------------------------

function BossChecklistBook:IsOpen()
    return self.book:IsVisible()
end

-- True while the mouse is over the open book (used to stop the camera from zooming).
function BossChecklistBook:IsMouseOver()
    return self:IsOpen() and self.book.focus == true
end

-- Opens the book on the next boss to defeat (the last boss once everything is defeated).
function BossChecklistBook:Open()
    self.book:Show()
    self:Select(self.state.current_index or #self.bosses)
end

function BossChecklistBook:Close()
    self.book:Hide()
end

function BossChecklistBook:Toggle()
    if self:IsOpen() then
        self:Close()
    else
        self:Open()
    end
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

function BossChecklistBook:OnDefeatedChanged()
    local net = TheWorld ~= nil and TheWorld.net or nil
    local netvar = net ~= nil and net.bosschecklist_defeated or nil
    self.defeated = Codec.decode(netvar ~= nil and netvar:value() or nil)
    self.state = Progression.compute(self.bosses, self.defeated, Config)

    self.progress:SetString(string.format("Defeated: %d / %d", self.state.defeated_count, #self.bosses))
    self.list:RefreshView()
    if self:IsOpen() then
        self:RefreshDetail()
    end
end

function BossChecklistBook:Select(index)
    self.selected_index = index
    self.list:RefreshView()
    self:RefreshDetail()
end

function BossChecklistBook:_GetUpcomingNames()
    local names = {}
    for i, index in ipairs(Progression.get_upcoming(self.state)) do
        names[i] = GameData.get_boss_title(self.bosses[index])
    end
    return names
end

function BossChecklistBook:RefreshDetail()
    local boss = self.bosses[self.selected_index]
    if boss == nil then
        return
    end
    self.detail:ShowBoss(boss, {
        status = self.state.status[self.selected_index],
        defeated_day = self.defeated[boss.id],
        can_mark = Config.can_mark(TheNet:GetIsServerAdmin()),
        upcoming_names = self:_GetUpcomingNames(),
    })
end

return BossChecklistBook

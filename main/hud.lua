-- Boss Checklist - puts the book on the HUD and handles its input (imported by modmain).

local G = GLOBAL
local require = G.require

local Config = require("bosschecklist/config")

-- Asks the server to mark (or unmark) a boss by hand. The server checks the permission.
local function request_set_defeated(id, is_defeated)
    SendModRPCToServer(G.GetModRPC(Config.RPC_NAMESPACE, "SetDefeated"), id, is_defeated)
end

local function get_book(hud)
    return hud ~= nil and hud.controls ~= nil and hud.controls.bosschecklist or nil
end

AddClassPostConstruct("widgets/controls", function(controls)
    local BossChecklistBook = require("widgets/bosschecklist_book")
    controls.bosschecklist = controls:AddChild(BossChecklistBook(controls.owner, request_set_defeated))
    controls.bosschecklist:MoveToBack()
end)

-- Scrolling over the open book should scroll the list, not zoom the camera. The game only
-- blocks the zoom over the crafting menu, so the zoom functions are switched off for the
-- duration of the camera update while the mouse is over the book.
local function noop() end

local function run_without_zoom(camera, fn, ...)
    -- rawget: remember instance overrides only, so restoring nil falls back to the class methods.
    local zoom_in, zoom_out = G.rawget(camera, "ZoomIn"), G.rawget(camera, "ZoomOut")
    camera.ZoomIn, camera.ZoomOut = noop, noop
    local ok, err = G.pcall(fn, ...)
    camera.ZoomIn, camera.ZoomOut = zoom_in, zoom_out
    if not ok then
        print("[Boss Checklist] DoCameraControl error: " .. tostring(err))
    end
end

AddComponentPostInit("playercontroller", function(self)
    local do_camera_control = self.DoCameraControl
    if do_camera_control == nil then
        return
    end
    function self:DoCameraControl(...)
        local book = get_book(self.inst.HUD)
        if book ~= nil and book:IsMouseOver() and G.TheCamera ~= nil then
            return run_without_zoom(G.TheCamera, do_camera_control, self, ...)
        end
        return do_camera_control(self, ...)
    end
end)

-- Esc closes the book instead of opening the pause menu, as the game does for the crafting menu.
AddClassPostConstruct("screens/playerhud", function(hud)
    local on_control = hud.OnControl
    function hud:OnControl(control, down)
        if not down and control == G.CONTROL_PAUSE and not G.TheInput:ControllerAttached() then
            local book = get_book(self)
            if book ~= nil and book:IsOpen() then
                book:Close()
                return true
            end
        end
        return on_control(self, control, down)
    end
end)

local function is_hud_active()
    local screen = G.TheFrontEnd:GetActiveScreen()
    return screen ~= nil and screen.name == "HUD"
end

local function on_toggle_key()
    local player = G.ThePlayer
    -- Ignore the key while another screen is open or while typing in chat.
    if player == nil or player.HUD == nil or not is_hud_active() or player.HUD:HasInputFocus() then
        return
    end
    local book = get_book(player.HUD)
    if book ~= nil then
        book:Toggle()
    end
end

local toggle_key = G["KEY_" .. tostring(Config.toggle_key)]
if toggle_key ~= nil then
    G.TheInput:AddKeyDownHandler(toggle_key, on_toggle_key)
end

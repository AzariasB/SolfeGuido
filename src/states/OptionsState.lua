
--- LIBS
local State = require('src.State')
local Theme = require('src.utils.Theme')
local ScreenManager = require('lib.ScreenManager')
local Config = require('src.data.Config')
local Drawer = require('src.objects.Drawer')
local EventTransmitter = require('src.utils.EventTransmitter')
local lume = require('lib.lume')

--- Special state where the user can changes
--- his preferences, it's a sidebar, that contains
--- buttons, when the buttons are pressed, a
--- drawer appears showing the available options to choose from
---@class OptionsState : State
---@field private drawers table
---@field private slidingOut boolean
local OptionsState = State:extend()

--- Constructor
function OptionsState:new()
    State.new(self)
    EventTransmitter.transmitEvents(self)
    self.xPos = love.graphics.getWidth() - 5
    self.drawers = {}
    self.slidingOut = false
end

--- Slides out, closes open drawers if any
function OptionsState:slideOut()
    if self.slidingOut then return end
    self.slidingOut = true
    for _, drawer in ipairs(self.drawers) do drawer:hide() end
    self.drawers = nil
    local settings = ScreenManager.first().settingsButton
    if settings then settings.consumed = false end

    self:transition(self.ui:transitionOut(), function()
        ScreenManager.removeSelf(self)
    end, 0)
    self.timer:tween(Vars.transition.tween, self, {xPos = love.graphics.getWidth() + 5}, 'out-expo')
    if settings then
        self.timer:tween(Vars.transition.tween, settings, {rotation = settings.rotation + math.pi}, 'linear')
    end
end

--- Capture the escape key to close the option
---@param key string
function OptionsState:keypressed(key)
    if State.keypressed(self, key) then return true end
    if key == "escape" then
        self:slideOut()
        return true
    end
    return false
end

--- Inherited method
function OptionsState:draw()
    local height = love.graphics.getHeight()
    local width = Vars.titleSize * 2
    love.graphics.setColor(Theme.background)
    love.graphics.rectangle('fill',self.xPos, -5, width, height + 10)

    love.graphics.setColor(Theme.font)
    love.graphics.rectangle('line', self.xPos, -5, width, height + 10)
    State.draw(self)
end

--- Create the drawers based on the data
--- in the given table, and adds it to the list
--- of drawers
---@param config table
---@param height number
function OptionsState:createDrawers(config, height)
    for _, v in ipairs(config) do
        local choices = {}
        for _, icon in pairs(v.icons) do
            local key = type(icon[2]) == 'string' and 'icon' or 'image'
            choices[#choices+1] = {
                [key] = icon[2],
                configValue = icon[1]
            }
        end

        local callback
        if v.config == "lang" or v.config == "theme" then
            callback = function(drawer)
                if Config.update(v.config, drawer.selected) then
                    ScreenManager.switch('MenuState')
                end
            end
        else
            callback = function(drawer)
                Config.update(v.config, drawer.selected)
                drawer:hide()
            end
        end
        local drawer = self:addEntity(Drawer, {
            x = love.graphics.getWidth() + 5,
            y = lume.round(v.y),
            height = height
        })
        self.drawers[#self.drawers+1] = drawer
        self[v.config .. 'Drawer']  = drawer
        drawer:init({
            selected = Config[v.config],
            choices = choices,
            callback = callback,
        })

    end
end

--- Creates all the widgets
function OptionsState:init()
    self.timer:tween(Vars.transition.tween, self, {xPos = love.graphics.getWidth() - Vars.titleSize * 1.5}, 'out-expo')

    local optionIcons = 6
    local remainingSpace = (love.graphics.getHeight() - Vars.titleSize * optionIcons)
    local padding = remainingSpace / (optionIcons + 1)

    local xPos = love.graphics.getWidth() - Vars.titleSize * 1.25
    local baseY = Vars.titleSize  + padding
    local elements = self:startUI()
        :createTransition()
            :add('IconButton', {
                from = 'right',
                to = xPos - Vars.titleSize * 1.25,
                y = 10,
                circled = true,
                size = Vars.titleSize / 1.5,
                callback = function() self:slideOut() end,
                icon = 'Times'
            })
            :add('IconButton', {
                from = 'right',
                to = xPos,
                y = padding,
                callback = function(btn)
                    btn.consumed = false
                    Config.update('sound', Config.sound == 'on' and 'off' or 'on')
                    btn:setIcon(Config.sound == 'on' and assets.IconName.VolumeOn or assets.IconName.VolumeOff)
                end,
                icon = Config.sound == 'on' and 'VolumeOn' or 'VolumeOff',
            })
            :add('IconButton', {
                from = 'right',
                to = xPos,
                y = baseY + padding,
                icon = Config.vibrations == 'on' and 'MobileVibrate' or 'Mobile',
                callback = function(btn)
                    btn.consumed = false
                    Config.update('vibrations', Config.vibrations == 'on' and 'off' or 'on')
                    if Config.vibrations == 'on' then btn:shake() end
                    btn:setIcon(Config.vibrations == 'on' and assets.IconName.MobileVibrate or assets.IconName.Mobile)
                end
            })
            :add('IconButton', {
                from = 'right',
                to = xPos,
                y = baseY * 2 + padding,
                callback = function(btn)
                    btn.consumed = false
                    self.noteStyleDrawer:show()
                end,
                icon = 'Tag'
            })
            :add('IconButton', {
                from = 'right',
                to = xPos,
                y = baseY * 3 + padding,
                callback = function(btn)
                    btn.consumed = false
                    self.answerTypeDrawer:show()
                end,
                icon = 'Pointer',
            })
            :add('IconButton', {
                from = 'right',
                to = xPos,
                y = baseY * 4 + padding,
                callback = function(btn)
                    btn.consumed = false
                    self.langDrawer:show()
                end,
                icon = 'Sphere'
            })
            :add('IconButton', {
                from = 'right',
                to = xPos,
                y = baseY * 5 + padding,
                callback = function(btn)
                    btn.consumed = false
                    self.themeDrawer:show()
                end,
                icon = 'Droplet',
            })
        :build()
    self:transition(elements)
    self:createDrawers({
        {
            icons = {
                {'englishNotes', 'EnglishNotes'},
                {'romanNotes', 'RomanNotes'},
                {'latinNotes', 'LatinNotes'}
            },
            config = 'noteStyle',
            y = baseY * 2 + padding / 2
        },
        {
            icons = {
                {'buttons', 'NotesButton'},
                {'piano', 'PianoKeys'},
                {'pianoWithNotes', 'PianoWithNotes'},
            },
            config = 'answerType',
            y = baseY * 3 + padding / 2
        },
        {
            icons = {
                {'en', assets.images.flags.en},
                {'es', assets.images.flags.es},
                {'it', assets.images.flags.it},
                {'fr', assets.images.flags.fr},
                {'sv', assets.images.flags.sv}
            },
            config = 'lang',
            y = baseY * 4 + padding / 2
        },
        {
            icons = {
                {'light', 'Sun'},
                {'dark', 'Moon'}
            },
            config = 'theme',
            y = baseY * 5 + padding / 2
        }
    }, padding + Vars.titleSize)
end

return OptionsState
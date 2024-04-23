local State = require('src.State')
local Config = require('src.data.Config')
local UIFactory = require('src.utils.UIFactory')
local ScreenManager = require('lib.ScreenManager')
local Theme = require('src.utils.Theme')
local RadiButtonGroup = require('src.objects.RadioButtonGroup')

--- State shown only once, when the user
--- starts the app right after having
--- installed it, this allows the user too
--- setup the app configuration
---@class StartupConfigState : State
local StartupConfigState = State:extend()

--- Reload all the states, and set the current
--- state to the given index, is used
--- when a configuration is changed and requires
--- a full reload (language, theme)
---@param index number
function StartupConfigState.reload(index)
    ScreenManager.switch('MenuState')
    for i = #StartupConfigState.options, index, -1 do
        ScreenManager.push('StartupConfigState', i, false)
    end
end

--- Creates all the option to choose from
function StartupConfigState.createOptions()
    if StartupConfigState.options ~= nil then
        return StartupConfigState.options
    end
    StartupConfigState.options = {
        {
            title = 'language',
            icon = 'Sphere',
            configName = 'lang',
            options = {
                {
                    optionName = 'en',
                    image = assets.images.flags.en,
                    title = 'English'
                },
                {
                    optionName = 'es',
                    image = assets.images.flags.es,
                    title = 'Español'
                },
                {
                    optionName = 'fr',
                    image = assets.images.flags.fr,
                    title = 'Français'
                },
                {
                    optionName = 'it',
                    image = assets.images.flags.it,
                    title = 'Italiano'
                },
                {
                    optionName = 'sv',
                    image = assets.images.flags.sv,
                    title = 'Svenska'
                }
            },
            changeCallback = function(index)
                StartupConfigState.reload(index)
            end
        },
        {
            title = 'note_style',
            subtitle = 'note_style_subtitle',
            icon = 'Tag',
            configName = 'noteStyle',
            options = {
                {
                    optionName = 'englishNotes',
                    icon = 'EnglishNotes',
                    title = 'english_note'
                },
                {
                    optionName = 'romanNotes',
                    icon = 'RomanNotes',
                    title = 'roman_notes'
                },
                {
                    optionName = 'latinNotes',
                    icon = 'LatinNotes',
                    title = 'latin_notes'
                }
            },
        },
        {
            title = 'answer_type',
            subtitle = 'answer_type_subtitle',
            icon = 'Pointer',
            configName = 'answerType',
            options = {
                {
                    optionName = 'buttons',
                    icon = 'NotesButton',
                    title = 'answer_button',
                    subtitle = 'answer_button_subtitle'
                },
                {
                    optionName = 'piano',
                    icon = 'PianoKeys',
                    title = 'answer_piano',
                    subtitle = 'answer_piano_subtitle'
                },
                {
                    optionName = 'pianoWithNotes',
                    icon = 'PianoWithNotes',
                    title = 'answer_pianowithnotes',
                    subtitle = 'answer_pianowithnotes_subtitle'
                }
            }
        },
        {
            title = 'theme',
            subtitle = 'theme_subtitle',
            configName = 'theme',
            icon = 'Droplet',
            options = {
                {
                    optionName = 'light',
                    icon = 'Sun',
                    title = 'light_theme'
                },
                {
                    optionName = 'dark',
                    icon = 'Moon',
                    title = 'dark_theme'
                },
            },
            changeCallback = function(index)
                StartupConfigState.reload(index)
            end
        }
    }
    return StartupConfigState.options
end

--- Inherited method
function StartupConfigState:draw()
    love.graphics.push()
    love.graphics.translate(self.x, 0)
    love.graphics.setColor(Theme.background)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(Theme.font)
    love.graphics.rectangle('line', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    State.draw(self)
    love.graphics.pop()
end

--- Slides out the entire state, to show the main menu
function StartupConfigState:slideOut()
    self.timer:tween(Vars.transition.tween, self, {x = -love.graphics.getWidth()}, 'out-cubic', function()
        ScreenManager.pop()
    end)
end

--- Intializes a single slide,
--- the slide will go get the configuration
--- options to show, and create the necessary widgets
---@param index number
---@param slideFrom string
function StartupConfigState:init(index, slideFrom)
    if slideFrom == 'left' then
        self.x = -love.graphics.getWidth()
    elseif slideFrom == 'right' then
        self.x = love.graphics.getWidth()
    else
        self.x = 0
    end
    self.timer:tween(Vars.transition.tween, self, {x = 0}, 'out-cubic')

    local config = StartupConfigState.options[index]
    UIFactory.createTitle(self, {
        text = tr(config.title),
        centered = true,
        y = 5,
        color = Theme.font:clone()
    })

    UIFactory.createTitle(self, {
        text = assets.IconName[config.icon],
        fontName = 'Icons',
        y = 15,
        x = 15,
        color = Theme.font:clone()
    })

    if config.subtitle then
        UIFactory.createTitle(self, {
            text = tr(config.subtitle),
            fontSize = Vars.mobileButton.fontSize,
            fontName = 'Oswald',
            centered = true,
            y = Vars.titleSize + 10,
            color = Theme.font:clone()
        })
    end

    self.selectedTitle = UIFactory.createTitle(self, {
        text = 'title',
        centered = true,
        fontName = 'Oswald',
        y = Vars.titleSize * 2 + 20,
        color = Theme.font:clone()
    })

    self.selectedSubtitle = UIFactory.createTitle(self, {
        text = 'subtitle',
        fontName = 'Oswald',
        fontSize = Vars.mobileButton.fontSize,
        centered = true,
        y = Vars.titleSize * 3 + 30,
        color = Theme.font:clone()
    })

    local optionsSize = #config.options
    local btnWidth = 100
    local availableSpace = (love.graphics.getWidth() - (optionsSize * (btnWidth + 10))) / 2
    self.choices = self:addEntity(RadiButtonGroup, {})
    local configValue = Config[config.configName]
    for i, v in pairs(config.options) do
        UIFactory.createRadioButton(self.choices, {
            callback = function(btn)
                Config.update(config.configName, btn.value)
                if config.changeCallback then
                    config.changeCallback(index)
                end
                self.selectedTitle:setCenteredText(tr(v.title))
                if v.subtitle then
                    self.selectedSubtitle:setCenteredText(tr(v.subtitle))
                end
            end,
            color = Theme.font:clone(),
            framed = true,
            image = v.image,
            icon = v.icon,
            size = Vars.titleSize,
            padding = 10,
            width = Vars.titleSize * 2,
            x = availableSpace + (i-1) * (btnWidth + 10),
            y = Vars.titleSize * 4 + 40,
            value = v.optionName,
            centerImage = true,
        })
        if v.optionName == configValue then
            self.selectedTitle:setCenteredText(tr(v.title))
            if v.subtitle then
                self.selectedSubtitle:setCenteredText(tr(v.subtitle))
            else
                self.selectedSubtitle.isDead = true
                self.selectedSubtitle = nil
            end
        end
    end
    self.choices:setSelectedValue(Config[config.configName])

    if index > 1 then
        UIFactory.createTextButton(self, {
            text = ' < ',
            x = 10,
            y = love.graphics.getHeight() - 10,
            yOrigin = 1,
            padding = 5,
            framed = true,
            color = Theme.font:clone(),
            callback = function(btn)
                btn.consumed = false
                ScreenManager.push('StartupConfigState', index - 1, 'left')
            end
        })
    end

    if index < #StartupConfigState.options then
        UIFactory.createTextButton(self, {
            text = ' > ',
            y = love.graphics.getHeight() - 10,
            x = love.graphics.getWidth() - 10,
            padding = 5,
            xOrigin = 1,
            yOrigin = 1,
            framed = true,
            callback = function()
                self:slideOut()
            end,
            color = Theme.font:clone()
        })
    else
        UIFactory.createTextButton(self, {
            text = assets.IconName.Check,
            fontName = 'Icons',
            y = love.graphics.getHeight() - 10,
            x = love.graphics.getWidth() - 10,
            padding = 10,
            xOrigin = 1,
            yOrigin = 1,
            framed = true,
            callback = function() self:slideOut() end,
            color = Theme.font:clone()
        })
    end
    State.init(self)
end

return StartupConfigState
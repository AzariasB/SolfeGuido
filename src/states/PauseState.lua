
local State = require('src.State')
local ScreenManager = require('lib.ScreenManager')


---@class PauseState : State
local PauseState = State:extend()


function PauseState:new()
    State.new(self)
end

function PauseState:init(...)
    self.color = {1, 1, 1, 0}
    self.timer:tween(0.2, self, {color = {1, 1, 1, 0.8}}, 'linear', function()
        self:addButtons()
    end)
end

function PauseState:addButtons()
    self:createUI({
        {
            {
                text = 'Pause',
                fontSize = assets.config.titleSize,
                y = 0
            },{
                type = 'TextButton',
                text = 'Resume',
                callback = function() self:back() end
            }, {
                type = 'TextButton',
                text = 'Exit',
                state = 'RootState'
            }
        }
    })
end

function PauseState:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    State.draw(self)
end


function PauseState:back()
    self:slideEntitiesOut()
    self.timer:tween(assets.config.transition.tween, self, {color = {1, 1, 1, 0}}, 'linear', function()
        ScreenManager.pop()
    end)
end


return PauseState


local Entity = require('src.Entity')
local Color = require('src.utils.Color')

---@class Note : Entity
---@field public area PlayState
---@field public measure Measure
local Note = Entity:extend()


function Note:new(area, options)
    Note.super.new(self, area, options)
    self.image = self.measure.noteIcon
    self.color = Color.black:clone()
    self.name = nil
    self.measureIndex = self.measure:indexOf(self.note)
    self.y = self:noteToPosition(self.measureIndex)
    self.width = self.image:getWidth() + (assets.config.note.padding * self.image:getWidth() * 2)
    self.rotation = self.measureIndex >= 10 and math.pi or 0
    self.yOrigin = assets.config.note.yOrigin * self.measure.noteHeight
    self.xOrigin = assets.config.note.xOrigin * self.image:getWidth()
end



---@param note number
---@return number
function Note:noteToPosition(note)
    return self.measure:getNotePosition(note)
end

function Note:correct()
    self.color = Color(0, 0.5, 0, 1)
    self:fadeTo(Color(0, 0.5, 0, 0))
end

function Note:wrong()
    self.color = Color(0.5, 0, 0, 1)
    self:fadeTo(Color.transparent)
    self.name = self.measure:getNoteName(self.note)
end

function Note:fadeAway()
    self:fadeTo( Color.transparent)
end

function Note:fadeTo(color)
    self.timer:tween(assets.config.note.fadeAway, self, {color = color}, 'linear', function() self.isDead = true end)
end

function Note:draw()
    --Color for the (optional) bars
    love.graphics.setColor(0, 0, 0, self.color.a)
    love.graphics.setLineWidth(1)
    local actualWidth = self.image:getWidth()
    local padding = assets.config.note.padding * actualWidth
    if self.measureIndex <= 4 then
        for i = 5, self.measureIndex + 1, -2 do
            local y = self:noteToPosition(i - 1)
            love.graphics.line(self.x, y, self.x + actualWidth + padding * 2, y)
        end
    elseif self.measureIndex >= 15 then
        for i = 16, self.measureIndex, 2 do
            local y = self:noteToPosition(i)
            love.graphics.line(self.x, y, self.x +  actualWidth + padding * 2, y)
        end
    end
    love.graphics.setColor(self.color)

    love.graphics.draw(self.image, self.x + padding + self.xOrigin, self.y, self.rotation, nil, nil,  self.xOrigin, self.yOrigin)

    if self.name then
        love.graphics.print(self.name, self.x - 15, self.y + 5)
    end
end

---@param dt number
function Note:update(dt)
    Note.super.update(self, dt)
    self.x = self.x - self.area:getMove()
    if self.x < 0 then
        self.isDead = true
    end
end

return Note
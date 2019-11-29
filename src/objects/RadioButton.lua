
local AbstractButton = require('src.objects.AbstractButton')
local Theme = require('src.utils.Theme')
local Rectangle = require('src.utils.Rectangle')

---@class RadioButton : Entity
local RadioButton = AbstractButton:extend()

function RadioButton:new(area, options)
    AbstractButton.new(self, area, options)
    self.isChecked = options.isChecked or false
    self.padding = options.padding or 0
    self.backgroundColor = self.isChecked and Theme.secondary:clone() or Theme.background:clone()
    self.tween = nil
    if self.image:type() == "Image" then
        self.scale = Vars.titleSize / self.image:getHeight()
    end
    if options.minWidth then
        local mWidth = self.image:getWidth() + self.padding * 2
        if mWidth < options.minWidth then
            self.padding = (options.minWidth - mWidth) / 2
        end
        self._width = options.minWidth
    else
        self._width = (options.width or self.image:getWidth() * (self.scale or 1)) + self.padding * 2
    end
    self.height = (self.image:getHeight() * (self.scale or 1)) + (self.padding * 2)
end

function RadioButton:width()
    return self._width
end

function RadioButton:uncheck()
    if not self.isChecked then return end
    self:toggle()
end

function RadioButton:check()
    if self.isChecked then return end
    self:toggle()
end

function RadioButton:toggle()
    if self.tween then self.timer:cancel(self.tween) end
    self.timer:tween(Vars.transition.tween, self, {backgroundColor = self.isChecked and Theme.background or Theme.secondary}, 'linear')
    self.isChecked = not self.isChecked
end

function RadioButton:boundingBox()
    return Rectangle(self.x, self.y, self._width, self.height)
end

function RadioButton:__tostring()
    return "RadioButton(" .. tostring(self.value) .. ")"
end

function RadioButton:onclick()
    TEsound.play(assets.sounds.click)
    if self.callback then self.callback(self) end
end

function RadioButton:draw()
    local bgColor = self.backgroundColor.rgb
    bgColor[#bgColor+1] = self.color.a
    love.graphics.setColor(bgColor)
    love.graphics.rectangle('fill', self.x, self.y, self._width, self.height)
    if self.framed then
        love.graphics.setColor(self.color)
        love.graphics.rectangle('line', self.x, self.y, self._width, self.height)
    end
    if self.image:type() ~= "Image" then
        love.graphics.setColor(self.color)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    if self.centerImage then
        local x = self.x + self._width / 2 - self.image:getWidth() / 2
        love.graphics.draw(self.image, x, self.y + self.padding)
    else
        love.graphics.draw(self.image, self.x + self.padding, self.y + self.padding, 0, self.scale, self.scale)
    end
end


return RadioButton
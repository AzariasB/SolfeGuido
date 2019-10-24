
-- LIBS
local ScreenManager = require('lib.ScreenManager')
local Config = require('src.utils.Config')
local ScoreManager = require('src.utils.ScoreManager')
local Color = require('src.utils.Color')
local Mobile = require('src.utils.Mobile')

-- Parent
local Scene = require('src.State')

-- Entities
local Measure = require('src.objects.Measure')
local Note = require('src.objects.Note')
local Queue = require('src.utils.Queue')
local StopWatch = require('src.objects.Stopwatch')
local Score = require('src.objects.Score')
local AnswerGiver = require('src.objects.AnswerGiver')


---@class PlayState : State
---@field public entities table
---@field public timer Timer
---@field public noteImage any
---@field private notes Queue
---@field private stopWatch StopWatch
---@field private points number
local PlayState = Scene:extend()

function PlayState:new()
    PlayState.super.new(self)
    self.progress = 0
    self.progressSpeed = assets.config.maxProgressSpeed
    self.notes = Queue()
    self:addMeasure()
    self.currentMeasure = 1
    self.stopWatch = self:addentity(StopWatch, {
        x = -assets.config.stopWatch.size,
        y = assets.config.stopWatch.y, size = assets.config.stopWatch.size,
        started = false,
        finishCallback = function()
            self:finish()
        end})

    local scoreText = love.graphics.newText(assets.MarckScript(assets.config.score.fontSize),"0")
    self.score = self:addentity(Score, {
        x = -scoreText:getWidth(),
        y = assets.config.score.y,
        points = 0,
        text =  scoreText,
        color = Color.transparent:clone()
    })
end

function PlayState:addMeasure()
    local btnSize = assets.config.mobileButton.fontSize + assets.config.mobileButton.padding * 2 + 20
    local availableSpace = love.graphics.getHeight() - (Config.answerType == 'buttons' and btnSize or 0)
    if Config.keySelect == 'gKey' then
        self.measures = {self:addentity(Measure, {
            keyData = assets.config.gKey,
            height = availableSpace
        })}
    elseif Config.keySelect == 'fKey' then
        self.measures = {self:addentity(Measure, {
            keyData = assets.config.fKey,
            height = availableSpace
        })}
    elseif Config.keySelect == 'both' then
        self.measures = {
            self:addentity(Measure, {
                keyData = assets.config.gKey,
                height = availableSpace / 2,
                y = 0
            }),
            self:addentity(Measure, {
                keyData = assets.config.fKey,
                height = availableSpace  / 2,
                y = availableSpace / 2
            })
        }
    else
        error("unknow key")
    end

end

function PlayState:init(...)
    local elements = {
        {element = self.stopWatch, target = {x = assets.config.stopWatch.x, color = {}}},
        {element = self.score, target = {x = assets.config.score.x, color = Color.black}}
    }

    self:addentity(AnswerGiver, {
        callback = function(x) self:answerGiven(x) end
    })

    self.finished = false
    self:transition(elements, function()
        self.stopWatch:start()
    end)
end

function PlayState:getMeasure()
    return self.measures[self.currentMeasure]
end

function PlayState:switchMeasure()
    if #self.measures == 1 then return end
    self.currentMeasure = 3 - self.currentMeasure
end

function PlayState:close()
    self.notes = nil
    self.measures = nil
    self.stopWatch = nil
    Scene.close(self)
end

---@return number
function PlayState:getBaseLine()
    return assets.config.baseLine + 5 * assets.config.lineHeight
end

function PlayState:finish()
    self.finished = true
    while not self.notes:isEmpty() do
        self.notes:shift():fadeAway()
    end
    self.timer:after(assets.config.note.fadeAway, function()
        ScoreManager.update(Config.keySelect, Config.difficulty, self.score.points)
        ScreenManager.push('EndGameState', self.score.points)
    end)
end

function PlayState:draw()
    love.graphics.push()

    love.graphics.setBackgroundColor(1,1,1)

    local width = Note.width(self:getMeasure())
    if not self.notes:isEmpty() then
        local x = self.notes:peek().x
        love.graphics.setColor(Color.stripe)
        love.graphics.rectangle('fill', x, self:getMeasure().y , width, self:getMeasure().height)
    end

    PlayState.super.draw(self)
    love.graphics.pop()

end

---@param key string
function PlayState:keypressed(key)
    Scene.keypressed(self, key)
    if key == "escape" then
        ScreenManager.push('PauseState')
        return
    end
end

function PlayState:answerGiven(idx)
    if self.notes:isEmpty() then return end
    local measure = self:getMeasure()
    local currentNote = self.notes:peek()
    TEsound.play(measure:getSoundFor(currentNote.note))
    if measure:isCorrect(currentNote.note, idx) then
        self.notes:shift():correct()
        self.score:gainPoint()
    else
        self.notes:shift():wrong()
        Mobile.vibrate(assets.config.mobile.vibrationTime)
        self.stopWatch:update(assets.config.timeLoss)
    end
    self:switchMeasure()
end

function PlayState:getMove()
    return self.progress
end

---Calculate the notes progression
---@param dt number
function PlayState:doProgress(dt)
    local first = self.notes:peek().x
    local normalProg = (dt * self.progressSpeed)
    local dist = first - self:getMeasure().limitLine
    if dist < 1  then
        self.progress = dist
    else
        self.progressSpeed = math.sqrt(dist) * 10
        self.progress = normalProg
    end
end

function PlayState:addNote()
    local note = self:getMeasure():getRandomNote()
    local ent = Scene.addentity(self, Note, {
        note = note,
        x = love.graphics.getWidth(),
        measure = self:getMeasure()
    })
    self.notes:push(ent)
end

--- Pops a note if needed
---@param dt number
function PlayState:tryPopNote(dt)
    if self.finished then return end
    if self.notes:isEmpty() then
        self:addNote()
    else
        local last = self.notes:last().x
        if love.graphics.getWidth() - last >= assets.config.note.distance then
            self:addNote()
        end
    end
end

--- Updates this state
---@param dt number
function PlayState:update(dt)
    if not self.active then return end
    Scene.update(self, dt)
    self:tryPopNote(dt)
    if self.notes:isEmpty() then return end
    self:doProgress(dt)
end

return PlayState
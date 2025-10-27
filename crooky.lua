local Textures = require("textures")

local Crooky = {}

local TALK_SPEED = 24

function Crooky:load()
    Textures.getTexture('crooky/eye', true)
    Textures.getTexture('crooky/eyes_0', true)
    Textures.getTexture('crooky/eyes_1', true)
    Textures.getTexture('crooky/eyes_2', true)
    Textures.getTexture('crooky/eyes_3', true)
    Textures.getTexture('crooky/eyes_4', true)
    Textures.getTexture('crooky/eyes_5', true)
    Textures.getTexture('crooky/eyes_6', true)
    Textures.getTexture('crooky/eyes_7', true)
    Textures.getTexture('crooky/mouth_0', true)
    Textures.getTexture('crooky/mouth_1', true)
    Textures.getTexture('crooky/mouth_2', true)
    Textures.getTexture('crooky/mouth_3', true)
    Textures.getTexture('crooky/pupils_0', true)
    Textures.getTexture('crooky/pupils_1', true)
    Textures.getTexture('crooky/pupils_2', true)
    Textures.getTexture('crooky/pupils_3', true)
    Textures.getTexture('crooky/body_back', true)
    Textures.getTexture('crooky/body_front', true)

    self.x = 1550
    self.y = 300

    self.movement = 'idle'

    self.visible = true

    self.spoken = 0
    self.waitToDissapear = 1
    self.nextWaitToDissapear = 1
    self.nextNextWaitToDissapear = 1

    self.text = 'this is a test please look look im so very cool and a lot of other things too, im so cool, look at me'
    self.nextText = 'oh my good look im so cool'
    self.nextNextText = ''

    self.textObj = love.graphics.newText(love.graphics.newFont(16))
    self.talkAnim = 0
    self.talking = true

    self.textW = 0
    self.textH = 0

    self.speechBubble = love.graphics.newMesh(54, 'triangles')
    self.speechBubble:setTexture(Textures.getTexture('crooky/speechBubble', false, true))

    self.timer = 0

    self.movements = {
        ['idle'] = {
            speed = 0.13,

            {
                55, 120, -- x, y
                2.2, 2.25, -- scalex, scaley
                0, -- eye 1 animation
                4, 15, -- eye 1 pos
                0, -- eye 2 animation
                11, 16, -- eye 2 pos
                0, -- pupil 1 animation
                2, 4, -- pupil 1 pos
                0, -- pupil 2 animation
                2, 4, -- pupil 2 pos
            },
            {
                55, 120,
                2.2, 2.2,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.15,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.2,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120, -- x, y
                2.2, 2.25, -- scalex, scaley
                0, -- eye 1 animation
                4, 15, -- eye 1 pos
                0, -- eye 2 animation
                11, 16, -- eye 2 pos
                0, -- pupil 1 animation
                2, 4, -- pupil 1 pos
                0, -- pupil 2 animation
                2, 4, -- pupil 2 pos
            },
            {
                55, 120,
                2.2, 2.2,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.15,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.2,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120, -- x, y
                2.2, 2.25, -- scalex, scaley
                0, -- eye 1 animation
                4, 15, -- eye 1 pos
                0, -- eye 2 animation
                11, 16, -- eye 2 pos
                0, -- pupil 1 animation
                2, 4, -- pupil 1 pos
                0, -- pupil 2 animation
                2, 4, -- pupil 2 pos
            },
            {
                55, 120,
                2.2, 2.2,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.15,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.2,
                0,
                4, 15,
                0,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120, -- x, y
                2.2, 2.25, -- scalex, scaley
                0, -- eye 1 animation
                4, 15, -- eye 1 pos
                0, -- eye 2 animation
                11, 16, -- eye 2 pos
                0, -- pupil 1 animation
                2, 4, -- pupil 1 pos
                0, -- pupil 2 animation
                2, 4, -- pupil 2 pos
            },
            {
                55, 120,
                2.2, 2.2,
                3,
                4, 15,
                3,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.15,
                7,
                4, 15,
                7,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            },
            {
                55, 120,
                2.2, 2.2,
                5,
                4, 15,
                5,
                11, 16,
                0,
                2, 4,
                0,
                2, 4,
            }
        }
    }

    self.tutorialPoints = {
        ['game'] = {
            ['open'] = {
                uses = 1,
                callFunc = function()
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble('Welcome!!', 1.5)
                end,
                animateFunc = function(time)
                    if Crooky.text == '' then
                        if time >= 5.6 then
                            Crooky:setSpeechBubble('To get started with destroying innocent lives you just have to open your "clicker" app.', 1)
                            Crooky:placeClickIcon(33, 4 * (30 + 18 + 20) + 18 + 25, 'left', 'double')
                            return true
                        else
                            Crooky:setSpeechBubble("I'm Crooky, your personal home computer and felony commiting assistant!", 1.2)
                        end
                    end
                end
            }
        },
        --[[['clicker'] = {
            ['open'] = {
                uses = 1,
                callFunc = function(mailButton)
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble('Click on the big mail button to send emails to people.\nPeople can respond with an application.', 1.5)
                    Crooky:addClickIcon(W95_CursorIndicator.newConnectedCursorIndicator(mailButton, nil, nil, 'up', 0, 'faster'))
                end,
                animateFunc = nil
            },
            ['applicant'] = {
                uses = 1,
                callFunc = function(filingCabinet)
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble("Oooh, you've gotten a reply.\nHover over the filing cabinet to view all of your applicants.", 2)
                    Crooky:addClickIcon(W95_CursorIndicator.newConnectedCursorIndicator(filingCabinet, nil, nil, 'down', 0, 'normal'))
                end,
                animateFunc = nil
            },
            ['cabinet hover'] = {
                neededName = 'clicker',
                neededInfo = 'applicant',
                neededUses = 0,
                uses = 1,
                callFunc = function()
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble('Now drag and drop the application onto the check mark to accept it.\rIf you drop it onto the X it will delete it.', 2.5)
                end,
                animateFunc = nil
            },
            ['accept'] = {
                uses = 1,
                callFunc = function(window)
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble("Congrats!! you've just gotten your first follower.\nNow to see them make you money, close the window.", 1.5)
                    Crooky:addClickIcon(W95_CursorIndicator.newConnectedCursorIndicator(window.closeButton, nil, nil, 'down', 0, 'normal'))
                end,
                animateFunc = nil
            },
            ['close'] = {
                uses = 1,
                callFunc = function()
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble('Now just open up your "tracker" app.', 1.5)
                    Crooky:placeClickIcon(33, 3 * (30 + 18 + 20) + 18 + 25, 'left', 'double')
                end,
                animateFunc = nil
            }
        },
        ['tracker'] = {
            ['open'] = {
                uses = 1,
                callFunc = function()
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble("Great! Every time the red bar fills up, your follower will make another 'investement' and put some sweet sweet cash in your pocket.", 3.2)
                end,
                animateFunc = nil
            },
            ['follower finish'] = {
                uses = 1,
                callFunc = function(poachButton)
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble("Oh no! Your follower has stopped giving you money, it looks like they're done investing.\nClick the 'Poach' button to stop responding to them, this will ensure you keep your money but can sometimes piss them off.", 4.1)
                    Crooky:addClickIcon(W95_CursorIndicator.newConnectedCursorIndicator(poachButton, nil, nil, 'up', 0, 'normal'))
                end,
                animateFunc = nil
            },
            ['poach'] = {
                uses = 1,
                callFunc = function()
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble("Great! now you got another slot for more followers; you can go back to the click app and accept more applicants.\nBe careful poaching followers though, do too many and they will report you to the police.", 3.6)
                end,
                animateFunc = nil
            },
            ['follower reported'] = {
                uses = 1,
                callFunc = function()
                    Crooky:setAnimation('idle')
                    Crooky:setSpeechBubble("It looks like one of your followers caught on to what you were doing and reported you, don't worry though, the worst that can happen is the police investigate you; find that you're commiting a heinous felony, and imprison you for the rest of your life.\nSo no biggie", 3.7)
                end,
                animateFunc = nil
            }
        }]]x
    }

    self.toAnimate = function() end
    self.toAnimateTimer = 0

    self.clickerIcons = {}

    local file = love.filesystem.newFile('savedata/save_1/crooky.txt')

    file:open('r')

    if not file:isOpen() then
        return
    end

    for line in file:lines() do
        if string.sub(line, 1,1) ~= '#' then
            local k1p = string.find(line, '|')
            local k2p = string.find(line, '|', k1p + 1)

            local k1 = string.sub(line, 1, k1p - 1)
            local k2 = string.sub(line, k1p + 1, k2p - 1)
            local amnt = tonumber(string.sub(line, k2p + 1, -1))

            self.tutorialPoints[k1][k2].uses = amnt
        end
    end
end

function Crooky:setVisible(visible)
    self.visible = visible
end

function Crooky:setAnimation(anim)
    self.movement = anim
end

function Crooky:setSpeechBubble(text, waitToDissapear, nextText, nextWaitToDissapear, nextNextText, nextNextWaitToDissapear)
    self.text = text
    self.spoken = 0
    self.waitToDissapear = waitToDissapear
    self.talking = true

    self.nextText = nextText or ''
    self.nextWaitToDissapear = nextWaitToDissapear or 0
    self.nextNextText = nextNextText or ''
    self.nextNextWaitToDissapear = nextNextWaitToDissapear or 0
end

function Crooky:placeClickIcon(x, y, clickDir, clickType, timeOffset)
    table.insert(self.clickerIcons, W95_CursorIndicator.newCursorIndicator(x, y, clickDir, timeOffset, clickType))
end
function Crooky:addClickIcon(clickIcon)
    table.insert(self.clickerIcons, clickIcon)
end
function Crooky:clearClickIcons()
    self.clickerIcons = {}
end

function Crooky:updateSpeechBubbleVerts()
    local x1 = -10
    local x2 = 0
    local x3 = self.textW
    local x4 = self.textW + 10

    local y1 = -5
    local y2 = 0
    local y3 = self.textH
    local y4 = self.textH + 15

    local verts = {
        {x1, y1, 0  , 0   }, {x1, y2, 0  , 0.25}, {x2, y2, 0.5, 0.25}, -- top left
        {x1, y1, 0  , 0   }, {x2, y1, 0.5, 0   }, {x2, y2, 0.5, 0.25},

        {x2, y1, 0.5, 0   }, {x2, y2, 0.5, 0.25}, {x3, y2, 0.5, 0.25}, -- top
        {x2, y1, 0.5, 0   }, {x3, y1, 0.5, 0   }, {x3, y2, 0.5, 0.25},

        {x3, y1, 0.5, 0   }, {x3, y2, 0.5, 0.25}, {x4, y2, 1  , 0.25}, -- top right
        {x3, y1, 0.5, 0   }, {x4, y1, 1  , 0   }, {x4, y2, 1  , 0.25},

        {x3, y2, 0.5, 0.25}, {x3, y3, 0.5, 0.25}, {x4, y3, 1  , 0.25}, -- right
        {x3, y2, 0.5, 0.25}, {x4, y2, 1  , 0.25}, {x4, y3, 1  , 0.25},

        {x3, y3, 0.5, 0.25}, {x3, y4, 0.5, 1   }, {x4, y4, 1  , 1   }, -- bottom right
        {x3, y3, 0.5, 0.25}, {x4, y3, 1  , 0.25}, {x4, y4, 1  , 1   },

        {x2, y3, 0.5, 0.25}, {x2, y4, 0.5, 1   }, {x3, y4, 0.5, 1   }, -- bottom
        {x2, y3, 0.5, 0.25}, {x3, y3, 0.5, 0.25}, {x3, y4, 0.5, 1   },

        {x1, y3, 0  , 0.25}, {x1, y4, 0  , 1   }, {x2, y4, 0.5, 1   }, -- bottom left
        {x1, y3, 0  , 0.25}, {x2, y3, 0.5, 0.25}, {x2, y4, 0.5, 1   },

        {x1, y2, 0  , 0.25}, {x1, y3, 0  , 0.25}, {x2, y3, 0.5, 0.25}, -- left
        {x1, y2, 0  , 0.25}, {x2, y2, 0.5, 0.25}, {x2, y3, 0.5, 0.25},

        {x2, y2, 0.5, 0.25}, {x2, y3, 0.5, 0.25}, {x3, y3, 0.5, 0.25}, -- center
        {x2, y2, 0.5, 0.25}, {x3, y2, 0.5, 0.25}, {x3, y3, 0.5, 0.25}
    }

    self.speechBubble:setVertices(verts)
end

function Crooky:giveInfo(programName, info, ...)
    local args = {...} -- this is for sending additional info to the individual points

    if      not self.tutorialPoints[programName]
        or  not self.tutorialPoints[programName][info]
        or  self.tutorialPoints[programName][info].uses == 0
    then
        return
    end

    local finalItem = self.tutorialPoints[programName][info]

    if finalItem.neededName and finalItem.neededInfo and finalItem.neededUses then
        if      self.tutorialPoints[finalItem.neededName]
            and self.tutorialPoints[finalItem.neededName][finalItem.neededInfo]
            and self.tutorialPoints[finalItem.neededName][finalItem.neededInfo].uses
        then
            if self.tutorialPoints[finalItem.neededName][finalItem.neededInfo].uses ~= finalItem.neededUses then
                return
            end
        end
    end

    self.clickerIcons = {}

    finalItem.uses = finalItem.uses - 1
    finalItem.callFunc(unpack(args))
    self.toAnimate = finalItem.animateFunc or function() end
    self.toAnimateTimer = 0
end

function Crooky:update(dt)
    if self.toAnimate(self.toAnimateTimer) then
        self.toAnimate = function() end
    end

    self.toAnimateTimer = self.toAnimateTimer + dt

    if not self.visible then
        return
    end

    for i, v in ipairs(self.clickerIcons) do
        v:update(dt)
    end

    self.timer = self.timer + dt

    if self.talking then
        self.spoken = self.spoken + TALK_SPEED * dt

        if self.spoken <= 4 or self.spoken >= string.len(self.text) - 3 then
            if self.spoken >= string.len(self.text) then
                self.talkAnim = 0
            else
                self.talkAnim = 1
            end
        else
            self.talkAnim = math.floor((self.spoken - 3) / 3) % 2 + 2
        end

        self.textObj:setf(string.sub(self.text, 1, math.floor(self.spoken)), 200, 'left')

        local pw = self.textW
        local ph = self.textH

        self.textW = self.textObj:getWidth() + 6
        self.textH = self.textObj:getHeight() + 6

        if self.textW > 185 then
            self.textW = 200
        end

        if self.textW ~= pw or self.textH ~= ph then
            self:updateSpeechBubbleVerts()
        end

        if self.spoken >= string.len(self.text) then
            if self.waitToDissapear <= 0 then
                if self.nextText ~= '' then
                    self.text = self.nextText
                    self.nextText = self.nextNextText

                    self.waitToDissapear = self.nextWaitToDissapear
                    self.nextWaitToDissapear = self.nextNextWaitToDissapear

                    self.spoken = 0
                else
                    self.talking = false
                    self.waitToDissapear = 0
                    self.text = ''
                    self.spoken = 0
                    self.textObj:setf('', 200, 'left')

                    local pw = self.textW
                    local ph = self.textH

                    self.textW = self.textObj:getWidth() + 6
                    self.textH = self.textObj:getHeight() + 6

                    if self.textW > 185 then
                        self.textW = 200
                    end

                    if self.textW ~= pw or self.textH ~= ph then
                        self:updateSpeechBubbleVerts()
                    end
                end
            end

            self.waitToDissapear = self.waitToDissapear - dt
        end
    end
end

function Crooky:draw()
    if not self.visible then
        return
    end

    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.draw(Textures.getTexture('crooky/background'), self.x, self.y)

    love.graphics.setColor(1,1,1)

    local cur = self.movements[self.movement]
    cur = cur[math.floor(self.timer / cur.speed) % #cur + 1]

    local tx = cur[1] + self.x
    local ty = cur[2] + self.y

    local w = cur[3]
    local h = cur[4]

    love.graphics.draw(Textures.getTexture('crooky/body_back'), tx + 9 * w, ty + 2 * h, 0, w,h, 10,64)

    love.graphics.draw(Textures.getTexture('crooky/eye'), tx + cur[6] * w, ty + cur[7] * h, 0, w,h, 10,64)
    love.graphics.draw(Textures.getTexture('crooky/eye'), tx + cur[9] * w, ty + cur[10] * h, 0, w,h, 10,64)

    love.graphics.draw(Textures.getTexture('crooky/pupils_' .. tostring(cur[11])), tx + (cur[12] + cur[6]) * w, ty + (cur[13] + cur[7]) * h, 0, w,h, 10,64)
    love.graphics.draw(Textures.getTexture('crooky/pupils_' .. tostring(cur[14])), tx + (cur[15] + cur[9]) * w, ty + (cur[16] + cur[10]) * h, 0, w,h, 10,64)

    love.graphics.draw(Textures.getTexture('crooky/eyes_' .. tostring(cur[5])), tx + cur[6] * w, ty + cur[7] * h, 0, w,h, 10,64)
    love.graphics.draw(Textures.getTexture('crooky/eyes_' .. tostring(cur[8])), tx + cur[9] * w, ty + cur[10] * h, 0, w,h, 10,64)

    love.graphics.draw(Textures.getTexture('crooky/mouth_' .. tostring(cur[17] or self.talkAnim)), tx + 3 * w, ty + 33 * h, 0, w,h, 10,64)

    love.graphics.draw(Textures.getTexture('crooky/body_front'), tx, ty, 0, w,h, 10,64)

    if self.talking then
        love.graphics.draw(self.speechBubble, self.x - self.textW + 3, self.y - self.textObj:getHeight() - 3)

        love.graphics.setColor(0,0,0)
        love.graphics.draw(self.textObj, self.x - self.textW + 6, self.y - self.textObj:getHeight())
        love.graphics.setColor(1,1,1)
    end

    for i, v in ipairs(self.clickerIcons) do
        v:draw()
    end
end

function Crooky:resetTutorialPoints()
    local file = love.filesystem.newFile('savedata/save_1/crooky.txt')
    file:open('w')
    file:write('#C\r\n')
    file:close()
end

function Crooky:quit()
    local file = love.filesystem.newFile('savedata/save_1/crooky.txt')

    file:open('w')

    file:write('#C\r\n') -- signify its crooky info

    for k1, v in pairs(self.tutorialPoints) do
        for k2, w in pairs(v) do
            file:write(k1 .. '|' .. k2 .. '|' .. tostring(w.uses) .. '\r\n')
        end
    end

    file:close()
end

return Crooky
local TutorialHelper = {};
TutorialHelper.__index = TutorialHelper;

function TutorialHelper.new()
    local instance = setmetatable({}, TutorialHelper);

    instance.tree = {}; -- linked list style based tree noding
    instance.currentNode = nil; -- pair to the tree

    instance.currentlySaying = ""; -- what is trying to be said
    instance.speechTimer = 0; -- how many seconds have ellapsed since the start of trying to speak
    instance.speechTimerMax = 0; -- maximum amount of seconds current speech will take
    instance.speaking = false;

    instance.intel = {};
    instance.fancyTextPointer = {}; -- not intel in order to prevent fancText from constantly updating when not needed
    instance.fancyText = FancyText.new("", 0, 0, 200, 24, "left", nil, instance.fancyTextPointer);

    instance.animations = {}; -- paired table of animations in the format of:
    -- { -- animation table
    --      pair = { -- animation
    --          [1] = texture; -- animations frame 1
    --          [2] = texture; -- animations frame 2 .etc
    --          framerate = 60; -- how many times does the frame change per second
    --          transition = pair; -- what animation to transition into (loop if nil)
    --      }
    -- }
    instance.animation = nil; -- pointer to the currently playing animation
    instance.animationFrame = 1; -- index of the current animation frame
    instance.animationTime = 0; -- amount of seconds the animation has been playing for

    instance.x = 0; -- position of the character
    instance.y = 0;

    instance.visible = true; -- if the character is visible

    return instance;
end

function TutorialHelper:addAnimation(name, frames, framerate, transition)
    if transition and not self.animations[transition] then
        print("tried to transition to animation that does not exist yet: " .. transition);
    end

    frames.framerate  = framerate  or 60;
    frames.transition = transition or nil; -- for clarity
    self.animations[name] = frames;
end

function TutorialHelper:setVisibility(visible)
    self.visible = visible;
end

function TutorialHelper:setAnimation(animation)
    assert(self.animations[animation], "tried to set animation to animation that does not exist: " .. animation);

    self.animation = self.animations[animation];
    self.animationFrame = 1; -- restart animation
    self.animationTime = 0; -- restart animation
end

function TutorialHelper:addConnection(from, to, ...)
    local args = {...};

    assert(self.tree[from], "tried to create a connection from a node that does not exist: " .. from);
    assert(self.tree[to], "tried to create a connection to a node that does not exist: " .. to);
    assert(self.tree[from].connections[to] == nil, "tried to add a connection that already existed: ".. from .. " to " .. to);

    self.tree[from].connections[to] = args;
end

function TutorialHelper:addNode(nodeName, text, textLength)
    assert(self.tree[nodeName], "tried to create a node that already exist: " .. nodeName);

    local node = {
        text = text;
        textLength = textLength or string.len(text) / 60;
        connections = {};
    };

    self.tree[nodeName] = node;
end

function TutorialHelper:setNode(name)
    assert(self.tree[name], "tried to set current node to node that does not exist: " .. name);

    self.currentNode = name;
    self.speaking = true;
    self.speechTimer = 0;
    self.speechTimerMax = self.tree[self.currentNode].textLength;

    self.fancyText:setText("");
end

function TutorialHelper:setPosition(x, y)
    self.x = x;
    self.y = y;

    --! magic numbers
    self.fancyText:setPosition(x - 240, y - 50);
end

function TutorialHelper:update(dt)
    -- update animation
    if self.animation then
        self.animationTime = self.animationTime + dt;

        self.animationFrame = math.floor(self.animationTime / self.animation.framerate);

        if self.animation.transition and self.animationFrame >= #self.animation then
            self:setAnimation(self.animation.transition);
        end

        self.animationFrame = self.animationFrame % #self.animation + 1;
    end

    -- update speech bubble
    if self.speaking then
        self.speechTimer = self.speechTimer + dt;

        local perun = self.speechTimer / self.speechTimerMax;
        local text = self.tree[self.currentNode].text;
        text = string.sub(text, 1, math.min(math.floor(string.len(text) * perun), string.len(text)));

        if self.speechTimer >= self.speechTimerMax then -- text bubble is filled out
            self.speaking = false;
        end

        self.fancyText:setText(text);

        return;
    end

    -- try to find next text to say
    for connect, connection in pairs(self.tree[self.currentNode].connections) do
        local connects = true;

        for i, v in ipairs(connection) do
            if type(v) == "function" then
                if not v(self.intel) then
                    connects = false;
                    break;
                end
            elseif type(v) == "string" then
                local pair, operation, compare = string.match(v, "^([^=<>~]+)([=<>~]+)(.+)$");

                assert(pair and operation and compare, "tried to use an invalid expression in a connection: " .. v);
                assert(self.intel[pair], "tried to use an invalid intel pair for connection: " .. pair);

                pair = self.intel[pair];
                compare = tonumber(compare) or self.intel[compare] or compare;

                local pass = false;

                if operation == "==" or operation == "=" then
                    pass = pair == compare;
                elseif operation == "<" then
                    pass = pair < compare;
                elseif operation == "<=" then
                    pass = pair <= compare;
                elseif operation == ">" then
                    pass = pair > compare;
                elseif operation == ">=" then
                    pass = pair >= compare;
                elseif operation == "~=" or operation == "~" then
                    pass = not pair == compare;
                end

                if not pass then
                    connects = false;
                    break;
                end
            else
                error("tried to connect with a comparison that is not a function or a comparative string");
            end
        end

        if connects then
            self:setNode(connect);
        end
    end
end

function TutorialHelper:createInfo(name, default)
    assert(self.intel[name] == nil, "tried to create a value that already exists: " .. name);

    self.intel[name] = default;
end

function TutorialHelper:sendInfo(name, value)
    assert(self.intel[name] ~= nil, "tried to set value that does not exist: " .. name);

    self.intel[name] = value;
end

function TutorialHelper:draw()
    love.graphics.setColor(1,1,1); -- white

    if self.animation then
        love.graphics.draw(self.animation[self.animationFrame], self.x, self.y);
    end

    self.fancyText:draw();
end

return TutorialHelper;
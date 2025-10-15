local path = string.match((...), "(.+[./]).-[./]") or "";

local Textinput = Component.new();
Textinput.__index = Textinput;

Textinput._trigger = "isEntered";

Textinput.texture = love.graphics.newImage(path .. "textures/textinput.png");
Textinput.texture:setFilter("nearest", "nearest");

Textinput.edgeScale = 3;
Textinput.blinkTimerMax = 0.5;

--Textinput.font = love.graphics.newFont("SpaceMono.ttf", 128);

function Textinput.new(x, y, w, h)
    local instance = setmetatable(Component.new(), Textinput);

    instance.box = instance:addBoundingBox(x, y, w, h);
    instance.isActive = false;

    instance.x = x;
    instance.y = y;
    instance.w = w;
    instance.h = h;

    instance.text = "";

    instance.entered = 0;

    instance.blink = false;
    instance.blinkTimer = 0;

    local x1 = x;
    local x2 = x + 5 * Textinput.edgeScale;
    local x3 = x + w - 5 * Textinput.edgeScale;
    local x4 = x + w;
    local y1 = y;
    local y2 = y + 5 * Textinput.edgeScale;
    local y3 = y + h - 5 * Textinput.edgeScale;
    local y4 = y + h;

    local meshVertices = {
        {x1,y1, 0  ,0  };
        {x1,y2, 0  ,0.5};
        {x2,y1, 0.5,0  };
        {x2,y1, 0.5,0  };
        {x1,y2, 0  ,0.5};
        {x2,y2, 0.5,0.5};

        {x2,y1, 0.5,0  };
        {x2,y2, 0.5,0.5};
        {x3,y1, 0.5,0  };
        {x3,y1, 0.5,0  };
        {x2,y2, 0.5,0.5};
        {x3,y2, 0.5,0.5};

        {x3,y1, 0.5,0  };
        {x3,y2, 0.5,0.5};
        {x4,y1, 1  ,0  };
        {x4,y1, 1  ,0  };
        {x3,y2, 0.5,0.5};
        {x4,y2, 1  ,0.5};

        {x3,y2, 0.5,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y2, 1  ,0.5};
        {x4,y2, 1  ,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y3, 1  ,0.5};

        {x3,y3, 0.5,0.5};
        {x3,y4, 0.5,1  };
        {x4,y3, 1  ,0.5};
        {x4,y3, 1  ,0.5};
        {x3,y4, 0.5,1  };
        {x4,y4, 1  ,1  };

        {x1,y3, 0  ,0.5};
        {x1,y4, 0  ,1  };
        {x2,y3, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x1,y4, 0  ,1  };
        {x2,y4, 0.5,1  };

        {x2,y3, 0.5,0.5};
        {x2,y4, 0.5,1  };
        {x3,y3, 0.5,0.5};
        {x3,y3, 0.5,0.5};
        {x2,y4, 0.5,1  };
        {x3,y4, 0.5,1  };

        {x1,y2, 0  ,0.5};
        {x1,y3, 0  ,0.5};
        {x2,y2, 0.5,0.5};
        {x2,y2, 0.5,0.5};
        {x1,y3, 0  ,0.5};
        {x2,y3, 0.5,0.5};

        {x2,y2, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x3,y2, 0.5,0.5};
        {x3,y2, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x3,y3, 0.5,0.5};
    };

    instance.mesh = love.graphics.newMesh(meshVertices, "triangles", "static");
    instance.mesh:setTexture(Textinput.texture);

    return instance;
end

function Textinput:unFocus()
    if self.active then
        self.entered = 2;
    end

    self.active = false;
    self.blink = false;
    self.blinkTimer = 0;
end

function Textinput:onPress(x, y)
    if self.box:isPointInside(x, y) then
        self.active = true;

        self.blinkTimer = self.blinkTimerMax;
        self.blink = true;
    else
        if self.active then
            self.entered = 2;
        end

        self.active = false;
        self.blink = false;
        self.blinkTimer = 0;
    end
end

function Textinput:onTextInput(text)
    if not self.active then
        return;
    end

    self.text = self.text .. text;
end

function Textinput:onKeypress(key)
    if not self.active then
        return;
    end

    if key == "backspace" then
        self.text = string.sub(self.text, 1, -2);
    elseif key == "return" then
        self.entered = 2;
        self.active = false;
        self.blink = false;
        self.blinkTimer = 0;
    end
end

function Textinput:isEntered()
    return self.entered ~= 0;
end

function Textinput:getText()
    return self.text;
end

function Textinput:setText(text)
    self.text = text;
end

function Textinput:update(dt)
    if self:isEntered() then
        self.entered = self.entered - 1;
    end

    if self.active then
        self.blinkTimer = self.blinkTimer - dt;

        if self.blinkTimer <= 0 then
            self.blinkTimer = self.blinkTimer % self.blinkTimerMax;
            self.blink = not self.blink;
        end
    end
end

function Textinput:draw()
    love.graphics.setColor(1,0,0);
    love.graphics.draw(self.mesh);

    love.graphics.setColor(1,1,1);

    love.graphics.setFont(PIXEL_FONT_128);

    local curText = self.text;

    local scale = (self.h - 3 * self.edgeScale) / PIXEL_FONT_HEIGHT;
    local maxWidth = self.w - 6 * self.edgeScale;

    -- this is to make sure that you can see what youre writing if the text is longer than the textinput box
    if PIXEL_FONT_128:getWidth(curText .. "_") * scale > maxWidth then
        if self.active then
            local newText = "";

            for char in string.gmatch(string.reverse(curText), ".") do
                if PIXEL_FONT_128:getWidth(".." .. char .. newText .. "_") * scale > maxWidth then
                    break;
                end

                newText = char .. newText;
            end

            curText = ".." .. newText;
        else
            local newText = "";

            for char in string.gmatch(curText, ".") do
                if PIXEL_FONT_128:getWidth(newText .. char .. "..") * scale > maxWidth then
                    break;
                end

                newText = newText .. char;
            end

            curText = newText .. "..";
        end
    end

    -- add blinking cursor to show when textinput is being edited
    if self.blink then
        curText = curText .. "_";
    end

    love.graphics.print(curText, self.x + self.edgeScale * 3, self.y + 1 * self.edgeScale, 0, scale);
end

return Textinput;
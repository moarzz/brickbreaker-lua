local FancyText = {};
FancyText.__index = FancyText;

FancyText.font = PIXEL_FONT_128;--love.graphics.newFont("SpaceMono.ttf", 128);
FancyText.fontHeight = FancyText.font:getHeight();

FancyText.defaultFont = PIXEL_FONT_128;

FancyText.DEFAULT_COLOURS = {
    ["red"] = {1,0,0};
    ["green"] = {0,1,0};
    ["blue"] = {0,0,1};
    ["cyan"] = {0,1,1};
    ["magenta"] = {1,0,1};
    ["yellow"] = {1,1,0};
    ["white"] = {1,1,1};
    ["black"] = {0,0,0};
    ["pink"] = {1,0,0.5};
    ["orange"] = {1,0.5,0};
    ["purple"] = {0.5,0,1};
    ["white_"] = {0.9,0.9,0.9};
    ["black_"] = {0.1,0.1,0.1};
    ["gray"] = {0.5,0.5,0.5};
    ["grey"] = {0.5,0.5,0.5};
    ["clear"] = {1,1,1,0};
    -- for easier usage. <highlight=off> / <highlight=none> looks more like its being disabled than <highlight=clear>
    ["none"] = {1,1,1,0};
    ["off"] = {1,1,1,0};
};

function FancyText.new(text, x, y, width, textHeight, alignment, font, dataReference)
    local instance = setmetatable({}, FancyText);

    instance.x = x;
    instance.y = y;

    instance.textHeight = textHeight or 20;

    instance.width = width;
    instance.alignment = alignment or "left";

    instance.text = text;
    instance.lines = nil; -- gets redefined in FancyText:alignText()

    instance.pointer = dataReference or {};

    instance.font = font or FancyText.defaultFont;
    instance.fontHeight = font and font:getHeight() or FancyText.fontHeight;

    instance.highlighterEdge = 5;

    instance.height = 0; -- needs to be calculated

    instance:alignText();

    return instance;
end

-- changes the radius of the highlighter corners
function FancyText:setHighLighterEdge(newEdge)
    self.highlighterEdge = newEdge;
end

function FancyText:setPosition(x, y)
    self.x = x;
    self.y = y;
end

function FancyText:setText(text)
    self.text = text;

    self:alignText();
end

function FancyText:setPointer(pointer)
    self.pointer = pointer;

    self:alignText();
end

function FancyText:update()
    self:alignText();
end

function FancyText:alignText()
    local realText = self.text;
    realText = string.gsub(realText, "%b<>",
        function(strToReplace)
            -- check if it is changing a graphical component
            if string.find(strToReplace, "=") then
                return nil; -- dont alter the string (yet)
            else -- otherwise its a key to the pointer table
                return tostring(self.pointer[string.sub(strToReplace,2,-2)]);
            end
        end
    );

    local specialCharacter = nil;
    -- find a character that is not being used in the text. this will be used to mark when modifiers are changed
    for i = 0, 255 do
        local specialChar = string.char(i);

        -- look to see if character is absent from text (if so then it is usable as a marking character)
        if not string.find(realText, specialChar, 1, true) then
            specialCharacter = specialChar;

            break;
        end
    end

    assert(specialCharacter ~= nil, "fancyText was unable to find a special character to use in a given string (this means that every possible byte value of a character is present in the text wanted to be displayed)");

    local graphicalChanges = {};

    realText = string.gsub(realText, "%b<>",
        function(strToReplace)
            table.insert(graphicalChanges, string.sub(strToReplace,2,-2));

            return specialCharacter;
        end
    );

    local lineHeight = 0;
    local lineWidth = 0;
    local scale = self.textHeight / self.fontHeight;

    self.lines = {}; -- empty the table
    self.height = 0; -- reset height to be calculated again

    local curLine = "";
    local curAddLine = {};

    local curFont = self.font; -- what the current font is while printing

    while string.len(realText) > 0 do
        local tillNextSpace, rest = string.match(realText, "^([^%s\n]*[%s\n])(.*)$"); -- get the text up to the next space and split it there

        -- if there is not any spaces left in the text then just split it at the end of the text
        if not tillNextSpace then
            tillNextSpace = realText;
            realText = "";
        else
            realText = rest or "";
        end

        local tempAddLine = {};

        local widthOfStr = 0; -- start remembering the width of this line

        local parsedText = ""; -- if we change the font then we need to store the previously calculated text

        -- while there are graphical changes in the string up till the next space
        while string.find(tillNextSpace, specialCharacter, 1, true) do -- final arg is true 2 prevent 'specialCharacter' from accidentally performing a regex
            local modif = table.remove(graphicalChanges, 1);

            local ind = string.find(tillNextSpace, specialCharacter, 1, true); -- get the amount of characters b4 the graphical change

            -- if the graphical change we just found is a font change then we need to alter the calculation for the width of the line
            if string.find(modif, "^font=.*$") then
                local previousFontText = string.sub(tillNextSpace, 0, ind - 1);

                widthOfStr = widthOfStr + curFont:getWidth(previousFontText) * scale; -- add the width of the previous text to the width of the current line

                curFont = self.pointer[(string.match(modif, "^font=(.*)$"))];

                if not curFont then
                    if (string.match(modif, "^font=(.*)$")) == "default" then
                        curFont = self.font;
                    end
                end

                assert(curFont and curFont:type() == "Font", "tried to set font to a non font object");

                parsedText = parsedText .. previousFontText;
                tillNextSpace = string.sub(tillNextSpace, ind + 1,-1); -- remove the graphical change from the text
            else -- if the graphical change is not a font change then dont alter anything
                tillNextSpace = string.sub(tillNextSpace, 0, ind - 1) .. string.sub(tillNextSpace, ind + 1,-1); -- remove the graphical change from the text
            end

            table.insert(tempAddLine, {charStart = ind, modificationName = string.match(modif, "^[^=]*"), setTo = string.match(modif, "[^=]*$")});
        end

        widthOfStr = widthOfStr + curFont:getWidth(string.match(tillNextSpace, "^[^%s\n]*")) * scale; -- remove space for measurement

        tillNextSpace = parsedText .. tillNextSpace; -- add previously parsed text after we calculated the width of the non-parsed text

        -- check if this string can be added to the current line, or if it will overflow the provided width
        if lineWidth + widthOfStr > self.width then
            -- add the current line to the list of lines
            curAddLine.text = (string.match(curLine, "^(.*)[%s\n]$")) or curLine;
            curAddLine.width = lineWidth;
            curAddLine.height = lineHeight;
            table.insert(self.lines, curAddLine);
            curAddLine = {};

            -- add this string to the next line
            for _, v in ipairs(tempAddLine) do
                table.insert(curAddLine, v);
            end

            curLine = tillNextSpace;
            lineWidth = widthOfStr + curFont:getWidth(string.sub(tillNextSpace, -1,-1)) * scale;
            lineHeight = curFont:getHeight() * scale;
        else
            for _, v in ipairs(tempAddLine) do
                v.charStart = v.charStart + string.len(curLine);
                table.insert(curAddLine, v);
            end

            curLine = curLine .. tillNextSpace;
            lineWidth = lineWidth + widthOfStr + curFont:getWidth(string.sub(tillNextSpace, -1,-1)) * scale;
            lineHeight = math.max(lineHeight, curFont:getHeight() * scale);
        end

        -- check if line ended with a line break
        if string.find(tillNextSpace, "\n") then
            curAddLine.text = (string.match(curLine, "^(.*)[%s\n]$")) or curLine;
            curAddLine.width = lineWidth - curFont:getWidth(string.sub(tillNextSpace, -1,-1)) * scale;
            curAddLine.height = lineHeight;
            table.insert(self.lines, curAddLine);
            curAddLine = {};

            curLine = "";
            lineWidth = 0;
            lineHeight = 0;
        end
    end

    curAddLine.text = (string.match(curLine, "^(.*)[ \n]$")) or curLine;
    curAddLine.width = lineWidth;
    curAddLine.height = lineHeight;
    table.insert(self.lines, curAddLine);
end

function FancyText:getHeight()
    local height = 0;

    for _, v in ipairs(self.lines) do
        height = height + v.height;
    end

    return height;
end

function FancyText:getWidth()
    local longest = self.lines[1].width;

    for i = 2, #self.lines do
        longest = math.max(self.lines[i].width, longest);
    end

    return longest;
end

function FancyText:draw()
    local colour = self.DEFAULT_COLOURS.black;
    local highlight = self.DEFAULT_COLOURS.clear;

    local scale = self.textHeight / self.fontHeight;

    love.graphics.push();
    love.graphics.translate(self.x, self.y);
    love.graphics.setFont(self.font);

    local curFont = self.font; -- what the current font is while printing
    local y = 0;

    -- has some bad coding practices but is very hard to fix without creating unecessary public functions
    -- or extremely inefficient local functions that are created and destroyed every draw call
    for _, v in ipairs(self.lines) do
        local x;

        if self.alignment == "left" then
            x = 0;
        elseif self.alignment == "middle" or self.alignment == "center" then
            x = (self.width - v.width) / 2;
        elseif self.alignment == "right" then
            x = self.width - v.width;
        else
            x = 0;
        end

        -- if there are any graphical changes inside of this line
        if #v > 0 then
            local alreadyDrawn = 1;

            for _, w in ipairs(v) do
                local toDraw = string.sub(v.text, alreadyDrawn, w.charStart - 1);
                alreadyDrawn = w.charStart;

                if highlight[4] ~= 0 then -- if alpha of the colour is not 0 then draw the highlight
                    love.graphics.setColor(highlight);
                    love.graphics.rectangle("fill", x - 2, y + v.height - curFont:getHeight() * scale, curFont:getWidth(toDraw) * scale + 4, curFont:getHeight() * scale, self.highlighterEdge);
                end

                love.graphics.setColor(colour);
                love.graphics.print(toDraw, x, y + v.height - curFont:getHeight() * scale, 0, scale,scale);

                x = x + curFont:getWidth(toDraw) * scale;

                if w.modificationName == "colour" or w.modificationName == "color" then
                    colour = self.DEFAULT_COLOURS[w.setTo];
                elseif w.modificationName == "highlight" then
                    highlight = self.DEFAULT_COLOURS[w.setTo];
                elseif w.modificationName == "font" then
                    curFont = self.pointer[w.setTo];

                    if not curFont then
                        if w.setTo == "default" then
                            curFont = self.font;
                        end
                    end

                    love.graphics.setFont(curFont);
                end
            end

            local toDraw = string.sub(v.text, alreadyDrawn, -1);

            if highlight[4] ~= 0 then -- if alpha of the colour is not 0 then draw the highlight
                love.graphics.setColor(highlight);
                love.graphics.rectangle("fill", x - 2, y + v.height - curFont:getHeight() * scale, curFont:getWidth(toDraw) * scale + 4, curFont:getHeight() * scale, self.highlighterEdge);
            end

            love.graphics.setColor(colour);
            love.graphics.print(toDraw, x, y + v.height - curFont:getHeight() * scale, 0, scale,scale);
        else -- if there are ZERO graphical changes in this line
            if highlight[4] ~= 0 then -- if alpha of the colour is not 0 then draw the highlight
                love.graphics.setColor(highlight);
                love.graphics.rectangle("fill", x - 2, y, v.width + 4, v.height, self.highlighterEdge);
            end

            love.graphics.setColor(colour);
            love.graphics.print(v.text, x, y, 0, scale,scale);
        end

        y = y + v.height; -- move the next line downwards by the height of this line
    end

    love.graphics.pop();
end

return FancyText;

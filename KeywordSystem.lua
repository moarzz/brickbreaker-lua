-- KeywordSystem.lua
local KeywordSystem = {}
KeywordSystem.__index = KeywordSystem

function KeywordSystem.new()
    local self = setmetatable({}, KeywordSystem)
    
    -- Keyword definitions
    self.keywords = {
        ["Spear"] = {
            image = nil, -- Will be loaded later
            description = "A sharp blade used for combat.\nDeals 10-15 damage.",
            width = 24,
            height = 24
        },
        ["potion"] = {
            image = nil,
            description = "A magical healing elixir.\nRestores 50 HP when consumed.",
            width = 20,
            height = 28
        },
        ["gold"] = {
            image = nil,
            description = "Precious currency.\nUsed for trading and upgrades.",
            width = 22,
            height = 22
        }
    }
    
    -- Tooltip state
    self.tooltip = {
        visible = false,
        text = "",
        x = 0,
        y = 0,
        width = 0,
        height = 0
    }
    
    -- Font for tooltip
    self.tooltipFont = love.graphics.newFont(12)
    self.tooltipPadding = 8
    
    -- Mouse state
    self.mouseX = 0
    self.mouseY = 0
    
    return self
end

function KeywordSystem:loadKeywordImages()
    -- Create simple colored rectangles as placeholder images
    -- In a real game, you'd load actual images here
    for name, keyword in pairs(self.keywords) do
        -- Create canvas with explicit format for better compatibility
        local canvas = love.graphics.newCanvas(keyword.width, keyword.height)
        
        -- Store current graphics state
        local currentCanvas = love.graphics.getCanvas()
        local r, g, b, a = love.graphics.getColor()
        
        -- Set canvas and clear it
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0) -- Clear to transparent
        
        -- Draw colored rectangle based on keyword
        if name == "Spear" then
            love.graphics.setColor(0.5, 0.7, 1, 1) -- Bright blue
        elseif name == "potion" then
            love.graphics.setColor(1, 0.2, 0.2, 1) -- Bright red
        elseif name == "gold" then
            love.graphics.setColor(1, 0.8, 0, 1) -- Bright gold
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Default gray
        end
        
        -- Fill the rectangle
        love.graphics.rectangle("fill", 0, 0, keyword.width, keyword.height)
        
        -- Add a black border for definition
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", 0, 0, keyword.width - 1, keyword.height - 1)
        
        -- Restore graphics state
        love.graphics.setCanvas(currentCanvas)
        love.graphics.setColor(r, g, b, a)
        
        -- Store the canvas as the keyword image
        keyword.image = canvas
    end
end

function KeywordSystem:parseText(text)
    -- Parse text and return segments with their types and positions
    local segments = {}
    local currentPos = 1
    
    while currentPos <= #text do
        local keywordStart, keywordEnd = string.find(text, "%[\"[^\"]+\"%]", currentPos)
        
        if keywordStart then
            -- Add text before keyword
            if keywordStart > currentPos then
                table.insert(segments, {
                    type = "text",
                    content = string.sub(text, currentPos, keywordStart - 1)
                })
            end
            
            -- Extract keyword name
            local keywordMatch = string.sub(text, keywordStart, keywordEnd)
            local keywordName = string.match(keywordMatch, "%[\"([^\"]+)\"%]")
            
            -- Add keyword segment
            table.insert(segments, {
                type = "keyword",
                name = keywordName,
                content = keywordMatch
            })
            
            currentPos = keywordEnd + 1
        else
            -- Add remaining text
            table.insert(segments, {
                type = "text",
                content = string.sub(text, currentPos)
            })
            break
        end
    end
    
    return segments
end

function KeywordSystem:calculateTooltipSize(text)
    local font = self.tooltipFont
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    local maxWidth = 0
    for _, line in ipairs(lines) do
        local width = font:getWidth(line)
        if width > maxWidth then
            maxWidth = width
        end
    end
    
    local height = font:getHeight() * #lines
    return maxWidth + self.tooltipPadding * 2, height + self.tooltipPadding * 2
end

function KeywordSystem:update(dt)
    self.mouseX = love.mouse.getX()
    self.mouseY = love.mouse.getY()
end

function KeywordSystem:drawText(text, x, y, font)
    font = font or love.graphics.getFont()
    local segments = self:parseText(text)
    local currentX = x
    local currentY = y
    local lineHeight = font:getHeight()
    
    love.graphics.setFont(font)
    
    -- First pass: draw everything and collect keyword positions
    local keywordRects = {}
    
    for _, segment in ipairs(segments) do
        if segment.type == "text" then
            -- Draw regular text
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(segment.content, currentX, currentY)
            currentX = currentX + font:getWidth(segment.content)
        elseif segment.type == "keyword" then
            local keyword = self.keywords[segment.name]
            if keyword and keyword.image then
                -- Draw keyword image
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(keyword.image, currentX, currentY)
                love.graphics.rectangle("line", currentX, currentY, keyword.width, keyword.height)
                
                -- Store keyword rectangle for hover detection
                table.insert(keywordRects, {
                    x = currentX,
                    y = currentY,
                    width = keyword.width,
                    height = keyword.height,
                    keyword = keyword
                })
                
                currentX = currentX + keyword.width
            else
                -- Fallback: draw original text if keyword not found
                love.graphics.setColor(1, 0.5, 0.5, 1) -- Red tint for missing keywords
                love.graphics.print(segment.content, currentX, currentY)
                currentX = currentX + font:getWidth(segment.content)
            end
        end
    end
    
    -- Second pass: check for hover on any keyword
    for _, rect in ipairs(keywordRects) do
        if self.mouseX >= rect.x and self.mouseX <= rect.x + rect.width and
           self.mouseY >= rect.y and self.mouseY <= rect.y + rect.height then
            -- Show tooltip for this keyword
            self.tooltip.visible = true
            self.tooltip.text = rect.keyword.description
            self.tooltip.x = self.mouseX + 10
            self.tooltip.y = self.mouseY - 10
            self.tooltip.width, self.tooltip.height = self:calculateTooltipSize(rect.keyword.description)
            
            -- Adjust tooltip position to stay on screen
            if self.tooltip.x + self.tooltip.width > love.graphics.getWidth() then
                self.tooltip.x = self.mouseX - self.tooltip.width - 10
            end
            if self.tooltip.y < 0 then
                self.tooltip.y = self.mouseY + 20
            end
            
            break -- Only show one tooltip at a time
        end
    end
end

function KeywordSystem:drawTooltip()
    if not self.tooltip.visible then return end
    
    -- Draw tooltip background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", self.tooltip.x, self.tooltip.y, 
                           self.tooltip.width, self.tooltip.height)
    
    -- Draw tooltip border
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle("line", self.tooltip.x, self.tooltip.y, 
                           self.tooltip.width, self.tooltip.height)
    
    -- Draw tooltip text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.tooltipFont)
    
    local textX = self.tooltip.x + self.tooltipPadding
    local textY = self.tooltip.y + self.tooltipPadding
    local lineHeight = self.tooltipFont:getHeight()
    
    for line in self.tooltip.text:gmatch("[^\n]+") do
        love.graphics.print(line, textX, textY)
        textY = textY + lineHeight
    end
end

function KeywordSystem:resetTooltip()
    self.tooltip.visible = false
end

return KeywordSystem
local suit = require("Libraries.Suit")
local permanentUpgrades = {}

-- Add dress at the top of the file
local dress = suit.new()

local data = loadGameData()

local invisButtonColor = {
    normal  = {bg = {0,0,0,0}, fg = {1,1,1}},           -- invisible bg, black fg
    hovered = {bg = {0.19,0.6,0.73,0.2}, fg = {1,1,1}}, -- glowing bg, white fg
    active  = {bg = {1,0.6,0}, fg = {1,1,1}}          -- faint bg, white fg
}

-- List of all permanent upgrades
local upgrades = data.upgrades and {
    speed = data.upgrades.speed or 0,
    damage = data.upgrades.damage or 0,
    cooldown = data.upgrades.cooldown or 0,
    fireRate = data.upgrades.fireRate or 0,
    ammo = data.upgrades.ammo or 0,
    range = data.upgrades.range or 0,
    amount = data.upgrades.amount or 0,
    --paddleSize = data.upgrades.paddleSize or 0,
    health = data.upgrades.health or 0,
} or {
    speed = 0,
    damage = 0,
    cooldown = 0,
    fireRate = 0,
    ammo = 0,
    range = 0,
    amount = 0,
    --paddleSize = 0,
}

local bonusPriceDefaults = {
    moneyBonus = 100,
    damageBonus = 150,
    speedBonus = 200,
    healthBonus = 250,
    extraBallBonus = 300,
    criticalBonus = 400
}

-- Helper function to format numbers
local function formatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

local function startingItemsDraw()
    -- === Unlockable Starting Items Menu ===
    local menuX = screenWidth - 300
    local menuY = 110
    local menuWidth = 275
    local buttonHeight = 130
    local buttonSpacing = 35
    setFont(32)
    suit.Label("Unlock Starting Items", {align = "center"}, menuX - menuWidth, menuY, menuWidth*2, 40)
    menuX = menuX - menuWidth/2*2  -- Center the label
    menuY = menuY + 80  -- Adjust Y position for the label

    local unlockables = {
        {name = "Machine Gun", label = "Machine Gun", key = "Machine Gun", price = 100},
        -- {name = "Laser Beam", label = "Laser Beam", key = "Laser Beam", price = 250},
        --{name = "Shadow Ball", label = "Shadow Ball", key = "Shadow Ball", price = 500}
    }
    Player.unlockedStartingBalls = Player.unlockedStartingBalls or {}
    local itemsPerCol = 5
    local total = #unlockables
    local colWidth = menuWidth + 20
    local rowHeight = buttonHeight + buttonSpacing
    for i, item in ipairs(unlockables) do
        local col = math.floor((i-1) / itemsPerCol)
        local row = (i-1) % itemsPerCol
        local x = menuX + col * colWidth + menuWidth/2 -- colWidth/2
        local y = menuY + row * rowHeight
        local unlocked = Player.unlockedStartingBalls[item.key]
        local affordable = Player.gold >= item.price
        local color = {0.35,0.35,0.35,0.5}
        local buttonID = generateNextButtonID()
        local label = unlocked and (item.label .. " (Unlocked)") or (item.label)
        local buttonColor = {
            normal = {bg = color, fg = {1,1,1}},
            hovered = {bg = {math.min(color[1]+0.2,1), math.min(color[2]+0.2,1), math.min(color[3]+0.2,1), 1}, fg = {1,1,1}},
            active = {bg = {math.max(color[1]-0.2,0), math.max(color[2]-0.2,0), math.max(color[3]-0.2,0), 1}, fg = {1,1,1}}
        }
        if not unlocked then
            if suit.Button(label, {color = buttonColor, id = buttonID}, x, y, menuWidth, buttonHeight).hit then
                if affordable then
                    Player.gold = Player.gold - item.price
                    playSoundEffect(upgradeSFX, 0.6, 1, false)
                    Player.unlockedStartingBalls[item.key] = true
                    -- Add to startingItems in Player and save
                    Player.startingItems = Player.startingItems or {}
                    Player.startingItems[item.key] = true
                    saveGameData()
                    print("Unlocked starting item: " .. item.key)
                else
                    print("Not enough gold to unlock " .. item.key)
                end
            end
            local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(item.price))/2
            -- Draw price with shadow and color (see printMoney logic)
            local moneyText = formatNumber(item.price) .. "$"
            local moneyColor = affordable and {14/255, 202/255, 92/255, 1} or {164/255, 14/255, 14/255,1}
            local shadowOffset = 4
            setFont(35)
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(moneyText, x + menuWidth - 20 + moneyOffsetX + shadowOffset, y + shadowOffset, math.rad(5))
            love.graphics.setColor(moneyColor)
            love.graphics.print(moneyText, x + menuWidth - 20 + moneyOffsetX, y, math.rad(5))
            love.graphics.setColor(1,1,1,1)
        else
            suit.Label(label, {align = "center"}, x, y, menuWidth, buttonHeight)
        end
    end
end

local function paddleCoresDraw()
    -- === Paddle Cores Menu ===
    local menuX = 1000
    local menuY = 110
    local menuWidth = 300
    local buttonHeight = 150
    local buttonSpacing = 30
    setFont(32)
    suit.Label("Paddle Cores", {align = "center"}, menuX - menuWidth, menuY, menuWidth*2, 40)
    menuX = menuX - menuWidth/2*2  -- Center the label
    menuY = menuY + 80  -- Adjust Y position for the label

    -- Use Player.availableCores directly instead of overwriting it
    Player.paddleCores = Player.paddleCores or {}
    
    local i = 0
    for _, core in ipairs(Player.availableCores) do
        i = i + 1
        local colWidth = menuWidth + 20
        local rowHeight = buttonHeight + buttonSpacing
        local col = (i-1) % 2
        local row = math.floor((i-1) / 2)
        local x = menuX + col * colWidth
        local y = menuY + row * rowHeight
        
        -- Check if the core is unlocked using the full name
        local unlocked = Player.paddleCores[core.name]
        local affordable = Player.gold >= core.price
        
        local color = {0.35,0.35,0.35,0.5}
        local buttonID = generateNextButtonID()
        
        local label = unlocked and (core.name .. " (Unlocked)") or core.name
        local buttonColor = {
            normal = {bg = color, fg = {1,1,1}},
            hovered = {bg = {math.min(color[1]+0.2,1), math.min(color[2]+0.2,1), math.min(color[3]+0.2,1), 1}, fg = {1,1,1}},
            active = {bg = {math.max(color[1]-0.2,0), math.max(color[2]-0.2,0), math.max(color[3]-0.2,0), 1}, fg = {1,1,1}}
        }
        
        if not unlocked then
            if suit.Button(label, {color = buttonColor, id = buttonID}, x, y, colWidth, buttonHeight).hit then
                if affordable then
                    Player.gold = Player.gold - core.price
                    playSoundEffect(upgradeSFX, 0.6, 1, false)
                    Player.paddleCores[core.name] = true
                    saveGameData()
                    print("Unlocked paddle core: " .. core.name)
                else
                    print("Not enough gold to unlock " .. core.name)
                end
            end
            local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(core.price))/2
            -- Draw price with shadow and color
            local moneyText = formatNumber(core.price) .. "$"
            local moneyColor = affordable and {14/255, 202/255, 92/255, 1} or {164/255, 14/255, 14/255,1}
            local shadowOffset = 4
            setFont(35)
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(moneyText, x + colWidth - 20 + moneyOffsetX + shadowOffset, y + shadowOffset, math.rad(5))
            love.graphics.setColor(moneyColor)
            love.graphics.print(moneyText, x + colWidth - 20 + moneyOffsetX, y, math.rad(5))
            love.graphics.setColor(1,1,1,1)
        else
            suit.Label(label, {align = "center"}, x, y, colWidth, buttonHeight)
        end
        ::continue::
    end
end

function permanentUpgrades.draw()
    local padding = 20
    local cellWidth = 200
    local x, y = padding, padding    
    -- startingItemsDraw()  -- Draw the starting items menu
    paddleCoresDraw()

    -- Draw money and score at the top
    local statsLayout = {
        min_width = 430,
        pos = {x, y},
        padding = {padding, padding},
        {"fill", 30},
        {"fill"}
    }
    local definition = suit.layout:cols(statsLayout)
    local xx = x

    -- render money
    local x, y, w, h = definition.cell(2)
    setFont(25) 
    local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(Player.gold))/2
    suit.Label("Money", {align = "center"}, screenWidth/2 + moneyOffsetX, y, moneyOffsetX*2, h)
    setFont(35)
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(formatNumber(Player.gold) .. "$", screenWidth/2 + moneyOffsetX, y+30, math.rad(1.5))
    local moneyColor = {14/255, 202/255, 92/255,1}
    love.graphics.setColor(moneyColor)
    love.graphics.print(formatNumber(Player.gold) .. "$", screenWidth/2 + moneyOffsetX, y + 26, math.rad(1.5))
    love.graphics.setColor(1,1,1,1)

    -- Draw rest of UI (title and upgrades)
    y = y + 90  -- Add spacing after money/score display
    setFont(28)
    --[[suit.Label("Stat Upgrades", {align = "center", valign = "center"}, x - 85, y, uiLabelImg:getWidth()*1.5, uiLabelImg:getHeight())
    y = y - 120

    -- Draw upgrades in a grid
    local cols = 2
    local col = 0
    local row = 0
    for upgradeName, upgradeValue in pairs(upgrades) do
        col = col >= 2 and 0 or col + 1
        row = col == 1 and row + 1 or row

        local x = padding + col * (cellWidth + padding)
        local y = y + row * 200  -- Space for price, value and icon        -- Render price
        local price
        --[[if (Player.permanentUpgrades[upgradeName] or 0) < 1 and (not (upgradeName == "cooldown" and (Player.permanentUpgrades[upgradeName] or 0) <= -1)) then
            setFont(45)
            price = Player.permanentUpgradePrices[upgradeName] or 100  -- Default price if not set
            local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(price))/2
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(formatNumber(price) .. "$", x + 104 + moneyOffsetX, y + 4, math.rad(5))
            local moneyColor = Player.gold >= price and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
            love.graphics.setColor(moneyColor)
            love.graphics.print(formatNumber(price) .. "$", x + 100 + moneyOffsetX, y, math.rad(5))
            love.graphics.setColor(1,1,1,1)
        else
            setFont(25)
            local text = "Max Level"
            local offsetX = -getTextSize(text)/2
            love.graphics.print(text, x + 110 + offsetX, y)
        end

        -- Draw value
        setFont(35)
        suit.Label("+ " .. tostring(Player.permanentUpgrades[upgradeName] or 0), {align = "center"}, x, y + 50, cellWidth, 100)        -- Draw icon
        if iconsImg[upgradeName] then
            local iconX = x + cellWidth/2 - iconsImg[upgradeName]:getWidth()*1.75/2 * 32/500
            love.graphics.draw(iconsImg[upgradeName], iconX, y + 125, 0, 1.75 * 32/500, 1.75 * 32/500)
        end

        -- Add invisible button for upgrading (now using dress)
        local buttonID = generateNextButtonID()
        local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonID}, x+5, y-20, cellWidth, 200)
        
        if upgradeStatButton.hit and ((Player.permanentUpgrades[upgradeName] or 0) < 1 and (not (upgradeName == "cooldown" and (Player.permanentUpgrades[upgradeName] or 0) <= -1))) then
            if Player.gold < price then
                print("Not enough money to upgrade " .. upgradeName)
            else
                playSoundEffect(upgradeSFX, 0.6, 1, false)
                -- Apply the upgrade
                if Player.permanentUpgrades[upgradeName] then
                    if upgradeName == "cooldown" then
                        Player.permanentUpgrades[upgradeName] = Player.permanentUpgrades[upgradeName] - 1
                    else
                        Player.permanentUpgrades[upgradeName] = Player.permanentUpgrades[upgradeName] + 1
                    end
                else
                    Player.permanentUpgrades[upgradeName] = 1
                end
                Player.gold = Player.gold - price
                Player.permanentUpgradePrices[upgradeName] = price * 10
                -- Apply any immediate effects of the upgrade
                if upgradeName == "paddleSize" then
                    Player.bonusUpgrades.paddleSize()
                end
                saveGameData()  -- Make sure this is called
                print(upgradeName .. " upgraded to " .. Player.permanentUpgrades[upgradeName])
            end
        end
    end]]
    
    -- Grid layout settings
    local gridStartX = 100
    local gridStartY = 150
    local buttonWidth = 200
    local buttonHeight = 100
    local gapX = 50
    local gapY = 30
    local columnsCount = 3
    
    -- Draw upgrade buttons in a grid
    local row = 0
    local col = 0

    

    dress:draw()
end

return permanentUpgrades

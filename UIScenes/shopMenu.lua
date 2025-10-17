local ShopMenu = UIScene.new();

function ShopMenu:init()
    -- always 1920x1080
    local screenWidth, screenHeight = love.graphics.getDimensions();

    self.interestValue = math.floor(math.min(Player.money, Player.currentCore == "Economy Core" and 50 or 25) / 5);
    self.gainValue = self.interestValue + 5 + getItemsIncomeBonus();

    if Player.currentCore == "Economy Core" then
        self.gainValue = 12;
    end

    self.popupPointer = {
        default = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 20);
        big = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 26);
        bold = love.graphics.newFont("assets/Fonts/KenneyFutureBold.ttf", 28);
        interest = self.interestValue;
        totalInterest = self.gainValue;
    };

    local popupMsg;

    if Player.currentCore == "Economy core" then
        popupMsg = "At the end of the level up phase, gain <color=money><font=big>12$";
    else
        popupMsg = "At the end of the level up phase, gain <color=money><font=big>8$<color=white><font=default> + <font=big><color=money>1$ <color=white><font=default>for every <font=big><color=money>5$<color=white><font=default> you have, max <color=money><font=big>13$";
    end

    -- self.curCore = Player.currentCore;

    self.popupText = FancyText.new(popupMsg, 20, 15, 350, 20, "left", self.popupPointer.default, self.popupPointer);

    self.moneyColor = {14/255, 202/255, 92/255};




    self.ballsToShow = {};
    self.ballsToShowNames = {};
    for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        table.insert(self.ballsToShow, ballType);
        table.insert(self.ballsToShowNames, ballName);
    end

    self.ballButtons = {};

    ShopMenu:addElements(
    );
end

function ShopMenu:onActivation()
    self.interestValue = math.floor(math.min(Player.money, Player.currentCore == "Economy Core" and 50 or 25) / 5);
    self.gainValue = self.interestValue + 5 + getItemsIncomeBonus();

    if Player.currentCore == "Economy Core" then
        self.gainValue = 12;
    end

    self.popupPointer.interest = self.interestValue;
    self.popupPointer.totalInterest = self.gainValue;

    local popupMsg;

    if Player.currentCore == "Economy core" then
        popupMsg = "At the end of the level up phase, gain <color=money><font=big>12$";
    else
        popupMsg = "At the end of the level up phase, gain <color=money><font=big>8$<color=white><font=default> + <font=big><color=money>1$ <color=white><font=default>for every <font=big><color=money>5$<color=white><font=default> you have, max <color=money><font=big>13$";
    end

    self.popupText:setText(popupMsg);



    self.ballsToShow = {};
    self.ballsToShowNames = {};
    for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        table.insert(self.ballsToShow, ballType);
        table.insert(self.ballsToShowNames, ballName);
    end
end

function ShopMenu:update(dt)
end

function ShopMenu:drawPlayerStats()
    local statsWidth = 450;

    local moneyText = formatNumber(Player.money) .. "$";
    local moneyTextWidth = getTextSize(moneyText);
    local x = statsWidth / 2 - moneyTextWidth / 2;
    local y = 176 - love.graphics.getFont():getHeight() / 2;

    setFont(80 * (moneyScale.scale or 1));
    love.graphics.setColor(0,0,0); -- drop shadow
    love.graphics.print(moneyText, x + 4, y + 4, math.rad(1.5));
    love.graphics.setColor(self.moneyColor);
    love.graphics.print(moneyText, x, y, math.rad(1.5));

    love.graphics.setColor(1,1,1);
    self.popupText:draw();

    if Player.levelingUp and self.gainValue > 0 then
        setFont(45);

        love.graphics.setColor(self.moneyColor);

        x = x + 90;
        y = y - 45;

        love.graphics.print("+" .. formatNumber(self.gainValue) .. "$", x, y, math.rad(1.5));
    end

    if Player.currentCore and Player.levelingUp and not Player.choosingUpgrade then
        setFont(38);

        local coreText = tostring(Player.currentCore);

        love.graphics.setColor(0, 0, 0, 0.7);

        local tw = love.graphics.getFont():getWidth(coreText);
        local th = love.graphics.getFont():getHeight();

        -- Centered under Bricks Destroyed (which is at x=40, y=40)
        love.graphics.setColor(0.9, 0.9, 0.9);
        love.graphics.print(coreText, 1920 / 2 - tw / 2, 1080 - th - 15);
    end

    if Player.score then
        setFont(38);

        local text = formatNumber(Player.score) .. " pts";
        local tw = love.graphics.getFont():getWidth(text);
        local th = love.graphics.getFont():getHeight();

        love.graphics.setColor(0.25, 0.5, 1, 1);
        love.graphics.print(text, statsWidth / 2 - th / 2 - 25, 315 - th / 2);
        love.graphics.setColor(1, 1, 1, 1); -- Reset color to white
    end
end

function ShopMenu:draw()
    self:drawPlayerStats();






    -- local x, y = suit.layout:nextRow() -- Get the next row position
    -- local x = 10;
    -- local y = 10; -- Starting position for the ball stats (horizontal from left)
    local w, h;
    local padding = 100;
    -- Initialize the layout with the starting position and padding
    -- suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)

    ----------------
    -- Draw Title --
    ----------------
    setFont(28);
    -- suit.layout:row(screenWidth - 20, 60)
    -- local x,y = suit.layout:nextRow()

    ----------------------------
    -- Prepare Ball List Data --
    ----------------------------
    -- local ballsToShow = {}
    -- for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
    -- ballsToShow[ballName] = ballType
    -- end
    
    -----------------------
    -- Draw Ball Entries --
    -----------------------
    local startX = 460; -- Starting X position
    local currentX = startX; -- Current X position for drawing

    for i = 1, math.min(#self.ballsToShow, 6) do--, ballType in ipairs(self.ballsToShow) do
        local ballName = self.ballsToShowNames[i];
        local ballType = self.ballsToShow[i];

        -- Reset X position at the start of each row (every 3 balls)
        if (i - 1) % 3 == 0 then
            currentX = startX;
        end
        y = 475 + math.floor((i - 1) / 3) * 300; -- Move to next row every 3 balls
        -- suit.layout:reset(currentX, y, padding, padding)

        -- draw window
        love.graphics.draw(getRarityWindow(ballType.rarity, "mid"), currentX - 25, y);

        -- draw title label and title
        -- setFont(26);

        love.graphics.draw(uiLabelImg, currentX + statsWidth / 2-uiLabelImg:getWidth() / 2 - 10, y - 25);
        setFont(getMaxFittingFontSize(ballType.name or "Unk", 30, uiLabelImg:getWidth() - 20));
        drawTextCenteredWithScale(ballType.name or "Unk", currentX + statsWidth / 2 - uiLabelImg:getWidth() / 2 + 3, y - 8, 1, uiLabelImg:getWidth() - 20);

        -- type label
        -- setFont(20);
        -- local typeColor = {normal = {fg = {0.6,0.6,0.6,1}}}
        local labelY = y + uiLabelImg:getHeight() / 2;
        -- suit.Label(ballType.type or "Unk type", {color = typeColor, align = "center"}, currentX + statsWidth/2-50-7, labelY, 100, 50)
        -- drawTextCenteredWithScale(ballType.type or "Unk type", currentX + statsWidth/2-50-7, labelY, 1, 100, {0.6,0.6,0.6,1})

        -- price label
        setFont(50);
        local ballPrice = math.ceil(ballType.price);
        local ballPriceText = formatNumber(ballPrice) .. "$";
        local moneyOffsetX = getTextSize(ballPriceText) / 2; -- was * cos(5 deg) but =~ 1

        love.graphics.setColor(0,0,0);
        love.graphics.print(ballPriceText, currentX + statsWidth / 2 + 104 - moneyOffsetX, labelY + 4, math.rad(5));
        --local moneyColor = Player.money >= ballPrice and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1};

        love.graphics.setColor(self.moneyColor);
        love.graphics.print(ballPriceText, currentX + statsWidth / 2 + 100 - moneyOffsetX, labelY, math.rad(5));
        -- love.graphics.setColor(1,1,1);

        -- damageDealt label (top right, mirroring price)
        local damageDealt = ballType.damageDealt or 0;
        local dmgText = tostring(formatNumber(damageDealt)) .. " dmg";

        setFont(25);
        local dmgOffsetX = getTextSize(dmgText) / 2; -- was * cos(-2.5 deg) but =~ 1
        local dmgTextWidth = love.graphics.getFont():getWidth(dmgText);

        -- Place at top right of the window, mirroring price
        local dmgX = currentX + statsWidth / 4;
        local dmgY = labelY + 13;
        love.graphics.setColor(0,0,0);
        love.graphics.print(dmgText, dmgX + 4 - dmgOffsetX, dmgY + 4, math.rad(-2.5));
        love.graphics.setColor(1,0.25,0.25);
        love.graphics.print(dmgText, dmgX - dmgOffsetX, dmgY, math.rad(-2.5));
        love.graphics.setColor(1,1,1);
        

        -- labelY = labelY + 20;
        -- local statsX = currentX + 10;
        -- if #Balls.getUnlockedBallTypes() > 1 then
        -- end
        -- local myLayout = {
            -- min_width = 410, -- Minimum width for the layout
            -- pos = {statsX, labelY + 40}, -- Starting position (x, y)
            -- padding = {5, 5}, -- Padding between cells
        -- };
        -- Calculate the number of rows needed for the stats
        -- if ballType.noAmount and ballType.stats.amount then
        -- rowCount = rowCount-- - 1 -- If no amount, don't count it
        -- end
        -- for x = 1,  rowCount do -- adds a {"fill"} for each stat in the ballType.stats table
        -- table.insert(myLayout, {"fill", 30}) -- for stats
        -- end
        -- local definition = suit.layout:cols(myLayout)
        -- statsX, labelY, w, h = definition.cell(1)
        statsX = currentX + 15;
        labelY = labelY + 65;

        local rowCount = (ballType.noAmount or false) and countStringKeys(ballType.stats) or countStringKeys(ballType.stats) + 1;
        -- suit.layout:reset(10, labelY, padding, padding) -- Set padding (10px horizontal and vertical)
        -- suit.layout:row(w, h)

        -- Draw upgrade buttons for each stat
        local intIndex = 1; -- keeps track of the current cell int id being checked
        -- Define the order of keys
        -- local statOrder = { "amount", "damage", "speed", "cooldown", "range", "fireRate", "ammo"} -- Order of stats to display

        -- makes sure amount is only called on things that use it




        -- local typeStats = {} -- Initialize the typeStats table
        -- if ballType.noAmount == false then
        --    typeStats = { amount = ballType.ballAmount } -- Start with amount
        -- end
        -- for statName, statValue in pairs(ballType.stats) do
            -- typeStats[statName] = statValue -- Add stats to the table
        -- end

        -- loops over each stats
        for _, statName in ipairs(self.statOrder) do
            local statValue = nil;
            -- makes speed display as low value
            if ballType.stats[statName] then
                if statName == "speed" then
                    statValue = ballType.stats[statName] / 50; -- Add speed to the stats table
                else
                    statValue = ballType.stats[statName];
                end
            end

            if statValue then -- Only process if the stat exists
                local buttonResult = nil;

                statsX = currentX + 15 * (intIndex % rowCount + 1);
                labelY = y + uiLabelImg:getHeight() / 2 + 65 * math.floor(intIndex / rowCount);
                --, w, h = definition.cell(intIndex)
                -- suit.layout:reset(statsX, labelY, padding, padding) -- Set padding (10px horizontal and vertical)
                -- setFont(20);

                local cellWidth = (430 - 10 * rowCount) / rowCount;
                
                -- draw value
                setFont(35);
                -- suit.layout:padding(0, 0)
                -- Add permanent upgrades to the display value
                local permanentUpgradeValue = Player.permanentUpgrades[statName] or 0;
                local bonusValue = getStatItemsBonus(statName, ballType) or 0;
                local value = (Player.currentCore == "Cooldown Core" and statName == "cooldown") and 2 or statValue + bonusValue + permanentUpgradeValue;

                if statName == "ammo" then
                    value = value - permanentUpgradeValue - bonusValue + bonusValue * ballType.ammoMult; -- Adjust ammo value based on ammoMult
                end
                if (statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core" then
                    value = 1;
                end
                if statName == "damage" then
                    if Player.currentCore == "Damage Core" then
                        value = value * 5; -- Double damage for Damage Core
                    elseif Player.currentCore == "Phantom Core" and (ballType.type == "gun" or ballType.name == "Gun Turrets" or ballType.name == "Gun Ball") then
                        value = value / 2;
                    end
                    if ballName == "Sniper" then
                        value = value * 10;
                    end
                end

                if statName == "cooldown" then
                    value = math.max(0, value);
                end
                if Player.currentCore == "Madness Core" then
                    if statName == "damage" or statName == "cooldown" then
                        value = value / 2; -- Half damage and cooldown for Madness Core
                    else
                        value = value * 2; -- Double speed for Madness Core
                    end
                end
                if (Player.currentCore == "Phantom Core" and ballType.type == "gun" and statName == "damage") or (Player.currentCore == "Madness Core" and (statName == "damage" or statName == "cooldown")) then
                    drawTextCenteredWithScale(string.format("%.1f", value), statsX, labelY - 15, 1, cellWidth);
                else
                    drawTextCenteredWithScale(tostring(value), statsX, labelY - 15, 1, cellWidth);
                end

                -- draw stat icon
                local iconX = statsX + cellWidth / 2 - iconsImg[statName]:getWidth() * 1.35 / 2 * 50 / 500 - 3;
                love.graphics.draw(iconsImg[statName], iconX, labelY + 55, 0, 1.35 * 50 / 500, 1.35 * 50 / 500)

                -- draw seperator
                if intIndex < rowCount then
                    love.graphics.setColor(0.4,0.4,0.4);
                    love.graphics.rectangle("fill", statsX + cellWidth, labelY, 1, 125);
                    love.graphics.setColor(1,1,1);
                end

                -- draw invis button
                --[[local invisButtonColor = {
                    normal  = {bg = {0,0,0,0}, fg = {0,0,0}},           -- invisible bg, black fg
                    hovered = {bg = {0.19,0.6,0.73,0.2}, fg = {1,1,1}}, -- glowing bg, white fg
                    active  = {bg = {1,0.6,0}, fg = {1,1,1}}          -- faint bg, white fg
                }
                -- local buttonID
                -- buttonID = generateNextButtonID() -- Generate a unique ID for the button
                --local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonID}, statsX, labelY-10, cellWidth, 150)
                -- Right-click to remove all queued upgrades of this stat
                local canUpgrade = true;
                -- Core-specific restrictions
                if statName == "cooldown" and Player.currentCore == "Cooldown Core" then
                    canUpgrade = false; -- Cannot upgrade cooldown if using Cooldown Core
                end
                if ((statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core") then
                    canUpgrade = false -- Cannot upgrade fireRate or amount if using Damage Core
                end
                -- Ammo restrictions
                if statName == "ammo" and (((ballType.stats.cooldown or 1000) + getStatItemsBonus("cooldown", ballType) + (Player.permanentUpgrades["cooldown"] or 0)) <= 0 and ballType.name ~= "Gun Turrets") then
                    canUpgrade = false -- Cannot upgrade ammo if cooldown is already at 0
                end
                local upgradeQueued = false
                if ballType.queuedUpgrades then
                    if ballType.queuedUpgrades[1] == statName then
                        upgradeQueued = true
                    end
                end]]

                local upgradeCount = 0;
                for _, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                    if queuedUpgrade == statName then
                        upgradeCount = upgradeCount + 1;
                    end
                end

                setFont(30);

                if upgradeCount > 0 then
                    love.graphics.setColor(161/255, 231/255, 1);
                    love.graphics.print((statName == "cooldown" and "-" or "+") .. upgradeCount, statsX + cellWidth * 2 / 3 - 5, labelY - 5); -- Display queued upgrade count\
                end

                intIndex = intIndex + 1;
                love.graphics.setColor(1,1,1);
            end
        end
        suit.layout:row(statsWidth, 20) -- Add spacing for the separator
        
        -- upgrade button
        local buttonId = ballType.name .. "_upgradeButton"
        local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonId}, currentX + 10, y + 15, getRarityWindow("common"):getWidth() - 30, getRarityWindow("common"):getHeight()/2 - 30)
        if upgradeStatButton.hit then
            if Player.money < math.ceil(ballType.price) then
                -- does nothing
            else
                playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                Player.pay(math.ceil(ballType.price)) -- Deduct the cost from the player's money
                local totalStats = {}
                for statName, statValue in pairs(ballType.stats) do
                    totalStats[statName] = statValue
                end
                if ballType.type == "ball" then
                    totalStats["amount"] = ballType.ballAmount
                end
                ballType.price = ballType.price + tableLength(totalStats)
                for statName, statValue in pairs(totalStats) do
                    if statName == "cooldown" and getStat(ballName, "cooldown") <= 0 then
                        print("cannot upgrade cooldown any further")       
                    else
                        if upgradeQueued then
                            for i, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                                if queuedUpgrade == statName then
                                    table.remove(ballType.queuedUpgrades, i)
                                    break
                                end
                            end
                        end
                        setFont(16)
                        print("Upgrading " .. ballType.name .. "'s " .. statName)
                        local stat = ballType.stats[statName] or 0-- Get the current stat value
                        if statName == "speed" then
                            ballType.stats.speed = ballType.stats.speed + 50 -- Example action
                            Balls.adjustSpeed(ballType.name) -- Adjust the speed of the ball
                        elseif statName == "amount" and ballType.type == "ball" then
                            Balls.addBall(ballType.name, true) -- Add a new ball of the same type
                            ballType.ballAmount = ballType.ballAmount + 1
                        elseif statName == "cooldown" then
                            ballType.stats.cooldown = ballType.stats.cooldown - 1
                        elseif statName == "ammo" then
                            print(ballType.name .. " ammo increased by " .. ballType.ammoMult)
                            ballType.currentAmmo = ballType.currentAmmo + ballType.ammoMult -- Increase ammo by ammoMult
                            ballType.stats.ammo = ballType.stats.ammo + ballType.ammoMult -- Example action
                        else
                            ballType.stats[statName] = ballType.stats[statName] + 1 -- Example action
                            print( "stat ".. statName .. " increased to " .. ballType.stats[statName])
                        end
                    end
                end
            end
        end
        
        -- Move to next horizontal position
        currentX = currentX + statsWidth + 50 -- Move right for next ball (20px spacing)
        if #self.ballsToShow > 6 then
            i = i + 3 * 0
        end
        ::continue::
    end
    
    local numBalls = tableLength(Balls.getUnlockedBallTypes())
    local column = numBalls % 3 -- Get the current column (0, 1, or 2)
    
    -- If we're at the start of a new row, reset X position
    if column == 0 then
        currentX = startX
        y = y + 300 -- Move to next row
    end
    
    suit.layout:reset(currentX, y, padding, padding)
    love.graphics.draw(uiSmallWindowImg, currentX-25, y) -- Draw the background window image
    -- Button to unlock a new ball type
    setFont(30)
    local angle = angle or math.rad(1.5) -- Default angle if not provided
    love.graphics.setColor(1, 1, 1, 1)
    setFont(35)
    local levelRequirement = Player.level + (3 - ((Player.level - 1) % 3))

    drawTextCenteredWithScale("unlock new weapon at lvl " .. levelRequirement, currentX, y + 50, 1, uiSmallWindowImg:getWidth() - 40)

    -- Add DOWN and UP buttons to the bottom of the area, side by side (no logic inside)
    if #self.ballsToShow > 6 then
        local btnW, btnH = 120, 40
        -- Place buttons below the last row of balls
        local numRows = math.ceil(#self.ballsToShow / 3)
        local btnY = screenHeight - btnH
        local btnX = startX + (screenWidth - startX - btnW)/2
        setFont(25)
        if 0 < math.ceil(#self.ballsToShow/3) then
            if suit.Button("DOWN", {id="ballStatsDown"}, btnX, btnY, btnW, btnH).hit then
                0 = math.min(0 + 1, math.ceil(#self.ballsToShow/3))
            end
        end
        btnX = btnX + btnW + 20
        if 0 > 0 then
            if suit.Button("UP", {id="ballStatsUp"}, btnX, btnY, btnW, btnH).hit then
                0 = math.max(0, 0 - 1)
            end
        end
    end
end

ShopMenu:init();
return ShopMenu;
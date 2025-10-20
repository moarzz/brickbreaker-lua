local ShopMenu = UIScene.new();

function ShopMenu:init()
    -- always 1920x1080
    local screenWidth, screenHeight = love.graphics.getDimensions();

    self.interestValue = math.floor(math.min(Player.money, Player.currentCore == "Economy Core" and 50 or 25) / 5);
    self.gainValue = self.interestValue + 5 + getItemsIncomeBonus();

    if Player.currentCore == "Economy Core" then
        self.gainValue = 12;
    end

    self.default = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 18);
    self.big     = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 23);
    self.bold    = love.graphics.newFont("assets/Fonts/KenneyFutureBold.ttf", 25);

    self.popupPointer = {
        default = self.default;
        big = self.big;
        bold = self.bold;
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

    self.popupText = FancyText.new(popupMsg, 20, 15, 350, 20, "left", self.default, self.popupPointer);

    self.moneyColor = {14/255, 202/255, 92/255};




    self.ballsToShow = {};
    self.ballsToShowNames = {};
    for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        table.insert(self.ballsToShow, ballType);
        table.insert(self.ballsToShowNames, ballName);
    end

    -- self.ballButtons = {};

    self.displayedItems = {};
    self.buyButtons = {};
    self.shopItemDescriptions = {};
    self.shopItemDescriptionPointers = {};

    self.getValue = function() return longTermInvestment.value end;

    self.itemCount = Player.currentCore == "Collector's Core" and 2 or 3;

    local arbitraryWidth = uiBigWindowImg:getWidth() * 0.75;
    local arbitraryHeight = uiBigWindowImg:getHeight() * 0.65;
    for i = 1, self.itemCount do
        local itemX = 450 + (i - 1) * (arbitraryWidth + 50);
        local itemY = 25;

        table.insert(self.buyButtons, Button(itemX + 10, itemY + 12, arbitraryWidth - 20, arbitraryHeight - 24));

        local newPointer = {
            default = self.default;
            big     = self.big;
            bold    = self.bold;
            longTermValue = self.getValue;
        };
        local newFancyText = FancyText.new("", itemX + 25, itemY + 110, arbitraryWidth - 50, 20, "center", self.default, newPointer);

        table.insert(self.shopItemDescriptionPointers, newPointer);
        table.insert(self.shopItemDescriptions, newFancyText);
    end

    self.rarityDistribution = {
        common = 1;
        uncommon = 0;
        rare = 0;
        legendary = 0;
    };

    self.white = {1,1,1,1};
    self.dark = {0.6,0.6,0.6,1};

    self.maxItems = 3; -- arbitrary from another script
    self.rerollPrice = 2;

    self.rerollButton = Button(
        screenWidth - 260,
        50 + arbitraryHeight / 2 - 57,
        arbitraryWidth / 0.75 - 30,
        arbitraryHeight / 0.65 - 6
    );




    self.playerItemDescriptions = {};
    self.playerItemDescriptionPointers = {};
    self.playerItemSellButtons = {};

    for i = 1, self.maxItems do
        local newPointer = {
            default = self.default;
            big     = self.big;
            bold    = self.bold;
            longTermValue = self.getValue;
        };

        local text = "";

        if Player.items[i] and Player.items[i].descriptionPointers then
            for pointerName, pointerFunc in pairs(Player.items[i].descriptionPointers) do
                pointers[pointerName] = pointerFunc;
            end
        end

        local scaleFactor = self.maxItems <= 4 and 0.86 or 0.69;
        local itemY = 1080 / 2 - 85 + (i - 1) * arbitraryHeight + 10 * scaleFactor;
        local newFancyText = FancyText.new(text, 25 * scaleFactor, itemY + 65 * scaleFactor, arbitraryWidth - 50 * scaleFactor, 10, "center", self.default, newPointer);

        table.insert(self.playerItemDescriptionPointers, newPointer);
        table.insert(self.playerItemDescriptions, newFancyText);

        local buttonWidth = 120 * scaleFactor;
        local buttonHeight = 100 * scaleFactor;
        local buttonX = arbitraryWidth + 5 * scaleFactor;
        local buttonY = itemY + arbitraryHeight / 2 - 50 * scaleFactor;

        local newButton = Button(buttonX, buttonY, buttonWidth, buttonHeight);

        table.insert(self.playerItemSellButtons, newButton);
    end

    ShopMenu:addElements(
        self.buyButtons[1],
        self.buyButtons[2],
        self.buyButtons[3],
        self.rerollButton
    );

    ShopMenu:addElements(
        unpack(self.playerItemSellButtons)
    );
end

function ShopMenu:roll(forcedItems)
    forcedItems = forcedItems or {};
    self.displayedItems = {};

    for i = 1, Player.currentCore == "Collector's Core" and 2 or 3 do
        local itemToDisplay = nil;

        if forcedItems[i] then
            itemToDisplay = forcedItems[i];

            if itemToDisplay then
                if itemToDisplay.onInShop then
                    itemToDisplay.onInShop(itemToDisplay);
                end

                self.displayedItems[i] = itemToDisplay;
            else
                print("Error: No item found in setItemShop()")
            end
        else
            -- calculate wanted rarity and choose an available item of that rarity
            -- local rarityDistribution = getRarityDistributionByLevel();
            local commonChance    = self.rarityDistribution.common;
            local uncommonChance  = self.rarityDistribution.uncommon;
            local rareChance      = self.rarityDistribution.rare;
            local legendaryChance = self.rarityDistribution.legendary;

            if Player.currentCore == "Picky Core" then
                commonChance    = commonChance + (1 - commonChance) / 2;
                uncommonChance  = uncommonChance / 2;
                rareChance      = rareChance / 2;
                legendaryChance = legendaryChance / 2;
            end

            uncommonChance  = uncommonChance  + commonChance;
            rareChance      = rareChance      + uncommonChance;
            legendaryChance = legendaryChance + rareChance;

            local doAgain = true;
            local iterations = 0;
            local maxIterations = 100;
            while doAgain and iterations < maxIterations do
                local rarity = math.random();
                local isConsumable = math.random() <= 0.15 -- 15% chance to be a consumable

                iterations = iterations + 1;
                doAgain = false;

                if rarity <= commonChance then
                    itemToDisplay = getRandomItemOfRarity("common", isConsumable);
                elseif rarity <= uncommonChance then
                    itemToDisplay = getRandomItemOfRarity("uncommon", isConsumable);
                elseif rarity <= rareChance then
                    itemToDisplay = getRandomItemOfRarity("rare", isConsumable);
                elseif rarity <= legendaryChance then
                    itemToDisplay = getRandomItemOfRarity("legendary", isConsumable);
                else
                    itemToDisplay = getRandomItemOfRarity("common", isConsumable); -- should never get here
                end

                if iterations > 20 then --! I dont like this
                    itemToDisplay = getRandomItemOfRarity("common", false);
                end

                for _, displayedItem in pairs(self.displayedItems) do
                    if displayedItem.name == itemToDisplay.name then
                        doAgain = true;
                        break;
                    end
                end
                for _, playerItem in ipairs(Player.items) do
                    if playerItem.name == itemToDisplay.name then
                        doAgain = true;
                        break;
                    end
                end
            end

            if iterations >= maxIterations then
                print("Warning: setItemShop exceeded maxIterations, skipping slot or allowing duplicate.")
            end

            -- if testItems[i] and not forcedItems[i] then
                -- if itemToDisplay.onInShop then
                    -- itemToDisplay.onInShop(itemToDisplay);
                -- end
                -- self.displayedItems[i] = items[testItems[i]];
            -- else
            if itemToDisplay then
                if itemToDisplay.onInShop then
                    itemToDisplay.onInShop(itemToDisplay);
                end

                self.displayedItems[i] = itemToDisplay;
            else
                print("Error: No item found in setItemShop()");
            end
            -- end
        end

        if itemToDisplay and itemToDisplay.descriptionPointers then
            for k, v in pairs(self.shopItemDescriptionPointers[i]) do -- clear the table (not technically necessary)
                if k ~= "default" and k ~= "big" and k ~= "bold" and k ~= "getValue" then
                    self.shopItemDescriptionPointers[i][k] = nil;
                end
            end

            for valueName, functionPointer in pairs(itemToDisplay.descriptionPointers) do
                self.shopItemDescriptionPointers[i][valueName] = functionPointer;
            end

            self.shopItemDescriptions[i]:setText(getItemFullDescription(itemToDisplay) or "");
        end
    end
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



    -- self.ballsToShow = {};
    -- self.ballsToShowNames = {};
    -- for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        -- table.insert(self.ballsToShow, ballType);
        -- table.insert(self.ballsToShowNames, ballName);
    -- end

    if Player.level < 5 then
        self.rarityDistribution.common = 1;
        self.rarityDistribution.uncommon = 0;
        self.rarityDistribution.rare = 0.0;
        self.rarityDistribution.legendary = 0.0;
    elseif Player.level < 8 then
        self.rarityDistribution.common = 0.88;
        self.rarityDistribution.uncommon = 0.1;
        self.rarityDistribution.rare = 0.02;
        self.rarityDistribution.legendary = 0.0;
    elseif Player.level < 13 then
        self.rarityDistribution.common = 0.75;
        self.rarityDistribution.uncommon = 0.2;
        self.rarityDistribution.rare  = 0.05;
        self.rarityDistribution.legendary = 0;
    elseif Player.level < 18 then
        self.rarityDistribution.common = 0.625;
        self.rarityDistribution.uncommon = 0.3;
        self.rarityDistribution.rare = 0.075;
        self.rarityDistribution.legendary = 0;
    elseif Player.level < 22 then
        self.rarityDistribution.common = 0.53;
        self.rarityDistribution.uncommon = 0.35;
        self.rarityDistribution.rare = 0.1;
        self.rarityDistribution.legendary = 0.02;
    elseif Player.level < 26 then
        self.rarityDistribution.common = 0.485;
        self.rarityDistribution.uncommon = 0.35;
        self.rarityDistribution.rare = 0.125;
        self.rarityDistribution.legendary = 0.04;
    else
        self.rarityDistribution.common = 0.4;
        self.rarityDistribution.uncommon = 0.39;
        self.rarityDistribution.rare = 0.15;
        self.rarityDistribution.legendary = 0.06;
    end

    -- if somehow the number of items in the shop has changed
    if (Player.currentCore == "Collector's Core" and 2 or 3) ~= self.itemCount then
        self.itemCount = Player.currentCore == "Collector's Core" and 2 or 3;

        self:removeElements(unpack(self.buyButtons));
        self.buyButtons = {};

        local arbitraryWidth = uiBigWindowImg:getWidth() * 0.75;
        local arbitraryHeight = uiBigWindowImg:getHeight() * 0.65;
        for i = 1, self.itemCount do
            local itemX = 450 + (i - 1) * (arbitraryWidth + 50);
            local itemY = 25;

            table.insert(self.buyButtons, Button(itemX + 10, itemY + 12, arbitraryWidth - 20, arbitraryHeight - 24));

            if not self.shopItemDescriptions[i] then
                local newPointer = {
                    default = self.default;
                    big     = self.big;
                    bold    = self.bold;
                    longTermValue = self.getValue;
                };
                local newFancyText = FancyText.new("", itemX + 25, itemY + 110, arbitraryWidth - 50, 20, "center", self.default, newPointer);

                table.insert(self.shopItemDescriptionPointers, newPointer);
                table.insert(self.shopItemDescriptions, newFancyText);
            end
        end

        ShopMenu:addElements(
            self.buyButtons[1],
            self.buyButtons[2],
            self.buyButtons[3]
        );
        -- error("shop item count not handled to change mid game");
    end

    self:roll(); --!
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

function ShopMenu:drawItemShop()
    setFont(60);

    local arbitraryWidth = uiBigWindowImg:getWidth() * 0.75;
    local arbitraryHeight = uiBigWindowImg:getHeight() * 0.65;

    for i = #self.displayedItems, 1, -1 do
        local item = self.displayedItems[i];
        local scale = item.consumable and 0.8 or 1.0;

        local windowW = arbitraryWidth * scale;
        local windowH = arbitraryHeight * scale;

        local itemX = 450 + (i - 1) * (arbitraryWidth + 50);
        local itemY = 25;

        local centerX = itemX + arbitraryWidth / 2
        local centerY = itemY + arbitraryHeight / 2
        -- itemX = centerX - windowW / 2;
        -- itemY = centerY - windowH / 2;

        local upgradePrice = item.rarity == "common" and 8 or item.rarity == "uncommon" and 16 or item.rarity == "rare" and 24 or item.rarity == "legendary" and 32 or 8;
        -- local upgradePrice = item.cost;

        if item.consumable then
            upgradePrice = math.ceil(upgradePrice / 2);

            if Player.currentCore == "Picky Core" then
                upgradePrice = math.ceil(upgradePrice / 2);
            end
        end

        if hasItem("Elon's Shmuck") then
            upgradePrice = 2;
        end
        if hasItem("Coupon Collector") then
            upgradePrice = upgradePrice - 1;
        end

        if self.buyButtons[i].isHovering and item.image then
            self.shopItemDescriptions[i]:setPosition(centerX - arbitraryWidth * 0.7333 * scale / 2, itemY + windowH); -- 0.733 since 1 / 0.75 * 0.55 = 0.7333
            self.shopItemDescriptions[i]:setTextHeight(17);
            self.shopItemDescriptions[i]:update();
            self.shopItemDescriptions[i]:draw();
        end

        local colour = (tableLength(Player.items) >= self.maxItems and not item.consumable) and self.dark or self.white;
        love.graphics.setColor(colour);
        love.graphics.draw(getRarityWindow(item.rarity or "common"), itemX, itemY, 0, 0.75 * scale, 0.65 * scale);
        setFont(27);
        drawTextCenteredWithScale(item.name or "Unknown", itemX + 10 * scale, itemY + 30 * scale, scale, windowW - 20 * scale, colour);

        if item.image then
            love.graphics.setColor(1,1,1); -- white
            local imgScale = scale * 0.75;
            love.graphics.draw(item.image, centerX - (item.image:getWidth() * imgScale) / 2, itemY + 130 * imgScale, 0, imgScale, imgScale);
        else
            self.shopItemDescriptions[i]:setPosition(itemX + 25 * scale, itemY + 110 * scale);
            self.shopItemDescriptions[i]:setTextHeight(20);
            self.shopItemDescriptions[i]:update();
            self.shopItemDescriptions[i]:draw();
        end

        if self.buyButtons[i]:isReleased() then
            -- print("button working")
            if (#Player.items < self.maxItems or item.consumable) and Player.money >= upgradePrice then
                Player.pay(upgradePrice);
                playSoundEffect(upgradeSFX, 0.5, 0.95);
                table.remove(self.displayedItems, i);

                if item.onBuy then
                    item:onBuy();

                    if item.consumable and hasItem("Sommelier") then
                        item:onBuy();
                    end
                end

                if not item.consumable then
                    table.insert(Player.items, item);
                end
                if item.stats.amount then
                    Balls.amountIncrease(item.stats.amount);
                end

                for _, weaponType in pairs(Balls.getUnlockedBallTypes()) do
                    if weaponType.type == "ball" then
                        Balls.adjustSpeed(weaponType.name); -- Adjust the speed of the ball
                    end
                end
            end
        end

        local moneyXoffset = item.consumable and -65 or 0;
        local moneyYoffset = item.consumable and -25 or 0;
        printMoney(upgradePrice, itemX + arbitraryWidth - 40 - getTextSize(upgradePrice .. "$") / 2 + moneyXoffset, itemY + arbitraryHeight / 2 - 85 + moneyYoffset, math.rad(4), Player.money >= upgradePrice, 50);
    end

    love.graphics.draw(uiLabelImg, 1920 - 275, 50 + arbitraryHeight / 2 - 60); -- Draw the title background image
    setFont(30);
    local actualRerollPrice = Player.currentCore == "Picky Core" and 1 or self.rerollPrice;

    if hasItem("Elon's Shmuck") then
        actualRerollPrice = 2;
    end

    if self.rerollButton:isReleased() then
        if Player.money >= actualRerollPrice then
            Player.pay(actualRerollPrice);
            playSoundEffect(upgradeSFX, 0.5, 0.95);
            self:roll();

            if Player.currentCore ~= "Picky Core" then
                self.rerollPrice = self.rerollPrice + 1;
            end
        end
    end

    printMoney(actualRerollPrice, 1920 - 40 - getTextSize(actualRerollPrice .. "$") / 2, 30 + arbitraryHeight / 2 - 60, math.rad(4), Player.money >= actualRerollPrice, 40);
end

function ShopMenu:drawPlayerItems()
    love.graphics.setColor(1,1,1); -- white

    -- Determine scale factor based on item count
    local itemCount = #Player.items;
    local scaleFactor = self.maxItems <= 4 and 0.86 or 0.69; -- Scale down when more than 3 items (increased by 15%)

    -- Scale fonts and sizes
    local titleFontSize      = math.floor(40 * scaleFactor);
    local itemNameFontSize   = math.floor(16 * scaleFactor);
    local sellButtonFontSize = math.floor(20 * scaleFactor);
    local moneyFontSize      = math.floor(30 * scaleFactor);

    -- Scale image dimensions
    local imgScaleX = 0.75; -- 0.9 * 1.15
    local imgScaleY = 0.7 * scaleFactor; -- 0.7 * 1.15

    local arbitraryWidth = uiWindowImg:getHeight() * imgScaleX;
    local arbitraryHeight = uiWindowImg:getHeight() * imgScaleY;

    -- Scale spacing and positioning
    local baseSpacing = 10 * scaleFactor;
    local itemSpacing = arbitraryHeight + baseSpacing;

    setFont(titleFontSize);
    love.graphics.print("Items", 200 - getTextSize("Items") / 2, 400);

    -- local hoveredItem = nil; -- Track which item is being hovered

    for index = #Player.items, 1, -1 do--, item in ipairs(Player.items) do
        local item = Player.items[index];

        local sellPrice = 0;

        if item.rarity == "common" then
            sellPrice = 5;
        elseif item.rarity == "uncommon" then
            sellPrice = 10;
        elseif item.rarity == "rare" then
            sellPrice = 15;
        elseif item.rarity == "legendary" then
            sellPrice = 20;
        end

        if hasItem("Abandon Greed") then
            sellPrice = 0;
        end

        -- Keep original row-based positioning, just scaled
        local itemX = 0;
        local startingY = 1080 / 2 - 85; -- Don't scale the starting Y
        local itemY = startingY + (index - 1) * itemSpacing;

        -- local mouseX, mouseY = love.mouse.getPosition();
        local itemWidth = arbitraryWidth;
        local itemHeight = arbitraryHeight;

        -- if mouseX >= itemX and mouseX <= itemX + itemWidth and mouseY >= itemY and mouseY <= itemY + itemHeight then
            -- hoveredItem = item;
        -- end

        love.graphics.draw(getRarityWindow(item.rarity or "common", "mid"), itemX, itemY, 0, imgScaleX, imgScaleY)
        setFont(itemNameFontSize);
        setFont(15);
        drawTextCenteredWithScale(item.name or "Unknown", itemX, itemY + 25 * scaleFactor, 1, arbitraryWidth, self.white);

        self.playerItemDescriptions[index]:update();
        self.playerItemDescriptions[index]:draw();

        setFont(sellButtonFontSize);

        if self.playerItemSellButtons[index]:isReleased() then
            local moneyBefore = Player.money;
            Player.money = Player.money + sellPrice;

            richGetRicherUpdate(moneyBefore, Player.money);
            playSoundEffect(upgradeSFX, 0.5, 0.95);

            if item.stats.amount then
                if item.stats.amount > 0 then
                    Balls.amountDecrease(item.stats.amount);
                elseif item.stats.amount < 0 then
                    Balls.amountIncrease(math.abs(item.stats.amount));
                end
            end

            if item.onSell then
                item:onSell();
            end

            table.remove(Player.items, index);
        end
    end
end

function ShopMenu:draw()
    self:drawPlayerStats();

    -- draw ball stats

    self:drawItemShop();
    self:drawPlayerItems();
end

ShopMenu:init();
return ShopMenu;
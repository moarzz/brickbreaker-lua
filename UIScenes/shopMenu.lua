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
end

ShopMenu:init();
return ShopMenu;
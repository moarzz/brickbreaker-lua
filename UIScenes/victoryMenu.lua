local VictoryMenu = UIScene.new();

function VictoryMenu:init()
    -- always 1920x1080
    local screenWidth, screenHeight = love.graphics.getDimensions();

    local buttonWidth = 350;
    local buttonHeight = 125;
    local buttonSpacing = 40;
    local buttonGap = buttonWidth + buttonSpacing;

    local startX = (screenWidth - buttonWidth * 3 - buttonSpacing * 2) / 2
    local startY = screenHeight * 3 / 4;

    self.continueButton = Button(startX + buttonGap * 0, startY, buttonWidth, buttonHeight);
    self.menuButton     = Button(startX + buttonGap * 1, startY, buttonWidth, buttonHeight);
    self.upgradesButton = Button(startX + buttonGap * 2, startY, buttonWidth, buttonHeight);

    VictoryMenu:addElements(
        self.continueButton,
        self.menuButton,
        self.upgradesButton
    );


    --[[local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    setFont(64)
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.printf("VICTORY!", 0, centerY - 200, screenWidth, "center")
    setFont(36)
    love.graphics.setColor(0.4, 0.7, 1.0, 1) -- Light blue for Score
    love.graphics.printf("Score : " .. tostring(Player.score), 0, centerY - 80, screenWidth, "center")
    love.graphics.setColor(1.0, 0.85, 0.4, 1) -- Light gold for Gold
    love.graphics.printf("Gold earned : " .. tostring(goldEarnedFrl), 0, centerY - 30, screenWidth, "center")
    love.graphics.setColor(1, 1, 1, 1) -- White for Time
    love.graphics.printf("Time : " .. string.format("%02d:%02d", math.floor(gameTime / 60), math.floor(gameTime % 60)), 0, centerY + 20, screenWidth, "center")
    love.graphics.setColor(1.0, 0.6, 0.2, 1) -- Light orange for Bricks Destroyed
    love.graphics.printf("Bricks Destroyed : " .. tostring(Player.bricksDestroyed), 0, centerY + 70, screenWidth, "center")
    setFont(28)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    love.graphics.printf("Press R to restart or ESC to quit", 0, centerY + 2000, screenWidth, "center")
    ]]
end

function VictoryMenu:update(dt)
    if self.continueButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        SET_STATE(GameState.PLAYING);  -- Set state back to playing
    end

    if self.menuButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        resetGame();
        SET_STATE(GameState.MENU);
    end

    if self.upgradesButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        resetGame();
        SET_STATE(GameState.UPGRADES);
        loadGameData();
    end
end

VictoryMenu:init();
return VictoryMenu;
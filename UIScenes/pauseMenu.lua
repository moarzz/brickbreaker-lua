local PauseMenu = UIScene.new();

function PauseMenu:init()
    -- always 1920x1080
    local screenWidth, screenHeight = love.graphics.getDimensions();

    local buttonWidth = 400;
    local buttonHeight = 75;
    local buttonSpacing = 30;
    local buttonGap = buttonHeight + buttonSpacing;

    local centerX = screenWidth / 2 - buttonWidth / 2;
    local startY = screenHeight / 2 - (buttonHeight * 3 + buttonSpacing * 2.5) / 2;

    self.resumeButton   = Button(centerX, startY + buttonGap * 0, buttonWidth, buttonHeight);
    self.settingsButton = Button(centerX, startY + buttonGap * 1, buttonWidth, buttonHeight);
    self.restartButton  = Button(centerX, startY + buttonGap * 2, buttonWidth, buttonHeight);
    self.menuButton     = Button(centerX, startY + buttonGap * 3, buttonWidth, buttonHeight);
    self.exitButton     = Button(centerX, startY + buttonGap * 4, buttonWidth, buttonHeight);

    PauseMenu:addElements(
        self.resumeButton,
        self.settingsButton,
        self.restartButton,
        self.menuButton,
        self.exitButton
    );
end

function PauseMenu:update(dt)
    if self.resumeButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        SET_STATE(GameState.PLAYING);
    end

    if self.settingsButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        SET_STATE(GameState.SETTINGS);
    end

    if self.restartButton:isReleased() then
        local goldEarned = Player.level * math.ceil(Player.level / 5) * 5;

        playSoundEffect(selectSFX, 1, 0.8);
        Player.addGold(goldEarned);
        saveGameData();
        resetGame();
        SET_STATE(GameState.START_SELECT);
    end

    if self.menuButton:isReleased() then
        local goldEarned = Player.level * math.ceil(Player.level / 5) * 5;

        playSoundEffect(selectSFX, 1, 0.8);
        Player.addGold(goldEarned);
        saveGameData();
        resetGame();
        SET_STATE(GameState.MENU);
    end

    if self.exitButton:isReleased() then
        local goldEarned = Player.level * math.ceil(Player.level / 5) * 5;

        playSoundEffect(selectSFX, 1, 0.8);
        Player.addGold(goldEarned);
        saveGameData();
        love.event.quit();
    end
end

PauseMenu:init();
return PauseMenu;
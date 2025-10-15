local MainMenu = UIScene.new();

function MainMenu:init()
    -- always 1920x1080
    local screenWidth, screenHeight = love.graphics.getDimensions();

    local buttonWidth = 400;
    local buttonHeight = 75;
    local buttonSpacing = 100;
    local buttonGap = buttonHeight + buttonSpacing;

    local centerX = screenWidth / 2 - buttonWidth / 2;
    local startY = screenHeight / 2 - (buttonHeight * 3 + buttonSpacing * 2) / 2;

    self.playButton     = Button(centerX, startY + buttonGap * 0, buttonWidth, buttonHeight); -- play button
    self.tutorialButton = Button(centerX, startY + buttonGap * 1, buttonWidth, buttonHeight); -- tutorial button
    self.settingsButton = Button(centerX, startY + buttonGap * 2, buttonWidth, buttonHeight); -- settings button
    self.upgradesButton = Button(centerX, startY + buttonGap * 3, buttonWidth, buttonHeight); -- upgrades button

    MainMenu:addElements(
        self.playButton,
        self.tutorialButton,
        self.settingsButton,
        self.upgradesButton
    );
end

function MainMenu:update(dt)
    if self.playButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        SET_STATE(GameState.START_SELECT); -- Go to selection screen
    end

    if self.tutorialButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        SET_STATE(GameState.TUTORIAL);
    end

    if self.settingsButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        SET_STATE(GameState.SETTINGS);
    end

    if self.upgradesButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        SET_STATE(GameState.UPGRADES);
        loadGameData(); -- Load game data when entering upgrades screen
    end
end

MainMenu:init();
return MainMenu;
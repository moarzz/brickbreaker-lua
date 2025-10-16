local SettingsMenu = UIScene.new();

function SettingsMenu:init()
    -- always 1920x1080
    local screenWidth, screenHeight = love.graphics.getDimensions();

    local buttonWidth = 400;
    local buttonHeight = 75;
    local buttonSpacing = 100;
    local buttonGap = buttonHeight + buttonSpacing;

    local centerX = screenWidth / 2 - buttonWidth / 2;
    local startY = screenHeight / 2 - (buttonHeight * 2 + buttonSpacing * 2.5) / 2;

    local sliderWidth = 400;
    local sliderHeight = 40;
    local sliderSpacing = 80;
    local sliderX = screenWidth / 2 - sliderWidth / 2;
    local sliderY = startY + 60;

    self.musicSlider        =  Slider(sliderX, sliderY                         , sliderWidth              );
    self.sfxSlider          =  Slider(sliderX, sliderY + sliderSpacing         , sliderWidth              );
    self.fullScreenCheckbox = Tickbox(sliderX, sliderY + sliderSpacing * 2     , 40         , 40          );
    self.backButton         =  Button(sliderX, sliderY + sliderSpacing * 3 + 20, sliderWidth, buttonHeight);

    SettingsMenu:addElements(
        self.musicSlider,
        self.sfxSlider,
        self.fullScreenCheckbox,
        self.backButton
    );
end

function SettingsMenu:update(dt)
    if self.musicSlider:getNewValue() then
        if backgroundMusic then
            backgroundMusic:setVolume(self.musicSlider:getNewValue() / 5); -- Adjust the volume of the background music
        else
            print("Background music not found");
        end
    end

    if self.sfxSlider:getNewValue() then
        sfxVolume = self.sfxSlider:getNewValue();
        playSoundEffect(selectSFX, sfxVolume, 1, false);
    end

    if self.fullScreenCheckbox:isChanged() then
        love.window.setFullscreen(self.fullScreenCheckbox:isActive());
    end

    if self.backButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);

        if inGame then
            SET_STATE(GameState.PAUSED);
        else
            SET_STATE(GameState.MENU);
        end
    end
end

SettingsMenu:init();
return SettingsMenu;
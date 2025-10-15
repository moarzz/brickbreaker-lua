local StartMenu = UIScene.new();

function StartMenu:init()
    local screenWidth, screenHeight = love.graphics.getDimensions();

    local buttonWidth = 400;
    local buttonHeight = 75;
    local buttonSpacing = 100;
    local buttonGap = buttonHeight + buttonSpacing;

    local centerX = screenWidth / 2 - buttonWidth / 2;
    local startY = screenHeight / 4;

    self.topText = FancyText.new("Choose your starting item", 0, startY - 100, screenWidth, 36, "center");

    self.previousStartingItem = Button(centerX - 120             , startY                                     , 125        , buttonHeight);
    self.nextStartingItem     = Button(centerX + buttonWidth + 20, startY                                     , 125        , buttonHeight);
    self.previousCore         = Button(centerX - 120             , startY + buttonGap + 200                   , 125        , buttonHeight);
    self.nextCore             = Button(centerX + buttonWidth + 20, startY + buttonGap + 200                   , 125        , buttonHeight);
    self.playButton           = Button(centerX                   , startY + buttonGap + buttonHeight * 2 + 380, buttonWidth, buttonHeight);

    StartMenu:addElements(
        self.previousStartingItem,
        self.nextStartingItem,
        self.previousCore,
        self.nextCore,
        self.playButton
    );

    -- setFont(36)
    -- love.graphics.setColor(1, 1, 1, 1)
    -- suit.Label("Choose your starting item", {align = "center"}, screenWidth / 2 - getTextSize("Choose your starting item") / 2, startY - 100)

    -- Dynamically build the list of unlocked starting items
    --[[local startingItems = {}

    -- build the list of starting paddle cores
    local paddleCores = {}
    for _, core in ipairs(Player.availableCores) do
        local coreName = core.name -- Use core name if available, otherwise use the core itself
        if Player.paddleCores[coreName] then
            table.insert(paddleCores, coreName)
        end
    end

    -- Always include Ball
    table.insert(startingItems, {name = "Ball", id = "start_Ball", label = "Ball"})
    if Player.unlockedStartingBalls then
        for _, itemName in ipairs(startingItemOrder) do
            if Player.unlockedStartingBalls[itemName] then
                table.insert(startingItems, {name = itemName, id = "start_"..itemName:gsub(" ", "_"), label = itemName})
            end
        end
    end

    -- Always include Nothing
    --table.insert(startingItems, {name = "Nothing", id = "start_Nothing", label = "Nothing"})

    local btnY = startY
    local item = startingItems[currentStartingItemID]
    if paddleCores[currentSelectedCoreID] == "IncrediCore" then
        item = {name = "Incrediball", label = "Incrediball"}
    end
    -- Show the starting item description under the label
    local itemDescription = "No description available for ".. item.label
    if item.label == "Ball" then
        itemDescription = "Basic ball. Very fast."
    elseif item.label == "Machine Gun" then
        itemDescription = "Fires bullets. \nFast fire rate."
    elseif item.label == "Laser Beam" then
        itemDescription = "Fire a thin Laser beam in front of the paddle."
    elseif item.label == "Shadow Ball" then
        itemDescription = "Shoots shadowBalls that pass through bricks. \nVery slow fire rate."
    elseif item.label == "Incrediball" then
        itemDescription = "Has the effects of every other ball (except phantom ball)."
    end
    setFont(36)]]
    --local btn = suit.Label(item.label, {id = item.id}, centerX, btnY, buttonWidth, buttonHeight)
    --setFont(25)
    --suit.Label(itemDescription, {align = "center"}, centerX-100, btnY + buttonHeight + 10, 600, 60)


    -- local btnBefore = suit.Button("Back", {id = "back_starting_item"}, centerX - 100 - 20, btnY, 125, buttonHeight)
    -- local btnNext = suit.Button("Next", {id = "next_starting_item"}, centerX + buttonWidth + 20, btnY, 125, buttonHeight)
    --[[if btnNext.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentStartingItemID = currentStartingItemID + 1
        if currentStartingItemID > #startingItems then
            currentStartingItemID = 1
        end
        item = startingItems[currentStartingItemID]
        while (item.label == "1" or item.label == "2" or item.label == "3") do
            currentStartingItemID = currentStartingItemID + 1
            if currentStartingItemID > #startingItems then
                currentStartingItemID = 1
            end
            item = startingItems[currentStartingItemID]
        end
    end
    if btnBefore.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentStartingItemID = currentStartingItemID - 1
        if currentStartingItemID < 1 then
            currentStartingItemID = #startingItems
        end
        item = startingItems[currentStartingItemID]
        while (item.label == "1" or item.label == "2" or item.label == "3") do
            currentStartingItemID = currentStartingItemID - 1
            if currentStartingItemID < 1 then
                currentStartingItemID = #startingItems
            end
            item = startingItems[currentStartingItemID]
        end
    end]]

    -- logic for choosing paddle core
    --[[btnY = btnY + buttonHeight + 200
    setFont(36)
    suit.Label("Choose your paddle core", {align = "center"}, screenWidth / 2 - getTextSize("Choose your paddle core") / 2, btnY - 80)
    local currentSelectedCore = paddleCores[currentSelectedCoreID]
    if not currentSelectedCoreID then
        currentSelectedCoreID = 1
    end
    if not currentSelectedCore then
        currentSelectedCore = (paddleCores[currentSelectedCoreID] and paddleCores[currentSelectedCoreID].name or "Bouncy Core")
    end
    local btn2 = suit.Label(currentSelectedCore, centerX, btnY, buttonWidth, buttonHeight)
    
    setFont(25)
    local core = paddleCores[currentSelectedCoreID]
    -- local btn2Before = suit.Button("Back", {id = "back_core"}, centerX - 100 - 20, btnY, 125, buttonHeight)
    -- local btn2Next = suit.Button("Next", {id = "next_core"}, centerX + buttonWidth + 20, btnY, 125, buttonHeight)

    --[[if btn2Next.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentSelectedCoreID = currentSelectedCoreID + 1
        if currentSelectedCoreID > #paddleCores then
            currentSelectedCoreID = 1
        end
        core = paddleCores[currentSelectedCoreID]
        currentSelectedCore = core
    end
    if btn2Before.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentSelectedCoreID = currentSelectedCoreID - 1
        if currentSelectedCoreID < 1 then
            currentSelectedCoreID = #paddleCores
        end
        core = paddleCores[currentSelectedCoreID]
        currentSelectedCore = core.name
    end

    -- Show the currently selected core
    setFont(25)
    -- Draw Play button centered under everything else
    local btnY = btnY + buttonHeight + 80
    local coreDescription = Player.coreDescriptions[core] and Player.coreDescriptions[core] or "No description available"
    suit.Label(coreDescription, {align = "center"}, screenWidth / 2 - 300, btnY - 50, 600, 100)
    local playBtnY = btnY + buttonHeight + 100
    setFont(40)
    local playBtn = suit.Button("Play", {id = "start_play"}, screenWidth / 2 - buttonWidth / 2, playBtnY, buttonWidth, buttonHeight)
    if playBtn.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        startingChoice = item.name
        startingItemName = item.name
        Player.currentCore = currentSelectedCore -- Set the selected paddle core
        resetGame()
        SET_STATE(GameState.PLAYING);
        -- initializeGameState()
        Player.bricksDestroyed = 0 -- Reset bricks destroyed count
        if item.name ~= "Nothing" and Player.currentCore ~= "Speed Core" then
            Balls.addBall(item.name)
        end
    end]]







    -- always 1920x1080
    --[[local screenWidth, screenHeight = love.graphics.getDimensions();

    local buttonWidth = 400;
    local buttonHeight = 75;
    local buttonSpacing = 100;
    local buttonGap = buttonHeight + buttonSpacing;

    local centerX = screenWidth / 2 - buttonWidth / 2;
    local startY = screenHeight / 2 - (buttonHeight * 3 + buttonSpacing * 2) / 2;

    self.playButton     = Button(centerX, startY + buttonGap * 0, buttonWidth, buttonHeight);     -- play button
    self.tutorialButton = Button(centerX, startY + buttonGap * 1, buttonWidth, buttonHeight); -- tutorial button
    self.settingsButton = Button(centerX, startY + buttonGap * 2, buttonWidth, buttonHeight); -- settings button
    self.upgradesButton = Button(centerX, startY + buttonGap * 3, buttonWidth, buttonHeight); -- upgrades button

    StartMenu:addElements(
        self.playButton,
        self.tutorialButton,
        self.settingsButton,
        self.upgradesButton
    );]]
end

function StartMenu:update(dt)
    if self.nextStartingItem:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        currentStartingItemID = currentStartingItemID + 1;

        --if currentStartingItemID > #startingItems then
        --    currentStartingItemID = 1;
        --end

        --[[item = startingItems[currentStartingItemID];

        while (item.label == "1" or item.label == "2" or item.label == "3") do
            currentStartingItemID = currentStartingItemID + 1;

            if currentStartingItemID > #startingItems then
                currentStartingItemID = 1;
            end

            item = startingItems[currentStartingItemID];
        end]]
    end

    if self.previousStartingItem:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        currentStartingItemID = currentStartingItemID - 1;

        --if currentStartingItemID < 1 then
        --    currentStartingItemID = #startingItems;
        --end

        --[[item = startingItems[currentStartingItemID];

        while (item.label == "1" or item.label == "2" or item.label == "3") do
            currentStartingItemID = currentStartingItemID - 1;

            if currentStartingItemID < 1 then
                currentStartingItemID = #startingItems;
            end

            item = startingItems[currentStartingItemID];
        end]]
    end

    if self.nextCore:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        currentSelectedCoreID = currentSelectedCoreID + 1;

        --if currentSelectedCoreID > #paddleCores then
        --    currentSelectedCoreID = 1;
        --end

        -- core = paddleCores[currentSelectedCoreID];
        -- currentSelectedCore = core;
    end

    if self.previousCore:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        currentSelectedCoreID = currentSelectedCoreID - 1;

        --if currentSelectedCoreID < 1 then
        --    currentSelectedCoreID = #paddleCores;
        --end

        -- core = paddleCores[currentSelectedCoreID];
        -- currentSelectedCore = core.name;
    end

    if self.playButton:isReleased() then
        playSoundEffect(selectSFX, 1, 0.8);
        startingChoice = "Ball";
        startingItemName = "Ball";
        Player.currentCore = currentSelectedCore; -- Set the selected paddle core
        resetGame();
        SET_STATE(GameState.PLAYING);
        -- initializeGameState()
        Player.bricksDestroyed = 0; -- Reset bricks destroyed count
        if "Ball" ~= "Nothing" and Player.currentCore ~= "Speed Core" then
            Balls.addBall("Ball"); --! unfiltered
        end
    end
end

function StartMenu:draw()
    self.topText:draw();
end

StartMenu:init();
return StartMenu;
local ShopMenu = UIScene.new();

function ShopMenu:init()
    -- always 1920x1080
    local screenWidth, screenHeight = love.graphics.getDimensions();

    ShopMenu:addElements(
    );
end

function ShopMenu:update(dt)
end

function ShopMenu:draw()
    local xOffset = -uiOffset.x

    -- Initialize the layout for the stats section
    local x, y = screenWidth/2 - uiWindowImg:getWidth()/2, screenHeight - uiWindowImg:getHeight() + 60
    --love.graphics.draw(uiWindowImg, x, y) -- Draw the background window image
    local padding = 10
    x = x + 20 + xOffset
    y = y + 40

    -- Draw the "Stats" title header
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
    local xx = x
    local statsLayout = {
        min_width = 430, -- Minimum width for the layout
        pos = {x, y}, -- Starting position (x, y)
        padding = {padding, padding}, -- Padding between cells
        {"fill", 30},
        {"fill"}
    }

    local definition = suit.layout:cols(statsLayout) -- Create a column layout for the stats

    local x, y, w, h = definition.cell(2)
    local fontSize = 80 * (moneyScale.scale or 1)
    setFont(fontSize)
    -- love.graphics.setColor(1,1,1,1)
    -- x,y = statsWidth/2 - getTextSize(formatNumber(Player.money))/2 - 100, 175 - love.graphics.getFont():getHeight()/2 -- Adjust position for better alignment

    local statsWidth = 450;

    local moneyText = formatNumber(Player.money) .. "$";
    local x = statsWidth / 2 - getTextSize(moneyText) / 2 - 100;
    local y = 175 - love.graphics.getFont():getHeight() / 2;
    
    love.graphics.setColor(0,0,0); -- drop shadow
    love.graphics.print(moneyText, x + 104, y + 5, math.rad(1.5));
    love.graphics.setColor(14/255, 202/255, 92/255);
    love.graphics.print(moneyText, x + 100, y + 1, math.rad(1.5));
end

ShopMenu:init();
return ShopMenu;
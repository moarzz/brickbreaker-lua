local HugePaddle = ItemBase.new();
HugePaddle.__index = HugePaddle;
HugePaddle.name = "Huge Paddle";
HugePaddle.description = "paddle width is increased by <font=bold><paddleWidth>%";
HugePaddle.rarity = "common";
HugePaddle.imageReference = "assets/sprites/UI/itemIcons/Huge-Paddle.png";

function HugePaddle.new()
    local instance = setmetatable({}, HugePaddle):init();

    instance.descriptionPointers = {
        paddleWidth = hasItem("Four Leafed Clover") and 100 or 50;
    };

    return instance;
end

function HugePaddle.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.paddleWidth = 100;
end

function HugePaddle.events:item_sell_FourLeafedClover()
    self.descriptionPointers.paddleWidth = 50;
end

return HugePaddle;
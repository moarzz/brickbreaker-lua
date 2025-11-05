local TextBatching = {};
local self = TextBatching; -- for readability

TextBatching.filename = "textBatching.png";
TextBatching.fontSize = 18;

setFont(TextBatching.fontSize);

TextBatching.fontHeight = love.graphics.getFont():getHeight();
TextBatching.fontWidth = { -- because I dont trust french ppl
    love.graphics.getFont():getWidth("1");
    love.graphics.getFont():getWidth("2");
    love.graphics.getFont():getWidth("3");
    love.graphics.getFont():getWidth("4");
    love.graphics.getFont():getWidth("5");
    love.graphics.getFont():getWidth("6");
    love.graphics.getFont():getWidth("7");
    love.graphics.getFont():getWidth("8");
    love.graphics.getFont():getWidth("9");
    love.graphics.getFont():getWidth("0");
};
TextBatching.fontWidth["1"] = TextBatching.fontWidth[1];
TextBatching.fontWidth["2"] = TextBatching.fontWidth[2];
TextBatching.fontWidth["3"] = TextBatching.fontWidth[3];
TextBatching.fontWidth["4"] = TextBatching.fontWidth[4];
TextBatching.fontWidth["5"] = TextBatching.fontWidth[5];
TextBatching.fontWidth["6"] = TextBatching.fontWidth[6];
TextBatching.fontWidth["7"] = TextBatching.fontWidth[7];
TextBatching.fontWidth["8"] = TextBatching.fontWidth[8];
TextBatching.fontWidth["9"] = TextBatching.fontWidth[9];
TextBatching.fontWidth["0"] = TextBatching.fontWidth[10];

TextBatching.fontWidth[11] = math.max( -- [11] is just the widest character
    TextBatching.fontWidth[1],
    TextBatching.fontWidth[2],
    TextBatching.fontWidth[3],
    TextBatching.fontWidth[4],
    TextBatching.fontWidth[5],
    TextBatching.fontWidth[6],
    TextBatching.fontWidth[7],
    TextBatching.fontWidth[8],
    TextBatching.fontWidth[9],
    TextBatching.fontWidth[10]
);

TextBatching.spriteMax = 700;

function TextBatching.init()
    if not love.filesystem.getInfo(self.filename) then
        self.generateTexture();
    else
        self.image = love.graphics.newImage(self.filename);
    end

    self.maxDigits = 0;
    self.batches = {};
    self.generateQuads(); -- create quads
    self.generateBatches(1); -- create batches
end

function TextBatching.generateTexture()
    local canv = love.graphics.newCanvas(self.fontWidth[11] * 10, self.fontHeight);

    setFont(self.fontSize);

    love.graphics.setCanvas(canv);
    love.graphics.setShader(); -- no shader
    love.graphics.setColor(1,1,1); -- white

    for i = 1, 10 do
        local char = string.sub(tostring(i), -1,-1);

        love.graphics.print(char, (i - 1) * self.fontWidth[11], 0);
    end

    love.graphics.setCanvas();

    local imgData = canv:newImageData();

    imgData:encode("png", self.filename);
    self.image = love.graphics.newImage(imgData);
end

function TextBatching.generateQuads()
    self.quads = {}; -- table of quads to each sub sprite

    for i = 1, 10 do
        self.quads[tostring(i % 10)] = love.graphics.newQuad((i - 1) * self.fontWidth[11], 0, self.fontWidth[i], self.fontHeight, self.image);
    end
end

function TextBatching.generateBatches(digitLength)
    for i = #self.batches, digitLength + 1 do
        table.insert(self.batches, love.graphics.newSpriteBatch(self.image, self.spriteMax));
    end

    self.maxDigits = digitLength;
end

function TextBatching.clear()
    for _, v in ipairs(self.batches) do
        v:clear();
    end
end

function TextBatching.addText(text, x, y, r, sx, sy, ox, oy, kx, ky)
    local textLen = string.len(text);

    if textLen > self.maxDigits then -- if we need to add another digit top the sprite batches
        self.generateBatches(textLen);
    end

    assert(string.match(text, "[^0-9]") == nil, "tried to draw batched text that contains a non digit");

    local i = 1;
    for digit in string.gmatch(text, ".") do
        self.batches[i]:add(self.quads[digit], x, y, r, sx, sy, ox, oy, kx, ky);
        x = x + self.fontWidth[digit];
        i = i + 1;
    end
end

function TextBatching.setColor(...)
    for _, v in ipairs(self.batches) do
        v:setColor(...);
    end
end

function TextBatching.draw()
    for _, v in ipairs(self.batches) do
        love.graphics.draw(v);
    end
end

TextBatching.init(); -- call init on require()
return TextBatching;
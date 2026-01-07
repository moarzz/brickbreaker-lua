function love.conf(t)
    t.identity = 'brickbreaker-lua'
    t.version = "11.4"

    t.console = true;

    -- Window settings
    t.window.title = "Brick Breaker"
    t.window.width = 960
    t.window.height = 540
    t.window.fullscreen = false
    t.window.vsync = 0

    -- ADD THESE LINES HERE:
    t.window.resizable = true
    t.window.highdpi = false     -- Browsers struggle with HighDPI + complex shaders
    t.window.usedpiscale = false -- Keep coordinates consistent for shaders
    t.window.stencil = true      -- Some shaders need this for masking
    t.window.depth = 32          -- This forces RGBA8 instead of RGBA4
end
function love.conf(t)
    t.identity = 'brickbreaker-lua'           -- The name of the save directory
    t.version = "11.4"                        -- The LÖVE version this game was made for

    t.console = true;

    -- Window settings
    t.window.title = "Brick Breaker"          -- The window title
    t.window.width = 960;                     -- The window width
    t.window.height = 540;                    -- The window height
    t.window.fullscreen = false;                -- Enable fullscreen
    t.window.vsync = 0                        -- Disable VSync

    t.window.resizable = true;

    -- Performance
    --t.gammacorrect = true                    -- Enable gamma-correct rendering
    --t.window.refreshrate = 120                -- Target refresh rate (cap FPS)
end
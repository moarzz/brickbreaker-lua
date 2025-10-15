local targetFPS = 60;
local targetDT = 1 / targetFPS;

function love.run()
    LoveAffix.makeFunctionInjectable("timer", "getDelta");
    LoveAffix.replaceFunctionInLove(function() return targetDT end, "timer", "getDelta");

    if love.load then
        love.load(love.arg.parseGameArguments(arg), arg);
    end

    assert(love.timer, "tried to run the game without love.timer enabled");

	-- We don't want the first frame's dt to include time taken by love.load.
    love.timer.step();

	local dt = 0;

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump();

			for name, a, b, c, d, e, f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0;
					end
				end

				love.handlers[name](a, b, c, d, e, f);
			end
		end

		-- Update dt, as we'll be passing it to update
        dt = dt + love.timer.step();

		-- Call update and draw
		if love.update and dt >= targetDT then
            love.update(targetDT);

            if dt >= targetDT * 2 then
                print("lag");
            end

            dt = dt % targetDT; -- if lag lasts multiple frames then just eat the lag
            -- we dont want a spiral of lag frames
        end

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin();
			love.graphics.clear(love.graphics.getBackgroundColor());

			-- local startData = collectgarbage("count");
			if love.draw then
                love.draw();
            end
			-- print(collectgarbage("count") - startData);

			love.graphics.present();
		end

        love.timer.sleep(0.001);
	end
end
-- LOVE Asset Async Loader
-- Copyright (c) 2021 Miku AuahDark
--
-- This software is provided 'as-is', without any express or implied
-- warranty. In no event will the authors be held liable for any damages
-- arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
--
-- 1. The origin of this software must not be misrepresented; you must not
--    claim that you wrote the original software. If you use this software
--    in a product, an acknowledgment in the product documentation would be
--    appreciated but is not required.
-- 2. Altered source versions must be plainly marked as such, and must not be
--    misrepresented as being the original software.
-- 3. This notice may not be removed or altered from any source distribution.

-- Need love module
local love = require("love")
assert(love._version >= "11.0", "Lily v3.x require at least LOVE 11.0")
-- Need love.event
assert(love.event, "Lily requires love.event. Enable it in conf.lua or require it manually!")

-- Check if we're on web (no threading support)
local isWeb = love.system and love.system.getOS() == "Web"
local hasThreads = not isWeb and love.thread ~= nil

if not isWeb and not hasThreads then
	error("Lily requires love.thread on non-web platforms. Enable it in conf.lua or require it manually!")
end

local modulePath = select(1, ...):match("(.-)[^%.]+$")
local lily = {
	_VERSION = "3.0.12-web",
	-- Loaded modules
	modules = {},
	-- List of threads
	threads = {},
	-- Function handler
	handlers = {},
	-- Request list
	request = {},
	-- Web mode flag
	isWebMode = isWeb
}

-- List of excluded modules to be loaded (doesn't make sense to be async)
local excludedModules = {
	"event",
	"joystick",
	"keyboard",
	"math",
	"mouse",
	"physics",
	"system",
	"timer",
	"touch",
	"window"
}
-- List all loaded LOVE modules using hidden "love._modules" table
for name in pairs(love._modules) do
	local f = false
	for i = 1, #excludedModules do
		if excludedModules[i] == name then
			-- Excluded
			f = true
			break
		end
	end

	-- If not excluded, add it.
	if not(f) then
		lily.modules[#lily.modules + 1] = name
	end
end

-- Variables used for threading (only if not web)
local amountOfCPU = 1
local errorChannel, taskChannel, dataPullChannel, updateModeChannel
local lilyThreadScript = nil

if hasThreads then
	-- We have some ways to get processor count
	if love.system then
		-- love.system is loaded. We can use that.
		amountOfCPU = love.system.getProcessorCount()
	elseif love._os == "Windows" then
		-- Windows. Use NUMBER_OF_PROCESSORS environment variable
		amountOfCPU = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))

		-- We still have some workaround if that fails
		if not(amountOfCPU) and os.execute("wmic exit") == 0 then
			-- Use WMIC
			local a = io.popen("wmic cpu get NumberOfLogicalProcessors")
			a:read("*l")
			amountOfCPU = a:read("*n")
			a:close()
		end

		-- If it's fallback to 1, it's either very weird system configuration!
		-- (except if the CPU only has 1 processor)
		amountOfCPU = amountOfCPU or 1
	elseif os.execute() == 1 then
		-- Ok we have shell support
		if os.execute("nproc") == 0 then
			-- Use nproc
			local a = io.popen("nproc", "r")
			amountOfCPU = a:read("*n")
			a:close()
		end
		-- Fallback to single core (discouraged, it will perform same as love-loader)
	end
	-- Limit CPU to 4. Imagine how many threads will be created when
	-- someone runs this in threadripper.
	amountOfCPU = math.min(amountOfCPU, 4)

	-- Dummy channel used to signal main thread that there's error
	errorChannel = love.thread.newChannel()
	-- Main channel used to push task
	taskChannel = love.thread.newChannel()
	lily.taskChannel = taskChannel
	-- Main channel used to pull task
	dataPullChannel = love.thread.newChannel()
	lily.dataPullChannel = dataPullChannel
	-- Main channel to determine how to push event
	updateModeChannel = love.thread.newChannel()
	lily.updateModeChannel = updateModeChannel
	updateModeChannel:push("automatic") -- Use LOVE event handling by default
end

-- Web mode synchronous execution queue
local webQueue = {}
local webProcessing = false

-- Function to initialize threads. Must be declared as local
-- then called later
local function initThreads()
	if not hasThreads then return end
	
	for i = 1, amountOfCPU do
		-- Create thread
		local a = love.thread.newThread(
			lilyThreadScript or
			(modulePath:gsub("%.", "/").."lily_thread.lua")
		)
		-- Arguments are:
		-- Loaded modules
		-- errorChannel
		-- taskChannel
		-- dataPullChannel
		-- updateModeChannel
		a:start(lily.modules, errorChannel, taskChannel, dataPullChannel, updateModeChannel)
		lily.threads[i] = a
	end
end

--luacheck: push no unused args
----------------
-- LilyObject --
----------------
local lilyObjectMethod = {}
local lilyObjectMeta = {__index = lilyObjectMethod}

-- Complete function
function lilyObjectMethod.complete(userdata, ...)
end

-- On error function
function lilyObjectMethod.error(userdata, errorMessage, source)
	error(errorMessage.."\n"..source)
end

function lilyObjectMethod:onComplete(func)
	self.complete = assert(
		type(func) == "function" and func,
		"bad argument #1 to 'lilyObject:onComplete' (function expected)"
	)
	return self
end

function lilyObjectMethod:onError(func)
	self.error = assert(
		type(func) == "function" and func,
		"bad argument #1 to 'lilyObject:onError' (function expected)"
	)
	return self
end

function lilyObjectMethod:setUserData(userdata)
	self.userdata = userdata
	return self
end

function lilyObjectMethod:isComplete()
	return not(not(self.values))
end

function lilyObjectMethod:getValues()
	assert(self.values, "Incomplete request")
	return unpack(self.values)
end

function lilyObjectMeta:__tostring()
	return "LilyObject: "..self.requestType
end

---------------------
-- MultiLilyObject --
---------------------
local multiObjectMethod = {}
local multiObjectMeta = {__index = multiObjectMethod}
-- On loaded function (noop)
multiObjectMethod.loaded = lilyObjectMethod.complete
-- On error function
function multiObjectMethod.error(userdata, lilyIndex, errorMessage, source)
	error(errorMessage.."\n"..source)
end
-- On complete function (noop)
multiObjectMethod.complete = lilyObjectMethod.complete
-- Internal function for child lilies error handler
local function multiObjectChildErrorHandler(userdata, errorMessage, source)
	-- Userdata is {index, parentObject}
	local multi = userdata[2]
	multi.error(multi.userdata, userdata[1], errorMessage, source)
end

-- Internal function used for child lilies onComplete callback
local function multiObjectOnLoaded(info, ...)
	-- Info is {index, parentObject}
	local multiLily = info[2]

	multiLily.completedRequest = multiLily.completedRequest + 1
	multiLily.loaded(multiLily.userdata, info[1], select(1, ...))

	-- If it's complete, then call onComplete callback of MultiLilyObject
	if multiLily:isComplete() then
		-- Process
		local output = {}
		for i = 1, #multiLily.lilies do
			output[i] = multiLily.lilies[i].values
		end

		multiLily.complete(multiLily.userdata, output)
	end
end

function multiObjectMethod:onLoaded(func)
	self.loaded = assert(
		type(func) == "function" and func,
		"bad argument #1 to 'lilyObject:onLoaded' (function expected)"
	)
	return self
end

function multiObjectMethod:onComplete(func)
	self.complete = assert(
		type(func) == "function" and func,
		"bad argument #1 to 'lilyObject:onComplete' (function expected)"
	)
	return self
end

function multiObjectMethod:onError(func)
	self.error = assert(
		type(func) == "function" and func,
		"bad argument #1 to 'lilyObject:onError' (function expected)"
	)
	return self
end

function multiObjectMethod:setUserData(userdata)
	self.userdata = userdata
	return self
end

function multiObjectMethod:isComplete()
	return self.completedRequest >= #self.lilies
end

function multiObjectMethod:getValues(index)
	assert(self:isComplete(), "Incomplete request")

	if index == nil then
		local output = {}
		for i = 1, #self.lilies do
			output[i] = self.lilies[i].values
		end

		return output
	end

	return assert(self.lilies[index], "Invalid index"):getValues()
end

function multiObjectMethod:getCount()
	return #self.lilies
end

function multiObjectMethod:getLoadedCount()
	return self.completedRequest
end

multiObjectMeta.__len = multiObjectMethod.getCount

-- luacheck: pop

-- Lily global event handling function
local function lilyEventHandler(reqID, v1, v2)
	-- Check if specified request exist
	if lily.request[reqID] then
		local lilyObject = lily.request[reqID]
		lily.request[reqID] = nil

		-- Check for error
		if v1 == errorChannel or (isWeb and v1 == "error") then
			-- Second argument is the error message
			lilyObject.error(lilyObject.userdata, v2, lilyObject.trace)
		else
			-- "v2" is returned values
			-- Call main thread handler for specified request type
			local values = {pcall(lily.handlers[lilyObject.requestType], lilyObject, unpack(v2))}
			-- If values[1] is false then there's error
			if not(values[1]) then
				lilyObject.error(lilyObject.userdata, values[2])
			else
				-- No error. Remove first value (pcall status)
				table.remove(values, 1)
				-- Set values table
				lilyObject.values = values
				lilyObject.complete(lilyObject.userdata, unpack(values))
			end
		end
	end
end

-- Add Lily event handler to love.handlers (lily_resp)
if hasThreads then
	love.handlers.lily_resp = lilyEventHandler
end

--- Get amount of thread for processing
-- In most cases, this is amount of logical CPU available.
-- @treturn number Amount of threads used by Lily.
function lily.getThreadCount()
	return hasThreads and amountOfCPU or 0
end

--- Uninitializes Lily and used threads.
-- Call this just before your game quit (inside `love.quit()`).
-- Not calling this function in iOS and Android can cause
-- strange crash when re-starting your game!
function lily.quit()
	if not hasThreads then return end
	
	-- Clear up the task channel
	while taskChannel:getCount() > 0 do
		taskChannel:pop()
	end

	-- Push quit request in task channel
	-- Anything that is not a table is considered as "exit"
	for i = 1, amountOfCPU do
		taskChannel:push(i)
	end

	-- Clean up threads
	for i = 1, amountOfCPU do
		local t = lily.threads[i]
		if t then
			-- Wait
			t:wait()
			-- Clear
			lily.threads[i] = nil
		end
	end

	-- Reset package table
	package.loaded.lily = nil
end

do
local function atomicSetUpdateMode(_, mode)
	updateModeChannel:pop()
	updateModeChannel:push(mode)
end
--- Set update mode.
-- tell Lily to pull data by using LOVE event handler or by
-- using `lily.update` function.
-- @tparam string mode Either `automatic` or `manual`.
function lily.setUpdateMode(mode)
	if mode ~= "automatic" and mode ~= "manual" then
		error("bad argument #1 to 'setUpdateMode' (\"automatic\" or \"manual\" expected)", 2)
	end
	
	if hasThreads then
		-- Set update mode
		updateModeChannel:performAtomic(atomicSetUpdateMode, mode)
	end
	-- Web mode is always "automatic" (synchronous)
end
end -- do

local function manualProcessSingleData()
	local count = dataPullChannel:getCount()
	local processed = false

	if count > 0 then
		-- Pop data
		local data = dataPullChannel:pop()
		-- Pass to event handler
		lilyEventHandler(data[1], data[2], data[3])
		processed = true
	end

	return count, processed
end

-- Web mode: process one item from queue per frame
local function webProcessQueue()
	if #webQueue == 0 then
		webProcessing = false
		return
	end
	
	local task = table.remove(webQueue, 1)
	local reqID = task.reqID
	local requestType = task.requestType
	local args = task.args
	
	-- Execute synchronously
	local success, result = pcall(function()
		-- Get the actual LOVE function based on request type
		if requestType == "newSource" then
			return {love.audio.newSource(args[1], args[2])}
		elseif requestType == "compress" then
			return {love.data.compress("data", args[1] or "lz4", args[2], args[3]):getString()}
		elseif requestType == "decompress" then
			return {love.data.decompress("data", args[1], args[2]):getString()}
		elseif requestType == "append" then
			return {assert(love.filesystem.append(args[1], args[2], args[3]))}
		elseif requestType == "newFileData" then
			return {assert(love.filesystem.newFileData(args[1], args[2], args[3]))}
		elseif requestType == "read" then
			return {assert(love.filesystem.read(args[1], args[2]))}
		elseif requestType == "readFile" then
			return {args[1]:read(args[2])}
		elseif requestType == "write" then
			return {assert(love.filesystem.write(args[1], args[2], args[3]))}
		elseif requestType == "writeFile" then
			return {args[1]:write(args[2], args[3])}
		elseif requestType == "newFont" then
			return {love.graphics.newFont(args[1], args[2])}
		elseif requestType == "newImage" then
			local s, x = pcall(love.image.newImageData, args[1])
			local imgData = s and x or love.image.newCompressedData(args[1])
			return {love.graphics.newImage(imgData, args[2])}
		elseif requestType == "newVideo" then
			return {love.graphics.newVideo(args[1]), args[2]}
		elseif requestType == "encodeImageData" then
			return {args[1]:encode(args[2])}
		elseif requestType == "newImageData" then
			return {love.image.newImageData(args[1])}
		elseif requestType == "newCompressedData" then
			return {love.image.newCompressedData(args[1])}
		elseif requestType == "pasteImageData" then
			return {args[1]:paste(args[2], args[3], args[4], args[5], args[6], args[7])}
		elseif requestType == "newSoundData" then
			return {love.sound.newSoundData(args[1], args[2], args[3], args[4])}
		elseif requestType == "newVideoStream" then
			return {love.video.newVideoStream(args[1])}
		else
			error("Unknown request type: " .. tostring(requestType))
		end
	end)
	
	if success then
		lilyEventHandler(reqID, true, result)
	else
		lilyEventHandler(reqID, "error", result)
	end
end

-- Hook into love.update to process web queue
if isWeb then
	local oldUpdate = love.update
	function love.update(dt)
		if oldUpdate then oldUpdate(dt) end
		webProcessQueue()
	end
end

--- Pull processed data from other threads.
-- Signals other loader object (calling their callback function) when necessary.
function lily.update(timeout)
	if isWeb then
		-- Web mode: process all pending items
		while #webQueue > 0 do
			webProcessQueue()
		end
		return 0, 0
	end
	
	timeout = timeout or -1
	local left = -1
	local count = 0

	if love.timer and timeout >= 0 then
		local t = love.timer.getTime() + timeout

		while love.timer.getTime() < t and (left > 0 or left == -1) do
			local processed
			left, processed = manualProcessSingleData()
			count = count + (processed and 1 or 0)
		end
	else
		-- No love.timer (can't use timeout object) or timeout is negative.
		while (left > 0 or left == -1) do
			local processed
			left, processed = manualProcessSingleData()
			count = count + (processed and 1 or 0)
		end
	end

	return count, math.max(left, 0)
end

----------------------------------------
-- Lily async asset loading functions --
----------------------------------------
local function dummyhandler(...)
	return select(2, ...)
end

local function wraphandler(fname)
	return function(...)
		return fname(select(2, ...))
	end
end

-- Internal function to create request ID
local function createReqID()
	local t = {}
	for _ = 1, 64 do
		t[#t + 1] = string.char(math.random(0, 255))
	end

	return table.concat(t)
end

-- Internal function which return function to create LilyObject
-- with specified request type
local function newLilyFunction(requestType, handlerFunc)
	local tracebackname = "Function is lily."..requestType

	-- This function is the constructor
	lily[requestType] = function(...)
		-- Initialize
		local this = setmetatable({}, lilyObjectMeta)
		local reqID = createReqID()
		local args = {...}
		-- Values
		this.requestType = requestType
		this.done = false
		this.values = nil
		this.trace = debug.traceback(tracebackname)

		if isWeb then
			-- Web mode: add to synchronous queue
			table.insert(webQueue, {
				reqID = reqID,
				requestType = requestType,
				args = args
			})
			webProcessing = true
		else
			-- Thread mode: push task
			local treq = {reqID, requestType, #args}
			-- Push arguments
			for i = 1, #args do
				treq[i + 3] = args[i]
			end
			-- Add to task channel
			taskChannel:push(treq)
		end
		
		-- Insert to request table (to prevent GC collecting it)
		lily.request[reqID] = this
		-- Return
		return this
	end
	-- Handler function
	lily.handlers[requestType] = handlerFunc and wraphandler(handlerFunc) or dummyhandler
end

-- love.audio
if love.audio then
	newLilyFunction("newSource")
end

-- love.data (always exists)
if love.data then
	local function dataGetString(value)
		return value:getString()
	end
	newLilyFunction("compress", dataGetString)
	newLilyFunction("decompress", dataGetString)
end

-- love.filesystem (always exists)
if love.filesystem then
	newLilyFunction("append")
	newLilyFunction("newFileData")
	newLilyFunction("read")
	newLilyFunction("readFile")
	newLilyFunction("write")
	newLilyFunction("writeFile")
end

-- Most love.graphics functions are not meant for multithread, but we can circumvent that.
if love.graphics then
	-- Internal function
	local function defMultiToSingleError(udata, _, msg)
		udata[1].error(udata[1].userdata, msg)
	end
	-- Internal function to generate complete callback
	local function defImageMultiGen(f)
		return function(udata, values)
			local this = udata[1]
			local v = {}
			for i = 1, #values do
				v[i] = values[i][1]
			end
			this.values = {f(v, udata[2])}
			this.complete(this.userdata, unpack(this.values))
		end
	end

	-- Internal function to generate layering-based function
	local function genLayerImage(name, handlerFunc)
		local defCompleteFunction = defImageMultiGen(handlerFunc)

		lily.handlers[name] = wraphandler(handlerFunc)
		lily[name] = function(layers, setting)
			local multiCount = {}
			for _, v in ipairs(layers) do
				if type(v) == "table" then
					-- List of mipmaps
					error("Nested table (mipmaps) is not supported at the moment")
				else
					multiCount[#multiCount + 1] = {lily.newImageData, v, setting}
				end
			end
			-- Check count
			if #multiCount == 0 then
				error("Layers is empty", 2)
			end

			-- Initialize
			local this = setmetatable({}, lilyObjectMeta)
			-- Values
			this.requestType = name
			this.done = false
			this.values = nil

			this.multi = lily.loadMulti(multiCount)
			:setUserData({this, setting})
			:onComplete(defCompleteFunction)
			:onError(defMultiToSingleError)
			-- Return
			return this
		end
	end

	-- Basic function which is supported on all systems
	newLilyFunction("newFont", love.graphics.newFont)
	newLilyFunction("newImage", love.graphics.newImage)
	newLilyFunction("newVideo", love.graphics.newVideo)

	-- Get texture type
	local texType = love.graphics.getTextureTypes()
	-- Not all system support cube image. Make it unavailable in that case.
	if texType.cube then
		-- Another internal function
		local defNewCubeImageMulti = defImageMultiGen(love.graphics.newCubeImage)
		lily.newCubeImage = function(layers, setting)
			local multiCount = {}
			-- If it's table, that means it contains list of files
			if type(layers) == "table" then
				assert(#layers == 6, "Invalid list of files (must be exactly 6)")
				for _, v in ipairs(layers) do
					if type(v) == "table" then
						-- List of mipmaps
						error("Nested table (mipmaps) is not supported at the moment")
					else
						multiCount[#multiCount + 1] = {lily.newImage, v, setting}
					end
				end
				-- Are you specify tons of "Image" objects?
				if #multiCount == 0 then
					error("Nothing to parallelize", 2)
				end
			end

			-- Initialize
			local this = setmetatable({}, lilyObjectMeta)
			local reqID = createReqID()
			-- Values
			this.requestType = "newCubeImage"
			this.done = false
			this.values = nil

			-- If multi count is 0, that means it's just single file
			if #multiCount == 0 then
				-- Insert to request table
				lily.request[reqID] = this
				
				if isWeb then
					-- Web mode
					table.insert(webQueue, {
						reqID = reqID,
						requestType = "newImage",
						args = {layers, setting}
					})
					webProcessing = true
				else
					-- Create and push new task
					local treq = {reqID, "newImage", 2, layers, setting}
					taskChannel:push(treq)
				end
			else
				this.multi = lily.loadMulti(multiCount)
				:setUserData({this, setting})
				:onComplete(defNewCubeImageMulti)
				:onError(defMultiToSingleError)
			end
			-- Return
			return this
		end
		lily.handlers.newCubeImage = wraphandler(love.graphics.newCubeImage)
	end
	-- Not all system support array image
	if texType.array then
		genLayerImage("newArrayImage", love.graphics.newArrayImage)
	end
	-- Not all system support volume image
	if texType.volume then
		genLayerImage("newVolumeImage", love.graphics.newVolumeImage)
	end
end

if love.image then
	newLilyFunction("encodeImageData")
	newLilyFunction("newImageData")
	newLilyFunction("newCompressedData")
	newLilyFunction("pasteImageData")
end

if love.sound then
	newLilyFunction("newSoundData")
end

if love.video then
	newLilyFunction("newVideoStream")
end

function lily.loadMulti(tabdecl)
	local this = setmetatable({
		lilies = {},
		completedRequest = 0
	}, multiObjectMeta)

	for i = 1, #tabdecl do
		local tab = tabdecl[i]

		-- tab[1] is lily name, the rest is arguments
		local func

		if type(tab[1]) == "string" then
			if lily[tab[1]] and lily.handlers[tab[1]] then
				func = lily[tab[1]]
			else
				error("Invalid lily function ("..tab[1]..") at index #"..i)
			end
		elseif type(tab[1]) == "function" then
			-- Must be `lily[function]`
			func = tab[1]
		else
			error("Invalid lily function at index #"..i)
		end

		local lilyobj = func(unpack(tab, 2))
			:setUserData({i, this})
			:onComplete(multiObjectOnLoaded)
			:onError(multiObjectChildErrorHandler)

		this.lilies[#this.lilies + 1] = lilyobj
	end

	return this
end

-- do not remove this comment!
if hasThreads then
	initThreads()
end
return lily
-- "Parallel" module made by Vuiko
-- Do whatever you want with it, except claim it's yours
-- Thanks

-- Tables
local module = {}
module.objectFunctions = {}
module.__index = module.objectFunctions

-- Variables
local uidCounter = 0

-- Types
type parallelObject = {
	-- Methods
	Run: (self: parallelObject) -> (),
	Clean: (self: parallelObject) -> (),
	RunOnEnd: (self: parallelObject, ...parallelObject) -> (),

	-- variables
	finished: boolean,
}

type parallelModule = {
	New: <Args>(fn: () -> (), ...Args) -> parallelObject,
	WaitForEnd: (...parallelObject) -> ()
}

-- Functions

-- Creates parallel object with methods :Run() and :Clean()
-- First argument is function to run and second is function arguments
function module.New(fn: () -> (), ...: any): parallelObject
	local self = {}

	self.fn = fn
	self.finished = false
	self._ran = false
	self.args = { ... }
	self.uid = `{uidCounter}_parallel`
	uidCounter += 1

	self.endedEvent = Instance.new(`BindableEvent`)
	self.endedEvent.Name = `parallelEndedEvent {tostring(time())}`

	return setmetatable(self, { __index = module.objectFunctions })
end

-- Runs task in parallel, same as task.spawn()
function module.objectFunctions.Run(self: parallelObject)
	if self._ran or self.finished then
		warn(`Attempting to run already executed task`)
		return
	end

	self._ran = true
	local succ, errMsg: string?

	self.endedEvent.Event:Once(function()
		if not succ then
			error(errMsg)
		end
	end)

	self.thread = task.spawn(function()
		succ, errMsg = pcall(self.fn, table.unpack(self.args))
		self.finished = true

		if self.endedEvent then
			self.endedEvent:Fire(errMsg)
			self.endedEvent:Destroy() -- Self cleanup
			self.endedEvent = nil
		end
	end)
end

-- Removes internal instances and sets the finished property to true
function module.objectFunctions.Clean(self: parallelObject)
	-- If called before the function ends, cleans up everything it can
	self.finished = true
	if self.endedEvent then
		self.endedEvent:Destroy()
	end
end

-- Yields until parallel threads finish their work
function module.WaitForEnd(...: parallelObject)
	local running = coroutine.running()

	local accumulated = {}

	for _, self: parallelObject in pairs({ ... }) do
		local finished = self.finished
		if finished then
			continue
		end
		accumulated[self.uid] = true

		self.endedEvent.Event:Once(function()
			accumulated[self.uid] = nil

			if not next(accumulated) then
				coroutine.resume(running)
			end
		end)
	end

	if not next(accumulated) then
		return
	end

	coroutine.yield(running)
end

-- Waits until the other parallel threads finish, then runs the object
function module.objectFunctions.RunOnEnd(obj: parallelObject, ...: parallelObject)
	module.WaitForEnd(...)
	obj:Run()
end

return module :: parallelModule

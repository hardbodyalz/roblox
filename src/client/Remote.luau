--!strict
-- Wraps the Request RemoteFunction; surfaces failure messages as toasts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local Remote = {}

local requestFn = Net.func("Request")
local onError: ((string) -> ())? = nil

function Remote.setErrorHandler(fn: (string) -> ())
	onError = fn
end

function Remote.request(action: string, payload: any?): (boolean, any)
	local ok, success, result = pcall(requestFn.InvokeServer, requestFn, action, payload)
	if not ok then
		return false, "Connection problem."
	end
	if not success and type(result) == "string" and onError then
		onError(result)
	end
	return success, result
end

return Remote

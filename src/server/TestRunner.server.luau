--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

-- TestEZ ueber ServerPackages in ServerScriptService laden
local TestEZ = require(ServerScriptService.ServerPackages.TestEZ)

print("--------------------------------------------------")
print("[TDD RUNNER] Starte automatisierte Unit-Tests...")
print("--------------------------------------------------")

-- Führt alle Tests unter ServerScriptService.Server.modules aus (abgesichert gegen Timing-Probleme)
local serverFolder = ServerScriptService:WaitForChild("Server")
local modulesFolder = serverFolder:WaitForChild("modules")
local results = TestEZ.TestBootstrap:run({ modulesFolder })

local summary = {
	failureCount = results.failureCount,
	success = results.failureCount == 0,
	failures = {}
}

local function collectFailures(node, path)
	local currentPath = path == "" and node.planNode.phrase or (path .. " -> " .. node.planNode.phrase)
	if node.errors and #node.errors > 0 then
		table.insert(summary.failures, {
			path = currentPath,
			errors = node.errors
		})
	end
	if node.children then
		for _, child in ipairs(node.children) do
			collectFailures(child, currentPath)
		end
	end
end

for _, child in ipairs(results.children) do
	collectFailures(child, "")
end

local testResultsVal = workspace:FindFirstChild("TestResults")
if not testResultsVal then
	testResultsVal = Instance.new("StringValue")
	testResultsVal.Name = "TestResults"
	testResultsVal.Parent = workspace
end
testResultsVal.Value = HttpService:JSONEncode(summary)
print("TEST_RESULTS_JSON:" .. HttpService:JSONEncode(summary))

if results.failureCount > 0 then
	warn(string.format("[TDD FAILED] %d Tests sind fehlgeschlagen!", results.failureCount))
else
	print("[TDD PASSED] Alle TestEZ-Unit-Specs wurden erfolgreich verifiziert!")
end
print("--------------------------------------------------")


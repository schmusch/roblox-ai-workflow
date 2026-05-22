--!strict
local ServerScriptService = game:GetService("ServerScriptService")

-- TestEZ ueber ServerPackages in ServerScriptService laden
local TestEZ = require(ServerScriptService.ServerPackages.TestEZ)

print("--------------------------------------------------")
print("[TDD RUNNER] Starte automatisierte Unit-Tests...")
print("--------------------------------------------------")

-- Führt alle Tests unter ServerScriptService.Server (inkl. .modules) aus
local results = TestEZ.run(ServerScriptService.Server)

if results.failureCount > 0 then
	warn(string.format("[TDD FAILED] %d Tests sind fehlgeschlagen!", results.failureCount))
else
	print("[TDD PASSED] Alle TestEZ-Unit-Specs wurden erfolgreich verifiziert!")
end
print("--------------------------------------------------")

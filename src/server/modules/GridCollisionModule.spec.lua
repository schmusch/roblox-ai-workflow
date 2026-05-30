--!strict
-- Platziert in: src/server/modules/GridCollisionModule.spec.lua
return function()
	local GridCollisionModule = require(script.Parent.GridCollisionModule)

	describe("GridCollisionModule - Server-Authoritative Geometry Verification", function()
		local occupiedCells: { [number]: { [number]: string? } }
		local sizeX, sizeZ = 10, 10

		beforeEach(function()
			occupiedCells = {}
			for x = 1, sizeX do
				occupiedCells[x] = {}
			end
		end)

		it("sollte die rotierten Dimensionen korrekt berechnen (getRotatedDimensions)", function()
			local footprint = Vector3.new(3, 2, 1) -- Breite = 3, Tiefe = 1 (Höhe = 2)

			-- Rotation 0 & 180 -> Keine Änderung (3, 2, 1)
			local w0, h0, d0 = GridCollisionModule.getRotatedDimensions(footprint, 0)
			expect(w0).to.equal(3)
			expect(h0).to.equal(2)
			expect(d0).to.equal(1)

			local w180, h180, d180 = GridCollisionModule.getRotatedDimensions(footprint, 180)
			expect(w180).to.equal(3)
			expect(h180).to.equal(2)
			expect(d180).to.equal(1)

			-- Rotation 90 & 270 -> Swap Breite und Tiefe -> (1, 2, 3)
			local w90, h90, d90 = GridCollisionModule.getRotatedDimensions(footprint, 90)
			expect(w90).to.equal(1)
			expect(h90).to.equal(2)
			expect(d90).to.equal(3)

			local w270, h270, d270 = GridCollisionModule.getRotatedDimensions(footprint, 270)
			expect(w270).to.equal(1)
			expect(h270).to.equal(2)
			expect(d270).to.equal(3)
		end)

		it("sollte eine legitime Platzierung erfolgreich verifizieren (verifyPlacement)", function()
			-- Platziere ein 2x2x2 Objekt auf (3,3)
			local footprint = Vector3.new(2, 2, 2)
			local success, cells = GridCollisionModule.verifyPlacement(occupiedCells, footprint, 3, 3, 0)

			expect(success).to.equal(true)
			expect(cells).to.be.ok()
			expect(#cells).to.equal(4) -- 2x2 cells
		end)

		it("sollte Platzierungen außerhalb des Spielfelds blockieren (verifyPlacement OOB)", function()
			local footprint = Vector3.new(2, 2, 2)

			-- OOB links/oben (0,0) -> Ungültig da 1-basiert
			local success1 = GridCollisionModule.verifyPlacement(occupiedCells, footprint, 0, 3, 0)
			expect(success1).to.equal(false)

			-- OOB rechts (10, 3) -> Ein 2x2 ragt über 10 hinaus
			local success2 = GridCollisionModule.verifyPlacement(occupiedCells, footprint, 10, 3, 0)
			expect(success2).to.equal(false)
		end)

		it("sollte überlappende Platzierungen (Kollisionen) blockieren (verifyPlacement Overlap)", function()
			local footprint = Vector3.new(2, 2, 2)

			-- Belege manuell die Zelle (4,4)
			occupiedCells[4][4] = "existing_deity_id"

			-- Platziere ein 2x2 Objekt auf (3,3) -> Überschneidet sich bei (4,4)
			local success = GridCollisionModule.verifyPlacement(occupiedCells, footprint, 3, 3, 0)
			expect(success).to.equal(false)
		end)

		it("sollte rotierte Platzierungen auf Grenzen prüfen (verifyPlacement Rotated OOB)", function()
			local footprint = Vector3.new(1, 2, 3) -- Breite = 1, Tiefe = 3

			-- Bei 90 Grad Drehung: Breite = 3, Tiefe = 1
			-- Platziere auf (9, 9) mit 90 Grad -> Breite ragt bis 11 (OOB)
			local success90 = GridCollisionModule.verifyPlacement(occupiedCells, footprint, 9, 9, 90)
			expect(success90).to.equal(false)

			-- Platziere auf (9, 9) mit 0 Grad -> Tiefe ragt bis 11 (OOB)
			local success0 = GridCollisionModule.verifyPlacement(occupiedCells, footprint, 9, 9, 0)
			expect(success0).to.equal(false)
		end)

		it("sollte rotierte Platzierungen auf Überlappung prüfen (verifyPlacement Rotated Overlap)", function()
			local footprint = Vector3.new(1, 2, 3) -- Breite = 1, Tiefe = 3

			-- Belege Zelle (5, 3)
			occupiedCells[5][3] = "blocker"

			-- Platziere ein 1x3 Objekt bei (3, 3) mit 90 Grad Drehung -> Rotierte Zellen sind (3,3), (4,3), (5,3). Überschneidet sich bei (5,3)
			local success = GridCollisionModule.verifyPlacement(occupiedCells, footprint, 3, 3, 90)
			expect(success).to.equal(false)
		end)
	end)
end

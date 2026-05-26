--!strict
return function()
	local RingBufferModule = require(script.Parent.RingBufferModule)

	describe("RingBufferModule - Binäres 60Hz Kreispuffer-Layout (Epic 3.1 & 3.5)", function()
		it("sollte einen Zustand in den Puffer schreiben und korrekt wieder auslesen", function()
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 then 1 else 0,
					CatalogIndex = if i == 1 then 42 else 0,
					OwnerUserId = if i == 1 then 1234567 else 0,
					TileIndex = if i == 1 then 5 else 0,
					Health = if i == 1 then 100.5 else 0.0,
					ActionPoints = if i == 1 then 10 else 0,
					StatusMask = if i == 1 then 3 else 0, -- Bitmaske
				}
			end

			local tickNum = 15
			local timestamp = 1716500000.125
			RingBufferModule.writeFrame(tickNum, timestamp, entities)

			local readFrame = RingBufferModule.readFrame(tickNum)
			expect(readFrame.Tick).to.equal(tickNum)
			expect(readFrame.Timestamp).to.equal(timestamp)
			expect(readFrame.Entities[1].Active).to.equal(1)
			expect(readFrame.Entities[1].CatalogIndex).to.equal(42)
			expect(readFrame.Entities[1].OwnerUserId).to.equal(1234567)
			expect(readFrame.Entities[1].TileIndex).to.equal(5)
			expect(readFrame.Entities[1].Health).to.be.near(100.5, 0.01)
			expect(readFrame.Entities[1].ActionPoints).to.equal(10)
			expect(readFrame.Entities[1].StatusMask).to.equal(3)

			expect(readFrame.Entities[2].Active).to.equal(0)
		end)

		it("sollte bei circular index wrapping alte Frames ueberschreiben und das auslesen aelterer Frames verhindern", function()
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = 0,
					CatalogIndex = 0,
					OwnerUserId = 0,
					TileIndex = 0,
					Health = 0,
					ActionPoints = 0,
					StatusMask = 0,
				}
			end

			-- Schreibe Frame 0
			RingBufferModule.writeFrame(0, 100.0, entities)
			local read0 = RingBufferModule.readFrame(0)
			expect(read0.Tick).to.equal(0)

			-- Schreibe Frame 90 (kapazitaet ist 90, so index 90 wrapped zu index 0)
			RingBufferModule.writeFrame(90, 101.5, entities)

			-- Jetzt sollte Frame 90 gueltig sein
			local read90 = RingBufferModule.readFrame(90)
			expect(read90.Tick).to.equal(90)

			-- Aber Frame 0 wurde ueberschrieben!
			local read0Again = RingBufferModule.readFrame(0)
			expect(read0Again.Tick).to.equal(-1) -- Tick -1 signalisiert, dass der Frame ueberschrieben wurde
		end)

		it("sollte Zero-Allocation beim Lesen und Schreiben aufweisen", function()
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = 1,
					CatalogIndex = 12,
					OwnerUserId = 9999,
					TileIndex = i,
					Health = 50.0,
					ActionPoints = 5,
					StatusMask = 0,
				}
			end

			-- Waerme den Puffer auf
			RingBufferModule.writeFrame(1, 100.0, entities)
			local _ = RingBufferModule.readFrame(1)

			-- GC erzwingen vor der Messung
			task.wait(0.5) -- Ermöglicht die Garbage Collection und Stabilisierung des Heaps
			local memoryBefore = gcinfo()

			-- Führe 1000 read/write Operationen aus
			for tick = 1, 1000 do
				RingBufferModule.writeFrame(tick, 100.0 + tick, entities)
				local read = RingBufferModule.readFrame(tick)
				-- Static table validation
				assert(read.Tick == tick, "Tick mismatch")
			end

			local memoryAfter = gcinfo()
			
			-- Die Differenz muss 0 sein (oder extrem nahe 0 wegen GC-Rauschen, aber bei echten zero-allocs ist es 0)
			-- Da gcinfo() Kilobytes zurueckgibt, muss es exakt 0 KB Differenz aufweisen!
			expect(memoryAfter - memoryBefore).to.equal(0)
		end)
	end)
end

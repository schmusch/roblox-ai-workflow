--!strict
-- Platziert in: src/shared/MantissaExponentModule.luau

local MantissaExponentModule = {}

export type BigNumber = {
	Mantissa: number,
	Exponent: number
}

-- Normalisiert eine BigNumber so, dass 1 <= |Mantissa| < 10 gilt, oder Mantissa = 0.
function MantissaExponentModule.new(mantissa: number, exponent: number): BigNumber
	if mantissa == 0 then
		return { Mantissa = 0, Exponent = 0 }
	end

	local m = mantissa
	local e = exponent

	-- Vorzeichen merken
	local sign = m < 0 and -1 or 1
	m = math.abs(m)

	if m >= 10 then
		while m >= 10 do
			m = m / 10
			e = e + 1
		end
	elseif m < 1 then
		while m < 1 do
			m = m * 10
			e = e - 1
		end
	end

	return {
		Mantissa = m * sign,
		Exponent = e
	}
end

-- Konvertiert eine reguläre Luau-Zahl in eine BigNumber
function MantissaExponentModule.fromNumber(n: number): BigNumber
	if n == 0 then
		return { Mantissa = 0, Exponent = 0 }
	end
	
	-- Nutzen des mathematischen Logarithmus zur schnellen Bestimmung des Exponenten
	local exponent = math.floor(math.log10(math.abs(n)))
	local mantissa = n / math.pow(10, exponent)
	
	return MantissaExponentModule.new(mantissa, exponent)
end

-- Konvertiert eine BigNumber zurück in eine reguläre Zahl (Achtung: Kann bei > 10^308 überlaufen)
function MantissaExponentModule.toNumber(b: BigNumber): number
	return b.Mantissa * math.pow(10, b.Exponent)
end

-- Addiert zwei BigNumbers
function MantissaExponentModule.add(a: BigNumber, b: BigNumber): BigNumber
	if a.Mantissa == 0 then return b end
	if b.Mantissa == 0 then return a end

	local expDiff = a.Exponent - b.Exponent
	local newMantissa = 0
	local newExponent = 0

	if expDiff >= 0 then
		-- a hat den größeren oder gleichen Exponenten
		newExponent = a.Exponent
		newMantissa = a.Mantissa + (b.Mantissa / math.pow(10, expDiff))
	else
		-- b hat den größeren Exponenten
		newExponent = b.Exponent
		newMantissa = b.Mantissa + (a.Mantissa / math.pow(10, -expDiff))
	end

	return MantissaExponentModule.new(newMantissa, newExponent)
end

-- Multipliziert zwei BigNumbers
function MantissaExponentModule.multiply(a: BigNumber, b: BigNumber): BigNumber
	local m = a.Mantissa * b.Mantissa
	local e = a.Exponent + b.Exponent
	return MantissaExponentModule.new(m, e)
end

-- Dividiert a durch b
function MantissaExponentModule.divide(a: BigNumber, b: BigNumber): BigNumber
	if b.Mantissa == 0 then
		error("Division durch Null in MantissaExponentModule!")
	end
	local m = a.Mantissa / b.Mantissa
	local e = a.Exponent - b.Exponent
	return MantissaExponentModule.new(m, e)
end

-- Zieht die Quadratwurzel aus einer BigNumber (extrem wichtig für die sublineare Konvertierungs-Formel)
function MantissaExponentModule.sqrt(a: BigNumber): BigNumber
	if a.Mantissa < 0 then
		error("Quadratwurzel aus einer negativen Zahl in MantissaExponentModule!")
	end
	if a.Mantissa == 0 then
		return { Mantissa = 0, Exponent = 0 }
	end

	local m = a.Mantissa
	local e = a.Exponent

	-- Der Exponent muss gerade sein, um ihn sauber durch 2 teilen zu können
	if e % 2 ~= 0 then
		m = m * 10
		e = e - 1
	end

	local newMantissa = math.sqrt(m)
	local newExponent = e / 2

	return MantissaExponentModule.new(newMantissa, newExponent)
end

return MantissaExponentModule

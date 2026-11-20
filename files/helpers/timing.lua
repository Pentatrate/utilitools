local timing = {}

function timing.beatToMs(beat, bpm) return beat * 60 * 1000 / bpm end -- Penta: Code copied from Gamemanager
function timing.msToBeat(ms, bpm) return ms / 60 / 1000 * bpm end -- Penta: Code copied from Gamemanager
function timing.realBeatToMs(beat, initialBpm, timingPoints, rateMod)
	if beat == 0 then return 0 end
	if not timingPoints or #timingPoints <= 0 then return utilitools.timing.beatToMs(beat, initialBpm * rateMod) end
	timingPoints = helpers.copy(timingPoints)
	for i, data in ipairs(timingPoints) do data.order = i end
	table.sort(timingPoints, function(a, b) if a.beat ~= b.beat then return a.beat < b.beat end return a.order < b.order end)
	timingPoints[0] = { bpm = initialBpm }
	local i, ms = 0, 0
	if 0 < beat then
		while timingPoints[i + 1] and timingPoints[i + 1].beat <= 0 do i = i + 1 end
		while timingPoints[i + 1] and timingPoints[i + 1].beat < beat do
			ms = ms + utilitools.timing.beatToMs(timingPoints[i + 1].beat - (timingPoints[i].beat or 0), timingPoints[i].bpm * rateMod)
			i = i + 1
		end
		if not timingPoints[i].beat then
			return utilitools.timing.beatToMs(beat, timingPoints[i].bpm * rateMod)
		elseif timingPoints[i].beat < beat then
			ms = ms + utilitools.timing.beatToMs(beat - (timingPoints[i].beat or 0), timingPoints[i].bpm * rateMod)
		end
		return ms
	else
		while timingPoints[i + 1] and timingPoints[i + 1].beat < 0 do i = i + 1 end
		while timingPoints[i].beat and beat < timingPoints[i].beat do
			local prevBeat = (timingPoints[i + 1] and timingPoints[i + 1].beat < 0 and timingPoints[i + 1].beat or 0)
			ms = ms - utilitools.timing.beatToMs(prevBeat - timingPoints[i].beat, timingPoints[i].bpm * rateMod)
			i = i - 1
		end
		local prevBeat = (timingPoints[i + 1] and timingPoints[i + 1].beat < 0 and timingPoints[i + 1].beat or 0)
		if beat < prevBeat then
			ms = ms - utilitools.timing.beatToMs(prevBeat - beat, timingPoints[i].bpm * rateMod)
		end
		return ms
	end
end
function timing.realMsToBeat(ms, initialBpm, timingPoints, rateMod)
	if ms == 0 then return 0 end
	if not timingPoints or #timingPoints <= 0 then return utilitools.timing.msToBeat(ms, initialBpm * rateMod) end
	timingPoints = helpers.copy(timingPoints)
	for i, data in ipairs(timingPoints) do data.order = i data.ms = utilitools.timing.realBeatToMs(data.beat, initialBpm, timingPoints, rateMod) end
	table.sort(timingPoints, function(a, b) if a.ms ~= b.ms then return a.ms < b.ms end return a.order < b.order end)
	if ms < timingPoints[1].ms then
		return timingPoints[1].beat + utilitools.timing.msToBeat(ms - timingPoints[1].ms, initialBpm * rateMod)
	end
	for i, data in ipairs(timingPoints) do
		if not (timingPoints[i + 1] and timingPoints[i + 1].ms < ms) then
			return data.beat + utilitools.timing.msToBeat(ms - data.ms, data.bpm * rateMod)
		end
	end
end
function timing.getBeat(beat, ms, initialBpm, timingPoints, rateMod)
	local newBeat = utilitools.timing.realMsToBeat(utilitools.timing.realBeatToMs(beat, initialBpm, timingPoints, rateMod) + ms, initialBpm, timingPoints, rateMod)
	return newBeat
end
function timing.getActiveTiming()
	return cs and cs.timingInfo and cs.timingInfo.initial and cs.timingInfo.initial.bpm or cs.level and cs.level.bpm or 100, cs and cs.timingInfo and cs.timingInfo.timingPoints or {}, cs and cs.rateMod or 1
end

return timing

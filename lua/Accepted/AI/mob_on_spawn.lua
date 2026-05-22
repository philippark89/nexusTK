on_spawn = function(mob)
	local damRange = (mob.minDam + mob.maxDam) * 2
	if damRange <= 0 then return end

	local multiplier = math.random(0, 1) == 1 and -1 or 1
	local healthMod = math.random(damRange) * multiplier

	mob.maxHealth = mob.maxHealth + healthMod
	mob.health = mob.maxHealth
end

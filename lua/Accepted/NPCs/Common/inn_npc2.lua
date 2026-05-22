InnNpc2 = {
	click = async(function(player, npc)
		Tools.configureDialog(player, npc)

		local opts = {
			"NexusTK for Novices",
			"Transport",
			"Date & Time"
		}

		local choice = player:menuString("Hello! How can I help you today?", opts)

		if choice == "NexusTK for Novices" then
			general_npc_funcs.novices(player, npc)
		elseif choice == "Transport" then
			Waypoint.click(player, npc)
		elseif choice == "Date & Time" then
			general_npc_funcs.time(player)
		end
	end),

	onSayClick = async(function(player, npc)
		Waypoint.onSayClick(player, npc)
	end)
}

class DMus_EventHandler : StaticEventHandler
{
	DMus_Player plr;

	override void OnRegister()
	{
		plr = new("DMus_Player");
		let parser = new("DMus_Parser");
		parser.Parse(plr.chnk_arr);
		parser.ParseLegacy(plr.chnk_arr);
		plr.Init();
	}

	override void WorldTick()
	{
		uint i = 0; for(; i < MAXPLAYERS; ++i)
			if(playeringame[i])
				break;
		if(i < MAXPLAYERS){
			plr.WatchFile(players[i].mo);
			plr.DoFade();
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if(e.name == "dmus_random")
			plr.RandomTrack();
	}
}

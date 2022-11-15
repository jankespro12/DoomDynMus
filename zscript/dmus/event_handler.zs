class DMus_EventHandler : StaticEventHandler
{
	DMus_Player plr;
	bool plr_init;

	override void OnRegister()
	{
		plr = new("DMus_Player");
		let parser = new("DMus_Parser");
		parser.Parse(plr.chnk_arr);
		parser.ParseLegacy(plr.chnk_arr);
	}

	override void WorldLoaded(WorldEvent e)
	{
		if(!e.isSaveGame && CVar.GetCVar("dmus_shuffle_behaviour").GetInt() == 1)
			plr.RandomTrack();
	}

	override void WorldTick()
	{
		uint i = 0; for(; i < MAXPLAYERS; ++i)
			if(playeringame[i])
				break;
		if(i < MAXPLAYERS){
			if(!plr_init){
				plr.Init(players[i].mo);
				plr_init = true;
			}
			plr.WatchFile(players[i].mo);
			plr.DoFade();
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if(e.name == "dmus_random"){
			plr.dont_announce_fade = true;
			plr.RandomTrack();
		}
	}
}

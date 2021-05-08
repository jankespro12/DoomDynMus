struct DMus_Handler_Queue
{
	int qaction;
	int tgr, tcateg;
}

class DMus_Handler : StaticEventHandler
{
	ui DMus_Player plr;
	int plr_combat_timers[MAXPLAYERS];

	DMus_Handler_Queue queue;
	// Queue functions
	void QueueFade(int track_group, int track_category)
	{
		queue.qaction = 1;
		queue.tgr = track_group; queue.tcateg = track_category;
	}
	void QueuePlayTrack(int track_group, int track_category)
	{
		queue.qaction = 2;
		queue.tgr = track_group; queue.tcateg = track_category;
	}
	void QueueSetTrackGroup(int track_group)
	{
		queue.qaction = 3;
		queue.tgr = track_group;
	}

	// Events

	override void OnRegister()
	{
		queue.qaction = 0;
		for(uint i = 0; i < MAXPLAYERS; ++i)
			plr_combat_timers[i] = 0;
	}

	override void UITick()
	{
		if(!plr){ // Player initialization
			plr = new("DMus_Player");
			plr.LoadDesc();
			plr.SoundInit();
		}
		// Queue processing
		switch(queue.qaction)
		{
			case 1: plr.Fade(queue.tgr, queue.tcateg); break;
			case 2: plr.PlayTrack(queue.tgr, queue.tcateg); break;
			case 3: plr.SetTrackGroup(queue.tgr); break;
		}
		queue.qaction = 0;

		plr.OnTick();
	}

	override void WorldTick()
	{
		ThinkerIterator it = ThinkerIterator.create();
		Actor m;
		int conplr_inaction = 0;
		double prox_dist = CVar.getCVar("dmus_combat_proximity_dist", players[consoleplayer]).getFloat();
		while(m = Actor(it.next()))
		{
			if(!m.bISMONSTER || m.health <= 0)
				continue;
			if(m.target && m.target is "PlayerPawn" && players[consoleplayer] == m.target.player
				&& (m.CheckSight(m.target) || m.distance3D(m.target) <= prox_dist)){
				conplr_inaction = 1; break;
			}
		}

		for(uint i = 0; i < MAXPLAYERS; ++i)
			if(plr_combat_timers[i] > 0) plr_combat_timers[i]--;

		if(players[consoleplayer].mo.health > 0){
			if(conplr_inaction){
				QueueFade(-1, 1);
				plr_combat_timers[consoleplayer] = CVar.getCVar("dmus_combat_fade_time", players[consoleplayer]).getInt();
			}
			else if(plr_combat_timers[consoleplayer] == 0)
				QueueFade(-1, 0);
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		if(e.isSaveGame || e.isReopen) return;

		int shuffle_behv = CVar.getCVar("dmus_shuffle_behaviour", players[consoleplayer]).getInt();
		if(shuffle_behv == 1)
			QueueSetTrackGroup(-1);
		else
			QueuePlayTrack(-1, -1);
	}

	override void PlayerRespawned(PlayerEvent e)
	{
		if(consoleplayer == e.PlayerNumber)
			QueueFade(-1, 0);
	}
	override void PlayerDied(PlayerEvent e)
	{
		if(consoleplayer == e.PlayerNumber)
			QueueFade(-1, 2);
	}


	override void ConsoleProcess(ConsoleEvent e)
	{
		if(e.name == "dmus_fade"){
			if(e.args[0] == plr.cur_tgr && e.args[1] == plr.cur_tcateg)
				return;

			plr.Fade(e.args[0], e.args[1]);
		}
		else if(e.name == "dmus_next"){
			plr.NextTrackGroup();
		}
		else if(e.name == "dmus_prev"){
			plr.PrevTrackGroup();
		}
		else if(e.name == "dmus_random"){
			plr.SetTrackGroup(-1);
		}
	}
}

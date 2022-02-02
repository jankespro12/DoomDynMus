class DMus_Player ui
{
	// Music tracks file/lump names		  Category indicies
	Array<String> mnames_normal;		//0
	Array<String> mnames_action;		//1
	Array<String> mnames_death;		//2
	Array<String> mnames_high;		//3


	// Loads music descriptions from DMUSDESC lumps.
	void LoadDesc()
	{
		// Load regular music descriptions
		for(int hndl = Wads.FindLump("DMUSDESC", 0, Wads.ANYNAMESPACE);
			hndl != -1;
			hndl = Wads.FindLump("DMUSDESC", hndl+1, Wads.ANYNAMESPACE))
		{
			String wdat = Wads.ReadLump(hndl);
			String nbuf = ""; // track name buffer

			int pstate = 0;	// 0 - skipping whitespaces
					// 1 - reading a track name
			int tstate = 0;	// 0 - reading normal track name
					// 1 - reading action track name
					// 2 - reading death track name
			uint line = 1;  // line number
			int inquote = 0; // if the parser is currently inside a quote

			for(int i = 0; i < wdat.Length(); ++i)
			{
				int c = wdat.ByteAt(i);

				if(c == ch("\0")) break;
				if(c == ch("\n")) ++line;
				if(c == ch("\"")){
					inquote = !inquote;
					continue;
				}

				if(pstate == 0 && !cis_wspace(c)){
					pstate = 1; i--;
				}
				else if(pstate == 1)
				{
					if((cis_wspace(c) && !inquote) || i == wdat.Length() - 1)
					{
						if(nbuf.ByteAt(0) == ch("*")) // special character to duplicate one of track names
						{
							if(nbuf.ByteAt(1) == ch("*")) // '**' keeps the level music
							{
								nbuf = "*";
							}
							else
							{
								int dupi = nbuf.ByteAt(1) - ch("0");
								if(tstate == dupi){
									console.printf("[DoomDynMus]Error: Shortcut self-reference \"*%d\" at line %u", dupi, line);
								}
								else if(tstate < dupi){
									console.printf("[DoomDynMus]Error: Forward shortcut to an undeclared track \"*%d\" at line %u", dupi, line);
								}
								else{
									switch(dupi){
										case 0: nbuf = mnames_normal[mnames_normal.Size()-1]; break;
										case 1: nbuf = mnames_action[mnames_action.Size()-1]; break;
										default: console.printf("[DoomDynMus]Error: Forward shortcut to a non-existant index \"*%d\" at line %u", dupi, line); break;
									}
								}
							}
						}

						// Adding track name to one of the lists of track names
						switch(tstate)
						{
							case 0: mnames_normal.push(nbuf); break;
							case 1: mnames_action.push(nbuf); break;
							case 2: mnames_death.push(nbuf);  break;
						}
						tstate++;
						if(tstate > 2) tstate = 0;
						nbuf = "";
						pstate = 0;
					}
					else{
						nbuf.appendCharacter(c);
					}
				}
			}
		}

		// Load high-action music descriptions
		for(int hndl = Wads.FindLump("DMUSHIGH", 0, Wads.ANYNAMESPACE);
			hndl != -1;
			hndl = Wads.FindLump("DMUSHIGH", hndl+1, Wads.ANYNAMESPACE))
		{
			String wdat = Wads.ReadLump(hndl);
			String nbuf = ""; // track name buffer

			int pstate = 0;	// 0 - skipping whitespaces
					// 1 - reading a track name
			int inquote = 0; // if the parser is currently inside a quote

			for(int i = 0; i < wdat.Length(); ++i)
			{
				int c = wdat.ByteAt(i);

				if(c == ch("\0")) break;
				if(c == ch("\"")){
					inquote = !inquote;
					continue;
				}

				if(pstate == 0 && !cis_wspace(c)){
					pstate = 1; i--;
				}
				else if(pstate == 1)
				{
					if((cis_wspace(c) && !inquote) || i == wdat.Length() - 1)
						mnames_high.push(nbuf);
					else
						nbuf.appendCharacter(c);
				}
			}
		}
	}

	protected int ch(String s) { return s.byteAt(0); }
	protected int cis_wspace(int c)
	{
		return c == ch("\t") || c == ch(" ") || c == ch("\v") || c == ch("\r") || c == ch("\n");
	}


	void SetTrackGroup(int i)
	{
		if(i == -1)
			i = random(0, mnames_normal.size()-1);
		cur_tgr = i;
		PlayTrack(-1, -1);
	}
	void NextTrackGroup()
	{
		Fade(cur_tgr < mnames_normal.size() - 1 ? cur_tgr + 1 : 0, -1);
	}
	void PrevTrackGroup()
	{
		Fade(cur_tgr > 0 ? cur_tgr - 1 : mnames_normal.size() - 1, -1);
	}


	// Sound functions

	// Current track information
	int cur_tgr;	// current track group
	int cur_tcateg;	// current track category

	// Effect timers
	int timer_fade;
	int ticks_fadeout;
	int ticks_fadein;
	int fade_tgr;	// track group to transition in after fading
	int fade_tcateg; // track category to transition in after fading

	void SoundInit()
	{
		cur_tgr = -1; cur_tcateg = 0;
		timer_fade = 0;
		fade_tgr = fade_tcateg = -1;
		SoundUpdateCVar();
	}

	void SoundUpdateCVar()
	{
		ticks_fadeout = CVar.getCVar("dmus_fadeout_time", players[consoleplayer]).getInt();
		ticks_fadein = CVar.getCVar("dmus_fadein_time", players[consoleplayer]).getInt();
	}

	void OnTick()
	{
		// Fade effect
		if(timer_fade > ticks_fadein){ // fading out
			--timer_fade;
			SetMusicVolume((double(timer_fade) - ticks_fadein) / ticks_fadeout);

			if(timer_fade == ticks_fadein){
				bool enabled = CVar.getCVar("dmus_enabled", players[consoleplayer]).getBool();
				if(enabled){
					switch(fade_tcateg){
						case 0: S_ChangeMusic(mnames_normal[fade_tgr]); break;
						case 1: S_ChangeMusic(mnames_action[fade_tgr]); break;
						case 2: S_ChangeMusic(mnames_death[fade_tgr]); break;
						case 3: S_ChangeMusic(mnames_high[random(0, mnames_high.size()-1)]); break;
					}
				}
			}
		}
		else if(timer_fade > 0){ // fading in
			--timer_fade;
			bool enabled = CVar.getCVar("dmus_enabled", players[consoleplayer]).getBool();
			if(enabled)
				SetMusicVolume((ticks_fadein - double(timer_fade)) / ticks_fadeout);
			if(timer_fade == 0){
				fade_tcateg = fade_tgr = -1;
			}
		}
	}

	void Fade(int track_group, int track_category)
	{
		if(track_category == 3 && mnames_high.size() == 0)
			track_category = 1; // check for music packs without high-action music

		if(fade_tgr != -1 || fade_tcateg != -1) return;

		if(track_group == -1) track_group = cur_tgr;
		if(track_category == -1) track_category = cur_tcateg;
		if(track_group == cur_tgr && track_category == cur_tcateg) return;

		SoundUpdateCVar();
		timer_fade = ticks_fadeout + ticks_fadein;
		cur_tgr = fade_tgr = track_group;
		cur_tcateg = fade_tcateg = track_category;
	}

	void PlayTrack(int track_group, int track_category)
	{
		if(track_category == 3 && mnames_high.size() == 0)
			track_category = 1; // check for music packs without high-action music

		SoundUpdateCVar();
		if(cur_tgr == -1) cur_tgr = random(0, mnames_normal.size()-1);
		if(track_group == -1) track_group = cur_tgr;
		if(track_category == -1) track_category = cur_tcateg;

		cur_tgr = track_group;
		cur_tcateg = track_category;
		bool enabled = CVar.getCVar("dmus_enabled", players[consoleplayer]).getBool();
		if(enabled){
			switch(cur_tcateg){
				case 0: S_ChangeMusic(mnames_normal[cur_tgr]); break;
				case 1: S_ChangeMusic(mnames_action[cur_tgr]); break;
				case 2: S_ChangeMusic(mnames_death[cur_tgr]); break;
				case 3: S_ChangeMusic(mnames_high[random(0, mnames_high.size()-1)]); break;
			}
		}
	}
}

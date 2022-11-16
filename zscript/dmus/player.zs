class DMus_Player
{
	array<DMus_Chunk> chnk_arr;
	uint selected_chnk;

	string fname;
	string _state;

	play void Init(PlayerPawn plr)
	{
		timer_fade = -1;
		RandomTrack();
		chnk_arr[selected_chnk].UpdateCVars();
		[fname, _state] = chnk_arr[selected_chnk].SelectFile(plr);
		S_ChangeMusic(fname);
		AnnounceMusicChange();
	}

	void RandomChunk()
	{
		selected_chnk = random(0, chnk_arr.size() - 1);
	}

	/* Controls */
	bool dont_announce_fade;
	bool fade_instantly;
	void RandomTrack()
	{
		RandomChunk();
		chnk_arr[selected_chnk].RandomTrack();
	}

	/* Called every WorldTick() to see if file name from current chunk changes. */
	play void WatchFile(PlayerPawn plr)
	{
		if(Level.MapName == "TITLEMAP"){
			S_ChangeMusic("*");
			return;
		}

		if(!chnk_arr.size() || timer_fade != -1)
			return;

		string new_fname;
		string new_state;
		chnk_arr[selected_chnk].UpdateCVars();
		[new_fname, new_state] = chnk_arr[selected_chnk].SelectFile(plr);
		if(new_state != "*"
			&& (new_fname != fname && (new_state != _state || chnk_arr[selected_chnk].just_switched_track))){
			chnk_arr[selected_chnk].just_switched_track = false;
			FadeTo(new_fname, new_state, fade_instantly);
			if(dont_announce_fade)
				AnnounceMusicChange(new_fname);
			fade_instantly = false;
		}
	}

	/* Log announcements */
	void AnnounceMusicChange(string _fname = "")
	{
		string _name = _fname == "" ? fname : _fname;
		_name = _name.Mid(_name.RightIndexOf("/") + 1);
		_name = _name.Left(_name.RightIndexOf("."));
		console.printf("Now playing: *%s*", _name);
	}

	/* Fade In / Fade Out effect */
	int timer_fade;
	int ticks_fadeout;
	int ticks_fadein;
	string fade_to_fname;
	string fade_to_state;

	void UpdateCVars()
	{
		ticks_fadeout = CVar.GetCVar("dmus_fadeout_time").GetInt();
		ticks_fadein = CVar.GetCVar("dmus_fadein_time").GetInt();
	}

	void FadeTo(string to_fname, string to_state, bool instant = false)
	{
		UpdateCVars();
		if(ticks_fadein + ticks_fadeout <= 1 || instant){
			fname = to_fname;
			_state = to_state;
			S_ChangeMusic(fname);
			if(!dont_announce_fade)
				AnnounceMusicChange();
			dont_announce_fade = true;
		}
		else{
			timer_fade = 0;
			fade_to_fname = to_fname; fade_to_state = to_state;
		}
	}
	void DoFade()
	{
		if(timer_fade == -1)
			return;

		if(timer_fade < ticks_fadeout){
			++timer_fade;
			SetMusicVolume(1 - double(timer_fade) / ticks_fadeout);
		}
		else if(timer_fade < ticks_fadeout + ticks_fadein){
			if(timer_fade == ticks_fadeout){
				fname = fade_to_fname;
				_state = fade_to_state;
				S_ChangeMusic(fname);
				if(!dont_announce_fade)
					AnnounceMusicChange();
				dont_announce_fade = true;
			}
			++timer_fade;
			SetMusicVolume(double(timer_fade - ticks_fadeout) / ticks_fadein);
		}
		else
			timer_fade = -1;
	}
}

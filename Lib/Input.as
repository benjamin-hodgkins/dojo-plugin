class Input
{
    MemoryBuffer membuff = MemoryBuffer(0);

    int prevRaceTime = -6666;
    int currentRaceTime = -6666;
    int latestRecordedTime = -6666;

    // Idle detection
    vec3 latestPlayerPosition;
    int numSamePositions = 0;

    Input() {
        auto app = GetApp();
    }

    void Reset() {
        // Reset recording state
        game_input.membuff.Resize(0);
        game_input.latestRecordedTime = -6666;
        game_input.currentRaceTime = -6666;

    }

    void FillBuffer(CSceneVehicleVisState@ vis) {
        int gazAndBrake = 0;
        int gazPedal = vis.InputGasPedal > 0 ? 1 : 0;
        int isBraking = vis.InputBrakePedal > 0 ? 2 : 0;

        gazAndBrake |= gazPedal;
        gazAndBrake |= isBraking;

        membuff.Write(game_input.currentRaceTime);

        membuff.Write(vis.Position.x);
        membuff.Write(vis.Position.y);
        membuff.Write(vis.Position.z);

        membuff.Write(vis.WorldVel.x);
        membuff.Write(vis.WorldVel.y);
        membuff.Write(vis.WorldVel.z);

        membuff.Write(vis.FrontSpeed * 3.6f);

        membuff.Write(vis.InputSteer);
        membuff.Write(vis.FLSteerAngle);

        membuff.Write(gazAndBrake);

        membuff.Write(VehicleState::GetRPM(vis));
        membuff.Write(vis.CurGear);

        membuff.Write(vis.Up.x);
        membuff.Write(vis.Up.y);
        membuff.Write(vis.Up.z);

        membuff.Write(vis.Dir.x);
        membuff.Write(vis.Dir.y);
        membuff.Write(vis.Dir.z);

        uint8 fLGroundContactMaterial = vis.FLGroundContactMaterial;
        membuff.Write(fLGroundContactMaterial);
        membuff.Write(vis.FLSlipCoef);
        membuff.Write(vis.FLDamperLen);

        uint8 fRGroundContactMaterial = vis.FRGroundContactMaterial;
        membuff.Write(fRGroundContactMaterial);
        membuff.Write(vis.FRSlipCoef);
        membuff.Write(vis.FRDamperLen);

        uint8 rLGroundContactMaterial = vis.RLGroundContactMaterial;
        membuff.Write(rLGroundContactMaterial);
        membuff.Write(vis.RLSlipCoef);
        membuff.Write(vis.RLDamperLen);

        uint8 rRGroundContactMaterial = vis.RRGroundContactMaterial;
        membuff.Write(rRGroundContactMaterial);
        membuff.Write(vis.RRSlipCoef);
        membuff.Write(vis.RRDamperLen);
    }

    void Update(float dt)
	{

        //Get the current player's VehicleState  
		auto app = GetApp();
        CSceneVehicleVisState@ vis = null;
		CSmPlayer@ player = VehicleState::GetViewingPlayer();

		if (player !is null) {
			@vis = VehicleState::ViewingPlayerState();
		}

		if (vis is null) {
			return;
		}

        //Detects states for
        CSmPlayer@ smPlayer = cast<CSmPlayer>(app.CurrentPlayground.GameTerminals[0].GUIPlayer);
        CSmScriptPlayer@ smScript = cast<CSmScriptPlayer>(smPlayer.ScriptAPI);
        CGamePlaygroundUIConfig@ uiConfig = app.CurrentPlayground.UIConfigs[0];

        if (@smScript == null) {
            return;
        }

        //Condtions for resetting, finishing and otherwise

        //Finish
        if (uiConfig.UISequence == 11) {
            int endRaceTimeAccurate = -1;
            CSmArenaRulesMode@ PlaygroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);

            CGamePlayground@ GamePlayground = cast<CGamePlayground>(app.CurrentPlayground);
            if (PlaygroundScript !is null && GamePlayground.GameTerminals.get_Length() > 0) {
                if (GamePlayground.GameTerminals[0].UISequence_Current == SGamePlaygroundUIConfig::EUISequence::Finish && smScript !is null) {
                    auto ghost = PlaygroundScript.Ghost_RetrieveFromPlayer(smScript);
                    if (ghost !is null) {
                        if (ghost.Result.Time > 0 && ghost.Result.Time < 4294967295) endRaceTimeAccurate = ghost.Result.Time;
                        PlaygroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                    } else endRaceTimeAccurate = -1;
                } else endRaceTimeAccurate = -1;
            } else endRaceTimeAccurate = -1;
        }

        // Give up
         else if (latestRecordedTime > 0 && game_input.currentRaceTime < 0) {
            game_input.Reset();
        }
        //TODO Record current data
         else {
            int timeSinceLastRecord = game_input.currentRaceTime - latestRecordedTime;
            if (timeSinceLastRecord > (1.0 / RECORDING_FPS) * 1000) {
                // Keep track of the amount of samples for which the position did not changed, used to pause recording
                if (Math::Abs(latestPlayerPosition.x - smScript.Position.x) < 0.001 &&
                    Math::Abs(latestPlayerPosition.y - smScript.Position.y) < 0.001 && 
                    Math::Abs(latestPlayerPosition.z - smScript.Position.z) < 0.001 ) {
                    numSamePositions += 1;
                } else {
                    numSamePositions = 0;
                }
                // Fill buffer if player has moved recently
                if (numSamePositions < RECORDING_FPS) {
                    FillBuffer(vis);
                    latestRecordedTime = game_input.currentRaceTime;
                }

                latestPlayerPosition = smScript.Position;
            }
        }
	}
}
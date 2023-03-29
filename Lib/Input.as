class Input
{
    bool recording = false;
    MemoryBuffer membuff = MemoryBuffer(0);

    int prevRaceTime = -6666;
    int currentRaceTime = -6666;
    int latestRecordedTime = -6666;

    array<uint> sectorTimes;
    uint respawns;

    // Player info
    string playerName;
    string playerLogin;
    string webId;

    // Idle detection
    vec3 latestPlayerPosition;
    int numSamePositions = 0;

    Input() {
        auto app = GetApp();
        @network = cast<CTrackManiaNetwork>(app.Network);
        startnew(Api::checkServerWaitForValidWebId);
    }

    void Reset() {
        // Reset recording state
        game_input.recording = false;
        game_input.latestRecordedTime = -6666;
        game_input.currentRaceTime = -6666;
        game_input.membuff.Resize(0);
        game_input.sectorTimes.Resize(0);
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

		auto app = GetApp();

		auto sceneVis = app.GameScene;
		if (@sceneVis is null || @app.Editor != null) {
			return;
		}

        if (@app.CurrentPlayground == null || app.CurrentPlayground.GameTerminals.get_Length() == 0 || @app.CurrentPlayground.GameTerminals[0].GUIPlayer == null) {
            return;
        }

        CSmPlayer@ smPlayer = cast<CSmPlayer>(app.CurrentPlayground.GameTerminals[0].GUIPlayer);
        CSmScriptPlayer@ smScript = cast<CSmScriptPlayer>(smPlayer.ScriptAPI);
        CGamePlaygroundUIConfig@ uiConfig = app.CurrentPlayground.UIConfigs[0];
        CGameCtnChallenge@ rootMap = app.RootMap;

        if (@smScript == null) {
            return;
        }

        CSceneVehicleVisState@ vis = null;

		CSmPlayer@ player = Player::GetViewingPlayer();

		if (player !is null && player.User.Name.Contains(network.PlayerInfo.Name)) {
			@vis = VehicleState::ViewingPlayerState();
		}

		if (vis is null) {
			return;
		}

		uint entityId = Dev::GetOffsetUint32(vis, 0);
		if ((entityId & 0xFF000000) == 0x04000000) {
			return;
		}

        if (this.checkingServer || !this.serverAvailable) {
            return;
        }

        auto playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);

        bool hudOff = !UI::IsGameUIVisible();

        if (app.CurrentPlayground !is null && app.CurrentPlayground.Interface !is null) {
            if (hudOff || @playgroundScript == null) {
                if (@app.Network.PlaygroundClientScriptAPI != null) {
                    auto playgroundClientScriptAPI = cast<CGamePlaygroundClientScriptAPI>(app.Network.PlaygroundClientScriptAPI);
                    if (@playgroundClientScriptAPI != null) {
                        game_input.currentRaceTime = playgroundClientScriptAPI.GameTime - smScript.StartTime;
                    }
                }
            } else {
                game_input.currentRaceTime = smScript.CurrentRaceTime;
            }
        }

        if (@smScript.Score != null) {
            respawns = smScript.Score.NbRespawnsRequested;
        } else {
            respawns = 0;
        }

        if (Enabled && OverlayEnabled && !hudOff) {     
            drawRecordingOverlay();
        }

        if (!recording && game_input.currentRaceTime > -200 && game_input.currentRaceTime < 0) {
            recording = true;
        }

        if (recording) {
            
            if (uiConfig.UISequence == 11) {
                // Finished track
                print("[Input]: Finished");

                FinishHandle@ finishHandle = cast<FinishHandle>(FinishHandle());
                finishHandle.finished = true;
                @finishHandle.rootMap = rootMap;
                @finishHandle.uiConfig = uiConfig;
                @finishHandle.smScript = smScript;
                @finishHandle.network = network;
                finishHandle.endRaceTime = latestRecordedTime;
                finishHandle.sectorTimes = sectorTimes;
                finishHandle.respawns = respawns;

                // https://github.com/GreepTheSheep/openplanet-mx-random special thanks to greep for getting accurate endRaceTime

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

                if (endRaceTimeAccurate > 0) {
                    finishHandle.endRaceTime = endRaceTimeAccurate;
                }

                startnew(Api::PostRecordedData, finishHandle);
            } else if (latestRecordedTime > 0 && game_input.currentRaceTime < 0) {
                // Give up
                print("[Input]: Give up");

                game_input.Reset();

                /*
                FinishHandle@ finishHandle = cast<FinishHandle>(FinishHandle());
                finishHandle.finished = false;
                @finishHandle.rootMap = rootMap;
                @finishHandle.uiConfig = uiConfig;
                @finishHandle.smScript = smScript;
                @finishHandle.network = network;
                finishHandle.endRaceTime = latestRecordedTime;
                finishHandle.sectorTimes = sectorTimes;
                finishHandle.respawns = respawns;
                
                startnew(Api::PostRecordedData, finishHandle);
                */
            } else {
                 // Record current data
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
}
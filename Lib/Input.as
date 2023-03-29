class Input
{
    MemoryBuffer membuff = MemoryBuffer(0);

    // Idle detection
    vec3 latestPlayerPosition;
    int numSamePositions = 0;

    Input() {
        auto app = GetApp();
    }

    void Reset() {
        // Reset recording state
        game_input.membuff.Resize(0);
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

        CSceneVehicleVisState@ vis = null;

		CSmPlayer@ player = VehicleState::GetViewingPlayer();

		if (player !is null) {
			@vis = VehicleState::ViewingPlayerState();
		}

		if (vis is null) {
			return;
		}

        //game_input.Reset();

        FillBuffer(vis);

	}
}
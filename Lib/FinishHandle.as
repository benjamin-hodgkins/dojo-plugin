class FinishHandle
{
    bool finished;
    CSmScriptPlayer@ smScript;
    CGamePlaygroundUIConfig@ uiConfig;
    CGameCtnChallenge@ rootMap;
    CTrackManiaNetwork@ network;
    int endRaceTime;
    array<uint> sectorTimes;
    uint respawns;
}
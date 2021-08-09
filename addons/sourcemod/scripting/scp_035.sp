#include <sdkhooks>
#include <scpcore>
#include <json>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "[SCP] SCP-035",
    author = "GeTtOo",
    description = "Added SCP-035",
    version = "1.0",
    url = "https://github.com/GeTtOo/csgo_scp"
};

public void SCP_OnPlayerJoin(Client &ply) 
{
    SDKHook(ply.id, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void SCP_OnRoundStart()
{
    Ents.Create("035_mask")
    .SetPos(new Vector(-7682.0, 464.0, 118.0), new Angle(0.0, 0.0, 0.0))
    .UseCB(view_as<SDKHookCB>(Callback_EntUse))
    .Spawn();
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    char attackerClass[32];
    Client atk = Clients.Get(attacker);

    if (atk == null) return Plugin_Continue;
    atk.class.Name(attackerClass, sizeof(attackerClass)); 

    if(StrEqual(attackerClass, "035"))
    {
        damage += 180;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public SDKHookCB Callback_EntUse(int eid, int cid) 
{
    Client ply = Clients.Get(cid);

    if (ply.IsSCP && ply != null && ply.class != null) return;

    char team[32];
    ply.Team(team, sizeof(team));
    gamemode.mngr.team(team).count--;

    for(int i = 0; i < 63; i++)
    {
        int index = GetEntPropEnt(ply.id, Prop_Send, "m_hMyWeapons", i);

        if(index && IsValidEdict(index))
        {
            CS_DropWeapon(ply.id, index, true, true);
        }
    }

    ply.inv.Clear();
    ply.Team("SCP");
    ply.class = gamemode.team("SCP").class("035");
    gamemode.mngr.team("SCP").count++;

    Ents.Remove(eid);
}
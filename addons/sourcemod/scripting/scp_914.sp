#include <sdkhooks>
#include <scpcore>
#include <json>

#pragma semicolon 1
#pragma newdecls required

#define MATH_COUNTER_VALUE_OFFSET 924

int Counter = 0;

char modes[5][32] = {"rough", "coarse", "one_by_one", "fine", "very_fine"};
char curmode[32] = "rough";

public Plugin myinfo = {
    name = "SCP 914",
    author = "Andrey::Dono",
    description = "SCP-914 for CS:GO modification SCP Foundation",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("round_start", OnRoundStart);
}

public void OnPluginEnd() {
    gamemode.timer.PluginClear();
}

public void OnMapStart() {
    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));

    gamemode.config.Add("914", ReadConfig(mapName, "914"));
}

public Action OnRoundStart(Event ev, const char[] name, bool dbroadcast) {
    if (gamemode.config.GetObject("914").GetObject("config").GetBool("usemathcounter")) {
        int entId = 0;
        while ((entId = FindEntityByClassname(entId, "math_counter")) != -1) {
            char findedCounterName[32], configCounterName[32];
            GetEntPropString(entId, Prop_Data, "m_iName", findedCounterName, sizeof(findedCounterName));
            gamemode.config.GetObject("914").GetObject("config").GetString("countername", configCounterName, sizeof(configCounterName));
            if (StrEqual(findedCounterName, configCounterName))
                Counter = entId;
        }
    }
    else
    {
        Counter = 0;
    }
}

public void SCP_OnPlayerSpawn(Client &ply) {
    //Client client = Clients.Get(ply.id);
}

public void SCP_OnButtonPressed(Client &ply, int doorId) {
    JSON_Object config = gamemode.config.GetObject("914").GetObject("config");
    
    if (doorId == config.GetInt("runbutton"))
        gamemode.timer.Simple(config.GetInt("runtime"), "Transform", ply);
    
    if (doorId == config.GetInt("switchbutton"))
        if (config.GetBool("usemathcounter"))
            curmode = modes[RoundToZero(GetEntDataFloat(Counter, MATH_COUNTER_VALUE_OFFSET))];
        else
            if (Counter < 4) {
                Counter++;
                curmode = modes[Counter];
            }
            else
            {
                Counter = 0;
                curmode = modes[Counter];
            }
}

public void Transform(Client ply) {
    JSON_Object recipes = gamemode.config.GetObject("914").GetObject("recipes").GetObject(curmode);

    char filter[3][32] = {"prop_physics", "weapon_", "player"};
    ArrayList ents = Ents.FindInBox(new Vector(3630.0, -2072.0, 20.0), new Vector(3762.0, -1947.0, 90.0), filter, sizeof(filter));

    if (gamemode.config.debug)
        PrintToChatAll("Ents count: %i", ents.Length);

    for(int i=0; i < ents.Length; i++) 
    {
        Entity ent = ents.Get(i);

        bool upgraded = false;

        char entclass[32];
        ent.GetClass(entclass, sizeof(entclass));
        
        if (gamemode.config.debug)
            PrintToChat(ply.id, "class: %s, id: %i", entclass, ent.id);

        StringMapSnapshot srecipes = recipes.Snapshot();

        int keylen;
        for (int k = 0; k < srecipes.Length; k++)
        {
            keylen = srecipes.KeyBufferSize(k);
            char[] ientclass = new char[keylen];
            srecipes.GetKey(k, ientclass, keylen);
            if (json_is_meta_key(ientclass)) continue;

            if (StrEqual(entclass, ientclass)) {
                Vector oitempos = ent.GetPos() - new Vector(0.0, 425.0, 0.0);

                JSON_Array oentdata = view_as<JSON_Array>(recipes.GetObject(ientclass));
                JSON_Array recipe = view_as<JSON_Array>(oentdata.GetObject(GetRandomInt(0, oentdata.Length - 1)));

                char oentclass[32];
                recipe.GetString(0, oentclass, sizeof(oentclass));
                
                if (StrEqual(entclass, "player"))
                {
                    if (recipe.GetInt(1) >= GetRandomInt(1, 100)) {
                        char statusname[32];
                        recipe.GetString(0, statusname, sizeof(statusname));
                        
                        Call_StartFunction(null, GetFunctionByName(null, statusname));
                        Call_PushCell(ply);
                        Call_Finish();
                        
                        ent.SetPos(oitempos);
                    }
                }
                else
                {
                    if (recipe.GetInt(1) >= GetRandomInt(1, 100))
                    {
                        if (recipe.GetInt(2) >= GetRandomInt(1, 100))
                        {
                            Ents.Create(oentclass)
                            .SetPos(oitempos, ent.GetAng())
                            .UseCB(view_as<SDKHookCB>(Callback_EntUse))
                            .Spawn();

                            Ents.Remove(ent.id);
                        }
                        else
                        {
                            ent.SetPos(oitempos);
                        }
                    }
                    else
                    {
                        Ents.Remove(ent.id);
                    }
                }
                
                upgraded = true;
            }
        }

        if (!upgraded)
            ent.SetPos(ent.GetPos() - new Vector(0.0, 425.0, 0.0));
    }

    delete ents;
}

public SDKHookCB Callback_EntUse(int eid, int cid) {
    Client ply = Clients.Get(cid);
    Entity ent = Ents.Get(eid);

    char entClassName[32];
    ent.GetClass(entClassName, sizeof(entClassName));

    if (gamemode.entities.HasKey(entClassName))
        if (ply.inv.TryAdd(entClassName))
            Ents.Remove(ent.id);
        else
            PrintToChat(ply.id, " \x07[SCP] \x01Твой инвентарь переполнен");
}

public void Regeneration(Client ply) {
    PrintToChat(ply.id, "Ты получаешь бафф регенерации");

    char  timername[128];
    Format(timername, sizeof(timername), "Status effect Regeneraion for player id %i", ply.id);
    
    gamemode.timer.Create(timername, 1, 60, "Buff_Regeneration", ply);
}

public void Buff_Regeneration(Client ply) {
    if (ply.health < ply.class.health)
        if (ply.health + (ply.class.health * 5 /100) > ply.class.health)
            ply.health = ply.class.health;
        else
            ply.health += ply.class.health * 5 /100;
}

public void Speed(Client ply) {
    PrintToChat(ply.id, "Ты получаешь бафф увеличенной скорости");
    
    ply.speed *= 2.0;
}
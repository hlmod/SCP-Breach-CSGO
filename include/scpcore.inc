#if defined _scpcore_included
    #endinput
#endif
#define _scpcore_included

// ¯\_(ツ)_/¯
#include "scp/structures/vector"
#include "scp/classes/gamemode"

GameMode gamemode;

#include "scp/classes/entity"
#include "scp/classes/client"

ClientSingleton Clients;
EntitySingleton Ents;

forward void SCP_OnPlayerJoin(Client &ply);

forward void SCP_OnPlayerLeave(Client &ply);

forward void SCP_OnPlayerSpawn(Client &ply);

forward Action SCP_OnTakeDamage(Client vic, Client atk, float &damage, int &damagetype);

forward void SCP_OnButtonPressed(Client ply, int doorId);

public any NativeClients_Get(Handle Plugin, int numArgs) {
    int id = GetNativeCell(2);
    Client clients[MAXPLAYERS + 1];
    Clients.GetArray("Clients", clients, sizeof(clients));
    if (id <= MAXPLAYERS)
        return view_as<Client>(clients[id]);
    else
        return view_as<Client>(null);
}

public any NativeClients_GetRandom(Handle Plugin, int numArgs) {
    Client clients[MAXPLAYERS + 1];
    Clients.GetArray("Clients", clients, sizeof(clients));
    int random = GetRandomInt(1, Clients.InGame());
    return view_as<Client>(clients[random]);
}

public any NativeClients_InGame(Handle Plugin, int numArgs) {
    int client = 1;
    while (IsClientInGame(client) && GetClientTeam(client) > 1)
        client++;
    client--;
    return client;
}

public any NativeClients_Alive(Handle Plugin, int numArgs) {
    int client = 1;
    int clientAlive = 1;
    while (IsClientInGame(client) && GetClientTeam(client) > 1) {
        if (IsPlayerAlive(client))
            clientAlive++;
        client++;
    }
    clientAlive--;
    return clientAlive;
}

public any NativeEntities_Get(Handle Plugin, int numArgs) {
    int id = GetNativeCell(2);
    ArrayList entArr;
    Ents.GetValue("Entities", entArr);

    for(int i=0; i < entArr.Length; i++) {
        PrintToServer("In Arr ent: %i", view_as<Entity>(entArr.Get(i, 0)).id);
        if (view_as<Entity>(entArr.Get(i, 0)).id == id)
            return view_as<Entity>(entArr.Get(i, 0));
    }

    PrintToServer("Ent id: %i", id);
    return view_as<Entity>(0);
}
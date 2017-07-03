/***************************************************************************
	
	FragRadio SourceMod Plugin
	Copyright (c) 2011 JokerIce <http://forums.jokerice.co.uk/>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
	
****************************************************************************/

#define PLUGINVERSION "1.4.8.Akami.1"

#pragma semicolon 1
#include <sourcemod>
#include <socket>
#include <base64>
#include <kento_csgocolors>
#include <fragradio>

Handle g_hCvarPluginStatus = null;
Handle g_hCvarInteract = null;
Handle g_hCvarRating = null;
Handle g_hCvarWelcomeAdvert = null;
Handle g_hCvarAdverts = null;
Handle g_hCvarAdvertsInterval = null;
Handle g_hCvarGetStreamInfo = null;
Handle g_hCvarStreamInterval = null;
Handle g_hCvarStreamHost = null;
Handle g_hCvarStreamPort = null;
Handle g_hCvarStreamGamePath = null;
Handle g_hCvarStreamUpdatePath = null;
Handle g_hCvarStreamStatsPath = null;
Handle g_hCvarWebPlayerScript = null;
Handle g_hCvarServerUpdateInterval = null;

Handle g_hAdvertsTimer = null;
Handle g_hStreamTimer = null;
Handle g_hServerTimer = null;

char g_sDataReceived[5120];
char g_sDJ[512];
char g_sSong[512];

bool PluginEnabled;
bool InteractEnabled;
bool RatingEnabled;
bool WelcomeAdvertsEnabled;
bool AdvertsEnabled;
float AdvertsInterval;
bool GetStreamInfo;
float StreamInterval;
char StreamHost[512];
int StreamPort;
char StreamGamePath[512];
char StreamUpdatePath[512];
char StreamStatsPath[512];
char WebPlayerScript[512];
float ServerUpdateInterval;
bool isTuned[100];
int tunedVol[100];

public Plugin myinfo =  {
	name = "FragRadio SourceMod Plugin", 
	author = "BomBom - Dunceantix Edited By Akami Studio", 
	description = "FragRadio SourceMod Plugin", 
	version = PLUGINVERSION, 
	url = "http://www.fragradio.com/"
}

public OnPluginStart() {
	
	AutoExecConfig();
	
	g_hCvarPluginStatus = CreateConVar("fr_enabled", "1", "Enables or disables the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarPluginStatus, Cvar_Change_Enabled);
	
	g_hCvarInteract = CreateConVar("fr_interact", "1", "Enables or disables the request and shoutout system.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarInteract, Cvar_Changed);
	
	g_hCvarRating = CreateConVar("fr_rating", "1", "Enables or disables the song and dj rating system.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarRating, Cvar_Changed);
	
	g_hCvarWelcomeAdvert = CreateConVar("fr_welcomeadvert", "1", "Enables or disables the welcome advert you see upon joining the server.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarWelcomeAdvert, Cvar_Changed);
	
	g_hCvarAdverts = CreateConVar("fr_adverts", "1", "Enables or disables chat adverts that display after a time limit.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarAdverts, Cvar_Change_Adverts);
	
	g_hCvarAdvertsInterval = CreateConVar("fr_adverts_interval", "150.0", "Sets the delay between adverts shown in chat.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarAdvertsInterval, Cvar_Changed);
	
	g_hCvarGetStreamInfo = CreateConVar("fr_streaminfo", "1", "Enables or disables stream information from being gathered.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarGetStreamInfo, Cvar_Change_StreamInfo);
	
	g_hCvarStreamInterval = CreateConVar("fr_streaminfo_interval", "15.0", "DO NOT CHANGE OR YOUR SERVER IP WILL BE BANNED! Sets the time between stream info updates.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarStreamInterval, Cvar_Changed);
	
	g_hCvarStreamHost = CreateConVar("fr_stream_host", "fragradio.com", "Sets the website hostname used to send and retrieve info.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarStreamHost, Cvar_Changed);
	
	g_hCvarStreamPort = CreateConVar("fr_stream_port", "80", "Sets the website port used to send and retrieve info.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarStreamPort, Cvar_Changed);
	
	g_hCvarStreamGamePath = CreateConVar("fr_stream_game_path", "/resources/plugins/sourcemod/smreq.php", "Website path used for rating and interaction.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarStreamGamePath, Cvar_Changed);
	
	g_hCvarStreamUpdatePath = CreateConVar("fr_stream_update_path", "/resources/plugins/sourcemod/smsinfo.php", "Website path used for sending server info.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarStreamUpdatePath, Cvar_Changed);
	
	g_hCvarStreamStatsPath = CreateConVar("fr_stream_stats_path", "/resources/plugins/sourcemod/smsong.php", "Website path used for getting stream info.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarStreamStatsPath, Cvar_Changed);
	
	g_hCvarWebPlayerScript = CreateConVar("fr_webplayer_script", "/resources/plugins/sourcemod/player.php", "Website script used for the web player.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarWebPlayerScript, Cvar_Changed);
	
	g_hCvarServerUpdateInterval = CreateConVar("fr_server_update_interval", "600.0", "DO NOT CHANGE OR YOUR SERVER IP WILL BE BANNED! Set at 10min for enabledservers info.", FCVAR_NOTIFY);
	HookConVarChange(g_hCvarServerUpdateInterval, Cvar_Changed);
	
	RegConsoleCmd("sm_dj", Cmd_ShowDJ);
	RegConsoleCmd("sm_song", Cmd_ShowSong);
	RegConsoleCmd("sm_radio", Cmd_RadioMenu);
	RegConsoleCmd("sm_req", Cmd_Request);
	RegConsoleCmd("sm_request", Cmd_Request);
	RegConsoleCmd("sm_r", Cmd_Request);
	RegConsoleCmd("sm_shoutout", Cmd_Shoutout);
	RegConsoleCmd("sm_s", Cmd_Shoutout);
	RegConsoleCmd("sm_choon", Cmd_Choon);
	RegConsoleCmd("sm_ch", Cmd_Choon);
	RegConsoleCmd("sm_poon", Cmd_Poon);
	RegConsoleCmd("sm_p", Cmd_Poon);
	RegConsoleCmd("sm_djftw", Cmd_djFTW);
	RegConsoleCmd("sm_djftl", Cmd_djFTL);
	RegConsoleCmd("sm_djsftw", Cmd_djsFTW);
	RegConsoleCmd("sm_djsftl", Cmd_djsFTL);
	RegConsoleCmd("sm_competition", Cmd_Competition);
	RegConsoleCmd("sm_comp", Cmd_Competition);
	RegConsoleCmd("sm_c", Cmd_Competition);
	RegConsoleCmd("sm_joke", Cmd_Joke);
	RegConsoleCmd("sm_j", Cmd_Joke);
	RegConsoleCmd("sm_other", Cmd_Other);
	RegConsoleCmd("sm_o", Cmd_Other);
	
	LoadTranslations("akami.fragradio.phrases");
}

public OnClientPutInServer(client) {
	if (WelcomeAdvertsEnabled) {
		WelcomeAdvert(client);
	}
}

public OnClientDisconnect(client) {
	isTuned[client] = false;
}

stock ClearTimer(&Handle:timer) {
	if (timer != null) {
		KillTimer(timer);
	}
	
	timer = null;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("FR_IsPlayerListening", Native_IsPlayerListening);
	return APLRes_Success;
}

public int Native_IsPlayerListening(Handle plugin, int numParams)
{
	if (isTuned[GetNativeCell(1)]) {
		return true;
	} else {
		return false;
	}
	
}

public Action WelcomeAdvert(any:client) {
	CPrintToChat(client, "%t", "WelcomeAdvert");
}

public Action Advertise(Handle timer)
{
	switch (GetRandomInt(1, 10))
	{
		case 1:
		{
			CPrintToChatAll("%t", "Advert 1");
		}
		case 2:
		{
			CPrintToChatAll("%t", "Advert 2");
		}
		case 3:
		{
			CPrintToChatAll("%t", "Advert 3");
		}
		case 4:
		{
			CPrintToChatAll("%t", "Advert 4");
		}
		case 5:
		{
			CPrintToChatAll("%t", "Advert 5");
		}
		case 6:
		{
			CPrintToChatAll("%t", "Advert 6");
		}
		case 7:
		{
			CPrintToChatAll("%t", "Advert 7");
		}
		case 8:
		{
			CPrintToChatAll("%t", "Advert 8");
		}
		case 9:
		{
			CPrintToChatAll("%t", "Advert 9");
		}
		case 10:
		{
			CPrintToChatAll("%t", "Advert 10");
		}
	}
}

public OnMapEnd() {
	ClearTimer(g_hAdvertsTimer);
	ClearTimer(g_hStreamTimer);
	ClearTimer(g_hServerTimer);
}

public Cvar_Changed(Handle convar, const char[] oldValue, const char[] newValue) {
	OnConfigsExecuted();
}

public Cvar_Change_Enabled(Handle convar, const char[] oldValue, const char[] newValue) {
	PluginEnabled = GetConVarBool(g_hCvarPluginStatus);
	
	if (PluginEnabled) {
		if (AdvertsEnabled) {
			g_hAdvertsTimer = CreateTimer(AdvertsInterval, Advertise, 0, TIMER_REPEAT);
		}
		
		if (GetStreamInfo) {
			Server_Receive();
			g_hStreamTimer = CreateTimer(StreamInterval, UpdateStreamInfo, 0, TIMER_REPEAT);
			
			Server_Send();
			g_hServerTimer = CreateTimer(ServerUpdateInterval, UpdateServerList, 0, TIMER_REPEAT);
		}
		
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && IsClientInGame(i)) {
				if (isTuned[i]) {
					StreamPanel("Thanks for tuning into FragRadio!", "about:blank", i);
					
					char url[256];
					FormatEx(url, sizeof(url), "http://%s/%s?vol=%s", StreamHost, WebPlayerScript, tunedVol[i]);
					StreamPanel("You are tuned into FragRadio!", url, i);
					
					CPrintToChat(i, "%t", "Enabled1");
				}
			}
		}
	} else {
		ClearTimer(g_hAdvertsTimer);
		ClearTimer(g_hStreamTimer);
		ClearTimer(g_hServerTimer);
		
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && IsClientInGame(i)) {
				if (isTuned[i]) {
					StreamPanel("Thanks for tuning into FragRadio!", "about:blank", i);
					CPrintToChat(i, "%t", "Disabled1");
				}
			}
		}
	}
}

public Cvar_Change_Adverts(Handle convar, const char[] oldValue, const char[] newValue) {
	AdvertsEnabled = GetConVarBool(g_hCvarAdverts);
	
	if (AdvertsEnabled) {
		g_hAdvertsTimer = CreateTimer(AdvertsInterval, Advertise, 0, TIMER_REPEAT);
	} else {
		ClearTimer(g_hAdvertsTimer);
	}
}

public Cvar_Change_StreamInfo(Handle convar, const char[] oldValue, const char[] newValue) {
	GetStreamInfo = GetConVarBool(g_hCvarGetStreamInfo);
	
	if (GetStreamInfo) {
		Server_Receive();
		g_hStreamTimer = CreateTimer(StreamInterval, UpdateStreamInfo, 0, TIMER_REPEAT);
		
		Server_Send();
		g_hServerTimer = CreateTimer(ServerUpdateInterval, UpdateServerList, 0, TIMER_REPEAT);
	} else {
		ClearTimer(g_hStreamTimer);
		ClearTimer(g_hServerTimer);
	}
}

public OnConfigsExecuted() {
	PluginEnabled = GetConVarBool(g_hCvarPluginStatus);
	InteractEnabled = GetConVarBool(g_hCvarInteract);
	RatingEnabled = GetConVarBool(g_hCvarRating);
	WelcomeAdvertsEnabled = GetConVarBool(g_hCvarWelcomeAdvert);
	AdvertsEnabled = GetConVarBool(g_hCvarAdverts);
	AdvertsInterval = GetConVarFloat(g_hCvarAdvertsInterval);
	GetStreamInfo = GetConVarBool(g_hCvarGetStreamInfo);
	StreamInterval = GetConVarFloat(g_hCvarStreamInterval);
	GetConVarString(g_hCvarStreamHost, StreamHost, sizeof(StreamHost));
	StreamPort = GetConVarInt(g_hCvarStreamPort);
	GetConVarString(g_hCvarStreamGamePath, StreamGamePath, sizeof(StreamGamePath));
	GetConVarString(g_hCvarStreamUpdatePath, StreamUpdatePath, sizeof(StreamUpdatePath));
	GetConVarString(g_hCvarStreamStatsPath, StreamStatsPath, sizeof(StreamStatsPath));
	GetConVarString(g_hCvarWebPlayerScript, WebPlayerScript, sizeof(WebPlayerScript));
	ServerUpdateInterval = GetConVarFloat(g_hCvarServerUpdateInterval);
	
	if (PluginEnabled) {
		if (AdvertsEnabled) {
			g_hAdvertsTimer = CreateTimer(AdvertsInterval, Advertise, 0, TIMER_REPEAT);
		}
		
		if (GetStreamInfo) {
			Server_Receive();
			g_hStreamTimer = CreateTimer(StreamInterval, UpdateStreamInfo, 0, TIMER_REPEAT);
			
			Server_Send();
			g_hServerTimer = CreateTimer(ServerUpdateInterval, UpdateServerList, 0, TIMER_REPEAT);
		}
	}
}

public Action UpdateStreamInfo(Handle timer) {
	Server_Receive();
}

public Action UpdateServerList(Handle timer) {
	Server_Send();
}

public Cmd_Check(char[] type, client) {
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) {
		if (!PluginEnabled) {
			CReplyToCommand(client, "%t", "Disabled2");
			return false;
		}
		
		if (StrEqual(type, "streaminfo") && !GetStreamInfo) {
			CReplyToCommand(client, "%t", "Disabled3");
			return false;
		} else if (StrEqual(type, "interact") && !InteractEnabled) {
			CReplyToCommand(client, "%t", "Disabled4");
			return false;
		} else if (StrEqual(type, "rating") && !RatingEnabled) {
			CReplyToCommand(client, "%t", "Disabled5");
			return false;
		}
		
		if (!StrEqual(type, "streaminfo") && isTuned[client] != true) {
			CReplyToCommand(client, "%t", "NotTunedIn");
			return false;
		}
	} else {
		CReplyToCommand(client, "%t", "OnlyClients");
		return false;
	}
	
	return true;
}

public Action Cmd_ShowDJ(client, args) {
	if (Cmd_Check("streaminfo", client)) {
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CReplyToCommand(client, "%t", "CurrentDJ", g_sDJ);
		} else {
			CReplyToCommand(client, "%t", "NoStreamInfo");
		}
	}
	
	return Plugin_Handled;
}

public Action Cmd_ShowSong(client, args) {
	if (Cmd_Check("streaminfo", client)) {
		if (GetStreamInfo && !StrEqual(g_sSong, "")) {
			CReplyToCommand(client, "%t", "CurrentSong", g_sSong);
		} else {
			CReplyToCommand(client, "%t", "NoStreamInfo");
		}
	}
	
	return Plugin_Handled;
}

public StreamPanel(char[] title, char[] url, client) {
	Handle Radio = CreateKeyValues("data");
	KvSetString(Radio, "title", title);
	KvSetString(Radio, "type", "2");
	KvSetString(Radio, "msg", url);
	ShowVGUIPanel(client, "info", Radio, false);
	CloseHandle(Radio);
}

public RadioMenuHandle(Handle menu, MenuAction action, int client, int choice) {
	if (action == MenuAction_Select) {
		char info[32];
		bool found = GetMenuItem(menu, choice, info, sizeof(info));
		
		if (found) {
			if (StringToInt(info) == 0) {
				isTuned[client] = false;
				tunedVol[client] = 0;
				
				StreamPanel("Thanks for tuning into FragRadio!", "about:blank", client);
				CPrintToChat(client, "%t", "TuningInto1");
			} else {
				if (isTuned[client] != true) {
					char name[128];
					GetClientName(client, name, sizeof(name));
					CPrintToChatAll("%t", "TuningInto2", name);
				}
				
				StreamPanel("Thanks for tuning into FragRadio!", "about:blank", client);
				
				isTuned[client] = true;
				tunedVol[client] = StringToInt(info);
				
				char url[256];
				FormatEx(url, sizeof(url), "http://%s/%s?vol=%s", StreamHost, WebPlayerScript, info);
				StreamPanel("You are tuned into FragRadio!", url, client);
			}
		}
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action Cmd_RadioMenu(client, args) {
	if (!PluginEnabled) {
		CReplyToCommand(client, "%t", "Disabled2");
		return Plugin_Handled;
	}
	
	if (args > 1) {
		
		return Plugin_Handled;
	}
	
	Handle menu = CreateMenu(RadioMenuHandle);
	
	if (GetStreamInfo && !StrEqual(g_sDJ, "") && !StrEqual(g_sSong, "")) {
		SetMenuTitle(menu, "%t", "RadioMenuTitle1", g_sDJ, g_sSong);
	} else {
		SetMenuTitle(menu, "%t", "RadioMenuTitle2");
	}
	
	char Volume100[32];
	Format(Volume100, sizeof(Volume100), "%t", "Volume100");
	AddMenuItem(menu, "100", Volume100);
	
	char Volume80[32];
	Format(Volume80, sizeof(Volume80), "%t", "Volume80");
	AddMenuItem(menu, "80", Volume80);
	
	char Volume40[32];
	Format(Volume40, sizeof(Volume40), "%t", "Volume40");
	AddMenuItem(menu, "40", Volume40);
	
	char Volume20[32];
	Format(Volume20, sizeof(Volume20), "%t", "Volume20");
	AddMenuItem(menu, "20", Volume20);
	
	char Volume10[32];
	Format(Volume10, sizeof(Volume10), "%t", "Volume10");
	AddMenuItem(menu, "10", Volume10);
	
	char Volume5[32];
	Format(Volume5, sizeof(Volume5), "%t", "Volume5");
	AddMenuItem(menu, "5", Volume5);
	
	if (isTuned[client]) {
		char Volume0[32];
		Format(Volume0, sizeof(Volume0), "%t", "Volume0");
		AddMenuItem(menu, "0", Volume0);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public Action Cmd_Request(client, args) {
	if (Cmd_Check("interact", client)) {
		if (args < 1) {
			CReplyToCommand(client, "%t", "Usage1");
			return Plugin_Handled;
		}
		
		char request[256];
		GetCmdArgString(request, sizeof(request));
		
		if (StrEqual(g_sDJ, "AutoDJ")) {
			CReplyToCommand(client, "%t", "Request1");
			return Plugin_Handled;
		}
		
		if (strlen(request) < 8) {
			CReplyToCommand(client, "%t", "Request2");
			return Plugin_Handled;
		} else if (strlen(request) > 255) {
			CReplyToCommand(client, "%t", "Request3");
			return Plugin_Handled;
		}
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CReplyToCommand(client, "%t", "Request4", g_sDJ);
		} else {
			CReplyToCommand(client, "%t", "Request5");
		}
		
		Client_Send("req", request, client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_Shoutout(client, args) {
	if (Cmd_Check("interact", client)) {
		if (args < 1) {
			CReplyToCommand(client, "%t", "Usage2");
			return Plugin_Handled;
		}
		
		char shoutout[256];
		GetCmdArgString(shoutout, sizeof(shoutout));
		
		if (StrEqual(g_sDJ, "AutoDJ")) {
			CReplyToCommand(client, "%t", "Shoutout1");
			return Plugin_Handled;
		}
		
		if (strlen(shoutout) < 8) {
			CReplyToCommand(client, "%t", "Shoutout2");
			return Plugin_Handled;
		} else if (strlen(shoutout) > 255) {
			CReplyToCommand(client, "%t", "Shoutout3");
			return Plugin_Handled;
		}
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CReplyToCommand(client, "%t", "Shoutout4", g_sDJ);
		} else {
			CReplyToCommand(client, "%t", "Shoutout5");
		}
		
		Client_Send("shout", shoutout, client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_Other(client, args) {
	if (Cmd_Check("interact", client)) {
		if (args < 1) {
			CReplyToCommand(client, "%t", "Usage3");
			return Plugin_Handled;
		}
		
		char other[256];
		GetCmdArgString(other, sizeof(other));
		
		if (StrEqual(g_sDJ, "AutoDJ")) {
			CReplyToCommand(client, "%t", "Other1");
			return Plugin_Handled;
		}
		
		if (strlen(other) < 8) {
			CReplyToCommand(client, "%t", "Other2");
			return Plugin_Handled;
		} else if (strlen(other) > 255) {
			CReplyToCommand(client, "%t", "Other3");
			return Plugin_Handled;
		}
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CReplyToCommand(client, "%t", "Other4", g_sDJ);
		} else {
			CReplyToCommand(client, "%t", "Other5");
		}
		
		Client_Send("other", other, client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_Joke(client, args) {
	if (Cmd_Check("interact", client)) {
		if (args < 1) {
			CReplyToCommand(client, "%t", "Usage4");
			return Plugin_Handled;
		}
		
		char joke[256];
		GetCmdArgString(joke, sizeof(joke));
		
		if (StrEqual(g_sDJ, "AutoDJ")) {
			CReplyToCommand(client, "%t", "Joke1");
			return Plugin_Handled;
		}
		
		if (strlen(joke) < 4) {
			CReplyToCommand(client, "%t", "Joke2");
			return Plugin_Handled;
		} else if (strlen(joke) > 255) {
			CReplyToCommand(client, "%t", "Joke3");
			return Plugin_Handled;
		}
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CReplyToCommand(client, "%t", "Joke4", g_sDJ);
		} else {
			CReplyToCommand(client, "%t", "Joke5");
		}
		
		Client_Send("Joke", joke, client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_Competition(client, args) {
	if (Cmd_Check("interact", client)) {
		if (args < 1) {
			CReplyToCommand(client, "%t", "Usage5");
			return Plugin_Handled;
		}
		
		char competition[256];
		GetCmdArgString(competition, sizeof(competition));
		
		if (StrEqual(g_sDJ, "AutoDJ")) {
			CReplyToCommand(client, "%t", "Competition1");
			return Plugin_Handled;
		}
		
		if (strlen(competition) < 4) {
			CReplyToCommand(client, "%t", "Competition2");
			return Plugin_Handled;
		} else if (strlen(competition) > 255) {
			CReplyToCommand(client, "%t", "Competition3");
			return Plugin_Handled;
		}
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CReplyToCommand(client, "%t", "Competition4", g_sDJ);
		} else {
			CReplyToCommand(client, "%t", "Competition5");
		}
		
		Client_Send("Competition", competition, client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_Choon(client, args) {
	if (Cmd_Check("rating", client)) {
		char name[128];
		GetClientName(client, name, sizeof(name));
		
		if (GetStreamInfo && !StrEqual(g_sSong, "")) {
			CPrintToChatAll("%t", "Choon1", name, g_sSong);
		} else {
			CPrintToChatAll("%t", "Choon2", name);
		}
		
		Client_Send("song", "ftw", client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_Poon(client, args) {
	if (Cmd_Check("rating", client)) {
		char name[128];
		GetClientName(client, name, sizeof(name));
		
		if (GetStreamInfo && !StrEqual(g_sSong, "")) {
			CPrintToChatAll("%t", "Poon1", name, g_sSong);
		} else {
			CPrintToChatAll("%t", "Poon2", name);
		}
		
		Client_Send("song", "ftl", client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_djFTW(client, args) {
	if (Cmd_Check("rating", client)) {
		char name[128];
		GetClientName(client, name, sizeof(name));
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CPrintToChatAll("%t", "Awesome1", name, g_sDJ);
		} else {
			CPrintToChatAll("%t", "Awesome2", name);
		}
		
		Client_Send("dj", "ftw", client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_djFTL(client, args) {
	if (Cmd_Check("rating", client)) {
		char name[128];
		GetClientName(client, name, sizeof(name));
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CPrintToChatAll("%t", "Fail1", name, g_sDJ);
		} else {
			CPrintToChatAll("%t", "Fail2", name);
		}
		
		Client_Send("dj", "ftl", client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_djsFTW(client, args) {
	if (Cmd_Check("rating", client)) {
		char name[128];
		GetClientName(client, name, sizeof(name));
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CPrintToChatAll("%t", "Awesome3", name, g_sDJ);
		} else {
			CPrintToChatAll("%t", "Awesome4", name);
		}
		
		Client_Send("djs", "ftw", client);
	}
	
	return Plugin_Handled;
}

public Action Cmd_djsFTL(client, args) {
	if (Cmd_Check("rating", client)) {
		char name[128];
		GetClientName(client, name, sizeof(name));
		
		if (GetStreamInfo && !StrEqual(g_sDJ, "")) {
			CPrintToChatAll("%t", "Fail3", name, g_sDJ);
		} else {
			CPrintToChatAll("%t", "Fail4", name);
		}
		
		Client_Send("djs", "ftl", client);
	}
	
	return Plugin_Handled;
}

public Action Server_Send() {
	Handle dp = CreateDataPack();
	
	WritePackString(dp, "serverinfo");
	
	char serverip[32];
	char serverport[32];
	char serverinfo[64];
	
	GetConVarString(FindConVar("hostip"), serverip, sizeof(serverip));
	int hostip = GetConVarInt(FindConVar("hostip"));
	FormatEx(serverip, sizeof(serverip), "%u.%u.%u.%u", (hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF);
	GetConVarString(FindConVar("hostport"), serverport, sizeof(serverport));
	FormatEx(serverinfo, sizeof(serverinfo), "%s:%s", serverip, serverport);
	WritePackString(dp, serverinfo);
	
	Handle socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket, dp);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, StreamHost, StreamPort);
}

public Action Server_Receive() {
	Handle dp = CreateDataPack();
	
	WritePackString(dp, "streaminfo");
	
	Handle socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket, dp);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, StreamHost, StreamPort);
}

public Action Client_Send(char[] type, char[] message, client) {
	Handle dp = CreateDataPack();
	
	WritePackString(dp, type);
	WritePackString(dp, message);
	
	char ip[32];
	GetClientIP(client, ip, sizeof(ip), true);
	WritePackString(dp, ip);
	
	char name[128];
	GetClientName(client, name, sizeof(name));
	WritePackString(dp, name);
	
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
	WritePackString(dp, steamid);
	
	char serverip[32];
	char serverport[32];
	char serverinfo[64];
	
	GetConVarString(FindConVar("hostip"), serverip, sizeof(serverip));
	int hostip = GetConVarInt(FindConVar("hostip"));
	FormatEx(serverip, sizeof(serverip), "%u.%u.%u.%u", (hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF);
	GetConVarString(FindConVar("hostport"), serverport, sizeof(serverport));
	FormatEx(serverinfo, sizeof(serverinfo), "%s:%s", serverip, serverport);
	
	WritePackString(dp, serverinfo);
	WritePackCell(dp, client);
	
	Handle socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket, dp);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, StreamHost, StreamPort);
}

public OnSocketConnected(Handle socket, any:dp) {
	ResetPack(dp);
	
	char type[32];
	ReadPackString(dp, type, sizeof(type));
	
	char socketStr[1024];
	
	if (StrEqual(type, "serverinfo")) {
		char ip[64];
		ReadPackString(dp, ip, sizeof(ip));
		char eip[128];
		EncodeBase64(eip, sizeof(eip), ip);
		
		FormatEx(socketStr, sizeof(socketStr), "GET %s?ip=%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", StreamUpdatePath, eip, StreamHost);
	} else if (StrEqual(type, "streaminfo")) {
		FormatEx(socketStr, sizeof(socketStr), "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", StreamStatsPath, StreamHost);
	} else {
		char etype[64];
		EncodeBase64(etype, sizeof(etype), type);
		
		char message[256];
		ReadPackString(dp, message, sizeof(message));
		char emessage[512];
		EncodeBase64(emessage, sizeof(emessage), message);
		
		char ip[64];
		ReadPackString(dp, ip, sizeof(ip));
		char eip[128];
		EncodeBase64(eip, sizeof(eip), ip);
		
		char name[128];
		ReadPackString(dp, name, sizeof(name));
		char ename[256];
		EncodeBase64(ename, sizeof(ename), name);
		
		char steamid[64];
		ReadPackString(dp, steamid, sizeof(steamid));
		char esteamid[128];
		EncodeBase64(esteamid, sizeof(esteamid), steamid);
		
		char serverinfo[64];
		ReadPackString(dp, serverinfo, sizeof(serverinfo));
		char eserverinfo[128];
		EncodeBase64(eserverinfo, sizeof(eserverinfo), serverinfo);
		
		FormatEx(socketStr, sizeof(socketStr), "GET %s?type=%s&content=%s&playersip=%s&playersname=%s&playerssteam=%s&serversip=%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", StreamGamePath, etype, emessage, eip, ename, esteamid, eserverinfo, StreamHost);
	}
	
	SocketSend(socket, socketStr);
}

public OnSocketReceive(Handle socket, char[] receiveData, const dataSize, any:dp) {
	ResetPack(dp);
	
	char type[32];
	ReadPackString(dp, type, sizeof(type));
	
	if (StrEqual(type, "streaminfo")) {
		strcopy(g_sDataReceived, sizeof(g_sDataReceived), receiveData);
	}
}

public OnSocketDisconnected(Handle socket, any dp) {
	ResetPack(dp);
	
	char type[32];
	ReadPackString(dp, type, sizeof(type));
	
	if (StrEqual(type, "streaminfo")) {
		int pos = StrContains(g_sDataReceived, "INFO");
		
		if (pos > 0) {
			char streaminfo[5120];
			
			strcopy(streaminfo, sizeof(streaminfo), g_sDataReceived[pos - 1]);
			
			char file[512];
			BuildPath(Path_SM, file, 512, "configs/fragradio_stream_info.txt");
			
			Handle hFile = OpenFile(file, "wb");
			WriteFileString(hFile, streaminfo, false);
			CloseHandle(hFile);
			
			Handle Info = CreateKeyValues("INFO");
			FileToKeyValues(Info, file);
			
			DeleteFile(file);
			
			if (KvJumpToKey(Info, "FragRadio")) {
				char dj[512];
				char song[512];
				KvGetString(Info, "DJ", dj, sizeof(dj), "Unknown");
				KvGetString(Info, "SONG", song, sizeof(song), "Unknown");
				
				if (!StrEqual(dj, g_sDJ)) {
					g_sDJ = dj;
					CPrintToChatAll("%t", "NowPresenting", g_sDJ);
				}
				
				if (!StrEqual(song, g_sSong)) {
					g_sSong = song;
					CPrintToChatAll("%t", "NowPlaying", g_sSong);
				}
			}
			
			CloseHandle(Info);
		}
	}
	
	CloseHandle(dp);
	CloseHandle(socket);
}

public OnSocketError(Handle socket, const errorType, const errorNum, any:dp) {
	LogError("[FragRadio] Socket error %d (errno %d)", errorType, errorNum);
	
	CloseHandle(dp);
	CloseHandle(socket);
} 

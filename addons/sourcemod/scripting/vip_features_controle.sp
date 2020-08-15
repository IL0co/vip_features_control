
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>

public Plugin myinfo =
{
	name		= "[VIP] Features Controle",
	author	  	= "ღ λŌK0ЌЭŦ ღ ™",
	description = "",
	version	 	= "1.0.1",
	url			= "iLoco#7631"
};

char gPath[256];
KeyValues kv;
int iLastSelectClient[MAXPLAYERS+1], iLastSelection[MAXPLAYERS+1];
ArrayList arFeatures;

public void OnPluginStart()
{
	BuildPath(Path_SM, gPath, sizeof(gPath), "data/vip/modules/features_controle.ini");
	LoadCfg();
	RegAdminCmd("sm_vip_features_controle", CMD_Menu, ADMFLAG_RCON);

	LoadTranslations("vip_modules.phrases");

	if(VIP_IsVIPLoaded())
	{
		if(arFeatures)
			delete arFeatures;
		arFeatures = new ArrayList(64);

		VIP_FillArrayByFeatures(arFeatures);
	}
}

public Action CMD_Menu(int client, int args)
{
	if(client && arFeatures)
		Menu_SelectClient(client).Display(client, 0);
		
	return Plugin_Continue;
}

public void VIP_OnFeatureRegistered(const char[] szFeature)
{
	if(arFeatures)
		delete arFeatures;
	arFeatures = new ArrayList(64);

	VIP_FillArrayByFeatures(arFeatures);
}

public Menu Menu_SelectClient(int client)
{
	Menu menu = new Menu(MenuHendler_SelectClient);
	
	char translate[128], buff[4];
	Format(translate, sizeof(translate), "Выберите игрока");
	menu.SetTitle(translate);

	for(int i = 1; i <= MaxClients; i++)	if(IsClientAuthorized(i) && IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i))
	{
		Format(translate, sizeof(translate), "%N", i);
		Format(buff, sizeof(buff), "%i", GetClientUserId(i));
		menu.AddItem(buff, translate);
	}

	if(!menu.ItemCount)
	{
		Format(translate, sizeof(translate), "Вип игроков нету в данный момент!");
		menu.AddItem("", translate, ITEMDRAW_DISABLED);
	}

	return menu;
}

public int MenuHendler_SelectClient(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char buff[4];
		menu.GetItem(item, buff, sizeof(buff));

		iLastSelectClient[client] = StringToInt(buff);
		iLastSelection[client] = menu.Selection;	

		Menu_Features(client).Display(client, 0);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Menu Menu_Features(int client)
{
	Menu menu = new Menu(MenuHendler_Features);
	menu.ExitBackButton = true;

	int len = arFeatures.Length;
	int target = GetClientOfUserId(iLastSelectClient[client]);
	char translate[128];
	
	if(!len)
	{
		Format(translate, sizeof(translate), "Нету вип функций!");
		menu.AddItem("", translate, ITEMDRAW_DISABLED);
	}
	else
	{
		Format(translate, sizeof(translate), "[%s] Удалять данные об игроку после окончания випки?\n ", GetDeleteDataOnVipLeft(target) ? "-" : "+");
		menu.AddItem("d", translate);

		char feature[128];
		for(int p; p < len; p++)
		{
			arFeatures.GetString(p, feature, sizeof(feature));

			if(!VIP_IsValidFeature(feature) || VIP_GetFeatureType(feature) == SELECTABLE)
			{
				continue;
			}

			if(!VIP_GetClientFeatureInt(client, feature))
			{
				continue;
			}

			if(TranslationPhraseExists(feature))
				Format(translate, sizeof(translate), "%T", feature, client);
			else
				Format(translate, sizeof(translate), "%s", feature);

			Format(translate, sizeof(translate), "[%s] %s", (VIP_GetClientFeatureStatus(target, feature) != NO_ACCESS) ? "+" : "-", translate);
			menu.AddItem(feature, translate);
		}
	}
	
	return menu;
}

public int MenuHendler_Features(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
	{
		Menu_SelectClient(client).DisplayAt(client, iLastSelection[client], 0);
	}
	else if(action == MenuAction_Select)
	{
		int target = GetClientOfUserId(iLastSelectClient[client]);
		char feature[128];
		menu.GetItem(item, feature, sizeof(feature));

		char buff[64];
		JumpToClient(target, true);

		if(feature[0] == 'd')
		{
			kv.SetNum("delete on left", !kv.GetNum("delete on left", 1));
		}
		else
		{
			bool toggle = (VIP_GetClientFeatureStatus(target, feature) != NO_ACCESS);

			VIP_SetClientFeatureStatus(target, feature, toggle ? NO_ACCESS : ENABLED);
			
			Format(buff, sizeof(buff), "%N", target)
			kv.SetString("client name", buff);

			kv.SetNum(feature, !toggle);
		}

		Menu_Features(client).DisplayAt(client, menu.Selection, 0);

		kv.Rewind();
		kv.ExportToFile(gPath);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public void VIP_OnVIPClientRemoved(int client, const char[] szReason, int iAdmin)
{
	if(JumpToClient(client) && kv.GetNum("delete on left"))
		kv.DeleteThis();
}

public void VIP_OnVIPClientLoaded(int client)
{
	if(JumpToClient(client) && kv.GotoFirstSubKey(false))
	{
		char feature[64];
		do
		{
			kv.GetSectionName(feature, sizeof(feature))

			if(!VIP_IsValidFeature(feature) || kv.GetNum(NULL_STRING))
				continue;
			
			VIP_SetClientFeatureStatus(client, feature, NO_ACCESS);
		}
		while(kv.GotoNextKey(false));
	}
}

public void VIP_OnVIPClientAdded(int client, int iAdmin)
{
	VIP_OnVIPClientLoaded(client);
}

stock void LoadCfg()
{
	if(kv)
		delete kv;
	
	kv = new KeyValues("Features Controle");
	kv.ImportFromFile(gPath);
}

stock bool GetDeleteDataOnVipLeft(int target)
{
	if(JumpToClient(target) && kv.GetNum("delete on left", 1))
		return false;

	return true;
}

stock bool JumpToClient(int client, bool create = false)
{
	kv.Rewind();
	char buff[64];
	GetClientAuthId(client, AuthId_Steam2, buff, sizeof(buff));
	if(kv.JumpToKey(buff, create))
		return true;

	return false
}
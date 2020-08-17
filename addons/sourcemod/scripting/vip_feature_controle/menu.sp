#include <sourcemod>

KeyValues iKv[MAXPLAYERS+1];

public Menu Menu_Main(int client)
{
	if(iKv[client])
		delete iKv[client];
	iKv[client] = new KeyValues("config");

	Menu menu = new Menu(MenuHendler_Main);
	menu.ExitBackButton = true;
	
	char translate[128];
	Format(translate, sizeof(translate), "Настройки функций\n ");
	menu.SetTitle(translate);

	Format(translate, sizeof(translate), "Вкл/Выкл игроку функцию");
	menu.AddItem("0", translate);	// player_toggle

	// Format(translate, sizeof(translate), "Сменить значение функции игроку");
	// menu.AddItem("1", translate);	// player_edit

	return menu;
}

public int MenuHendler_Main(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char buff[4];
		menu.GetItem(item, buff, sizeof(buff));

		Menu_SelectClients(client).Display(client, 0);
	}
	else if(item == MenuCancel_Interrupted && item == MenuCancel_ExitBack && gTopMenu)
		gTopMenu.Display(client, TopMenuPosition_LastCategory);
	else if(action == MenuAction_End)
		delete menu;
}

public Menu Menu_SelectClients(int client)
{
	Menu menu = new Menu(MenuHendler_SelectClients);
	menu.ExitBackButton = true;

	char translate[64], userid[4], vip_group[64];
	int clients[MAXPLAYERS+1];
	int count;

	for(int i = 1; i <= MaxClients; i++)	if(IsValidClient(i))
		clients[count++] = i;

	Format(translate, sizeof(translate), "Выбор игроков\n ");
	menu.SetTitle(translate);

	if(count)
	{
		iKv[client].Rewind();

		Format(translate, sizeof(translate), "Продолжить\n ");
		menu.AddItem("c", translate, iKv[client].GetNum("targets count") ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		iKv[client].JumpToKey("targets", true);

		for(int i; i < count; i++)	
		{
			VIP_GetClientVIPGroup(clients[i], vip_group, sizeof(vip_group));
			Format(userid, sizeof(userid), "%i", GetClientUserId(clients[i]));
			Format(translate, sizeof(translate), "[%s][%s] %N", iKv[client].GetNum(userid, 0) ? "+" : "-", vip_group, clients[i]);
			menu.AddItem(userid, translate);
		}
	}
	else
	{
		Format(translate, sizeof(translate), "Вип игроков в данный момент нету!");
		menu.AddItem("", translate, ITEMDRAW_DISABLED);
	}

	return menu;
}

public int MenuHendler_SelectClients(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char userid[4];
		menu.GetItem(item, userid, sizeof(userid));

		if(userid[0] == 'c')
		{
			Menu_MultiTargets_ToggleFeatures(client).Display(client, 0);
		}
		else
		{
			bool state = !iKv[client].GetNum(userid);
			iKv[client].SetNum(userid, state);

			iKv[client].Rewind();
			iKv[client].SetNum("targets count", iKv[client].GetNum("targets count") + (state ? 1 : -1));
			if(state)
				iKv[client].SetString("last target", userid);

			Menu_SelectClients(client).DisplayAt(client, menu.Selection, 0);
		}
	}
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Menu_Main(client).Display(client, 0);
	else if(action == MenuAction_End)
		delete menu;
}

public Menu Menu_MultiTargets_ToggleFeatures(int client)
{
	Menu menu = new Menu(MenuHendler_MultiTargets_ToggleFeatures);
	menu.ExitBackButton = true;

	char translate[128], feature[64], userid[4], buff[70];
	int count = arFeatures.Length, target;

	Format(translate, sizeof(translate), "Вкл/Выкл функцию\n ");
	menu.SetTitle(translate);

	
	iKv[client].Rewind();
	bool isMultiTargets = (iKv[client].GetNum("targets count") > 1), once;

	if(count)
	{
		if(isMultiTargets)
		{
			Format(translate, sizeof(translate), "Настроить удаление этих данных\n ");
			menu.AddItem("c", translate);
		}

		for(int p; p < count; p++)	
		{
			arFeatures.GetString(p, feature, sizeof(feature));

			if(VIP_GetFeatureType(feature) == SELECTABLE)

			if(TranslationPhraseExists(feature))
				Format(translate, sizeof(translate), "%T", feature, client);
			else
				Format(translate, sizeof(translate), "%s", feature);

			iKv[client].Rewind();
			if(iKv[client].JumpToKey("targets") && iKv[client].GotoFirstSubKey(false))
			{
				do
				{
					if(!iKv[client].GetNum(NULL_STRING))
						continue;
						
					iKv[client].GetSectionName(userid, sizeof(userid));
					target = GetClientOfUserId(StringToInt(userid));

					if(!IsValidClient(target))
					{
						if(!isMultiTargets)
						{
							PrintToChat(target, "Данный игрок невалидный!");
							delete menu;
							return Menu_SelectClients(client);
						}

						continue;
					}

					if(TranslationPhraseExists(feature))
						Format(translate, sizeof(translate), "%T", feature, client);
					else
						Format(translate, sizeof(translate), "%s", feature);
					
					if(!isMultiTargets)
					{
						if(!once)
						{
							Format(buff, sizeof(buff), "[%s] Удаление этих данных\n ", GetDeleteDataOnVipLeft(target) ? "-" : "+");
							menu.AddItem("d", buff);
							once = true;
						}

						Format(translate, sizeof(translate), "[%s] %s", (VIP_GetClientFeatureStatus(target, feature) == NO_ACCESS) ? "-" : "+", translate);
					}
					else
					{
						Format(translate, sizeof(translate), "[%s][%N] %s", (VIP_GetClientFeatureStatus(target, feature) == NO_ACCESS) ? "-" : "+", target, translate);
					}

					Format(buff, sizeof(buff), "%s %s", feature, userid);
					menu.AddItem(buff, translate);
				}
				while(iKv[client].GotoNextKey(false));
			}
		}
	}
	else
	{
		Format(translate, sizeof(translate), "Список функций не найден!");
		menu.AddItem("", translate, ITEMDRAW_DISABLED);
	}

	return menu;
}

public int MenuHendler_MultiTargets_ToggleFeatures(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char buff[70];
		menu.GetItem(item, buff, sizeof(buff));

		if(buff[0] == 'c')
		{
			Menu_MultiTargets_ToggleDelete(client).Display(client, 0);
		}
		else if(buff[0] == 'd')
		{
			iKv[client].Rewind();

			if(JumpToClient(GetClientOfUserId(iKv[client].GetNum("last target"))))
				kv.SetNum("delete on left", !kv.GetNum("delete on left", 1));

			Menu_MultiTargets_ToggleFeatures(client).DisplayAt(client, menu.Selection, 0);
		}
		else
		{
			char exp[2][64];
			ExplodeString(buff, " ", exp, sizeof(exp), sizeof(exp[]));

			int target = GetClientOfUserId(StringToInt(exp[1]));

			if(JumpToClient(target, true))
			{
				kv.SetNum(exp[0], !kv.GetNum(exp[0]));
				
				if(VIP_GetClientFeatureStatus(target, exp[0]) == NO_ACCESS)
				{
					VIP_ToggleState state;
					iDefFeaturesToggles[target].GetValue(exp[0], state);
					VIP_SetClientFeatureStatus(target, exp[0], state);
				}
				else
					VIP_SetClientFeatureStatus(target, exp[0], NO_ACCESS);
			}
			
			Menu_MultiTargets_ToggleFeatures(client).DisplayAt(client, menu.Selection, 0);
		}

		SaveThisFile();
	}
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Menu_SelectClients(client).Display(client, 0);
	else if(action == MenuAction_End)
		delete menu;
}

public Menu Menu_MultiTargets_ToggleDelete(int client)
{
	Menu menu = new Menu(MenuHendler_MultiTargets_ToggleDelete);
	menu.ExitBackButton = true;

	char translate[128], userid[4];
	int target;

	Format(translate, sizeof(translate), "Удаление этих данных\n ");
	menu.SetTitle(translate);

	iKv[client].Rewind();
	if(iKv[client].JumpToKey("targets") && iKv[client].GotoFirstSubKey(false))
	{
		do
		{
			iKv[client].GetSectionName(userid, sizeof(userid));
			target = GetClientOfUserId(StringToInt(userid));

			if(!IsValidClient(target))
				continue;

			Format(translate, sizeof(translate), "[%s] %N", (GetDeleteDataOnVipLeft(target)) ? "-" : "+", target);
			menu.AddItem(userid, translate);
		}
		while(iKv[client].GotoNextKey(false));
	}
	
	return menu;
}

public int MenuHendler_MultiTargets_ToggleDelete(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char userid[128];
		menu.GetItem(item, userid, sizeof(userid));
		
		if(JumpToClient(GetClientOfUserId(StringToInt(userid))))
			kv.SetNum("delete on left", !kv.GetNum("delete on left", 1));
			
		SaveThisFile();
	}
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Menu_MultiTargets_ToggleFeatures(client).Display(client, 0);
	else if(action == MenuAction_End)
		delete menu;
}

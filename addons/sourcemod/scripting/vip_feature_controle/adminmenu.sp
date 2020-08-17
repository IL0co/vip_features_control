public void OnLibraryAdded(const char[] szLibraryName)
{
	if(strcmp(szLibraryName, "adminmenu") == 0)
	{
		TopMenu hTopMenu = GetAdminTopMenu();
		if(hTopMenu != null)
		{
			OnAdminMenuReady(hTopMenu);
		}
	}
}

public void OnLibraryRemoved(const char[] szLibraryName)
{
	if(strcmp(szLibraryName, "adminmenu") == 0)
	{
		gTopMenu = null;
	}
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	CreateTimer(1.0, Timer_Delay, aTopMenu);
}

public Action Timer_Delay(Handle timer, Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if(topmenu == gTopMenu)
		return;
	
	gTopMenu = topmenu;

	TopMenuObject category;

	if((category = gTopMenu.FindCategory("vip_admin")) != INVALID_TOPMENUOBJECT)
	{
		gTopMenu.AddItem("feature_contole", AdminMenu_Item_Main, category, "feature_contole", ADMFLAG_ROOT);
	}
}

public void AdminMenu_Item_Main(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int len)
{
	if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, len, "Настройки финкций")
	}
	else if(action == TopMenuAction_SelectOption)
	{
		Menu_Main(client).Display(client, 0);
	}
}

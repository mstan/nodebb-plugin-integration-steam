# nodebb-plugin-integration-steam (Workaround for admin approval)

This is a small hack of the steam-integration method provided for NodeBB. 

NodeBB does not take into account of user authentication for user accounts not made through standard registration. It is not currently possible to redirect an OAuth account into this system. Thus, a hack work-around has been made that automaticlaly bans any new profiles. The user's information stays intact and is immediately approved but immediately revokes all user sessions.

It is recommended that the language file for the forum changes the string for "banned" to "Pending approval" as to not confuse newly registered users.
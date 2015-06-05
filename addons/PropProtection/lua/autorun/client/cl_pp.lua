net.Receive("sendppsettings", function(_, pl)
	local fCheckForProps = net.ReadFloat();
	local iTicksOfLag = net.ReadInt(32);
	local fLengthOfLagMin = net.ReadFloat();
	local fLengthOfLagMax = net.ReadFloat();
	local bPunishUsers = net.ReadBool() or false;
	local iPunishAction = net.ReadInt(32);
	local iUserChances = net.ReadInt(32);
	local bResetOnDisconnect = net.ReadBool() or false;
	local fUserWarningsCoolDown = net.ReadFloat();
	local bRemovePropsIfPunished = net.ReadBool() or false;
	local bMessageAdminsOnly = net.ReadBool() or false;
	local bStrict = net.ReadBool() or false;
	local iStrictMax = net.ReadInt(32);
	local iStrict2Max = net.ReadInt(32);
	local bLogToFile = net.ReadBool() or false;
	local bDebug = net.ReadBool() or false;
	local arrBlackList = net.ReadTable();
	
	print("SETTINGS:\n");
	print("---------------------------------------------------\n");
	print("Check For Props: " .. fCheckForProps .. "\n");
	print("Ticks Of Lag: " .. iTicksOfLag .. "\n");
	print("Length Of Lag (Min): " .. fLengthOfLagMin .. "\n");
	print("Length Of Lag (Max): " .. fLengthOfLagMax .. "\n");
	print("Punish Users: " .. tostring(bPunishUsers) .. "\n");
	print("Punish Action: " .. iPunishAction .. "\n");
	print("User Chances: " .. iUserChances .. "\n");
	print("Reset On Disconnect: " .. tostring(bResetOnDisconnect) .. "\n");
	print("User Warnings Cool down: " .. fUserWarningsCoolDown .. "\n");
	print("Remove Props If Punished: " .. tostring(bRemovePropsIfPunished) .. "\n");
	print("Message Admins Only: " .. tostring(bMessageAdminsOnly) .. "\n");
	print("Strict: " .. tostring(bStrict) .. "\n");
	print("Strict Max: " .. iStrictMax .. "\n");
	print("Strict2 Max: " .. iStrict2Max .. "\n");
	print("Log To File: " .. tostring(bLogToFile) .. "\n");
	print("Debug: " .. tostring(bDebug) .. "\n");
	print("Black List: \n");
	for _,v in pairs (arrBlackList) do
		print("- " .. v .. "\n");
	end
	print("---------------------------------------------------");
end)

net.Receive("sendppvariables", function(_,pl)
	local arrEntityPool = net.ReadTable();
	local iLastThink = net.ReadInt(32);
	local arrSlowCount = net.ReadTable();
	local bLagging = net.ReadBool();
	local arrGoodToGo = net.ReadTable();
	local arrNotBL = net.ReadTable();
	local arrUserID = net.ReadTable();
	local arrPropCoolDown = net.ReadTable();
	local iStrictAmount = net.ReadInt(32);
	local iStrict2Amount = net.ReadInt(32);
	local fLengthOfLagMin = net.ReadFloat();
	local fLengthOfLagMax = net.ReadFloat();
	
	print("VARIABLES:\n");
	print("---------------------------------------------------");
	print("Entity Pool:\n");
	for _,v in pairs (arrEntityPool) do
		print("- " .. v .. "\n");
	end
	print("Last Think: " .. iLastThink .. "\n");
	print("Slow Count:\n");
	for _,v in pairs (arrSlowCount) do
		print("- " .. v .. "\n");
	end
	print("Lagging: " .. tostring(bLagging) .. "\n");
	print("Good To Go:\n");
	for k,v in pairs (arrGoodToGo) do
		print("- " .. k .. ":" .. tostring(v) .. "\n");
	end
	print("Not BlackListed:\n");
	for k,v in pairs (arrNotBL) do
		print("- " .. tostring(v) .. "\n");
	end
	print("User IDs:\n");
	for _,v in pairs (arrUserID) do
		print("- " .. v .. "\n");
	end
	print("Prop Cool Down:\n");
	for k,v in pairs (arrPropCoolDown) do
		print("- " .. k .. ":" .. tostring(v) .. "\n");
	end
	print("Strict Amount: " .. iStrictAmount .. "\n");
	print("Strict2 Amount: " .. iStrict2Amount .. "\n");
	print("Length Of Lag (Min): " .. fLengthOfLagMin .. "\n");
	print("Length Of Lag (Max): " .. fLengthOfLagMax .. "\n");
	print("---------------------------------------------------");
end)
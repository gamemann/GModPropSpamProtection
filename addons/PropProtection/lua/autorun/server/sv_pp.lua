-- Networking
util.AddNetworkString("sendppsettings");
util.AddNetworkString("sendppvariables");

-- Global Variables (Do Not Change)
local arrEntityPool = {};
local iLastThink = SysTime();
local arrSlowCount = {};
local bLagging = false;
local arrGoodToGo = {};
local arrNotBL = {};
local arrUserID = {}
local arrPropCoolDown = {}
local iStrictAmount = 0;
local iStrict2Amount = 0;
local fLengthOfLagMin;
local fLengthOfLagMax;

-- ConVars/Settings
local pp1 = CreateConVar("sv_pp_checkforprops", "1.0", _, "How often we check for props. The lower this value is, the higher chance of the lua script catching prop spammers. However, CPU usage will be increased.");
local pp2 = CreateConVar("sv_pp_ticksoflag", "2", _, "The ticks in-between lag spikes.");
local pp3 = CreateConVar("sv_pp_lengthoflag_min", "0.45", _, "The minimum length of lag.");
local pp4 = CreateConVar("sv_pp_lengthoflag_max", "0.05", _, "The maximum length of lag.");
local pp5 = CreateConVar("sv_pp_punishusers", "1", _, "Punish users if they are caught with penetrating/spamming props?");
local pp6 = CreateConVar("sv_pp_punishaction", "1", _, "0 = Disable, 1 = Ban User, 2 = Kick User.");
local pp7 = CreateConVar("sv_pp_userchances", "5", _, "The amount of chances the user receives until they are punished.");
local pp8 = CreateConVar("sv_pp_resetondisconnect", "0", _, "Reset the user's warnings on disconnect?");
local pp9 = CreateConVar("sv_pp_userwarningscooldown", "360.0", _, "Every x seconds one warning will be taken away.");
local pp10 = CreateConVar("sv_pp_removepropsifpunished", "1", _, "Remove all props of a punished victim?");
local pp11 = CreateConVar("sv_pp_messageadminsonly", "0", _, "Display notifications to the admins only?");
local pp12 = CreateConVar("sv_pp_strict", "1", _, "Enable strict mode.");
local pp13 = CreateConVar("sv_pp_strict_max", "2", _, "The maximum amount of stricts for strict #1.");
local pp14 = CreateConVar("sv_pp_strict2_max", "2", _, "The maximum amount of stricts for strict #2.");
local pp15 = CreateConVar("sv_pp_logtofile", "1", _, "Log all users who get caught to a file?");
local pp16 = CreateConVar("sv_pp_debug", "0", _, "Debug the lua script?");

local settings = {};
settings.fCheckForProps = pp1:GetFloat();	-- The lower this value is, the less chances of prop spammers successfully lagging your server but also may cause overall higher CPU usage
settings.iTicksOfLag = pp2:GetInt();
settings.fLengthOfLagMin = pp3:GetFloat();
settings.fLengthOfLagMax = pp4:GetFloat();
settings.bPunishUsers = pp5:GetBool();
settings.iPunishAction = pp6:GetInt();
settings.iUserChances = pp7:GetInt();
settings.bResetOnDisconnect = pp8:GetBool();
settings.fUserWarningsCoolDown = pp9:GetFloat();
settings.bRemovePropsIfPunished = pp10:GetBool();
settings.bMessageAdminsOnly = pp11:GetBool();
settings.bStrict = pp12:GetBool();
settings.iStrictMax = pp13:GetInt();
settings.iStrict2Max = pp14:GetInt();
settings.bLogToFile = pp15:GetBool();
settings.bDebug = pp16:GetBool();

cvars.AddChangeCallback("sv_pp_checkforprops", function(sCVarName, sOldv, sNewv)
	settings.fCheckForProps = pp1:GetFloat();
end);

cvars.AddChangeCallback("sv_pp_ticksoflag", function(sCVarName, sOldv, sNewv)
	settings.iTicksOfLag = pp2:GetInt();
end);

cvars.AddChangeCallback("sv_pp_lengthoflag_min", function(sCVarName, sOldv, sNewv)
	settings.fLengthOfLagMin = pp3:GetFloat();
	fLengthOfLagMin = pp1:GetInt() - pp3:GetFloat();
end);

cvars.AddChangeCallback("sv_pp_lengthoflag_max", function(sCVarName, sOldv, sNewv)
	settings.fLengthOfLagMax = pp4:GetFloat();
	fLengthOfLagMax = pp1:GetInt() + pp4:GetFloat();
end);

cvars.AddChangeCallback("sv_pp_punishusers", function(sCVarName, sOldv, sNewv)
	settings.bPunishUsers = pp5:GetBool();
end);

cvars.AddChangeCallback("sv_pp_punishaction", function(sCVarName, sOldv, sNewv)
	settings.iPunishAction = pp6:GetInt();
end);

cvars.AddChangeCallback("sv_pp_userchances", function(sCVarName, sOldv, sNewv)
	settings.iUserChances = pp7:GetInt();
end);

cvars.AddChangeCallback("sv_pp_resetondisconnect", function(sCVarName, sOldv, sNewv)
	settings.bResetOnDisconnect = pp8:GetBool();
end);

cvars.AddChangeCallback("sv_pp_userwarningscooldown", function(sCVarName, sOldv, sNewv)
	settings.fUserWarningsCoolDown = pp9:GetFloat();
end);

cvars.AddChangeCallback("sv_pp_removepropsifpunished", function(sCVarName, sOldv, sNewv)
	settings.bRemovePropsIfPunished = pp10:GetBool();
end);

cvars.AddChangeCallback("sv_pp_messageadminsonly", function(sCVarName, sOldv, sNewv)
	settings.bMessageAdminsOnly = pp11:GetBool();
end);

cvars.AddChangeCallback("sv_pp_strict", function(sCVarName, sOldv, sNewv)
	settings.bStrict = pp12:GetBool();
end);

cvars.AddChangeCallback("sv_pp_strict_max", function(sCVarName, sOldv, sNewv)
	settings.iStrictMax = pp13:GetInt();
end);

cvars.AddChangeCallback("sv_pp_strict2_max", function(sCVarName, sOldv, sNewv)
	settings.iStrict2Max = pp14:GetInt();
end);

cvars.AddChangeCallback("sv_pp_logtofile", function(sCVarName, sOldv, sNewv)
	settings.bLogToFile = pp15:GetBool();
end);

cvars.AddChangeCallback("sv_pp_debug", function(sCVarName, sOldv, sNewv)
	settings.bDebug = pp16:GetBool();
end);

-- Non-ConVar Settings (Feel free to edit)
settings.arrBlackList = 
{
	"func_door", 
	"func_door_rotating", 
	"prop_door_rotating", 
	"spawn_protect", 
	"gmt_instrument_piano", 
	"rm_car_dealer", 
	"realistic_atm", 
	"rx_slotmachine"
};

-- Other Global Variables (need to be set using settings._)
fLengthOfLagMin = settings.fCheckForProps - settings.fLengthOfLagMin;
fLengthOfLagMax = settings.fCheckForProps + settings.fLengthOfLagMax;

hook.Add( "PlayerSpawnedProp", "antipen", function( ply, _, iEnt )
	timer.Create( "antipen" .. iEnt:EntIndex(), 0.1, 10, function()
		if not IsValid( iEnt ) then return end
		if iEnt:GetPhysicsObject():IsPenetrating() then
			iEnt:Remove();
		end
	end )
end )

timer.Create("getridofbadprops", settings.fCheckForProps, 0, function ()
	if settings.bDebug then
		print ("Think and Length (" .. SysTime()-iLastThink .. ") (Max: " .. settings.fLengthOfLagMax .. " Min: " .. settings.fLengthOfLagMin .. ")!");
	end
	
	local iAmount = table.Count(arrEntityPool);
	if settings.bDebug then
		--[[
		print ("\n\nEntity Pool:");
		print ("--------------------");
		PrintTable(arrEntityPool);
		print("Amount: " .. iAmount .. "");
		print ("--------------------");
		]]--
	end
	
	for _,e in pairs(arrEntityPool) do
		if not IsValid(Entity(e)) then
			arrSlowCount[e] = nil;
			table.RemoveByValue(arrEntityPool, e);
		end
	end
	
	if SysTime()-iLastThink > fLengthOfLagMax or SysTime()-iLastThink < fLengthOfLagMin then
		for _,v in pairs(ents.GetAll()) do
			if IsValid(v) then
				if not v:IsWorld() and not v:IsPlayer() then
					local iPhys = v:GetPhysicsObject();
					if (iPhys:IsValid()) then
						if v:GetPhysicsObject():IsPenetrating() then
							if SysTime()-iLastThink > fLengthOfLagMax or SysTime()-iLastThink < fLengthOfLagMin then
								bLagging = true;
								arrNotBL[v] = true;
								for _,b in pairs(settings.arrBlackList) do
									if v:GetClass() == b then
										arrNotBL[v] = false;
										if settings.bDebug then
											print("Entity Black Listed!(" .. v:GetClass() .. ")");
										end
									end
								end
								
								if arrNotBL[v] then
									if settings.bDebug then
										print ("CLASS: " .. v:GetClass());
									end
									
									arrGoodToGo[v:EntIndex()] = true
									for k2,v2 in pairs(arrEntityPool) do
										if (v2 == v:EntIndex()) then
											arrGoodToGo[v:EntIndex()] = false;
										end
									end
									
									if arrGoodToGo[v:EntIndex()] then
										table.insert(arrEntityPool, v:EntIndex());
									end
									table.remove(arrGoodToGo, v:EntIndex());
									
									local iHighest = 0;
									for _,value in pairs(arrEntityPool) do
										if (value > iHighest) then
											iHighest = value;
										end
									end
									
									if settings.bDebug then
										print ("\n Highest Entity: " .. iHighest);
									end
									
									local iEnt = Entity(iHighest);
									if IsValid(iEnt) then
										if (arrSlowCount[iEnt:EntIndex()] == nil) then
											arrSlowCount[iEnt:EntIndex()] = 0;
										end
										
										arrSlowCount[iEnt:EntIndex()] = arrSlowCount[iEnt:EntIndex()] + 1;
										
										if arrSlowCount[iEnt:EntIndex()] >= settings.iTicksOfLag then
											if settings.bDebug then
												print ("Server is currently considered lagging.");
											end
											
											arrSlowCount[iEnt:EntIndex()] = nil;
											bLagging = false;
											local iUser = iEnt:CPPIGetOwner();
											local sNick = 0;
											local sSteamID = 0;
											
											if (IsValid(iUser)) then
												sNick = iUser:Nick();
												sSteamID = iUser:SteamID();
											end
											iEnt:Remove();
											
											for _, playa in pairs(player.GetAll()) do
												if (IsValid(playa)) then
													if settings.bMessageAdminsOnly then
														if playa:IsAdmin() then
															if (IsValid(iUser)) then
																playa:ChatPrint("[PP]Removed bad prop #" .. iEnt:EntIndex() .. ". Owner: " .. sNick .. " (" .. sSteamID .. ")");
															else
																playa:ChatPrint("[PP]Removed bad prop #" .. iEnt:EntIndex() .. ".");
															end
														end
													else
														if (IsValid(iUser)) then
															playa:ChatPrint("[PP]Removed bad prop #" .. iEnt:EntIndex() .. ". Owner: " .. sNick .. " (" .. sSteamID .. ")");
														else
															playa:ChatPrint("[PP]Removed bad prop #" .. iEnt:EntIndex() .. ".");
														end
													end
												end
											end
											
											if settings.bLogToFile then
												file.Append("propspammers.txt", "[PP]Removed bad prop #" .. iEnt:EntIndex() .. ". Owner: " .. sNick .. " (" .. sSteamID .. ") \n");
											end
											
											if settings.bPunishUsers and IsValid(iUser) then
												if (arrUserID[sSteamID] == nil) then
													arrUserID[sSteamID] = 0;
												end
												
												if settings.iPunishAction != 0 then
													if (arrPropCoolDown[sSteamID] == nil) then
														arrPropCoolDown[sSteamID] = false;
													end
													
													if arrPropCoolDown[sSteamID] == false then
														arrUserID[sSteamID] = arrUserID[sSteamID] + 1;
													end
													
													if (arrUserID[sSteamID] >= settings.iUserChances) then
														if (IsValid(iUser)) then
															if settings.iPunishAction == 1 then
																if arrPropCoolDown[sSteamID] == false then
																	if settings.bLogToFile then
																		file.Append("propspammers.txt", "[PSP_BAN]" .. sNick .. "(" .. sSteamID .. ") just got banned for prop spamming! \n");
																	end
																	
																	if settings.bRemovePropsIfPunished then
																		for k,v in pairs(ents.GetAll()) do
																			local person = v:CPPIGetOwner();
																			if (IsValid(person)) then
																				if settings.bDebug then
																					print (iUser:EntIndex() .. "/" .. person:EntIndex());
																				end
																				
																				if (iUser:EntIndex() == person:EntIndex()) then
																					v:Remove();
																					if settings.bDebug then
																						print(sNick .. " (" .. sSteamID .. ") received a ban. Removed their prop: #" .. v:EntIndex() .. " (" .. v:GetModel() .. ")!");
																					end
																				end
																			end
																		end
																	end
																	
																	arrUserID[sSteamID] = nil;
																	RunConsoleCommand("ulx", "banid", sSteamID, "1440.0", "Attempting to lag server. Caught with Roy's Prop Protection.");
																end
															elseif settings.iPunishAction == 2 then
																if arrPropCoolDown[sSteamID] == false then
																	if settings.bLogToFile then
																		file.Append("propspammers.txt", "[PSP_KICK]" .. nick .. "(" .. sSteamID .. ") just got banned for prop spamming! \n")
																	end
																	
																	arrUserID[sSteamID] = nil;
																	RunConsoleCommand("ulx", "kick", nick, "Attempting to lag server (Caught by prop spammer addon)");
																end
															end
														end
													else
														if arrPropCoolDown[sSteamID] == false then
															iUser:ChatPrint("Please stop prop spamming. Warning: " .. arrUserID[sSteamID] .. "/" .. settings.iUserChances .. ".");
														end
													end
													if (arrPropCoolDown[sSteamID] != nil) then
														arrPropCoolDown[sSteamID] = true;
													
														timer.Simple(2.0 + settings.iTicksOfLag, function()
															if (arrPropCoolDown[sSteamID] != nil) then
																arrPropCoolDown[sSteamID] = false;
															end
														end )
													end
												end
											end
											
											arrEntityPool[iEnt:EntIndex()] = nil;
											print("[PP]Removed Bad Prop! Entity: " .. iEnt:EntIndex());
										end
									else
										arrEntityPool[highest] = nil;
									end
								end
							else
								table.RemoveByValue(arrEntityPool, v:EntIndex());
								arrSlowCount[v:EntIndex()] = nil;
							end
						end
					end
				end
			end
		end
	else
		bLagging = false;
		for _,e in pairs(arrEntityPool) do
			arrSlowCount[e] = nil;
			table.RemoveByValue(arrEntityPool, e);
		end
	end
	iLastThink = SysTime();
end )

if settings.bPunishUsers then
	timer.Create("CheckUserChances", settings.fUserWarningsCoolDown, 0, function()
		if settings.bPunishUsers then
			for _,v in pairs(player.GetAll()) do
				local sSteamID = v:SteamID();
				if (arrUserID[sSteamID] != nil and arrUserID[sSteamID] != 0) then
					arrUserID[sSteamID] = arrUserID[sSteamID] - 1;
				end
			end
		end
	end )
end

hook.Add("PlayerDisconnected", "Resetwarnings", function (ply)
	if settings.bPunishUsers then
		local sSteamID = ply:SteamID();
		if settings.bResetOnDisconnect then
			if (arrUserID[sSteamID] != nil) then
				arrUserID[sSteamID] = nil;
				if settings.bDebug then
					print("Reset User: " .. sSteamID .. " warnings.");
				end
			end
		end
		
		if (arrPropCoolDown[sSteamID] != nil) then
			arrPropCoolDown[sSteamID] = nil;
			if settings.bDebug then
				print("Reset User: " .. sSteamID .. " cool downs.");
			end
		end

	end

end )

if settings.bStrict then
	timer.Create("antipenstrict", 15, 0, function()
		if SysTime()-iLastThink > fLengthOfLagMax or SysTime()-iLastThink < fLengthOfLagMin then
			bLagging = true;
			if settings.bDebug then
				print("[PP]Got to strict mode level zero. (Count: " .. iStrictAmount .. ")\n");
			end
			
			iStrictAmount = iStrictAmount + 1;
			if (iStrictAmount >= settings.iStrictMax) then
				if settings.bDebug then
					print("[PP]Got to strict mode level one. (Severe Count: " .. iStrict2Amount .. ")");
				end
				
				iStrict2Amount = iStrict2Amount + 1;
				RunConsoleCommand("deletebadprops");
				if settings.bLogToFile then
					file.Append("propspammers.txt", "[PP]Strict mode level one reached. Deleted all bad props.");
				end
				
				if (iStrict2Amount >= settings.iStrict2Max) then
					if settings.bDebug then
						print("[PP]Got to strict mode level two.");
					end

					RunConsoleCommand("deleteprops");
					if settings.bLogToFile then
						file.Append("propspammers.txt", "[PP]Strict mode level two reached. Deleted all props.");
					end
					
					for k,v in pairs(player.GetAll()) do
						v:ChatPrint("[PP]Deleting all penetrating props didn't work! Removed all props to stop the lag!");
					end
				else
					for k,v in pairs(player.GetAll()) do
						v:ChatPrint("[PP]Server has been lagging for a while. Removing all penetrating props...");
					end
				end
				
			end
		else
			iStrictAmount = 0;
			iStrict2Amount = 0;
		end
	end )
	iLastThink = SysTime();
end

concommand.Add("checkprops", function (ply)
	local iPropCount = 0;
	for k,prop in pairs(ents.GetAll()) do
		if IsValid(prop) then
			if not prop:IsWorld() and not prop:IsPlayer() then
				iPropCount = iPropCount + 1;
				local iPhys = prop:GetPhysicsObject();
				if (iPhys:IsValid()) then
					if prop:GetPhysicsObject():IsPenetrating() then
						local iUser = prop:CPPIGetOwner();
						local sNick = 0;
						local SSteamID = 0;
						if (IsValid(iUser)) then
							sNick = iUser:Nick();
							SSteamID = iUser:SteamID();
						end
						
						if (IsValid(ply) and IsValid(iUser)) then
							ply:ChatPrint("Prop #" .. prop:EntIndex() .. " is penetrating. Owner: " .. sNick .. " (" .. SSteamID .. ")");
						else
							print("Prop #" .. prop:EntIndex() .. " is penetrating. Owner: " .. sNick .. " (" .. SSteamID .. ")");
						end
					end
				end
			end
		end
	end
	
	if (IsValid(ply)) then
		ply:ChatPrint("[PP]Scanned Prop Count: " .. iPropCount);
		if settings.bLogToFile then
			file.Append("propspamming_commands.txt", "[PP][CHECK]" .. ply:Nick() .. " (" .. ply:SteamID() .. ") has checked for props! \n");
		end
	end
end )

concommand.Add("deletebadprops", function (ply)
	if (IsValid(ply)) then
		if not ply:IsAdmin() then
			ply:ChatPrint("[PP]Only Super Admins can use this command.");
			return;
		end
	end
	
	for k,prop in pairs(ents.GetAll()) do
		if IsValid(prop) then
			if not prop:IsWorld() and not prop:IsPlayer() then
				local iPhys = prop:GetPhysicsObject();
				if (iPhys:IsValid()) then
					if prop:GetPhysicsObject() and prop:GetPhysicsObject():IsPenetrating() then
						arrNotBL[prop] = true;
						for _,b in pairs(settings.arrBlackList) do
							if prop:GetClass() == b then
								arrNotBL[prop] = false;
								if settings.bDebug then
									print("Entity Black Listed!(" .. prop:GetClass() .. ")");
								end
							end
						end
						
						if arrNotBL[prop] then
							local iUser = prop:CPPIGetOwner();
							local sNick = 0;
							local sSteamID = 0;
							if (IsValid(iUser)) then
								sNick = iUser:Nick();
								sSteamID = iUser:SteamID();
							end
							prop:Remove();
			
							if (IsValid(ply) and IsValid(iUser)) then
								ply:ChatPrint("[PP]Deleted Prop #" .. prop:EntIndex() .. ". Owner: " .. sNick .. " (" .. sSteamID .. ")");
							else
								print("[PP]Deleted all bad props!")
							end
						end
					end
				end
			end
		end
	end
	
	if (IsValid(ply)) then
		if settings.bLogToFile then
			file.Append("propspamming_commands.txt", "[PP][BADPROPS]" .. ply:Nick() .. " (" .. ply:SteamID() .. ") has deleted all bad props! \n");
		end
	end
end )

concommand.Add("deleteprops", function (ply)
	if (IsValid(ply)) then
		if not ply:IsSuperAdmin() then
			ply:ChatPrint("[PP]Only Super Admins can use this command.");
			return;
		end
	end
	
	for _,prop in pairs(ents.GetAll()) do
		if IsValid(prop) then
			local iPhys = prop:GetPhysicsObject();
			if (iPhys:IsValid()) then
				if not prop:IsWorld() and not prop:IsPlayer() then
					arrNotBL[prop] = true;
					for _,b in pairs(settings.arrBlackList) do
						if prop:GetClass() == b then
							arrNotBL[prop] = false;
							if settings.bDebug then
								print("Entity Black Listed!(" .. prop:GetClass() .. ")");
							end
						end
					end
					
					if arrNotBL[prop] then
						local iUser = prop:CPPIGetOwner();
						local sNick = 0;
						local sSteamID = 0;
						if (IsValid(iUser)) then
							sNick = iUser:Nick();
							sSteamID = iUser:SteamID();
						end
						
						if (sNick != 0 and sSteamID != 0) then
							prop:Remove();
							if (IsValid(ply) and IsValid(iUser)) then
								ply:ChatPrint("[PP]Deleted Prop #" .. prop:EntIndex() .. ". Owner: " .. sNick .. " (" .. sSteamID .. ")");
							else
								print("[PP]Deleted all props!");
							end
						end
					end
				end
			end
		end
	end
	
	if (IsValid(ply)) then
		if settings.bLogToFile then
			file.Append("propspamming_commands.txt", "[PP][DELETEALLPROPS]" .. ply:Nick() .. " (" .. ply:SteamID() .. ") has deleted all props! \n");
		end
	end
end )

concommand.Add("pp_settings", function (ply)
	net.Start("sendppsettings");
	net.WriteFloat(settings.fCheckForProps);
	net.WriteInt(settings.iTicksOfLag, 32);
	net.WriteFloat(settings.fLengthOfLagMin);
	net.WriteFloat(settings.fLengthOfLagMax);
	net.WriteBool(settings.bPunishUsers);
	net.WriteInt(settings.iPunishAction, 32);
	net.WriteInt(settings.iUserChances, 32);
	net.WriteBool(settings.bResetOnDisconnect);
	net.WriteFloat(settings.fUserWarningsCoolDown);
	net.WriteBool(settings.bRemovePropsIfPunished);
	net.WriteBool(settings.bMessageAdminsOnly);
	net.WriteBool(settings.bStrict);
	net.WriteInt(settings.iStrictMax, 32);
	net.WriteInt(settings.iStrict2Max, 32);
	net.WriteBool(settings.bLogToFile);
	net.WriteBool(settings.bDebug);
	net.WriteTable(settings.arrBlackList);
	net.Send(ply);
end )

concommand.Add("pp_variables", function (ply)
	if not ply:IsSuperAdmin() then
		ply:ChatPrint("[PP]This command is only available for Super Admins.");
		return;
	end
	
	net.Start("sendppvariables");
	net.WriteTable(arrEntityPool);
	net.WriteInt(iLastThink, 32);
	net.WriteTable(arrSlowCount);
	net.WriteBool(bLagging);
	net.WriteTable(arrGoodToGo);
	net.WriteTable(arrNotBL);
	net.WriteTable(arrUserID);
	net.WriteTable(arrPropCoolDown);
	net.WriteInt(iStrictAmount, 32);
	net.WriteInt(iStrict2Amount, 32);
	net.WriteFloat(fLengthOfLagMin);
	net.WriteFloat(fLengthOfLagMax);
	net.Send(ply);
end )
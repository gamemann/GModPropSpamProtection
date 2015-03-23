--[[
Name: PSP.lua
Author: [GFL] Roy (Christian Deacon)
Description: Removes props that are lagging the server.
Version: 3.0
Year Created: 2014
Website: http://GFLClan.com/ & http://TheDevelopingCommunity.com/
]]--

local _debug = false
local entitypool = {}

-- Lag Settings
-- I have noticed that SysTime()-lastthink with no lag basically goes around 2.99XXXXX(etc) to about 3.0XXXXXX(etc) so I basically set this to 3.1 MAX and 2.5 MIN
local checkforprops = 1.0	-- The lower this value is, the less chances of prop spammers successfully lagging your server but also may cause overall higher CPU usage
local Ticks_of_lag = 2
local Length_of_lag = checkforprops + 0.05	-- Do not remove checkprops
local Length_of_lagM = checkforprops - 0.45	-- Do not remove checkprops
local lastthink = SysTime()
local blacklist = {"func_door", "func_door_rotating", "prop_door_rotating", "spawn_protect", "gmt_instrument_piano", "rm_car_dealer", "realistic_atm", "rx_slotmachine"}

-- Eh, other useful things to declare here.
local slowcount = {}
local lagging = false
local goodtogo = {}
local notbl = {}

-- User settings
local dosomething = true	-- Do something about these spammers!
local userid = {}
local useraction = 1 -- 1 = ban, 2 = kick, 0 or anything else = nothing
local userchances = 5 -- How many chances does the user get before user action occurs?
local userchancesremove = false
local userchangescooldown = 360.0 -- Every X seconds user amount goes down one
local removeallpropsifbanned = true
local propcooldown = {}

-- Messages for admin only or no?
local msgadminsonly = false

-- Strict mode
local strict = true

-- Level one strict
local strictamount = 0
local strictmax = 2

-- Level two strict
local strict2amount = 0
local strict2max = 2

local logtofile = true

hook.Add( "PlayerSpawnedProp", "antipen", function( ply, _, ent )
	timer.Create( "antipen" .. ent:EntIndex(), 0.1, 10, function()
		if not IsValid( ent ) then return end
		if ent:GetPhysicsObject():IsPenetrating() then
			ent:Remove()
		end
	end )
end )

timer.Create("getridofbadprops", checkforprops, 0, function ()
	if _debug then
		print ("Think and Length (" .. SysTime()-lastthink .. ") (Max: " .. Length_of_lag .. " Min: " .. Length_of_lagM .. ")!")
	end
	local amount = table.Count(entitypool)
	if _debug then
		--[[
		print ("\n\nEntity Pool:")
		print ("--------------------")
		PrintTable(entitypool)
		print("Amount: " .. amount .. "")
		print ("--------------------")
		]]--
	end
	for lol,e in pairs(entitypool) do
		if not IsValid(Entity(e)) then
			slowcount[e] = nil
			table.RemoveByValue(entitypool, e)
		end
	end
	if SysTime()-lastthink>Length_of_lag or SysTime()-lastthink<Length_of_lagM then
		-- First check for lag!
		for k,v in pairs(ents.GetAll()) do
			if IsValid(v) then
				if not v:IsWorld() and not v:IsPlayer() then
					local phys = v:GetPhysicsObject()
					if (phys:IsValid()) then
						if v:GetPhysicsObject():IsPenetrating() then
							-- lastthink = SysTime()
							if SysTime()-lastthink>Length_of_lag or SysTime()-lastthink<Length_of_lagM then
								-- Okay yes I know I added this before but this should get rid of people's innocent props getting deleted.
								lagging = true
								-- Black list!
								notbl[v] = true
								for _,b in pairs(blacklist) do
									if v:GetClass() == b then
										notbl[v] = false
										if _debug then
											print("Entity Black Listed!(" .. v:GetClass() .. ")")
										end
									end
								end
								if notbl[v] then
									if _debug then
										print ("CLASS: " .. v:GetClass())
									end
									goodtogo[v:EntIndex()] = true
									for k2,v2 in pairs(entitypool) do
										-- Let's make sure the entity isn't already in the pool!
										if (v2 == v:EntIndex()) then
											goodtogo[v:EntIndex()] = false
										end
									end
									if goodtogo[v:EntIndex()] then
										table.insert(entitypool, v:EntIndex())
									end
									table.remove(goodtogo, v:EntIndex())
									local highest = 0
									for key,value in pairs(entitypool) do
										if (value > highest) then
											highest = value
										end
									end
									if _debug then
										print ("\n Highest Entity: " .. highest)
									end
									local ent = Entity(highest)
									if IsValid(ent) then
										if (slowcount[ent:EntIndex()] == nil) then
											slowcount[ent:EntIndex()] = 0
										end
										slowcount[ent:EntIndex()] = slowcount[ent:EntIndex()] + 1
										if slowcount[ent:EntIndex()] >= Ticks_of_lag then
											if _debug then
												print ("SERVER IS LAGGING!")
											end
											slowcount[ent:EntIndex()] = nil
											lagging = false
											local user = ent:CPPIGetOwner()
											local nick = 0
											local steamid = 0
											if (IsValid(user)) then
												nick = user:Nick()
												steamid = user:SteamID()
											end
											-- I want to remove the prop ASAP. Before spitting out all of the other information.
											ent:Remove()
											
											for _, playa in pairs(player.GetAll()) do
												if (IsValid(playa)) then
													if msgadminsonly then
														if playa:IsAdmin() then
															if (IsValid(user)) then
																playa:ChatPrint("[PSP]Removed bad prop #" .. ent:EntIndex() .. ". Owner: " .. nick .. " (" .. steamid .. ")")
															else
																playa:ChatPrint("[PSP]Removed bad prop #" .. ent:EntIndex() .. ".")
															end
														end
													else
														if (IsValid(user)) then
															playa:ChatPrint("[PSP]Removed bad prop #" .. ent:EntIndex() .. ". Owner: " .. nick .. " (" .. steamid .. ")")
														else
															playa:ChatPrint("[PSP]Removed bad prop #" .. ent:EntIndex() .. ".")
														end
													end
												end
											end
											if logtofile then
												file.Append("propspammers.txt", "[PSP]Removed bad prop #" .. ent:EntIndex() .. ". Owner: " .. nick .. " (" .. steamid .. ") \n")
											end
											-- Time to start the user actions code!
											if dosomething and IsValid(user) then
												if (userid[steamid] == nil) then
													userid[steamid] = 0
												end
												if useraction != 0 then
													if (propcooldown[steamid] == nil) then
														propcooldown[steamid] = false
													end
													if propcooldown[steamid] == false then
														userid[steamid] = userid[steamid] + 1
													end
													if (userid[steamid] >= userchances) then
														if (IsValid(user)) then
															if useraction == 1 then
																-- Ban client!
																if propcooldown[steamid] == false then
																	if logtofile then
																		file.Append("propspammers.txt", "[PSP_BAN]" .. nick .. "(" .. steamid .. ") just got banned for prop spamming! \n")
																	end
																	if removeallpropsifbanned then
																		-- Remove all their props..
																			for k,v in pairs(ents.GetAll()) do
																				local person = v:CPPIGetOwner()
																				if (IsValid(person)) then
																					if _debug then
																						print (user:EntIndex() .. "/" .. person:EntIndex())
																					end
																					if (user:EntIndex() == person:EntIndex()) then
																						v:Remove()
																						if _debug then
																							print(nick .. " (" .. steamid .. ") got banned. Removed their prop: #" .. v:EntIndex() .. " (" .. v:GetModel() .. ")!")
																						end
																					end
																				end
																			end
																	end
																	userid[steamid] = nil
																	RunConsoleCommand("ulx", "banid", steamid, "1440.0", "Attempting to lag server (Caught by prop spammer addon)")
																end
															elseif useraction == 2 then
																-- Kick client!
																if propcooldown[steamid] == false then
																	if logtofile then
																		file.Append("propspammers.txt", "[PSP_KICK]" .. nick .. "(" .. steamid .. ") just got banned for prop spamming! \n")
																	end
																	userid[steamid] = nil
																	RunConsoleCommand("ulx", "kick", nick, "Attempting to lag server (Caught by prop spammer addon)")
																end
															end
														end
													else
														if propcooldown[steamid] == false then
															user:ChatPrint("Please stop prop spamming. Warning: " .. userid[steamid] .. "/" .. userchances .. ".")
														end
													end
													if (propcooldown[steamid] != nil) then
														propcooldown[steamid] = true
													
														timer.Simple(2.0 + Ticks_of_lag, function()
															if (propcooldown[steamid] != nil) then
																propcooldown[steamid] = false
															end
														end )
													end
												end
											end
											entitypool[ent:EntIndex()] = nil
											print("[PSP]Removed Bad Prop! Entity: " .. ent:EntIndex())
										end
									else
										entitypool[highest] = nil
									end
								end
							else
								-- The server isn't lagging anymore? #DELETEFROMTABLE
								table.RemoveByValue(entitypool, v:EntIndex())
								slowcount[v:EntIndex()] = nil
							end
						end
					end
				end
			end
		end
	else
		lagging = false
		for lol,e in pairs(entitypool) do
			slowcount[e] = nil
			table.RemoveByValue(entitypool, e)
		end
	end
	lastthink = SysTime()

end )

if dosomething then
	timer.Create("CheckUserChances", userchangescooldown, 0, function()
		-- Doing another dosomething check just incase we disable it while the script is running.
		if dosomething then
			for k,v in pairs(player.GetAll()) do
				local steamid = v:SteamID()
				if (userid[steamid] != nil and userid[steamid] != 0) then
					userid[steamid] = userid[steamid] - 1
				end
			end
		end
	end )
end

hook.Add("PlayerDisconnected", "Resetwarnings", function (ply)
	-- Reset the warnings and cool downs!
	if dosomething then
		local steamid = ply:SteamID()
		if userchancesremove then
			if (userid[steamid] != nil) then
				userid[steamid] = nil
				if _debug then
					print("Reset User: " .. steamid .. " warnings.")
				end
			end
		end
		
		if (propcooldown[steamid] != nil) then
			propcooldown[steamid] = nil
			if _debug then
				print("Reset User: " .. steamid .. " cool downs.")
			end
		end

	end

end )

-- Now let's see if it is strict
if strict then
	timer.Create("antipenstrict", 15, 0, function()
		if SysTime()-lastthink>Length_of_lag or SysTime()-lastthink<Length_of_lagM then
			lagging = true
			if _debug then
				print("[PSP]Got to strict mode level zero. (Count: " .. strictamount .. ")\n")	
			end
			strictamount = strictamount + 1
			if (strictamount >= strictmax) then
				if _debug then
					print("[PSP]Got to strict mode level one. (Severe Count: " .. strict2amount .. ")")
				end
				-- Server has been lagging for a while.. Let's just try deleting the bad props.
				strict2amount = strict2amount + 1
				-- This hopefully should get rid of the penetrating props.
				RunConsoleCommand("deletebadprops")
				if logtofile then
					file.Append("propspammers.txt", "[PSP]Strict mode level one reached. Deleted all bad props.")
				end
				if (strict2amount >= strict2max) then
					if _debug then
						print("[PSP]Got to strict mode level two.")
					end
					-- Screw it... Remove all props.
					-- If this happens, I am not sure why it occurs. It is known that prop penetrating can show up as false when in reality it is true (no reports on the other way around though)
					RunConsoleCommand("deleteprops")
					if logtofile then
						file.Append("propspammers.txt", "[PSP]Strict mode level two reached. Deleted all props.")
					end
					for k,v in pairs(player.GetAll()) do
						v:ChatPrint("[PSP]Deleting all penetrating props didn't work! Removed all props to stop the lag!")
					end
				else
					for k,v in pairs(player.GetAll()) do
						v:ChatPrint("[PSP]Server has been lagging for a while. Removing all penetrating props...")
					end
				end
				
			end
		else
			-- Reset the variables.
			strictamount = 0
			strict2amount = 0
		end
	end )
	lastthink = SysTime()
end

-- Check penetrating props (Available to everyone)!
concommand.Add("checkprops", function (ply)
	local propcount = 0
	for k,prop in pairs(ents.GetAll()) do
		if IsValid(prop) then
			if not prop:IsWorld() and not prop:IsPlayer() then
				propcount = propcount + 1
				local phys = prop:GetPhysicsObject()
				if (phys:IsValid()) then
					if prop:GetPhysicsObject():IsPenetrating() then
						local user = prop:CPPIGetOwner()
						local nick = 0
						local steamid = 0
						if (IsValid(user)) then
							nick = user:Nick()
							steamid = user:SteamID()
						end
						if (IsValid(ply) and IsValid(user)) then
							ply:ChatPrint("Prop #" .. prop:EntIndex() .. " is penetrating. Owner: " .. nick .. " (" .. steamid .. ")")
						else
							print("Prop #" .. prop:EntIndex() .. " is penetrating. Owner: " .. nick .. " (" .. steamid .. ")")
						end
					end
				end
			end
		end
	end
	if (IsValid(ply)) then
		ply:ChatPrint("Scan Prop Count: " .. propcount)
		if logtofile then
			file.Append("propspamming_commands.txt", "[PSP][CHECK]" .. ply:Nick() .. " (" .. ply:SteamID() .. ") has checked for props! \n")
		end
	end
end )

-- Delete Bad Props
concommand.Add("deletebadprops", function (ply)
	if (IsValid(ply)) then
		if not ply:IsAdmin() then
			ply:ChatPrint("This command is only for admins.")
			return
		end
	end
	for k,prop in pairs(ents.GetAll()) do
		if IsValid(prop) then
			if not prop:IsWorld() and not prop:IsPlayer() then
				local phys = prop:GetPhysicsObject()
				if (phys:IsValid()) then
					if prop:GetPhysicsObject() and prop:GetPhysicsObject():IsPenetrating() then
						-- Black list!
						notbl[prop] = true
						for _,b in pairs(blacklist) do
							if prop:GetClass() == b then
								notbl[prop] = false
								if _debug then
									print("Entity Black Listed!(" .. prop:GetClass() .. ")")
								end
							end
						end
						if notbl[prop] then
							local user = prop:CPPIGetOwner()
							local nick = 0
							local steamid = 0
							if (IsValid(user)) then
								nick = user:Nick()
								steamid = user:SteamID()
							end
							prop:Remove()
			
							if (IsValid(ply) and IsValid(user)) then
								ply:ChatPrint("Deleted Prop #" .. prop:EntIndex() .. ". Owner: " .. nick .. " (" .. steamid .. ")")
							else
								print("[PSP]Deleted all bad props!")
							end
						end
					end
				end
			end
		end
	end
	if (IsValid(ply)) then
		if logtofile then
			file.Append("propspamming_commands.txt", "[PSP][BADPROPS]" .. ply:Nick() .. " (" .. ply:SteamID() .. ") has deleted all bad props! \n")
		end
	end
end )

-- Delete all props command!
concommand.Add("deleteprops", function (ply)
	if (IsValid(ply)) then
		if not ply:IsSuperAdmin() then
			ply:ChatPrint("This command is only for super admins.")
			return
		end
	end
	for k,prop in pairs(ents.GetAll()) do
		if IsValid(prop) then
			local phys = prop:GetPhysicsObject()
			if (phys:IsValid()) then
				if not prop:IsWorld() and not prop:IsPlayer() then
					-- Black list!
					notbl[prop] = true
					for _,b in pairs(blacklist) do
						if prop:GetClass() == b then
							notbl[prop] = false
							if _debug then
								print("Entity Black Listed!(" .. prop:GetClass() .. ")")
							end
						end
					end
					if notbl[prop] then
						local user = prop:CPPIGetOwner()
						local nick = 0
						local steamid = 0
						if (IsValid(user)) then
							nick = user:Nick()
							steamid = user:SteamID()
						end
						if (nick != 0 and steamid != 0) then
							prop:Remove()
							if (IsValid(ply) and IsValid(user)) then
								ply:ChatPrint("Deleted Prop #" .. prop:EntIndex() .. ". Owner: " .. nick .. " (" .. steamid .. ")")
							else
								print("[PSP]Deleted all props!")
							end
						end
					end
				end
			end
		end
	end
	if (IsValid(ply)) then
		if logtofile then
			file.Append("propspamming_commands.txt", "[PSP][DELETEALLPROPS]" .. ply:Nick() .. " (" .. ply:SteamID() .. ") has deleted all props! \n")
		end
	end
end )
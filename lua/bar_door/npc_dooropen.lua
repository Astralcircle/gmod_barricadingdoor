if CLIENT then return end

local DoorBarNPC_Enable = CreateConVar("door_barricading_npc", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "NPCs will not be able to open barricaded doors if Enabled")
local DoorBarNPC_KickChance = CreateConVar("door_barricading_kickchance", "5", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Chance for an NPC to knock down a door")

Doormen_NPCS = {} --Епанные швейцары (НПС которые умеют открывать двери)

local IsValid = IsValid
local isvector = isvector
local util_TraceLine = util.TraceLine
local timer_Simple = timer.Simple
local table_remove = table.remove
local ipairs = ipairs
local Vector = Vector
local GetConVarNumber = GetConVarNumber

local DOOR_SEARCH_RADIUS = 125
local DOOR_CHECK_INTERVAL = 0.2

-- Я без понятия как узнать есть ли CAP_OPEN_DOORS у нпс, так что использовал таблицу
local Doormens_NPCS_Canbe = {
    -- комбонайны
	[ "npc_combine_s" ] = true,
	[ "npc_metropolice" ] = true,
    -- zа повстанцев
    [ "npc_alyx" ] = true,
    [ "npc_barney" ] = true,
    [ "npc_citizen" ] = true,
    [ "npc_odessa" ] = true,
    [ "npc_kleiner" ] = true,
    [ "npc_eli" ] = true,
    [ "npc_magnusson" ] = true,
    [ "npc_mossman" ] = true,
    [ "npc_vortigaunt" ] = true,
    [ "npc_monk"] = true
    --["npc_zombie"] = true
}
hook.Add("OnEntityCreated", "DoorBar_NPCCreate", function( ent )
    if ent:IsNPC() and ent:IsValid() and Doormens_NPCS_Canbe[ ent:GetClass() ] then
        ent.LastDoorCheck = 0
        table.insert(Doormen_NPCS,ent)
    end
end)

hook.Add( "Think", "DoorBar_NPCOpenThink", function()

    if DoorBarNPC_Enable:GetInt() == 1 then
        local curtime = CurTime()
        for i, npc in ipairs(Doormen_NPCS) do
            if !IsValid(npc) then
                table_remove(Doormen_NPCS,i)
            else
                if curtime > npc.LastDoorCheck then

                    local npcpos = npc:GetPos()
                    local npcfwr = npcpos + npc:OBBCenter()

                    local finddoorpos
                    local entities = ents.FindInSphere(npcfwr, DOOR_SEARCH_RADIUS)
                    for _, ent in ipairs(entities) do
                        if IsValid(ent) and ent:GetClass():find("door_rot") then
                            finddoorpos = ent:GetPos()
                            break 
                        end
                    end
                    if !finddoorpos then return end

                    local tr = util.TraceLine({
                        start = npcfwr,
                        endpos = finddoorpos,
                        filter = npc
                    })	 
                    local trent = tr.Entity
                    local trpos = tr.HitPos

                    if IsValid(trent) and trent:GetModel() == "models/props_c17/door01_left.mdl" and !trent.DoorBlocked then
                        local door_state = trent:GetInternalVariable( "m_eDoorState" ) ~= 0
                        local door_locked = trent:GetInternalVariable( "m_bLocked" ) ~= 0
                        if !door_locked then return end

                        local trnormal = tr.HitNormal

                        local doorpos = trent:GetPos()-trent:GetRight()*35-trent:GetUp()*35
                        local idealpos = doorpos + trnormal
                        local idealpos2 = doorpos + trnormal * -35

                        local doortr = util_TraceLine({
                            start = idealpos,
                            endpos = idealpos2,
                            filter = trent
                        })

                        local barricade_ent = doortr.Entity

                        if IsValid(barricade_ent) then

                            trent.DoorBlocked = true

                            local DoorBar_PushForce = GetConVarNumber("door_barricading_forcepower")
                            
                            local physbarricade = barricade_ent:GetPhysicsObject()
                            local barmass = physbarricade:GetMass()
                            local trentpos = trent:GetPos()
                            local barpos = barricade_ent:GetPos()

                            local kickchance = DoorBarNPC_KickChance:GetInt()
                            local randomama = math.random(1, 100)
                            if randomama <= kickchance then
                                trent:SetSaveValue("friction", 50)
                                trent.LastDoorSpeed = trent:GetKeyValues()["speed"]
                                trent:SetKeyValue("speed",750)
                                physbarricade:SetVelocity(-(trentpos-barpos+Vector(0,0,50))*5/barmass)
                                trent:Fire("Open",0,0,ply)
                                trent:Fire("Close",1,0.1,ply)
                                trent:EmitSound("physics/wood/wood_furniture_break1.wav")
                                timer_Simple(0.2, function() if IsValid(trent) then trent.DoorBlocked = false trent:SetKeyValue("speed",trent.LastDoorSpeed) end end)
                            elseif DoorBar_PushForce > 0 then
                                physbarricade:SetVelocity(-(trentpos-barpos)*DoorBar_PushForce*10/barmass)
                                trent:Fire("Open",1,0,ply)
                                trent:Fire("Close",1,0.1,ply)
                                timer_Simple(0.5, function() if IsValid(trent) then trent.DoorBlocked = false end end)
                                timer_Simple(0.1, function() if IsValid(trent) then trent:EmitSound("physics/wood/wood_crate_impact_hard2.wav") end end)
                            end
                        end

                        if trent.DoorBlocked then return end

                    end
                    npc.LastDoorCheck = curtime + DOOR_CHECK_INTERVAL -- Идеально же, привет астралище
                end
            end
        end
    end
end)
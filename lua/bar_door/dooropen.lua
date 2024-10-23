if CLIENT then return end

local DoorBar_Enable = CreateConVar("door_barricading_enable", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable/disable barricading of doors with objects")
local DoorBar_PushForce = CreateConVar("door_barricading_forcepower", "30", FCVAR_ARCHIVE, "The force of pushing objects away from a door")

local IsValid = IsValid
local util_TraceLine = util.TraceLine
local IN_USE = IN_USE
local timer_Simple = timer.Simple

hook.Add( "PlayerUse", "DoorBar_PlayerOpenDoor", function( ply, ent )
	if ( !IsValid( ent ) ) then return end
    if DoorBar_Enable:GetBool() then
	
        local eyetrace = ply:GetEyeTrace()

        local trent = eyetrace.Entity

        local doorclass = "prop_door_rotating"
        local getclass = ent:GetClass()
        if getclass == doorclass and trent != ent then return false end --Когда игрок смотрит в сторону двери то дверь открывается без проверки, фиксим быстра

        if (IsValid(trent) and trent:GetClass() == doorclass) then
            local door_state = trent:GetInternalVariable( "m_eDoorState" ) ~= 0
            local door_locked = trent:GetInternalVariable( "m_bLocked" ) ~= 0
            if !door_locked then return end

            local HitPos = eyetrace.HitPos
            local HitNormal = eyetrace.HitNormal
            
            local trentpos = trent:GetPos()

            local obb_maxs = trent:OBBMaxs()

            local doorpos = trentpos-trent:GetRight()*(obb_maxs.x * 7)-trent:GetUp()*(obb_maxs.z*0.5)
            local idealpos = doorpos + HitNormal * -1
            local idealpos2 = doorpos + HitNormal * -35

            --ply:SetPos(doorpos)

            local doortr = util_TraceLine({
                start = idealpos,
                endpos = idealpos2,
                filter = trent
            })

            local barricade_ent = doortr.Entity
            if IsValid(barricade_ent) and !trent.DoorBlocked and barricade_ent:GetClass() != getclass then

                trent.DoorBlocked = true

                local pushpower = DoorBar_PushForce:GetInt()
                if pushpower > 0 then
                    local physbarricade = barricade_ent:GetPhysicsObject()
                    physbarricade:SetVelocity(- ( trentpos - barricade_ent:GetPos() ) * pushpower * 10 / physbarricade:GetMass())
                end

                trent:Fire("Open",1,0,ply)
                --как оказалось, замена таймерам
                trent:Fire("Close",1,0.1,ply)
                timer_Simple(0.5, function() if IsValid(trent) then trent.DoorBlocked = false end end)
                timer_Simple(0.1, function() if IsValid(trent) then trent:EmitSound("physics/wood/wood_crate_impact_hard2.wav") end end)
            end

            if trent.DoorBlocked then return false end
        end
    end
end )

hook.Add("OnEntityCreated", "ignitedones_gentoi_iniatlize", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end
        if ent:GetClass() ~= "pill_ent_costume" then return end


        if ent.formTable then
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if ent.formTable.ignitedones_jentoi_pill_init then
                ent.formTable:ignitedones_jentoi_pill_init(entityply, ent, PuppetEntity)

                local self = ent
                ent.Think = function()
                    local ply = self:GetPillUser()
                    local puppet = self:GetPuppet()
                    if not IsValid(puppet) or not IsValid(ply) then return end
                    local vel = ply:GetVelocity():Length()

                    if SERVER then
                        --Anims
                        local anims = table.Copy(self.formTable.anims.default or {})
                        table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                        local anim
                        --local useSeqVel=true
                        local overrideRate

                        if (not self.anim or not anims[self.anim]) then
                            self.animFreeze = nil
                            self.animStart = nil
                        end

                        if self.animFreeze and not self.plyFrozen then
                            ply:SetWalkSpeed(ply:GetWalkSpeed() / 2)
                            ply:SetRunSpeed(ply:GetWalkSpeed() / 2)
                            self.plyFrozen = true
                        elseif not self.animFreeze and self.plyFrozen then
                            local speed = self.formTable.moveSpeed or {}
                            ply:SetWalkSpeed(speed.walk or 200)
                            ply:SetRunSpeed(speed.run or speed.walk or 500)
                            self.plyFrozen = nil
                        end

                        if self.anim and anims[self.anim] then
                            anim = anims[self.anim]
                            overrideRate = anims[self.anim .. "_rate"] or 1
                            local cycle = puppet:GetCycle()

                            if not self.animStart then
                                if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                    self.anim = nil
                                    self.animCycle = nil

                                    if self.animFreeze then
                                        self.animFreeze = nil
                                    end
                                elseif self.animCycle then
                                    self.animCycle = cycle
                                end
                            end
                        elseif self.tickAnim and anims[self.tickAnim] then
                            anim = anims[self.tickAnim]
                            overrideRate = anims[self.tickAnim .. "_rate"] or 1
                            self.tickAnim = nil
                        elseif self.burrowed then
                            anim = anims["burrow_loop"]
                        elseif ply:WaterLevel() > 2 then
                            anim = anims["swim"] or anims["glide"] or anims["idle"]
                        elseif ply:IsOnGround() then
                            if ply:Crouching() then
                                if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                    anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                else
                                    anim = anims["crouch"] or anims["idle"]
                                end
                            else
                                if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                    anim = anims["run"] or anims["walk"] or anims["idle"]
                                elseif vel > ply:GetWalkSpeed() / 4 then
                                    anim = anims["walk"] or anims["idle"]
                                else
                                    anim = anims["idle"]
                                end
                            end
                        else
                            anim = anims["glide"] or anims["idle"]
                        end

                        if anim == anims["idle"] or anim == anims["crouch"] then
                            overrideRate = 1
                        end

                        if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then
                            puppet:ResetSequence(puppet:LookupSequence(anim))
                            puppet:SetCycle(0)
                            self.animCycle = 0
                        end

                        self.animStart = nil
                        local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                        --print(puppet:GetCycle())
                        if self.formTable.movePoseMode then
                            --
                            if self.formTable.movePoseMode == "yaw" then
                                local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                puppet:SetPoseParameter("move_yaw", move_dir.y)
                            elseif self.formTable.movePoseMode == "xy" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                end
                            elseif self.formTable.movePoseMode == "xy-bot" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    puppet:SetPoseParameter("move_yaw", move_dir.y)
                                    puppet:SetPoseParameter("move_scale", 1)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_scale", math.Clamp(localvel:Length() / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                    puppet:SetPoseParameter("move_yaw", 0)
                                    puppet:SetPoseParameter("move_scale", 0)
                                end
                            end
                        end

                        --Aimage
                        if self.formTable.aim then
                            if self.formTable.aim.xPose then
                                local yaw = math.AngleDifference(ply:EyeAngles().y, self:GetAngles().y)

                                if self.formTable.aim.xInvert then
                                    yaw = -yaw
                                end

                                puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                            end

                            if self.formTable.aim.yPose then
                                local pitch = math.AngleDifference(ply:EyeAngles().p, self:GetAngles().p)

                                if self.formTable.aim.yInvert then
                                    pitch = -pitch
                                end

                                puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                            end
                        end

                        --gliding and landing
                        if not ply:IsOnGround() and ply:WaterLevel() == 0 and self.formTable.glideThink then
                            self.formTable.glideThink(ply, self)
                        end

                        if not ply:IsOnGround() and not self.touchingWater and ply:WaterLevel() > 0 and self.formTable.land then
                            self.formTable.land(ply, self)
                        end

                        --water death
                        self.touchingWater = ply:WaterLevel() > 1

                        if (self.formTable.damageFromWater and self.touchingWater) then
                            if self.formTable.damageFromWater == -1 then
                                --self:PillDie()
                                ply:Kill()
                            else
                                ply:TakeDamage(self.formTable.damageFromWater)
                                --TODO APPLY DAMAGE
                            end
                        end

                        --tick attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                            self.formTable.attack.func(ply, self, self.formTable.attack)
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                            self.formTable.attack2.func(ply, self, self.formTable.attack2)
                        end

                        --auto attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack")
                            else
                                self:PillLoopStop("attack")
                            end

                            if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                                self.lastAttack = CurTime()
                            end
                        else
                            self:PillLoopStop("attack")
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack2")
                            else
                                self:PillLoopStop("attack2")
                            end

                            if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                self.lastAttack2 = CurTime()
                            end
                        else
                            self:PillLoopStop("attack2")
                        end

                        --charge
                        if self:GetChargeTime() ~= 0 then
                            if ply:OnGround() then
                                local charge = self.formTable.charge
                                local angs = ply:EyeAngles()
                                self:PillAnimTick("charge_loop")
                                local hit_ent = ply:TraceHullAttack(ply:EyePos(), ply:EyePos() + angs:Forward() * 100, Vector(-20, -20, -20), Vector(20, 20, 20), charge.dmg, DMG_CRUSH, 1, true)

                                if IsValid(hit_ent) then
                                    self:PillAnim("charge_hit", true)
                                    --self:PillGesture("charge_hit")
                                    self:PillSound("charge_hit")
                                    self:SetChargeTime(0)
                                    self:PillLoopStop("charge")
                                end
                            else
                                self:SetChargeTime(0)
                                self:PillLoopStop("charge")
                            end
                        end

                        --Cloak
                        if self.formTable.cloak then
                            local cloak = self.formTable.cloak

                            if self.iscloaked then
                                local cloakamt = self:GetCloakLeft()

                                if cloakamt ~= -1 then
                                    cloakamt = cloakamt - FrameTime()

                                    if cloakamt < 0 then
                                        cloakamt = 0
                                        self:ToggleCloak()
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            else
                                local cloakamt = self:GetCloakLeft()

                                if cloakmt ~= -1 and cloakamt < cloak.max then
                                    cloakamt = cloakamt + FrameTime() * cloak.rechargeRate

                                    if cloakamt > cloak.max then
                                        cloakamt = cloak.max
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            end

                            local color = self:GetPuppet():GetColor()

                            if self.iscloaked then
                                if color.a > 0 then
                                    color.a = color.a - 5
                                    self:GetPuppet():SetColor(color)
                                end
                            else
                                if color.a < 255 then
                                    color.a = color.a + 5
                                    self:GetPuppet():SetColor(color)
                                end
                            end

                            --PrintTable(color)
                            if IsValid(self.wepmdl) and self.wepmdl:GetColor().a ~= color.a then
                                self.wepmdl:SetColor(color)
                            end
                        end

                        --if !IsValid(ply) then self:NextThink(CurTime()) return true end
                        --wepon-no longer SO hackey
                        if not self.formTable.hideWeapons then
                            local realWep = self:GetPillUser():GetActiveWeapon()

                            --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
                            if IsValid(realWep) and realWep:GetModel() ~= "" then
                                --hiding the real thing [BROKEN]
                                --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                                    realWep:SetRenderMode(RENDERMODE_NONE)
                                end]]
                                if realWep.pill_attachment then
                                    if IsValid(self.wepmdl) then
                                        self.wepmdl:Remove()
                                    end

                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl.attachment = realWep.pill_attachment
                                    self.wepmdl:Spawn()

                                    if realWep.pill_offset then
                                        self.wepmdl:SetWepOffset(realWep.pill_offset)
                                    end

                                    if realWep.pill_angle then
                                        self.wepmdl:SetWepAng(realWep.pill_angle)
                                    end

                                    realWep.pill_proxy = self.wepmdl
                                elseif not IsValid(self.wepmdl) then
                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl:Spawn()
                                    realWep.pill_proxy = self.wepmdl
                                elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                                    self.wepmdl:SetModel(realWep:GetModel())
                                end
                            elseif IsValid(self.wepmdl) then
                                self.wepmdl:Remove()
                            end
                        end
                    else
                        self:SetNWBool('clientsideshould', not pk_pills.convars.cl_thirdperson:GetBool())

                        if self:GetPillUser() ~= LocalPlayer() or true then
                            puppet:SetNoDraw(false)
                        end

                        local realWep = self:GetPillUser():GetActiveWeapon()

                        if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                            realWep:SetNoDraw(true)
                        end
                    end

                    --Align pos and angles with player
                    if SERVER then
                        puppet:SetPos(ply:GetPos())
                        self:SetAngles(ply:GetAngles())
                    else
                        puppet:SetRenderOrigin(ply:GetPos())
                    end

                    if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 or self:GetNWBool('clientsideshould') then
                        local angs = ply:EyeAngles()
                        angs.p = 0

                        if SERVER then
                            puppet:SetAngles(angs)
                        else
                            --puppet:SetAngles(angs)
                            puppet:SetRenderAngles(angs)
                        end
                    end

                    self:NextThink(CurTime())

                    return true
                end


            else
            end
        end

        if ent.formTable.HandleAnimEvent_g_ignitedones then
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if IsValid(PuppetEntity) then
                function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                    ent.formTable.HandleAnimEvent_g_ignitedones(entityply, ent, inputName)
                    return true
                end
            end
        else
        end
    end)
end)

hook.Add("Think", "ignitedones_gentoi_think", function()
    for _, ent in ipairs(ents.FindByClass("pill_ent_costume")) do
        if !IsValid(ent) then continue end
        local ply = ent:GetPillUser()
        local puppet = ent:GetPuppet()

        if not IsValid(puppet) or not IsValid(ply) then continue end

        if ent.formTable.ignitedones_gentoi_think then
            ent.formTable.ignitedones_gentoi_think(ply, ent)
        end
    end
end)



if SERVER then
    AddCSLuaFile()
    util.AddNetworkString('ignited_jumpscare_gen')

else

    hook.Add("PostDrawOpaqueRenderables","IgnitedCharacters_NoDraw",function()
        for _,ent in ipairs(ents.GetAll()) do
            if !IsValid(ent) then continue end

            local endTime = ent:GetNWFloat("IgnitedCharacters_NoDraw", 0) 

            if endTime > CurTime() and ent:GetNWEntity("IgnitedCharacters_nodrawply", 0) == LocalPlayer() then
                if not ent.IgnitedCharacters_NoDraw_gent then
                    ent.IgnitedCharacters_NoDraw_gent = true
                    ent:SetNoDraw(true)
                end

            else
                if ent.IgnitedCharacters_NoDraw_gent then
                    ent.IgnitedCharacters_NoDraw_gent = false
                    ent:SetNoDraw(false)
                end
            end
        end
    end)

    surface.CreateFont("CreditsText_Large_ignitedbonnie", {
        font = "Arial",
        size = 70,
        weight = 700,
        antialias = true,
    })

    local preservedmats = {
        ["BowTie"] = Material("icons/fasterboost_gent_ignited.png"),
    }
    
    hook.Add("HUDPaint", "gentoi_ignitedbonnie_hud", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local pillentity = ply.pk_pill_ent
        if not IsValid(pillentity) then return end
        if not pillentity.GetPuppet then return end
        if not IsValid(pillentity:GetPuppet()) then return end
        if not pillentity.formTable.ignitedCharacter_gent then return end

        local screenW, screenH = ScrW(), ScrH()
        local iconize = ScreenScale(70)

        local lx, ly = screenW/2 + screenW/3, screenH - ScreenScale(80)

        if pillentity:GetNWBool("GentoiPills_ignitedbonnie_Rushdown") then
            surface.SetDrawColor(255,255,255,255)
        else
            surface.SetDrawColor(255,0,0,255)
        end
        surface.SetMaterial(preservedmats["BowTie"])
        surface.DrawTexturedRectRotated(lx + iconize/2,ly + iconize/2,iconize,iconize,0)

        if pillentity:GetNWFloat("BonnieRushdown_Gentoi_cooldown") > CurTime() then
            local frac = math.Clamp(
                (pillentity:GetNWFloat("BonnieRushdown_Gentoi_cooldown") - CurTime()) /
                pillentity:GetNWFloat("BonnieRushdown_Gentoi_cooldown_max"),
                0, 1
            )

            local h  = Lerp(frac, 0, iconize)
            local y2 = Lerp(frac, ly + iconize, ly)
            local uv = Lerp(frac, 1, 0)

            surface.SetDrawColor(25,25,25,255)
            surface.DrawTexturedRectUV(lx,y2,iconize,h,0,uv,1,1)

            local number = math.ceil(pillentity:GetNWFloat("BonnieRushdown_Gentoi_cooldown") - CurTime())
            draw.SimpleTextOutlined(number,"CreditsText_Large_ignitedbonnie",lx +iconize/2,ly +iconize/2,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,6,color_black)
        end

        draw.SimpleTextOutlined("R","CreditsText_Large_ignitedbonnie",lx + ScreenScale(5),ly + ScreenScale(2),color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,6,color_black)
    end)

    net.Receive('ignited_jumpscare_gen', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "ignited_jumpscare_" .. LocalPlayer():SteamID()

        --print(state)

        if not state then
            hook.Remove('CalcView', hookID)
        else
            hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
                if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
                    hook.Remove('CalcView', hookID)
                    if IsValid(ply) then
                        ply:RemoveFlags(FL_NOTARGET)
                        ply:Freeze(false)
                        ply:DrawViewModel(true)
                    end
                    return
                end

                local cam = ent:GetAttachment(ent:LookupAttachment('camera'))

                ply:AddFlags(FL_NOTARGET)
                ply:Freeze(true)
                ply:DrawViewModel(false)

                local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
                
                local targetFOV = 80 

                local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
                local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
                local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

                local view = {
                    origin = orgiginlerpto,
                    angles = angleslerpto,
                    fov = interpolatedFOV,
                    drawviewer = false
                }
                return view
            end)
        end
    end)

end

local function AdvancedPillSound(SoundData, ent)
    if IsValid(ent) then
        SoundData = SoundData or {}
        SoundData.stringe = SoundData.stringe or {}
        SoundData.soundLevel = SoundData.soundLevel or 75
        SoundData.pitchPercent = SoundData.pitchPercent or 100
        SoundData.volume = SoundData.volume or 1
        SoundData.channel = SoundData.channel or CHAN_AUTO
        SoundData.soundFlags = SoundData.soundFlags or 0
        SoundData.dsp = SoundData.dsp or 0
        SoundData.filter = SoundData.filter or nil

        local chosenSound = SoundData.stringe

        if istable(SoundData.stringe) then
            local index = math.random(1, #SoundData.stringe)
            chosenSound = SoundData.stringe[index]
        end

        ent:EmitSound(
            chosenSound,
            SoundData.soundLevel,
            SoundData.pitchPercent,
            SoundData.volume,
            SoundData.channel,
            SoundData.soundFlags,
            SoundData.dsp,
            SoundData.filter
        )
    end
    return true
end


local function racheljackietien_jumpscare(ply, ent, duration, customanimstuff)
    if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
    if ent.IsInJumpscare >= CurTime() then return end
    if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
    if ent.IsInJumpscareCooldown >= CurTime() then return end

    local jumpscare_entity = nil

    for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
        if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
            if ent2 == ply then continue end
            if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

            if IsValid(ent2) then
                jumpscare_entity = ent2
                break
            end
        end
    end

    if jumpscare_entity ~= nil then
        
        ent.JuumpscareStart = CurTime()

        ent.jumpscare_entity = jumpscare_entity
        ent.entitylastpos = jumpscare_entity:GetPos()
        ent.entitylastang = jumpscare_entity:GetAngles()

        local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

        targetAngle.p = 0
        targetAngle.r = 0

        ply:SetNWInt("DisableMovement_jumpscare_pill_ignited", duration+CurTime())
        jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_ignited", duration+CurTime())

        ent.IsInJumpscare = CurTime() + duration

        local puppet = ent:GetPuppet()

        if jumpscare_entity:IsPlayer() then
            net.Start('ignited_jumpscare_gen')
            net.WriteEntity(puppet)
            net.WriteBool(true)
            net.Send(jumpscare_entity)
        else
            jumpscare_entity:NextThink(duration+0.1+CurTime())
        end
        
        jumpscare_entity:AddFlags(FL_NOTARGET)

        ent:CallOnRemove("RachelJumpscare"..ent:EntIndex(), function()
            if !IsValid(jumpscare_entity) then return end

            jumpscare_entity:RemoveFlags(FL_NOTARGET)
            ent.jumpscare_entity = nil

            if jumpscare_entity:IsPlayer() then
                net.Start('ignited_jumpscare_gen')
                net.WriteEntity(puppet)
                net.WriteBool(false)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(CurTime())
            end
            jumpscare_entity:SetPos(ent.entitylastpos)
            jumpscare_entity:SetAngles(ent.entitylastang)
            jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_ignited", CurTime())
        end)


            if !IsValid(ent) then return end
            local jumpscare_entity = ent.jumpscare_entity
            if !(IsValid(jumpscare_entity)) then return end

            local ragdoll = ents.Create("prop_ragdoll")
            ragdoll:SetModel(jumpscare_entity:GetModel())
            ragdoll:SetPos(jumpscare_entity:GetPos())
            ragdoll:SetAngles(jumpscare_entity:GetAngles())
            ragdoll:SetSkin(jumpscare_entity:GetSkin() or 0)
            ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
            ragdoll:Spawn()

            ragdoll:SetNWFloat("IgnitedCharacters_NoDraw", duration+CurTime())
            ragdoll:SetNWEntity("IgnitedCharacters_nodrawply", jumpscare_entity)

            local physCount = ragdoll:GetPhysicsObjectCount()
            if physCount <= 0 then
                ragdoll:Remove()
                return end

            if not jumpscare_entity:IsPlayer() then
                local wep = jumpscare_entity:GetActiveWeapon()
                if IsValid(wep) then
                    jumpscare_entity.OldWeapon = wep
                    wep:SetNoDraw(true)
                end
            end

            if jumpscare_entity.GetBodyGroups then
                for _, bg in ipairs(jumpscare_entity:GetBodyGroups()) do
                    ragdoll:SetBodygroup(bg.id, jumpscare_entity:GetBodygroup(bg.id))
                end
            end

            if jumpscare_entity.GetPlayerColor and ragdoll.SetPlayerColor then
                ragdoll:SetPlayerColor(jumpscare_entity:GetPlayerColor())
            end

            if jumpscare_entity.GetColor then
                ragdoll:SetColor(jumpscare_entity:GetColor())
            end

            if jumpscare_entity.GetMaterial then
                ragdoll:SetMaterial(jumpscare_entity:GetMaterial())
            end

            if ragdoll.GetNumSubMaterials and ragdoll.SetSubMaterial and jumpscare_entity.GetSubMaterial then
                for i = 0, ragdoll:GetNumSubMaterials() - 1 do
                    local sub = jumpscare_entity:GetSubMaterial(i)
                    if sub then
                        ragdoll:SetSubMaterial(i, sub)
                    end
                end
            end

            jumpscare_entity:SetNoDraw(true)
            jumpscare_entity:SetNotSolid(true)

            ent.CurrentJumpscareRagdoll = ragdoll
            ent:DeleteOnRemove(ragdoll)

            hook.Add("Think", "ragdoll_nosey".. ent:EntIndex(), function()
                if !IsValid(ragdoll) then return end
                if SERVER then
                    local headPhys = nil

                    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                        local phys = ragdoll:GetPhysicsObjectNum(i)
                        if IsValid(phys) then
                            local boneIndex = ragdoll:TranslatePhysBoneToBone(i)
                            local boneName = ragdoll:GetBoneName(boneIndex) or ""
                            if string.find(string.lower(boneName), "head") then
                                headPhys = phys
                                break
                            end
                        end
                    end

                    if !IsValid(headPhys) then
                        headPhys = ragdoll:GetPhysicsObject()
                    end

                    if IsValid(headPhys) then
                        local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))
                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos)
                        headPhys:SetPos(cam.Pos)
                        headPhys:SetAngles(cam.Ang)

                        headPhys:Wake()
                    end
                end
            end)

        customanimstuff()
    end
end

hook.Add("SetupMove", "DisablePlayerMovement_ignited", function(ply, mv, cmd)
    if ply:GetNWInt("DisableMovement_jumpscare_pill_ignited") >= CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end
end)


hook.Add("PlayerButtonDown", "ActivateKeybind_ignited_gentoi_pills", function(ply, button)
    local pillentity = ply.pk_pill_ent
    if IsValid(pillentity) then
        if pillentity.formTable.noodles_ignited_gentoi_keybinds then
            pillentity.formTable.noodles_ignited_gentoi_keybinds(ply, pillentity, button)
        end
    end
end)

pk_pills.packStart("TheIgnitedOnes_gentoi", "AnalogHorrorPills_gentio_ignitedones", "pills/pill_gentoi_ignitedbonnie.png")

pk_pills.register('pill_gentoi_ignitedbonnie', {

    printName='Ignited Bonnie',
    ignitedCharacter_gent = "IgnitedBonnie",
    model="models/gentoi/anologhorror/ignitedbonnie.mdl",
        
    modelScale='1.0',
        
    noragdoll = true,
    muteSteps = true,
        
    anims={
        default={
            idle="idle",
            run="run",
            walk="walk",
            jumpscare1="jumpscare1",
            jumpscare2="jumpscare2",
            crouch = "CrouchIdle",
            crouch_walk = "CrocuhWalk"
        },
    },

    moveSpeed = {
        walk = 57,
        run = 450,
        ducked=47,
    },
        
    sounds={
        jumpscare1 = "gentoi/anologhorror/ignitedones/bonniekill1.wav",
        jumpscare2 = "gentoi/anologhorror/ignitedones/bonniekill2.wav"
    },

    type='ply',


    FirstPersonBone = {
        'Head',
        7,
        0,
        7,
    },
    ThirdPersonBone = {
        'Pelvus',
        0,
        22,
        15,
    },

    camera={
        offset = Vector(0, 0, 75),
        dist=90,
    },
        
    jumpPower=0,
        
    health=2000,
    
    movePoseMode="xy",
        aim={
        xPose="aim_yaw",
        yPose="aim_pitch",
        nocrosshair = true
    },
        
    canAim=function(ply,ent) return ent.active end,    

    HandleAnimEvent_g_ignitedones = function(ply, ent, event)
        if event == "playerded" or event == "playerded2" then
            timer.Simple(0.4, function()
                if !IsValid(ent) then return end

                if ent.CurrentJumpscareRagdoll then
                    if IsValid(ent.CurrentJumpscareRagdoll) then
                        ent:DontDeleteOnRemove(ent.CurrentJumpscareRagdoll)

                        local ragdoll = ent.CurrentJumpscareRagdoll
                        local headPhys = nil

                        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                            local phys = ragdoll:GetPhysicsObjectNum(i)
                            if IsValid(phys) then
                                local boneIndex = ragdoll:TranslatePhysBoneToBone(i)
                                local boneName = ragdoll:GetBoneName(boneIndex) or ""
                                if string.find(string.lower(boneName), "head") then
                                    headPhys = phys
                                    break
                                end
                            end
                        end

                        if !IsValid(headPhys) then
                            headPhys = ragdoll:GetPhysicsObject()
                        end

                        if IsValid(headPhys) then
                            if event ~= "playerded2" then
                                headPhys:SetVelocity(ent:GetPuppet():GetForward()*9000000)
                            end
                            headPhys:Wake()
                        end
                    end
                end
                hook.Remove('Think', "ragdoll_nosey".. ent:EntIndex())
                
                local jumpscare_entity = ent.jumpscare_entity
                if !(IsValid(jumpscare_entity)) or !IsValid(ent) then return end
                ent.jumpscare_entity = nil
                jumpscare_entity:SetPos(ent.entitylastpos)
                jumpscare_entity:SetAngles(ent.entitylastang)
                if jumpscare_entity:IsPlayer() then
                    net.Start('ignited_jumpscare_gen')
                    net.WriteEntity(puppet)
                    net.WriteBool(false)
                    net.Send(jumpscare_entity)
                    jumpscare_entity:Kill(ply)
                else
                    jumpscare_entity:NextThink(CurTime())

                    jumpscare_entity:TakeDamage(1e9, ply)
                end
                ent:RemoveCallOnRemove("RachelJumpscare"..ent:EntIndex())
            end)
        end
        if event == "Step" then
            if IsValid(ent) then
                AdvancedPillSound({
                    stringe = {"gentoi/anologhorror/ignitedones/step_1.wav", "gentoi/anologhorror/ignitedones/step_2.wav", "gentoi/anologhorror/ignitedones/step_3.wav"},
                    pitchPercent = 100,
                    soundLevel = 57
                }, ent)
            end
        end
    end,


    attack = {
        mode = 'trigger',
        func = function(ply, ent)

            local cuddd = math.random(1,2)
            local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("jumpscare"..cuddd))
            racheljackietien_jumpscare(
                ply,
                ent,
                dur,
                function()
                    ent:PillSound('jumpscare'..cuddd)
                    ent:PillAnim('jumpscare'..cuddd)
                end
            )
        end
    },


    attack2 = {
        mode = "trigger",
        func = function(ply, ent)

        end,
    },

    noragdoll=true,


    ignitedones_jentoi_pill_init=function(ply,ent, puppet)
        puppet.IsInJumpscare = 0
    end,

    reload=function(ply,ent)
    end,

    flashlight = function(ply, ent)
    end,
        
    jump = function(ply, ent) end,

    noodles_ignited_gentoi_keybinds = function(ply,ent,button)
        if SERVER then
            if button == KEY_R then

                if not GetConVar("GentoiPills_ignitedbonnie_Rushdown"):GetBool() then return end
                if ent:GetNWFloat("BonnieRushdown_Gentoi_cooldown") > CurTime() then return end
                if ent:GetNWFloat("BonnieRushdown_Gentoi_Duration") > CurTime() then return end
                if ent:GetNWBool("BonnieRushdown_Gentoi_toggle") then return end
                ent:SetNWFloat("BonnieRushdown_Gentoi_Duration", CurTime()+ GetConVar("GentoiPills_ignitedbonnie_RushdownDuration"):GetFloat())
            end
            if button == KEY_SPACE then
                if ent:GetNWFloat("glitchout_playsfx", 0) > CurTime() then return end
                ent:SetNWFloat("glitchout_playsfx", CurTime()+4)
                AdvancedPillSound({
                    stringe = "gentoi/anologhorror/ignitedones/glitchout.wav",
                    pitchPercent = 100,
                    soundLevel = 57
                }, ent)
            end
        end
    end,

    ignited_stats = {
        moveSpeed = {
            walk = 50,
            run = 540,
            ducked=20,
            jumppower = 0,
        },
    },

    ignitedones_gentoi_think = function(ply, ent)
        if SERVER then
            ent:SetNWBool("GentoiPills_ignitedbonnie_Rushdown",GetConVar("GentoiPills_ignitedbonnie_Rushdown"):GetBool())
            local speed = {
                ['walk'] = GetConVar("GentoiPills_ignitedbonnie_walkspeed"):GetFloat(),
                ['run'] = GetConVar("GentoiPills_ignitedbonnie_runspeed"):GetFloat(),
                ['ducked'] = GetConVar("GentoiPills_ignitedbonnie_crouchspeed"):GetFloat(),
                ['jumppower'] = GetConVar("GentoiPills_ignitedbonnie_jumppower"):GetFloat(),
            }

            if ent:GetPuppet():GetSequence() == ent:GetPuppet():LookupSequence("Run") and ent:GetNWFloat("BonnieRushdown_Gentoi_Duration") > CurTime() then
                local multi = GetConVar("GentoiPills_ignitedbonnie_Rushdown_speedmultiplyer"):GetFloat()
                speed.run = speed.run * multi
                ent:GetPuppet():SetPlaybackRate(multi)
            else
                ent:GetPuppet():SetPlaybackRate(1)
            end

            if ent:GetNWFloat("BonnieRushdown_Gentoi_Duration") > CurTime() then
                if not ent:GetNWBool("BonnieRushdown_Gentoi_toggle") then
                    ent:SetNWBool("BonnieRushdown_Gentoi_toggle", true)
                end
            else
                if ent:GetNWBool("BonnieRushdown_Gentoi_toggle") then
                    ent:SetNWBool("BonnieRushdown_Gentoi_toggle", false)
                    
                    local cooldown = GetConVar("GentoiPills_ignitedbonnie_RushdownCooldown"):GetFloat()
                    ent:SetNWFloat("BonnieRushdown_Gentoi_cooldown", CurTime()+ cooldown)
                    ent:SetNWFloat("BonnieRushdown_Gentoi_cooldown_max", cooldown)
                end
            end

            if IsValid(ply) and IsValid(ent) then
                ply:SetWalkSpeed(speed.walk)
                ply:SetRunSpeed(speed.run)
                ply:SetCrouchedWalkSpeed(speed.ducked)
                ply:SetJumpPower(speed.jumppower)
            end
            if ent.jumpscare_entity then
                local entity = ent.jumpscare_entity
                if IsValid(entity) then

                    local lengthofentitybody = (entity:EyePos() - entity:GetPos()):Length() /2

                    local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

                    if entity:Health() < 0.1 and entity:IsPlayer() then
                        ent.jumpscare_entity = nil
                    else
                        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                        local lengthofentitybody = ((maxs.z - mins.z)/2) * 4

                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - entity:GetUp() * lengthofentitybody)
                        entity:SetPos(NewVector)
                        entity:SetAngles(newAngle)
                    end
                end
            end
        end
    end
})
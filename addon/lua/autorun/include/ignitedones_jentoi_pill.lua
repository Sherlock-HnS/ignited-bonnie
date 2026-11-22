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

                        -- Velocidade: sempre a do Parakeet's (formTable.moveSpeed / jumpPower).
                        if self.animFreeze and not self.plyFrozen then
                            self:ApplyMoveSpeed()
                            self.plyFrozen = true
                        elseif not self.animFreeze and self.plyFrozen then
                            self:ApplyMoveSpeed()
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
        if not ent.formTable then continue end
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

    -- A HUD da pill (icone do Rushdown + cooldown) foi removida:
    -- agora quem desenha e a HUD de habilidades do gamemode (SherlockHNS.HUD).

    -- Camera do jumpscare: aberta/fechada pelo pk_pills.playHNSJumpscare.
    net.Receive('ignited_jumpscare_gen', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "ignited_jumpscare_" .. LocalPlayer():SteamID()

        if not state then
            hook.Remove('CalcView', hookID)

            local lp = LocalPlayer()
            if IsValid(lp) then
                lp:DrawViewModel(true)
            end
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

-- ---------------------------------------------------------------------
-- Jumpscare (Kill API)
-- O gamemode cuida de travas, alvo valido, cancelamento e morte
-- (SherlockHNS.KillWithDelay via pk_pills.playHNSJumpscare).
-- Aqui ficam so o alvo mais proximo e o visual do ragdoll falso.
-- ---------------------------------------------------------------------
local JUMPSCARE_RADIUS = 90

local function ConVarNumber(name, default)
    local cv = GetConVar(name)
    return cv and cv:GetFloat() or default
end

local function FindHeadPhys(ragdoll)
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)

        if IsValid(phys) then
            local boneName = ragdoll:GetBoneName(ragdoll:TranslatePhysBoneToBone(i)) or ""

            if string.find(string.lower(boneName), "head") then
                return phys
            end
        end
    end

    return ragdoll:GetPhysicsObject()
end

local function FindJumpscareTarget(ply, ent)
    local origin = ent:LocalToWorld(Vector(0, 0, 50))
    local best, bestDist

    for _, v in ipairs(ents.FindInSphere(origin, JUMPSCARE_RADIUS)) do
        if v ~= ply and v:IsPlayer() and SherlockHNS.CanTarget(v, ply) then
            local dist = v:GetPos():DistToSqr(origin)

            if not bestDist or dist < bestDist then
                best, bestDist = v, dist
            end
        end
    end

    return best
end

local function CreateVictimRagdoll(victim, duration)
    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then return end

    ragdoll:SetModel(victim:GetModel())
    ragdoll:SetPos(victim:GetPos())
    ragdoll:SetAngles(victim:GetAngles())
    ragdoll:SetSkin(victim:GetSkin() or 0)
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ragdoll:Spawn()

    if ragdoll:GetPhysicsObjectCount() <= 0 then
        ragdoll:Remove()
        return
    end

    -- esconde o ragdoll so para a propria vitima
    ragdoll:SetNWFloat("IgnitedCharacters_NoDraw", duration + CurTime())
    ragdoll:SetNWEntity("IgnitedCharacters_nodrawply", victim)

    for _, bg in ipairs(victim:GetBodyGroups()) do
        ragdoll:SetBodygroup(bg.id, victim:GetBodygroup(bg.id))
    end

    if victim.GetPlayerColor and ragdoll.SetPlayerColor then
        ragdoll:SetPlayerColor(victim:GetPlayerColor())
    end

    ragdoll:SetColor(victim:GetColor())
    ragdoll:SetMaterial(victim:GetMaterial())

    for i = 0, ragdoll:GetNumSubMaterials() - 1 do
        local sub = victim:GetSubMaterial(i)

        if sub then
            ragdoll:SetSubMaterial(i, sub)
        end
    end

    return ragdoll
end

-- Chamado no onStart do jumpscare. Retorna a funcao de limpeza, que o
-- pk_pills.playHNSJumpscare executa no fim (morte, escudo ou cancelamento).
local function StartJumpscareVisuals(ply, ent, victim, duration)
    local puppet = ent:GetPuppet()
    local hookId = "ragdoll_nosey" .. ent:EntIndex()
    local lastPos, lastAng = victim:GetPos(), victim:GetAngles()

    ent.jumpscare_entity = victim
    ent.entitylastpos = lastPos
    ent.entitylastang = lastAng
    ent.JuumpscareStart = CurTime()
    ent.jumpscareEvent = nil

    local ragdoll = CreateVictimRagdoll(victim, duration)

    victim:SetNoDraw(true)
    victim:SetNotSolid(true)

    if IsValid(ragdoll) then
        ent.CurrentJumpscareRagdoll = ragdoll
        ent:DeleteOnRemove(ragdoll)

        -- a cabeca do ragdoll acompanha a camera do puppet
        hook.Add("Think", hookId, function()
            if not IsValid(ragdoll) or not IsValid(puppet) then
                hook.Remove("Think", hookId)
                return
            end

            local cam = puppet:GetAttachment(puppet:LookupAttachment("camera"))
            local headPhys = FindHeadPhys(ragdoll)

            if cam and IsValid(headPhys) then
                headPhys:SetPos(cam.Pos)
                headPhys:SetAngles(cam.Ang)
                headPhys:Wake()
            end
        end)
    end

    return function()
        hook.Remove("Think", hookId)

        local event, forward

        if IsValid(ent) then
            event = ent.jumpscareEvent
            ent.jumpscare_entity = nil
            ent.CurrentJumpscareRagdoll = nil
        end

        if IsValid(puppet) then
            forward = puppet:GetForward()
        end

        if IsValid(victim) then
            victim:SetNoDraw(false)
            victim:SetNotSolid(false)
            victim:SetPos(lastPos)
            victim:SetAngles(lastAng)
        end

        if not IsValid(ragdoll) then return end

        -- no proximo tick a API ja resolveu: se a vitima morreu o ragdoll
        -- vira o corpo; se um escudo barrou, ele some
        timer.Simple(0, function()
            if not IsValid(ragdoll) then return end

            if IsValid(victim) and not victim:Alive() then
                if IsValid(ent) then
                    ent:DontDeleteOnRemove(ragdoll)
                end

                local headPhys = FindHeadPhys(ragdoll)

                if IsValid(headPhys) then
                    if event == "playerded" and forward then
                        headPhys:SetVelocity(forward * 9000000)
                    end

                    headPhys:Wake()
                end

                ragdoll:Fire("FadeAndRemove", nil, 10)
            else
                ragdoll:Remove()
            end
        end)
    end
end

pk_pills.packStart("TheIgnitedOnes_gentoi", "AnalogHorrorPills_gentio_ignitedones", "pills/pill_gentoi_ignitedbonnie.png")

pk_pills.register('pill_gentoi_ignitedbonnie', {

    printName='Ignited Bonnie',
    ignitedCharacter_gent = "IgnitedBonnie",
    model="models/gentoi/anologhorror/ignitedbonnie.mdl",
        
    modelScale='1.0',
        
    noragdoll = true,
    muteSteps = true,

    -- A morte passa toda pela Kill API (pk_pills.playHNSJumpscare -> KillWithDelay).
    -- O auditor nao enxerga o helper do pk_pills, entao o estado e declarado aqui.
    hnsKillAPI = true,
        
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

    -- Velocidade: unica fonte e o Parakeet's (moveSpeed / jumpPower).
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

    -- Eventos de animacao do puppet. A morte nao depende mais deles;
    -- "playerded" so avisa o visual do ragdoll que ele deve ser arremessado.
    HandleAnimEvent_g_ignitedones = function(ply, ent, event)
        if event == "playerded" or event == "playerded2" then
            if IsValid(ent) then
                ent.jumpscareEvent = event
            end
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

    -- Habilidades (Abilities API): cooldown, duracao, tecla e HUD ficam com o gamemode.
    -- Forma de funcao para ler as convars no momento em que a pill e concedida.
    hnsAbilities = function(ply, ent)
        local list = {
            {
                id       = "jumpscare",
                name     = "Jumpscare",
                key      = IN_ATTACK,
                cooldown = 0,
                color    = Color(200, 30, 30),
                order    = 10,

                OnUse = function(ply, ent, ab)
                    if not SherlockHNS or not IsValid(ent) then return false end

                    local puppet = ent:GetPuppet()
                    if not IsValid(puppet) then return false end

                    local victim = FindJumpscareTarget(ply, ent)
                    if not victim then return false end

                    local anim = "jumpscare" .. math.random(1, 2)
                    local seq = puppet:LookupSequence(anim)
                    if seq < 0 then return false end

                    local dur = puppet:SequenceDuration(seq)

                    local ok = pk_pills.playHNSJumpscare(ply, ent, victim, dur, {
                        camera    = "ignited_jumpscare_gen",
                        animation = anim,
                        sound     = anim,
                        onStart   = function(v)
                            return StartJumpscareVisuals(ply, ent, v, dur)
                        end,
                    })

                    if ok == false then return false end
                end,
            },

            -- Som de glitch na tecla de pulo (so efeito sonoro, a pill nao pula).
            {
                id       = "glitch",
                name     = "Glitch",
                key      = IN_JUMP,
                cooldown = 4,
                anyRound = true,
                hidden   = true,

                OnUse = function(ply, ent, ab)
                    AdvancedPillSound({
                        stringe = "gentoi/anologhorror/ignitedones/glitchout.wav",
                        pitchPercent = 100,
                        soundLevel = 57
                    }, ent)
                end,
            },
        }

        if ConVarNumber("GentoiPills_ignitedbonnie_Rushdown", 1) ~= 0 then
            table.insert(list, {
                id       = "rushdown",
                name     = "Rushdown",
                icon     = "icons/fasterboost_gent_ignited.png",
                key      = IN_RELOAD,
                keyLabel = "R",
                toggle   = true,
                duration = math.max(ConVarNumber("GentoiPills_ignitedbonnie_RushdownDuration", 1.5), 0.1),
                cooldown = ConVarNumber("GentoiPills_ignitedbonnie_RushdownCooldown", 25),
                color    = Color(255, 60, 60),
                order    = 20,

                OnUse = function(ply, ent, ab)
                    if not IsValid(ent) then return false end

                    -- Multiplica a corrida base do Parakeet's pelo tempo da habilidade.
                    -- Override de admin (speedOverrides) continua tendo prioridade.
                    local mult = ConVarNumber("GentoiPills_ignitedbonnie_Rushdown_speedmultiplyer", 2.5)
                    local sp = pk_pills.getMoveSpeed(ent.formTable, ply)

                    ent.rushdownMult = mult
                    pk_pills.setCostumeMoveSpeed(ent, nil, sp.run * mult, nil, nil)
                end,

                OnEnd = function(ply, ent, ab, reason)
                    if not IsValid(ent) then return end

                    ent.rushdownMult = nil
                    pk_pills.setCostumeMoveSpeed(ent, nil, nil, nil, nil)
                end,
            })
        end

        return list
    end,

    noragdoll=true,


    ignitedones_jentoi_pill_init=function(ply,ent, puppet)
        -- Mantido: a existencia deste campo ativa o Think proprio do addon.
    end,

    flashlight = function(ply, ent)
    end,
        
    jump = function(ply, ent) end,

    ignitedones_gentoi_think = function(ply, ent)
        if not SERVER then return end

        local puppet = ent:GetPuppet()
        if not IsValid(puppet) then return end

        -- Animacao de corrida acelerada durante o Rushdown
        if ent.rushdownMult and puppet:GetSequence() == puppet:LookupSequence("Run") then
            puppet:SetPlaybackRate(ent.rushdownMult)
        else
            puppet:SetPlaybackRate(1)
        end

        -- Durante o jumpscare, a vitima (travada pela API) e puxada ate a camera
        local victim = ent.jumpscare_entity

        if IsValid(victim) and victim:Alive() and ent.JuumpscareStart then
            local cam = puppet:GetAttachment(puppet:LookupAttachment('camera'))

            if cam then
                local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                local lengthofentitybody = ((maxs.z - mins.z) / 2) * 4

                local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - victim:GetUp() * lengthofentitybody)

                victim:SetPos(NewVector)
                victim:SetAngles(newAngle)
            end
        end
    end
})

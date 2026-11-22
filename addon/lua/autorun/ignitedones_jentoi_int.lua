if SERVER then
    hook.Add("OnEntityCreated", "Bonnie_ModelInitialize_OM", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            if ent:GetModel() ~= "models/gentoi/anologhorror/ignitedbonnie.mdl" then return end

            local function CreateEye(att)

                local light = ents.Create("env_projectedtexture")
                if IsValid(light) then
                    light:SetKeyValue("lightfov", "60")
                    light:SetKeyValue("farz", "500")
                    light:SetKeyValue("lightcolor", "255 0 0")
                    light:SetKeyValue("brightness", "8")
                    light:Spawn()

                    light:Input("SpotlightTexture", NULL, NULL, "effects/flashlight001")
                    light:Input("TurnOn")

                    light:SetParent(ent, att)
                    light:SetLocalPos(vector_origin)
                    light:SetLocalAngles(Angle(0,180,0))

                    ent:DeleteOnRemove(light)
                end

                local glow = ents.Create("env_sprite")
                if IsValid(glow) then
                    glow:SetKeyValue("model", "sprites/light_glow02_add.vmt")
                    glow:SetKeyValue("rendermode", "5")
                    
                    glow:SetKeyValue("rendercolor", "2555 0 0")

                    glow:SetKeyValue("scale", "0.15")
                    glow:SetKeyValue("GlowProxySize", "32")

                    glow:Spawn()

                    glow:SetParent(ent, att)
                    glow:SetLocalPos(Vector(-1,0,0))

                    ent:DeleteOnRemove(glow)
                end
            end

            local leftAtt = ent:LookupAttachment("LeftEye")
            local rightAtt = ent:LookupAttachment("RightEye")

            if leftAtt == 0 or rightAtt == 0 then return end

            CreateEye(leftAtt)
            CreateEye(rightAtt)

        end)
    end)
end
if !pcall(require,"pk_pills") then
    if SERVER then
        hook.Add("PlayerInitialSpawn","pk_pill_extfail_cl",function(ply)
            if game.SinglePlayer() || ply:IsListenServerHost() then
                ply:SendLua('notification.AddLegacy("One or more pill extensions failed to load. Did you forget to install Parakeet\'s Pill Pack?",NOTIFY_ERROR,30)')
            end
        end)
        hook.Add("Initialize","pk_pill_extfail_sv",function(ply)
            print("[ALERT] One or more pill extensions failed to load. Did you forget to install Enhanced Parakeet's Pill Base?")
        end)
    end
    return
end

AddCSLuaFile()
include("include/ignitedones_jentoi_pill.lua")



if SERVER then

    local function CreateAConvVarConstant(VarName, DefaultSetting, Text,min,max)
        CreateConVar(VarName, DefaultSetting, FCVAR_ARCHIVE, Text, min, max)     
    end

    -- Velocidade (walk/run/crouch/jump) nao tem mais convars: vem do Parakeet's.
    -- Restam so os ajustes do Rushdown, lidos pela habilidade da pill.
    CreateAConvVarConstant("GentoiPills_ignitedbonnie_Rushdown",1,"", 0,1)  
    CreateAConvVarConstant("GentoiPills_ignitedbonnie_RushdownDuration",1.5,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_ignitedbonnie_RushdownCooldown",25,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_ignitedbonnie_Rushdown_speedmultiplyer",2.5,"", 0,1e9) 
else

    hook.Add("PopulateToolMenu", "Gentoi_pill_ignitedbonnie_populate", function()   

        spawnmenu.AddToolMenuOption("Gentoi Pill Settings", "Pills", "Gentoi_pills_ignitedbonnie", "Ignited Bonnie", "", "", function(panel)

            panel:Help("------------ ignitedbonnie ------------")


            panel:Help("-- Preset --")
            local presettable = {
                name = "Gentoi_pills_ignitedbonnie_presets",

                listofdefualtconvars = {

                    "GentoiPills_ignitedbonnie_Rushdown",
                    "GentoiPills_ignitedbonnie_RushdownDuration",
                    "GentoiPills_ignitedbonnie_RushdownCooldown",
                    "GentoiPills_ignitedbonnie_Rushdown_speedmultiplyer"
                }
            }

            local presetName = presettable.name
            local listofdefualtconvars = presettable.listofdefualtconvars

            local combo = vgui.Create("DComboBox")
            combo:Dock(TOP)
            combo:SetTall(30)
            combo:SetValue("Default")

            local saveButton = vgui.Create("DButton")
            saveButton:Dock(TOP)
            saveButton:SetTall(25)
            saveButton:SetText("Save Current")

            local editButton = vgui.Create("DButton")
            editButton:Dock(TOP)
            editButton:SetTall(25)
            editButton:SetText("Edit Presets")

            panel:AddItem(combo)
            panel:AddItem(saveButton)
            panel:AddItem(editButton)

            local PRESET_FOLDER = "OM_LNZ"
            local PRESET_FILE = PRESET_FOLDER .. "/preset_" .. presetName .. ".json"

            local function EnsureFolder()
                if not file.Exists(PRESET_FOLDER, "DATA") then
                    file.CreateDir(PRESET_FOLDER)
                end
            end

            local function LoadPresets()
                EnsureFolder()

                if not file.Exists(PRESET_FILE, "DATA") then
                    return {}
                end

                return util.JSONToTable(file.Read(PRESET_FILE, "DATA")) or {}
            end

            local function SavePresets(presets)
                EnsureFolder()
                file.Write(PRESET_FILE, util.TableToJSON(presets, true))
            end

            local defaultValues = {}

            for _, cvar in ipairs(listofdefualtconvars) do
                local cv = GetConVar(cvar)

                if cv then
                    defaultValues[cvar] = cv:GetDefault()
                end
            end

            local function RefreshDropdown()
                combo:Clear()
                combo:AddChoice("Default")

                for name in pairs(LoadPresets()) do
                    combo:AddChoice(name)
                end
            end

            RefreshDropdown()

            function combo:OnSelect(_, value)
                if value == "Default" then
                    for cvar, default in pairs(defaultValues) do
                        RunConsoleCommand(cvar, tostring(default))
                    end

                    return
                end

                local preset = LoadPresets()[value]
                if not preset then return end

                for cvar, value in pairs(preset) do
                    -- ignora convars antigas (ex.: velocidade) de presets ja salvos
                    if defaultValues[cvar] ~= nil then
                        RunConsoleCommand(cvar, tostring(value))
                    end
                end
            end

            saveButton.DoClick = function()
                Derma_StringRequest(
                    "Save Preset",
                    "Preset name:",
                    "",
                    function(name)
                        if not name or name == "" then return end

                        local presets = LoadPresets()
                        presets[name] = {}

                        for _, cvar in ipairs(listofdefualtconvars) do
                            local cv = GetConVar(cvar)

                            if cv then
                                presets[name][cvar] = cv:GetString()
                            end
                        end

                        SavePresets(presets)
                        RefreshDropdown()
                        combo:SetValue(name)
                    end
                )
            end

            local function OpenPresetEditor()
                local presets = LoadPresets()

                local frame = vgui.Create("DFrame")
                frame:SetSize(550, 420)
                frame:Center()
                frame:SetTitle("Preset Editor - " .. presetName)
                frame:MakePopup()

                local list = vgui.Create("DListView", frame)
                list:Dock(LEFT)
                list:SetWide(160)
                list:AddColumn("Presets")

                for name in pairs(presets) do
                    list:AddLine(name)
                end

                local right = vgui.Create("DScrollPanel", frame)
                right:Dock(FILL)

                local selected

                list.OnRowSelected = function(_, _, row)
                    right:Clear()
                    selected = row:GetColumnText(1)

                    for cvar, value in pairs(presets[selected] or {}) do
                        local rowPanel = right:Add("DPanel")
                        rowPanel:Dock(TOP)
                        rowPanel:SetTall(30)
                        rowPanel:DockMargin(4, 4, 4, 4)

                        local label = rowPanel:Add("DLabel")
                        label:Dock(LEFT)
                        label:SetWide(250)
                        label:SetText(cvar)

                        local entry = rowPanel:Add("DTextEntry")
                        entry:Dock(FILL)
                        entry:SetValue(value)

                        entry.OnChange = function(self)
                            presets[selected][cvar] = self:GetValue()
                        end
                    end
                end

                local bottom = vgui.Create("DPanel", frame)
                bottom:Dock(BOTTOM)
                bottom:SetTall(35)

                local save = bottom:Add("DButton")
                save:Dock(LEFT)
                save:SetWide(100)
                save:SetText("Save")
                save.DoClick = function()
                    SavePresets(presets)
                    RefreshDropdown()
                end

                local delete = bottom:Add("DButton")
                delete:Dock(RIGHT)
                delete:SetWide(100)
                delete:SetText("Delete")
                delete.DoClick = function()
                    if not selected then return end

                    presets[selected] = nil
                    SavePresets(presets)

                    frame:Close()
                    RefreshDropdown()
                end

                local rename = bottom:Add("DButton")
                rename:Dock(FILL)
                rename:SetText("Rename")
                rename.DoClick = function()
                    if not selected then return end

                    Derma_StringRequest(
                        "Rename Preset",
                        "New name:",
                        selected,
                        function(name)
                            if not name or name == "" or presets[name] then return end

                            presets[name] = presets[selected]
                            presets[selected] = nil

                            SavePresets(presets)
                            frame:Close()
                            RefreshDropdown()
                        end
                    )
                end
            end

            editButton.DoClick = OpenPresetEditor

            panel:Help("-- Rushdown --")
            panel:CheckBox("Rushdown", "GentoiPills_ignitedbonnie_Rushdown")
            panel:NumSlider("Rushdown Duration", "GentoiPills_ignitedbonnie_RushdownDuration", 0, 10)
            panel:NumSlider("Rushdown Cooldown", "GentoiPills_ignitedbonnie_RushdownCooldown", 0, 60)
            panel:NumSlider("Rushdown Speed Multiplyer", "GentoiPills_ignitedbonnie_Rushdown_speedmultiplyer", 0, 10)

            panel:Help("")

        end)        
    end)
end

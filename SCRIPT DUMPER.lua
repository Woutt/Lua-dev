local CoreGui, CorePackages, Players, RunService = game:GetService("CoreGui"), game:GetService("CorePackages"), game:GetService("Players"), game:GetService("RunService")
local Result = "<roblox xmlns:xmime=\"http://www.w3.org/2005/05/xmlmime\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"http://www.roblox.com/roblox.xsd\" version=\"4\">"
local Decompiled, Scripts = 0, {}
local DecompiledScripts = {}
local Instances = {
    "LocalScript";
    "ModuleScript";
    "RemoteEvent";
    "RemoteFunction";
}
local Services = {
    "StarterPlayerScripts";
    "StarterCharacterScripts";
}
local SpecialCharacters = {
    ["<"] = "&lt;";
    [">"] = "&gt;";
    ["&"] = "&amp;";
    ["\""] = "&quot;";
    ["'"] = "&apos;";
}

if not RunService:IsRunning() then --// So you can dump scripts in games that do a bit of funny business (I'm mainly trying to patch the things I come up with)
    local function IsNetworkOwner(Object)
        if Object:IsA("BasePart") and isnetworkowner(Object) then
            return true
        elseif not Object.Parent then
            return false
        end

        return IsNetworkOwner(Object.Parent)
    end

    game.DescendantAdded:Connect(function(Obj)
        if Obj:IsA("LocalScript") then
            --if not Obj:IsDescendantOf(workspace) then --// when will I be able to spoof network replication :(
                Obj.Disabled = true --// Not my fault if a game dev is actually smart (or maybe it is)
            --end
        end
    end)

    --[[repeat
        task.wait(0.5) --// There's no rush
    until RunService:IsRunning()]]

    game.Loaded:Wait()
end

local LocalPlayer = Players.LocalPlayer
local InstancesCreated, InstancesTotal = 0, #game:GetDescendants()

local function GiveColour(Current, Max)
    return (Current < Max * 0.25 and "@@RED@@") or (Current < Max * 0.5 and "@@YELLOW@@") or (Current < Max * 0.75 and "@@CYAN@@") or "@@GREEN@@"
end

local function ProgressBar(Current, Max)
    local Size = 100
    local Progress, Percentage = math.floor(Size * Current / Max), math.floor(100 * Current / Max)
    rconsoleprint(GiveColour(Current, Max))
    rconsoleprint(("\13%s%s %s"):format(("#"):rep(Progress), ("."):rep(Size - Progress), Percentage.."%"))
    rconsoleprint("@@WHITE@@")
end

local function CheckObject(Object)
    for _, v in next, Instances do
        if Object:FindFirstChildWhichIsA(v, true) or Object:IsA(v) then
            return true
        end
    end

    return false
end

local function FindService(Service)
    local Success, Response = pcall(game.FindService, game, Service)

    return Success and Response
end

local function GetClassName(Object)
    local ClassName = Object.ClassName

    if table.find(Instances, ClassName) or table.find(Services, ClassName) or FindService(ClassName) then
        return ClassName
    end

    return "Folder"
end

local function SteralizeString(String)
    return String:gsub("['\"<>&]", SpecialCharacters)
end

local function MakeInstance(Object)
    local ClassName = Object.ClassName
    local IntResult = ("<Item class=\"%s\" referent=\"RBX%s\"><Properties><string name=\"Name\">%s</string>"):format(GetClassName(Object), Object:GetDebugId(0), SteralizeString(Object.Name))
    ProgressBar(InstancesCreated, InstancesTotal)
    
    if (ClassName == "LocalScript" or ClassName == "ModuleScript") then
        local Hash = getscripthash(Object)
        local Source = Hash and (DecompiledScripts[Hash] or "--// Not Found") or "--// Script has no bytecode"

        if ClassName == "LocalScript" then
            IntResult ..= ("<bool name=\"Disabled\">%s</bool>"):format(tostring(Object.Disabled))
        end
        
        IntResult ..= ([==[<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>]==]):format(("--// Hash: %s\n%s"):format(Hash or "nil", Source))
    end

    IntResult ..= "</Properties>"
    for _, v in next, Object:GetChildren() do
        if v ~= nil and v ~= game and CheckObject(v) then --// Give me stength
            IntResult ..= MakeInstance(v)
        end
    end

    IntResult ..= "</Item>"
    InstancesCreated += 1

    return IntResult
end

local function Save()
    local Place = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    Result ..= "</roblox>"
    
    rconsoleprint("\n\nWriting to file\n")
    ProgressBar(0, 1)
    writefile(("Scripts for %s (%s) [%s].rbxlx"):format(tostring(Place and Place.Name or "Unknown Game"):gsub("[^%w%s]", ""), game.PlaceId, game.PlaceVersion), Result)
    ProgressBar(1, 1)
end

local function GetScripts(Table)
    for i, v in next, Table do
        ProgressBar(i, #Table)

        if (not v:IsA("LocalScript") and not v:IsA("ModuleScript")) or (v:IsDescendantOf(CoreGui) or v:IsDescendantOf(CorePackages)) or table.find(Scripts, v) then
            continue;
        end
        
        table.insert(Scripts, v)
    end

    rconsoleprint("\n")
end

local function DecompileScripts()
    local Thread = coroutine.running()
    local RunningThreads = 0
    local Threads = 4

    rconsoleprint(("\nDecompiling Scripts [%s]\n"):format(#Scripts))

    for i = 1, Threads do
        task.spawn(function()
            local Previous = i
            RunningThreads += 1

            while true do
                local Script = Scripts[Previous]
                if not Script then
                    break;
                end

                local Hash = getscripthash(Script)

                if Hash and not DecompiledScripts[Hash] then
                    DecompiledScripts[Hash] = decompile(Script) or "--// Failed to decompile"
                end

                Decompiled += 1
                Previous += Threads
                ProgressBar(Decompiled, #Scripts)
            end

            RunningThreads -= 1

            if RunningThreads == 0 then
                ProgressBar(1, 1)
                coroutine.resume(Thread, true)
            end
        end)
    end

    return coroutine.yield()
end

rconsoleclear()
rconsolename("Script Dumper")
rconsoleprint("Collecting Scripts\n")
GetScripts(getscripts())
GetScripts(getnilinstances())
GetScripts(game:GetDescendants())
DecompileScripts()
rconsoleprint("\n\nCreating XML\n")
ProgressBar(0, 1)

for i, v in next, game:GetChildren() do
    if v == CoreGui or v == CorePackages then
        continue;
    end

    Result ..= MakeInstance(v)
end

Result..= MakeInstance({
    ClassName = "Folder";
    Name = "Nil Instances";
    Parent = game;
    GetChildren = function()
        return getnilinstances()
    end;
    GetDebugId = function()
        return Instance.new("Folder"):GetDebugId(0)
    end;
    FindFirstChildWhichIsA = function()
        return true
    end;
    IsA = function(_, IsA)
        return IsA == "Folder"
    end
})

ProgressBar(1, 1)
Save()
rconsoleprint("\n\nFinished")
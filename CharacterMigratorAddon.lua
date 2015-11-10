local myJSON = json.json
CHDMP = CHDMP or {}
local private = {}

function private.GetGlobalInfo()
    local retTbl            = {}
    retTbl.locale           = GetLocale();
    retTbl.realm            = GetRealmName();
    retTbl.realmlist        = GetCVar("realmList");
    local version, build, date, tocversion = GetBuildInfo();
    retTbl.clientbuild      = build;
    return retTbl;
end
function private.GetUnitInfo()
    local retTbl            = {}
    retTbl.name             = UnitName("player");
    local _, class          = UnitClass("player");
    retTbl.class            = class;
    retTbl.level            = UnitLevel("player");
    local _,race            = UnitRace("player");
    retTbl.race             = race;
    retTbl.gender           = UnitSex("player");
    local honorableKills    = GetPVPLifetimeStats()
    retTbl.kills            = honorableKills;
    retTbl.honor            = GetHonorCurrency();
    retTbl.arenapoints      = GetArenaCurrency();
    retTbl.money            = GetMoney();
    retTbl.specs            = GetNumTalentGroups();
    return retTbl;
end
function private.GetSpellData()
    local retTbl = {}
    for i = 1, MAX_SKILLLINE_TABS do
        local name, _, _, offset, numSpells = GetSpellTabInfo(i);
        if not name then
            break;
        end
        for s = offset + 1, offset + numSpells do
            spellInfo = GetSpellLink(s, BOOKTYPE_SPELL);
            if spellInfo ~= nil then
                for spellid in string.gmatch(GetSpellLink(s, BOOKTYPE_SPELL), ".-Hspell:(%d+).*") do
                    retTbl[spellid] = {["ID"] = i, ["S"] = spellid}
                end
            end
        end
    end
    private.ILog("Copying spells...");
    return retTbl;
end
function private.GetGlyphData()
    local retTbl = {}
    for i = 1, GetNumTalentGroups() do
        retTbl[i] = {}
        local curid = {[1] = 1,[2] = 1}
        for j = 1, 6 do
            local _, glyphType, glyphSpellID, _ = GetGlyphSocketInfo(j,i);
            if not retTbl[i][glyphType] then
                retTbl[i][glyphType] = {}
            end
            if not glyphSpellID then
                glyphSpellID = -1;
            end
            retTbl[i][glyphType][curid[glyphType]] = glyphSpellID;
            curid[glyphType] = curid[glyphType]+1;
        end
    end
    private.ILog("Copying glyphs...");
    return retTbl;
end
function private.GetCurrencyData()
    local retTbl = {}
    for i = 1, GetCurrencyListSize() do
        local name, _, _, _, _, count, _, _, itemID = GetCurrencyListInfo(i)
        retTbl[i] = {['C'] = count, ['I'] = itemID};
    end
    return retTbl;
end
function private.GetMACData()
    local retTbl = {}
    for i = 1, GetNumCompanions("MOUNT") do
        local _, _, M = GetCompanionInfo("MOUNT", i);
        retTbl["M:"..i] = M;
    end
    private.ILog("Copying mounts...");
    return retTbl;
end

function private.GetMACData2()
    local retTbl = {}
    for i = 1, GetNumCompanions("CRITTER") do
        local _, _, C = GetCompanionInfo("CRITTER", i);
        retTbl["C:"..i] = C;
    end
    private.ILog("Copying critters...");
    return retTbl;
end

function private.GetAchievements()
    local retTbl = {}
    for _, j in pairs(CHDMP.AchievementIds) do
        IDNumber, _, _,Completed, Month, Day, Year, _, _, _, _ = GetAchievementInfo(j)
        if IDNumber and Completed then
            local posixtime = time{year = 2000 + Year, month = Month, day = Day};
            if posixtime then
                retTbl[IDNumber] = {["I"] = IDNumber, ["D"] = posixtime}
            end
        end
    end
    private.ILog("Copying achievements...");
    return retTbl;
end
function private.GetRepData()
    local retTbl = {}
    for i = 1, GetNumFactions() do
        local name, _, _, _, _, earnedValue, _, canToggleAtWar, _, _, _, _, _ = GetFactionInfo(i)
        retTbl[i] = {["N"] = name, ["V"] = earnedValue, ["F"] = bit.bor(((not canToggleAtWar) and 16) or 0)}
    end
    private.ILog("Copying reputations...");
    return retTbl;
end
function private.GetIData()
    local retTbl = {}
    for bag = 0, 11 do
        for slot = 1, GetContainerNumSlots(bag) do
            ItemLink = GetContainerItemLink(bag, slot)
            if ItemLink then
                local texture, count, locked, quality, readable = GetContainerItemInfo(bag, slot);
                local Tbag = bag + 1000;
                for entry, chant, Gem1, Gem2, Gem3, unk1, unk2, unk3, lvl1 in string.gmatch(ItemLink,".-Hitem:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+).*") do
                    retTbl[Tbag..":"..slot] = {["B"] = Tbag,["S"] = slot, ["I"] = entry, ["C"] = count, ["G1"] = Gem1, ["G2"] = Gem2, ["G3"] = Gem3};
                end
            end
        end
    end
    private.ILog("Copying items...");
    return retTbl;
end

function private.GetIData2()
    local retTbl = {}
    for i = 1, 74 do
        itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            count = GetInventoryItemCount("player",i)
            for entry, chant, Gem1, Gem2, Gem3,unk1,unk2,unk3,lvl1 in string.gmatch(itemLink,".-Hitem:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+).*") do
                retTbl["0000:"..i] =  {["I"] = entry, ["C"] = count, ["G1"] = Gem1, ["G2"] = Gem2, ["G3"] = Gem3};
            end
        end
    end
    private.ILog("Copying gear...");
    return retTbl;
end

function private.GetSkillData()
    local retTbl = {}
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, skillMaxRank, _, _, _, _, _, _ = GetSkillLineInfo(i)
        retTbl[i] = {["N"] = skillName,["C"] = skillRank,["M"] = skillMaxRank}
    end
    return retTbl;
end
function private.CreateWoWCharacterMigratorAddon()
    private.dmp             = {};
    private.dmp.ginf        = private.trycall(private.GetGlobalInfo, private.ErrLog)    or {};
    private.dmp.uinf        = private.trycall(private.GetUnitInfo, private.ErrLog)      or {};
    private.dmp.rep         = private.trycall(private.GetRepData, private.ErrLog)       or {};
    private.dmp.achiev      = private.trycall(private.GetAchievements, private.ErrLog)  or {};
    private.dmp.glyphs      = private.trycall(private.GetGlyphData, private.ErrLog)     or {};
    private.dmp.monturas    = private.trycall(private.GetMACData, private.ErrLog)       or {};
	private.dmp.creaturas   = private.trycall(private.GetMACData2, private.ErrLog)       or {};
    private.dmp.spells      = private.trycall(private.GetSpellData, private.ErrLog)     or {};
    private.dmp.skills      = private.trycall(private.GetSkillData, private.ErrLog)     or {};
    private.dmp.items       = private.trycall(private.GetIData, private.ErrLog)         or {};
	private.dmp.equipo      = private.trycall(private.GetIData2, private.ErrLog)         or {};
    private.dmp.currency    = private.trycall(private.GetCurrencyData, private.ErrLog)  or {};
    return myJSON.encode(private.dmp);
    end
function private.Log(str_in)
    print("\124c0080C0FF  "..str_in.."\124r");
end
function private.ErrLog(err_in)
    private.errlog = private.errlog or ""
    private.errlog = private.errlog .. "err=" .. b64_enc(err_in) .. "\n"
    print("\124c00FF0000"..(err_in or "nil").."\124r");
end
function private.CharacterMigratorAddon()
    return private.CreateWoWCharacterMigratorAddon();
end
function private.ILog(str_in)
    print("\124c0080FF80"..str_in.."\124r");
end
function private.trycall(f,herr)
    local status, result = xpcall(f,herr)
    if status then
        return result;
    end
    return status;
end
function private.SaveCharData(data_in)
    private.ILog("Migration finished in \WTF\Account\%Username%\SavedVariables%\CharacterMigratorAddon.lua ");
    CHDMP_DATA  = data_in
    CHDMP_KEY   = Sha1(data_in)
end
function private.TradeSkillFrame_OnShow_Hook(frame, force)
    if private.done == true then
        return
    end
    if frame and frame.GetName and frame:GetName() == "TradeSkillFrame" then
        local isLink, _ = IsTradeSkillLinked();
        if isLink == nil then
            local link = GetTradeSkillListLink();
            if not link then
                return
            end
            local skillname = link:match("%[(.-)%]");
            private.dmp = private.dmp or {};
            private.dmp.skilllink = private.dmp.skilllink or {};
            private.dmp.skilllink[skillname] = link;
            print("TradeSkillFrame_Show",skillname,link)
            private.SaveCharData(private.CharacterMigratorAddon())
        end
    end
end
SLASH_CHDMP1 = "/dps";
SlashCmdList["CHDMP"] = function(msg)
    if msg == "done" then
        private.done = true;
        return;
    elseif msg == "help" then
        return;
    else
        private.done = false;
    end
    if not private.tradeskillframehooked then
        hooksecurefunc(_G, "ShowUIPanel", private.TradeSkillFrame_OnShow_Hook);
        private.tradeskillframehooked = true;
    end
    --private.SaveCharData(private.CharacterMigratorAddon())
	private.SaveCharData(b64_enc(private.CharacterMigratorAddon()))
end

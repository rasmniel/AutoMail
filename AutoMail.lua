-- ==================== --
--	AUTOMAIL FUNCTIONS  --
-- ==================== --

-- Assess all mail to claim their contents and determine whether to delete them or not.
SLASH_AUTOMAIL1 = "/automail"
SlashCmdList.AUTOMAIL = function (arg)
	whitelist = Split(arg, ", ")
	mails = GetInboxNumItems()
	if mails > 0 then
		-- Acquire enclosed item from first available mail or delete the mail if it contains nothing.
		message = ""
		for i = 1, mails, 1 do
			claimed, content = TryClaimMailContent(i, whitelist)
			if claimed then
				message = "Mail contains " .. content
				break
			end	
		end
		-- Print the resulting mail transaction to the user.
		Print(message)
	else
		CloseMail()
	end
end

-- Claims the content of a mail provided it is free. Returns the status of the mail before any content was claimed.
function TryClaimMailContent(index, whitelist)
	packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, wasReturned, textCreated = GetInboxHeaderInfo(index)
	claimed = false
	contentString = ""
	-- If sender is whitelisted, leave their mail for the player.
	if IsWhitelisted(whitelist, sender) then
		return false
	end
	-- Assess mail content.
	if money > 0 then
		-- Take money.
		contentString = GetMoneyString(money)
		TakeInboxMoney(index)
		claimed = true
	elseif itemCount and itemCount > 0 then
		-- Take item.
		contentString = AppendIfNotEmpty(contentString, " and ")
		contentString = GetNameFromIcon(packageIcon)
		if CODAmount == 0 then 
			TakeInboxItem(index)
			claimed = true
		else
			contentString = contentString .. " awaiting " .. GetMoneyString(CODAmount) .. " COD"
		end
	else
		-- Identify as mail spam.
		contentString = "spam"
		DeleteInboxItem(index)
		claimed = true
		if not wasRead then
			AddIgnore(sender)
		end
	end
	-- Append sender's name to content string.
	contentString = contentString .. " from " .. sender
	return claimed, contentString
end

-- Get a string representing the trinity of coins from an arbitrary amount of copper.
function GetMoneyString(copper)
	copper = tonumber(copper)
	gold, silver = 0
	if copper > 0 then
		-- Calculate gold, silver and copper values.
		gold = math.floor(copper / 10000)
		copper = copper - (gold * 10000)
		silver = math.floor(copper / 100)
		copper = copper - (silver * 100)
	end
	-- Construct money string.
	moneyString = ""
	if gold > 0 then
		moneyString = gold .. "g"
	end
	if silver > 0 then
		moneyString = AppendIfNotEmpty(moneyString, " ")
		affix = silver .. "s"
		moneyString = moneyString .. affix
	end
	if copper > 0 then
		moneyString = AppendIfNotEmpty(moneyString, " ")
		affix = copper .. "c"
		moneyString = moneyString .. affix
	end
	return moneyString
end

-- Interpret the item name from the icon path.
function GetNameFromIcon(icon)
	startChar = string.find(icon, "_%u") + 1
	endChar = string.find(icon, "_%d")
	endChar = endChar and endChar - 1 or string.len(icon)
	icon = string.sub(icon, startChar, endChar)
	icon = string.gsub(icon, "_", " ")
	return icon
end

-- Determine whether a sender is whitelisted.
function IsWhitelisted(whitelist, sender)
	for i = 0, table.getn(whitelist), 1 do
		if sender == whitelist[i] then
			return true
		end
	end
end


-- ============================== --
--	HELPER AND UTILITY FUNCTIONS  --
-- ============================== --

-- Splits a string separated by a delimiter into an array of strings.
function Split(str, delimiter)
	array = {}
	n = string.len(str)
	for i = 0, n, 1 do
		index = string.find(str, delimiter)
		if index then
			name = string.sub(str, 0, index - 1)
			str = string.sub(str, index + 2)
			array[i] = name
		elseif table.getn(array) > 0 then
			array[i] = str
			break
		else
			break
		end
	end
	return array
end

-- Appends an affix to a base string, if the base is not an empty string.
function AppendIfNotEmpty(base, affix)
	return string.len(base) > 0 and base .. affix or ""
end

-- Print a message to the console, if it exists.
function Print(message)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end
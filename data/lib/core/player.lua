-- Functions from The Forgotten Server
local foodCondition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)

function Player.feed(self, food)
	local condition = self:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
	if condition then
		condition:setTicks(condition:getTicks() + (food * 1000))
	else
		local vocation = self:getVocation()
		if not vocation then
			return nil
		end

		foodCondition:setTicks(food * 1000)
		foodCondition:setParameter(CONDITION_PARAM_HEALTHGAIN, vocation:getHealthGainAmount())
		foodCondition:setParameter(CONDITION_PARAM_HEALTHTICKS, vocation:getHealthGainTicks())
		foodCondition:setParameter(CONDITION_PARAM_MANAGAIN, vocation:getManaGainAmount())
		foodCondition:setParameter(CONDITION_PARAM_MANATICKS, vocation:getManaGainTicks())

		self:addCondition(foodCondition)
	end
	return true
end

function Player.getClosestFreePosition(self, position, extended)
	if self:getGroup():getAccess() and self:getAccountType() >= ACCOUNT_TYPE_GOD then
		return position
	end
	return Creature.getClosestFreePosition(self, position, extended)
end

function Player.getDepotItems(self, depotId)
	return self:getDepotChest(depotId, true):getItemHoldingCount()
end

function Player.hasFlag(self, flag)
	return self:getGroup():hasFlag(flag)
end

function Player.hasCustomFlag(self, customflag)
	return self:getGroup():hasCustomFlag(customflag)
end

function Player.isPremium(self)
	return self:getPremiumDays() > 0 or configManager.getBoolean(configKeys.FREE_PREMIUM)
end

function Player.isPromoted(self)
	local vocation = self:getVocation()
	local promotedVocation = vocation:getPromotion()
	promotedVocation = promotedVocation and promotedVocation:getId() or 0

	return promotedVocation == 0 and vocation:getId() ~= promotedVocation
end

function Player.sendCancelMessage(self, message)
	if type(message) == "number" then
		message = Game.getReturnMessage(message)
	end
	return self:sendTextMessage(MESSAGE_FAILURE, message)
end

function Player.isUsingOtClient(self)
	return self:getClient().os >= CLIENTOS_OTCLIENT_LINUX
end

function Player.sendExtendedOpcode(self, opcode, buffer)
	if not self:isUsingOtClient() then
		return false
	end

	local networkMessage = NetworkMessage()
	networkMessage:addByte(0x32)
	networkMessage:addByte(opcode)
	networkMessage:addString(buffer)
	networkMessage:sendToPlayer(self)
	networkMessage:delete()
	return true
end

APPLY_SKILL_MULTIPLIER = true
local addSkillTriesFunc = Player.addSkillTries
function Player.addSkillTries(...)
	APPLY_SKILL_MULTIPLIER = false
	local ret = addSkillTriesFunc(...)
	APPLY_SKILL_MULTIPLIER = true
	return ret
end

local addManaSpentFunc = Player.addManaSpent
function Player.addManaSpent(...)
	APPLY_SKILL_MULTIPLIER = false
	local ret = addManaSpentFunc(...)
	APPLY_SKILL_MULTIPLIER = true
	return ret
end

-- Functions From OTServBR-Global
function Player.allowMovement(self, allow)
	return self:setStorageValue(STORAGE.blockMovementStorage, allow and -1 or 1)
end

function Player.addFamePoint(self)
	local points = self:getStorageValue(SPIKE_FAME_POINTS)
	local current = math.max(0, points)
	self:setStorageValue(SPIKE_FAME_POINTS, current + 1)
	self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have received a fame point.")
end

function Player.getFamePoints(self)
	local points = self:getStorageValue(SPIKE_FAME_POINTS)
	return math.max(0, points)
end

function Player.removeFamePoints(self, amount)
	local points = self:getStorageValue(SPIKE_FAME_POINTS)
	local current = math.max(0, points)
	self:setStorageValue(SPIKE_FAME_POINTS, current - amount)
end

function Player.depositMoney(self, amount)
	if not self:removeMoney(amount) then
		return false
	end

	self:setBankBalance(self:getBankBalance() + amount)
	return true
end

function Player.transferMoneyTo(self, target, amount)
	if not target then
		return false
	end

	-- See if you can afford this transfer
	local balance = self:getBankBalance()
	if amount > balance then
		return false
	end

	-- See if player is online
	local targetPlayer = Player(target)
	if targetPlayer then
		targetPlayer:setBankBalance(targetPlayer:getBankBalance() + amount)
	else
		if not playerExists(target) then
			return false
		end

		local query_town = db.storeQuery('SELECT `town_id` FROM `players` WHERE `name` = ' .. db.escapeString(target) ..' LIMIT 1;')
		if query_town ~= false then
			result.free(consulta)
			db.query("UPDATE `players` SET `balance` = `balance` + '" .. amount .. "' WHERE `name` = " .. db.escapeString(target))
		end
	end

	self:setBankBalance(self:getBankBalance() - amount)
	return true
end

function Player.withdrawMoney(self, amount)
	local balance = self:getBankBalance()
	if amount > balance or not self:addMoney(amount) then
		return false
	end

	self:setBankBalance(balance - amount)
	return true
end

-- player:removeMoneyBank(money)
function Player:removeMoneyBank(amount)

	if type(amount) == 'string' then
		amount = tonumber(amount)
	end

	local moneyCount = self:getMoney()
	local bankCount = self:getBankBalance()

	-- The player have all the money with him
	if amount <= moneyCount then
		-- Removes player inventory money
		self:removeMoney(amount)

		self:sendTextMessage(MESSAGE_TRADE, ("Paid %d gold from inventory."):format(amount))
		return true

	-- The player doens't have all the money with him
	elseif amount <= (moneyCount + bankCount) then

		-- Check if the player has some money
		if moneyCount ~= 0 then
			-- Removes player inventory money
			self:removeMoney(moneyCount)
			local remains = amount - moneyCount

			-- Removes player bank money
			self:setBankBalance(bankCount - remains)

			self:sendTextMessage(MESSAGE_TRADE, ("Paid %d from inventory and %d gold from bank account. Your account balance is now %d gold."):format(moneyCount, amount - moneyCount, self:getBankBalance()))
			return true

		else
			self:setBankBalance(bankCount - amount)
			self:sendTextMessage(MESSAGE_TRADE, ("Paid %d gold from bank account. Your account balance is now %d gold."):format(amount, self:getBankBalance()))
			return true
		end
	end
	return false
end

function Player.hasAllowMovement(self)
	return self:getStorageValue(STORAGE.blockMovementStorage) ~= 1
end

function Player.isSorcerer(self)
	return table.contains({VOCATION.ID.SORCERER, VOCATION.ID.MASTER_SORCERER}, self:getVocation():getId())
end

function Player.isDruid(self)
	return table.contains({VOCATION.ID.DRUID, VOCATION.ID.ELDER_DRUID}, self:getVocation():getId())
end

function Player.isKnight(self)
	return table.contains({VOCATION.ID.KNIGHT, VOCATION.ID.ELITE_KNIGHT}, self:getVocation():getId())
end

function Player.isPaladin(self)
	return table.contains({VOCATION.ID.PALADIN, VOCATION.ID.ROYAL_PALADIN}, self:getVocation():getId())
end

function Player.isMage(self)
	return table.contains({VOCATION.ID.SORCERER, VOCATION.ID.MASTER_SORCERER, VOCATION.ID.DRUID, VOCATION.ID.ELDER_DRUID},
		self:getVocation():getId())
end

local ACCOUNT_STORAGES = {}
function Player.getAccountStorage(self, accountId, key, forceUpdate)
	local accountId = self:getAccountId()
	if ACCOUNT_STORAGES[accountId] and not forceUpdate then
		return ACCOUNT_STORAGES[accountId]
	end

	local query = db.storeQuery("SELECT `key`, MAX(`value`) as value FROM `player_storage` WHERE `player_id` IN (SELECT `id` FROM `players` WHERE `account_id` = ".. accountId ..") AND `key` = ".. key .." GROUP BY `key` LIMIT 1;")
	if query ~= false then
		local value = result.getDataInt(query, "value")
		ACCOUNT_STORAGES[accountId] = value
		result.free(query)
		return value
	end
	return false
end

function Player.getMarriageDescription(thing)
	local descr = ""
	if getPlayerMarriageStatus(thing:getGuid()) == MARRIED_STATUS then
		playerSpouse = getPlayerSpouse(thing:getGuid())
		if self == thing then
			descr = descr .. " You are "
		elseif thing:getSex() == PLAYERSEX_FEMALE then
			descr = descr .. " She is "
		else
			descr = descr .. " He is "
		end
		descr = descr .. "married to " .. getPlayerNameById(playerSpouse) .. '.'
	end
	return descr
end

function Player.sendWeatherEffect(self, groundEffect, fallEffect, thunderEffect)
    local position, random = self:getPosition(), math.random
    position.x = position.x + random(-7, 7)
      position.y = position.y + random(-5, 5)
    local fromPosition = Position(position.x + 1, position.y, position.z)
       fromPosition.x = position.x - 7
       fromPosition.y = position.y - 5
    local tile, getGround
    for Z = 1, 7 do
        fromPosition.z = Z
        position.z = Z
        tile = Tile(position)
        if tile then -- If there is a tile, stop checking floors
            fromPosition:sendDistanceEffect(position, fallEffect)
			position:sendMagicEffect(groundEffect, self)
			getGround = tile:getGround()
            if getGround and ItemType(getGround:getId()):getFluidSource() == 1 then
                position:sendMagicEffect(CONST_ME_LOSEENERGY, self)
            end
            break
        end
    end
    if thunderEffect and tile and not tile:hasFlag(TILESTATE_PROTECTIONZONE) then
        if random(2) == 1 then
            local topCreature = tile:getTopCreature()
            if topCreature and topCreature:isPlayer() and topCreature:getAccountType() < ACCOUNT_TYPE_SENIORTUTOR then
                position:sendMagicEffect(CONST_ME_BIGCLOUDS, self)
                doTargetCombatHealth(0, self, COMBAT_ENERGYDAMAGE, -weatherConfig.minDMG, -weatherConfig.maxDMG, CONST_ME_NONE)
                --self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You were hit by lightning and lost some health.")
            end
        end
    end
end

function Player.sellItem(self, itemid, count, cost)
	if self:removeItem(itemid, count) then
		if not self:addMoney(cost) then
			return error('Could not add money to ' .. self:getName() .. '(' .. cost .. 'gp)')
		end
		return true
	end
	return false
end

function Player.buyItemContainer(self, containerid, itemid, count, cost, charges)
	if not self:removeMoney(cost) then
		Spdlog.error("[doPlayerBuyItemContainer] - Player ".. self:getName() .." do not have money or money is invalid")
		return false
	end

	for i = 1, count do
		local container = Game.createItem(containerid, 1)
		for x = 1, ItemType(containerid):getCapacity() do
			container:addItem(itemid, charges)
		end

		if self:addItemEx(container, true) ~= RETURNVALUE_NOERROR then
			return false
		end
	end
	return true
end
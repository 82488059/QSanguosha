function sgs.ai_cardsview.jiushi(class_name, player)
	if class_name == "Analeptic" then
		if player:hasSkill("jiushi") and player:faceUp() then
			return ("analeptic:jiushi[no_suit:0]=.")
		end
	end
end

function sgs.ai_skill_invoke.jiushi(self, data)
	return not self.player:faceUp()
end


sgs.ai_skill_use["@@jujian"] = function(self, prompt)
	local needfriend = 0
	local nobasiccard = 0
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _,card in ipairs(cards) do
		if card:getTypeId() ~= sgs.Card_Basic then nobasiccard = nobasiccard+1 end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:isWounded() or not friend:faceUp() 
		or (friend:getArmor() and friend:getArmor():objectName() == "vine" and (enemy:isChained() and not self:isGoodChainPartner(friend))) then
			needfriend = needfriend + 1
		end
	end
	if nobasiccard < 1 or needfriend < 1 then return "." end
	self:sort(self.friends_noself,"defense")
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
			return "@JujianCard=.->"..friend:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getArmor() and friend:getArmor():objectName() == "vine" and (enemy:isChained() and not self:isGoodChainPartner(friend)) then
			return "@JujianCard=.->"..friend:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			return "@JujianCard=.->"..friend:objectName()
		end
	end
	return "@JujianCard=.->"..self.friends_noself[1]:objectName()
end

sgs.ai_skill_cardask["@jujian-discard"] = function(self, data)
	local effect = data:toCardEffect()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() ~= sgs.Card_Basic then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end


sgs.ai_skill_choice.jujian = function(self, choices)
	if not self.player:faceUp() then return "reset" end
	if self:isEquip("Vine") and self.player:isChained() and not self:isGoodChainPartner() then 
		return "reset"
	end
	if self:isWeak() and self.player:isWounded() then return "recover" end
	return "draw"
end

sgs.xushu_keep_value = 
{
	Peach = 6,
	Jink = 5.1,
	Weapon = 5,
	Armor = 5,
	DefensiveHorse = 5,
	OffensiveHorse = 5,
	Duel = 5,
	FireAttack = 5,
	ArcheryAttack = 5,
	SavageAssault = 5
}

function sgs.ai_armor_value.yizhong(card)
	if not card then return 4 end
end

local xinzhan_skill={}
xinzhan_skill.name="xinzhan"
table.insert(sgs.ai_skills,xinzhan_skill)
xinzhan_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("XinzhanCard") and self.player:getHandcardNum() > self.player:getMaxHP() then
		return sgs.Card_Parse("@XinzhanCard=.")
	end
end

sgs.ai_skill_use_func.XinzhanCard=function(card,use,self)
	use.card = card
end

sgs.ai_use_value.XinzhanCard = 4.4
sgs.ai_use_priority.XinzhanCard = 9.2

function sgs.ai_slash_prohibit.huilei(self, to)
	if self.player:hasSkill("jueqing") then return false end
	if self:isFriend(to) and self:isWeak(to) then return true end
	return #self.enemies>1 and self:isWeak(to) and (self.player:getHandcardNum()>3 or self:getCardsNum("Shit")>0)
end

sgs.ai_chaofeng.masu = -4

sgs.ai_skill_cardask["@enyuan"] = function(self)
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getSuit() == sgs.Card_Heart and not (card:inherits("Peach") or card:inherits("ExNihilo")) then
			return card:getEffectiveId()
		end
	end
	return "."
end

function sgs.ai_slash_prohibit.enyuan(self)
	if self:isWeak() then return true end
end

xuanhuo_skill={}
xuanhuo_skill.name="xuanhuo"
table.insert(sgs.ai_skills,xuanhuo_skill)
xuanhuo_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("XuanhuoCard") then
		return sgs.Card_Parse("@XuanhuoCard=.")
	end
end

sgs.ai_skill_use_func.XuanhuoCard = function(card, use, self)
	local cards = self.player:getHandcards()
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)

	local target
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty() then
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart and self.player:getHandcardNum() > 1 then
					use.card = sgs.Card_Parse("@XuanhuoCard=" .. card:getEffectiveId())
					target = friend
					break
				end
			end
		end
		if target then break end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				for _, card in ipairs(cards)do
					if card:getSuit() == sgs.Card_Heart and not card:inherits("Peach")  and self.player:getHandcardNum() > 1 then
						use.card = sgs.Card_Parse("@XuanhuoCard=" .. card:getEffectiveId())
						target = enemy
						break
					end
				end
			end
			if target then break end
		end
	end

	if target then
		self.room:setPlayerFlag(target, "xuanhuo_target")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_playerchosen.xuanhuo = function(self, targets)
	for _, player in sgs.qlist(targets) do
		if (player:getHandcardNum() <= 2 or player:getHp() < 2) and self:isFriend(player) 
			and not player:hasFlag("xuanhuo_target") and not self:needKongcheng(player) and not player:hasSkill("manjuan") then
			return player
		end
	end
end

sgs.fazheng_suit_value = 
{
	heart = 3.9
}

sgs.ai_chaofeng.fazheng = -3

function sgs.ai_skill_invoke.xuanfeng(self, data)
	local enemynum = 0
	for _, enemy in ipairs(self.enemies) do
		if not self:needKongcheng(enemy) then
			enemynum = enemynum + 1
		end
	end
	return enemynum > 0 
end

sgs.ai_skill_choice.xuanfeng = function(self, choices)
	return "discard"
end

sgs.ai_skill_playerchosen.xuanfeng = function(self, targets)	
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _, enemy in ipairs(self.enemies) do
		if not self:needKongcheng(enemy) then
			return enemy
		end
	end
end



sgs.ai_skill_invoke.pojun = function(self, data)
	local damage = data:toDamage()

	if not damage.to:faceUp() then
		return self:isFriend(damage.to)
	end

	local good = damage.to:getHp() > 2
	if self:isFriend(damage.to) then
		return good
	elseif self:isEnemy(damage.to) then
		return not good
	end
end

ganlu_skill={}
ganlu_skill.name="ganlu"
table.insert(sgs.ai_skills,ganlu_skill)
ganlu_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("GanluCard") then
		return sgs.Card_Parse("@GanluCard=.")
	end
end

sgs.ai_skill_use_func.GanluCard = function(card, use, self)
	local lost_hp = self.player:getLostHp()
	local enemy_equip = 0
	local target

	for _, friend in ipairs(self.friends) do
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.lose_equip_skill, enemy) then
				local ee = self:getCardsNum(".",enemy,"e")
				if self:isEquip("GaleShell", enemy) then ee = ee - 1 end
				local fe = self:getCardsNum(".",friend, "e")
				if self:isEquip("GaleShell", friend) then fe = fe - 1 end
				if self:hasSkills(sgs.lose_equip_skill, friend) then ee = ee + fe end
				local value = self:evaluateArmor(enemy:getArmor(),friend) - self:evaluateArmor(friend:getArmor(),enemy)
					- self:evaluateArmor(friend:getArmor(),friend) + self:evaluateArmor(enemy:getArmor(),enemy)
				if math.abs(self:getCardsNum(".", enemy, "e")-self:getCardsNum(".", friend, "e")) <= lost_hp and
					self:getCardsNum(".", enemy, "e")>0 and
					(ee > fe or (ee == fe and value>0)) then
					use.card = sgs.Card_Parse("@GanluCard=.")
					if use.to then
						use.to:append(friend)
						use.to:append(enemy)
					end
					return
				end
			end
		end
	end

	target = nil
	for _,friend in ipairs(self.friends) do
		if self:isEquip("YitianSword", friend) or (self:isEquip("SilverLion",friend) and friend:isWounded()) 
			or (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty()) then target = friend break end
	end
	if not target then return end
	for _,friend in ipairs(self.friends) do
		if friend~=target and math.abs(self:getCardsNum(".", friend, "e")-self:getCardsNum(".", target, "e")) <= lost_hp then
			use.card = sgs.Card_Parse("@GanluCard=.")
			if use.to then
				use.to:append(friend)
				use.to:append(target)
			end
			return
		end
	end
end

sgs.dynamic_value.control_card.GanluCard = true

sgs.ai_skill_invoke.buyi = function(self, data)
	local dying = data:toDying()
	return self:isFriend(dying.who)
end

sgs.ai_cardshow.buyi = function(self, requestor)
	assert(self.player:objectName() == requestor:objectName())

	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getTypeId() ~= sgs.Card_Basic then
			return card
		end
	end

	return self.player:getRandomHandCard()
end

mingce_skill={}
mingce_skill.name="mingce"
table.insert(sgs.ai_skills,mingce_skill)
mingce_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("MingceCard") then return end

	local card
	if self.player:getArmor() and (self.player:getArmor():objectName() == "silver_lion" and self.player:isWounded()) then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:inherits("Slash") or hcard:inherits("EquipCard") then
				card = hcard
				break
			end
		end
	end
	if card then
		card = sgs.Card_Parse("@MingceCard=" .. card:getEffectiveId())
		return card
	end

	return nil
end

sgs.ai_skill_use_func.MingceCard=function(card,use,self)
	local target
	self:sort(self.friends_noself, "defense")
	local friends = self.friends_noself
	for _, friend in ipairs(friends) do
		if friend:getHp() <= 2 and friend:getHandcardNum() < 2 and not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
			target = friend
			break
		end
	end

	if not target then
		local maxAttackRange=0
		for _, friend in ipairs(friends) do
			if friend:getAttackRange() > maxAttackRange and not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
				maxAttackRange = friend:getAttackRange()
				target = friend
			end
		end
	end

	if not target then
		local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
		if zhugeliang and zhugeliang:isKongcheng() and zhugeliang:getHp() < 2 and zhugeliang:objectName() ~= self.player:objectName() then
			target = zhugeliang
		end
	end

	if target then
		use.card=card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_choice.mingce = function(self, choices)
	local chengong = self.room:findPlayerBySkillName("mingce")
	if chengong and not self:isFriend(chengong) then return "draw" end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	if self.player:getHandcardNum()<=2 then return "draw" end
	if self.player:getHp()<=1 then return "draw" end
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and not self:slashProhibit(slash ,enemy) then return "use" end
	end
	return "draw"
end

sgs.ai_skill_playerchosen.mingce = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.ai_playerchosen_intention.mingce = 80

sgs.ai_use_value.MingceCard = 5.9
sgs.ai_use_priority.MingceCard = 4

sgs.ai_card_intention.MingceCard = -70

sgs.ai_cardneed.mingce = sgs.ai_cardneed.equip
local jiejiu_skill={}
jiejiu_skill.name="jiejiu"
table.insert(sgs.ai_skills,jiejiu_skill)
jiejiu_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local anal_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:inherits("Analeptic") then
			anal_card = card
			break
		end
	end

	if anal_card then
		local suit = anal_card:getSuitString()
		local number = anal_card:getNumberString()
		local card_id = anal_card:getEffectiveId()
		local card_str = ("slash:jiejiu[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		return slash
	end
end

sgs.ai_filterskill_filter.jiejiu = function(card, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:inherits("Analeptic") then return ("slash:jiejiu[%s:%s]=%d"):format(suit, number, card_id) end
end

local xianzhen_skill={}
xianzhen_skill.name="xianzhen"
table.insert(sgs.ai_skills,xianzhen_skill)
xianzhen_skill.getTurnUseCard=function(self)

	if self.player:hasUsed("XianzhenCard") then
		local card_str = "@XianzhenSlashCard=."
		local card = sgs.Card_Parse(card_str)
		return card
	end

	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local max_card = self:getMaxCard()
	local slashNum=self:getCardsNum("Slash")
	if max_card then 
		local max_point = max_card:getNumber()
		if max_card:inherits("Slash") then slashNum=slashNum-1 end
	end

	self:sort(self.enemies, "hp")

	for _, enemy in ipairs(self.enemies) do
		local enemy_max_card = self:getMaxCard(enemy)
		if enemy_max_card and max_point and max_point > enemy_max_card:getNumber() and slashNum > 1 then

			local slash=self:getCard("Slash")
			local dummy_use={}
			dummy_use.isDummy=true

			local no_distance=true
			self:useBasicCard(slash,dummy_use,no_distance)

			if dummy_use.card then
				local card_id = max_card:getEffectiveId()
				local card_str = "@XianzhenCard=" .. card_id
				local card = sgs.Card_Parse(card_str)
				return card
			end
		end
	end
	self:sortByUseValue(cards, true)
	if self:getOverflow()>0	then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and not enemy:hasSkill("tuntian") then
				local card_id = cards[1]:getEffectiveId()
				local card_str = "@XianzhenCard=" .. card_id
				local card = sgs.Card_Parse(card_str)
				return card
			end
		end
	end
end

sgs.ai_skill_use_func.XianzhenSlashCard=function(card,use,self)
	local target = self.player:getTag("XianzhenTarget"):toPlayer()
	if self:askForCard("slash", "@xianzhen-slash") == "." then return end
	
	if self:getCard("Slash") and not (target:hasSkill("kongcheng") and target:isKongcheng()) and target:isAlive() then
		use.card=card
	end
end

sgs.ai_skill_use_func.XianzhenCard=function(card,use,self)

	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = max_card:getNumber()

	for _, enemy in ipairs(self.enemies) do
		local enemy_max_card = self:getMaxCard(enemy)
		if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1)
			and (enemy_max_card and max_point > enemy_max_card:getNumber()) then
			if use.to then
				use.to:append(enemy)
			end
			use.card=card
			return
		end
	end
	if self:getOverflow()>0	then
		for _, enemy in ipairs(self.enemies) do
			if use.to then
				use.to:append(enemy)
			end
			use.card=card
			break
		end
	end
end

sgs.ai_cardneed.xianzhen = sgs.ai_cardneed.bignumber
function sgs.ai_skill_pindian.xianzhen(minusecard, self, requestor)
	if self:isFriend(requestor) then return end
	if requestor:getHandcardNum() <= 2 then return minusecard end
end

sgs.ai_card_intention.XianzhenCard = 70

sgs.dynamic_value.control_card.XianzhenCard = true

sgs.ai_use_value.XianzhenCard = 9.2
sgs.ai_use_priority.XianzhenCard = 9.2

sgs.ai_skill_cardask["@xianzhen-slash"] = function(self)
	if self.player:hasSkill("tianxiang") then
		local dmgStr = {damage = 1, nature = 0}
		local willTianxiang = sgs.ai_skill_use["@tianxiang"](self, dmgStr)
		if willTianxiang ~= "." then return "." end
	elseif self.player:hasSkill("longhun") and self.player:getHp() > 1 then
		return "."
	end
	local target = self.player:getTag("XianzhenTarget"):toPlayer()
	local slashes = self:getCards("Slash")
	for _, slash in ipairs(slashes) do
		if self:slashIsEffective(slash, target) then return slash:toString() end
	end
	return "."
end

sgs.ai_use_value.XianzhenSlashCard = 9.2
sgs.ai_use_priority.XianzhenSlashCard = 2.6

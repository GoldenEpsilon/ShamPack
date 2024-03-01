--- STEAMODDED HEADER
--- MOD_NAME: ShamPack
--- MOD_ID: ShamPack
--- MOD_AUTHOR: [Golden Epsilon, DankShamwow]
--- MOD_DESCRIPTION: Adds a couple of custom jokers and mechanics to the game.

----------------------------------------------
------------MOD CODE -------------------------

local MOD_ID = "ShamPack";

-- Fix for atlases while I'm waiting for the PR to be merged
local set_spritesref = Card.set_sprites
function Card:set_sprites(_center, _front)
    set_spritesref(self, _center, _front);
    if _center then
        if _center.set then
            if (_center.set == 'Joker' or _center.consumeable or _center.set == 'Voucher') and _center.atlas then
                self.children.center.atlas = G.ASSET_ATLAS
                [(_center.atlas or (_center.set == 'Joker' or _center.consumeable or _center.set == 'Voucher') and _center.set) or 'centers']
                self.children.center:set_sprite_pos(_center.pos)
            end
        end
    end
end

-- REMEMBER TO CALL refresh_items AFTERWARDS
function add_item(mod_id, pool, id, data, desc)
    -- Add Sprite
    data.pos = {x=0,y=0};
    data.key = id;
    data.atlas = mod_id .. id;
    SMODS.Sprite:new(mod_id .. id, SMODS.findModByID(mod_id).path, id .. ".png", 71, 95, "asset_atli"):register();

    data.key = id
    data.order = #G.P_CENTER_POOLS[pool] + 1
    G.P_CENTERS[id] = data
    table.insert(G.P_CENTER_POOLS[pool], data)
    
    if pool == "Joker" then
        table.insert(G.P_JOKER_RARITY_POOLS[data.rarity], data)
    end

    G.localization.descriptions[pool][id] = desc;
end

function refresh_items()
    for k, v in pairs(G.P_CENTER_POOLS) do
        table.sort(v, function(a, b) return a.order < b.order end)
    end

    -- Update localization
    for g_k, group in pairs(G.localization) do
        if g_k == 'descriptions' then
            for _, set in pairs(group) do
                for _, center in pairs(set) do
                    center.text_parsed = {}
                    for _, line in ipairs(center.text) do
                        center.text_parsed[#center.text_parsed + 1] = loc_parse_string(line)
                    end
                    center.name_parsed = {}
                    for _, line in ipairs(type(center.name) == 'table' and center.name or { center.name }) do
                        center.name_parsed[#center.name_parsed + 1] = loc_parse_string(line)
                    end
                    if center.unlock then
                        center.unlock_parsed = {}
                        for _, line in ipairs(center.unlock) do
                            center.unlock_parsed[#center.unlock_parsed + 1] = loc_parse_string(line)
                        end
                    end
                end
            end
        end
    end

    for k, v in pairs(G.P_JOKER_RARITY_POOLS) do 
        table.sort(G.P_JOKER_RARITY_POOLS[k], function (a, b) return a.order < b.order end)
    end
end

function SMODS.INIT.ShamPack()
    add_item(MOD_ID, "Joker", "j_prideful", {
        unlocked = true,
        discovered = false,
        rarity = 2,
        cost = 8,
        name = "Prideful Joker",
        set = "Joker",
        config = {
            extra = 8,
        },
    },{
        name = "Prideful Joker",
        text = {
            "{C:attention}Wild Cards{} give",
            "+8 Mult when scored"
        }
    });
    add_item(MOD_ID, "Joker", "j_slothful", {
        unlocked = true,
        discovered = false,
        rarity = 2,
        cost = 6,
        name = "Slothful Joker",
        set = "Joker",
        config = {
            extra = 8,
        },
    },{
        name = "Slothful Joker",
        text = {
            "{C:attention}Mild Cards{} give",
            "+8 Mult when scored"
        }
    });
    add_item(MOD_ID, "Joker", "j_unstable", {
        unlocked = true,
        discovered = false,
        blueprint_compat = false,
        rarity = 3,
        cost = 5,
        name = "Unstable Joker",
        set = "Joker",
        config = {
            extra = "Unstable Joker"
        },
    },{
        name = "Unstable Joker",
        text = {
            "Becomes a new {C:attention}Joker Card{}",
            "every round"
        }
    });
    add_item(MOD_ID, "Joker", "j_vince", {
        unlocked = true,
        discovered = false,
        blueprint_compat = false,
        rarity = 2,
        cost = 8,
        name = "Vince Joker",
        set = "Joker",
        config = {
            extra = {poker_hand = "Flush", dollars = 5}
        },
    },{
        name = "Vince Joker",
        text = {
            "When you play a {C:attention}Flush{},",
            "gain {C:money}$5{}",
            "and all cards scored become {C:attention}Mild Cards{}"
        }
    });

    add_item(MOD_ID, "Tarot", "c_haters", {
        discovered = false,
        cost = 3,
        consumeable = true,
        name = "The Haters",
        set = "Tarot",
        effect = "Enhance",
        cost_mult = 1.0,
        config = { mod_conv = 'm_mild', max_highlighted = 5 },
    },{
        name = "The Haters",
        text = {
            "Enhances up to {C:attention}5{} selected",
            "cards into a",
            "{C:attention}Mild Card"
        }
    });

    add_item(MOD_ID, "Enhanced", "m_mild", {
        max = 500,
        name = "Mild Card", 
        set = "Enhanced", 
        effect = "Mild Card", 
        label = "Mild Card", 
        config = {},
    },{
        name = "Mild Card",
        text = {
            "Can not be used",
            "as any suit"
        }
    });

    -- For the unstable joker
    G.localization.descriptions["Joker"]["effect_unstable"] = {
        name = "UNSTABLE!",
        text = {
            "Will become a new",
            "{C:attention}Joker Card{}",
            "at the end of the round"
        }
    };

    -- Apply our changes
    refresh_items();
end


-- Mild Card Effect Code
local is_suitref = Card.is_suit
function Card:is_suit(suit, bypass_debuff, flush_calc)
    if flush_calc then
        if self.ability.effect == 'Mild Card' then
            return false
        end
    else
        if self.debuff and not bypass_debuff then return end
        if self.ability.effect == 'Mild Card' then
            return false
        end
    end
    return is_suitref(self, suit, bypass_debuff, flush_calc)
end

local calculate_jokerref = Card.calculate_joker;
function Card:calculate_joker(context)
    local ret_val = calculate_jokerref(self, context);
    if self.ability.set == "Joker" and not self.debuff then
        if context.individual then
            if context.cardarea == G.play then
                if self.ability.name == 'Slothful Joker' and context.other_card.ability.name == "Mild Card" then
                    print(self.ability.extra);
                    return {
                        mult = self.ability.extra,
                        card = self
                    }
                end
                if self.ability.name == 'Prideful Joker' and context.other_card.ability.name == "Wild Card" then
                    return {
                        mult = self.ability.extra,
                        card = self
                    }
                end
            end
        else
            if context.cardarea == G.jokers then
                if context.before then
                    if self.ability.name == 'Vince Joker' and next(context.poker_hands[self.ability.extra.poker_hand]) then
                        for k, v in ipairs(context.full_hand) do
                            v:set_ability(G.P_CENTERS.m_mild, nil, true)
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    v:juice_up()
                                    return true
                                end
                            })) 
                        end
                        if #context.full_hand > 0 then 
                            print(self.ability.extra.dollars);
                            ease_dollars(self.ability.extra.dollars)
                            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + self.ability.extra.dollars
                            G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
                            return {
                                message = localize('$')..self.ability.extra.dollars,
                                dollars = self.ability.extra.dollars,
                                card = self
                            }
                        else
                            return {
                                message = localize('k_debuffed'),
                                colour = G.C.RED,
                                card = self,
                            }
                        end
                    end
                end
            end
        end
        if context.end_of_round then
            if not context.blueprint then
                if self.ability.unstablejoker or self.ability.extra == "Unstable Joker" then
                    G.jokers:remove_card(self)
                    self:remove()
                    self = create_card('Joker', G.jokers, nil, nil, nil, nil, nil, nil);
                    self.ability.unstablejoker = true;
                    self:add_to_deck()
                    G.jokers:emplace(self)
                    self:start_materialize()
                end
            end
        end
    end
    return ret_val;
end
 
local card_uiref = Card.generate_UIBox_ability_table;
function Card:generate_UIBox_ability_table()
    local ret_val = card_uiref(self);
    if self.ability and self.ability.unstablejoker then
        return generate_card_ui({key="effect_unstable", set="Joker"}, ret_val);
    end
    return ret_val
end

----------------------------------------------
------------MOD CODE END----------------------

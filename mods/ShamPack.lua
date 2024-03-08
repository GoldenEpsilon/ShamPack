table.insert(mods,
    {
        mod_id = "sham_pack",
        name = "ShamPack",
        author = "Golden Epsilon, DankShamwow",
        version = "0.1",
        description = {
            "Adds a couple of custom Jokers,",
            "Tarot Cards, Enhancements,",
            "and mechanics to the game.",
        },
        enabled = true,
        on_enable = function()
            GE:init()
            
            local MOD_ID = "ShamPack";



            injectHead("card.lua", "Card:is_suit", [[
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
            ]])
            injectHead("card.lua", "Card:calculate_joker", [[
                if self.ability.set == "Joker" and not self.debuff then
                    if context.individual then
                        if context.cardarea == G.play then
                            if self.ability.name == 'Slothful Joker' and context.other_card.ability.name == "Mild Card" then
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
                            if self.ability.name == 'Comedy Joker' then
                            end
                            if self.ability.name == 'Tragedy Joker' then
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
            ]])
            
            GE:inject(MOD_ID, "card.lua", "Card:generate_UIBox_ability_table", 
            [[
                return generate_card_ui(self.config.center, nil, loc_vars, card_type, badges, hide_desc, main_start, main_end)
            ]], [[
                if self.ability and self.ability.unstablejoker then
                    return generate_card_ui({key="effect_unstable", set="Joker"}, generate_card_ui(self.config.center, nil, loc_vars, card_type, badges, hide_desc, main_start, main_end););
                end
                return generate_card_ui(self.config.center, nil, loc_vars, card_type, badges, hide_desc, main_start, main_end)
            ]])


            GE:add_item(MOD_ID, "Joker", "j_prideful", {
                rarity = 2,
                cost = 8,
                name = "Prideful Joker",
                set = "Joker",
                config = {
                    extra = 8,
                },
                loc_var_func = function(card) return {localize{type = 'name_text', set = 'Enhanced', key = "m_wild"}, card.ability.extra} end
            },{
                name = "Prideful Joker",
                text = {
                    "{C:attention}#1#{} give",
                    "+#2# Mult when scored"
                }
            });
            GE:add_item(MOD_ID, "Joker", "j_slothful", {
                rarity = 2,
                cost = 6,
                name = "Slothful Joker",
                set = "Joker",
                config = {
                    extra = 8,
                },
                loc_var_func = function(card) return {localize{type = 'name_text', set = 'Enhanced', key = "m_mild"}, card.ability.extra} end
            },{
                name = "Slothful Joker",
                text = {
                    "{C:attention}#1#{} give",
                    "+#2# Mult when scored"
                }
            });
            GE:add_item(MOD_ID, "Joker", "j_unstable", {
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
            GE:add_item(MOD_ID, "Joker", "j_vince", {
                rarity = 2,
                cost = 8,
                name = "Vince Joker",
                set = "Joker",
                config = {
                    extra = {poker_hand = "Flush", dollars = 5}
                },
                loc_var_func = function(card) return {card.ability.extra.poker_hand, card.ability.extra.dollars} end
            },{
                name = "Vince Joker",
                text = {
                    "When you play a {C:attention}#1#{}, gain {C:money}$#2#{}",
                    "and all cards scored",
                    "become {C:attention}Mild Cards{}"
                }
            });
            --[=[GE:add_item(MOD_ID, "Joker", "j_comedy", {
                rarity = 1,
                cost = 4,
                name = "Comedy Joker",
                set = "Joker",
                config = {
                    extra = {
                        suit = "",
                        chips = 50
                    }
                },
                loc_var_func = function(card) return {card.ability.extra.suit, card.ability.extra.chips} end
            },{
                name = "Comedy Joker",
                text = {
                    "Played #1#s give +#2# chips when scored.",
                    "Becomes Tragedy Joker when triggered."
                }
            });
            GE:add_item(MOD_ID, "Joker", "j_tragedy", {
                rarity = -1,
                cost = 4,
                name = "Tragedy Joker",
                set = "Joker",
                config = {
                    extra = {
                        rank = "",
                        mult = 4
                    }
                },
                loc_var_func = function(card) return {card.ability.extra.rank, card.ability.extra.mult} end
            },{
                name = "Tragedy Joker",
                text = {
                    "Played #1#s give +#2# Mult when scored.",
                    "Becomes Comedy Joker when triggered."
                }
            });]=]
        
            GE:add_item(MOD_ID, "Tarot", "c_haters", {
                cost = 3,
                consumeable = true,
                name = "The Haters",
                set = "Tarot",
                effect = "Enhance",
                cost_mult = 1.0,
                config = { mod_conv = 'm_mild', max_highlighted = 5 },
                loc_var_func = function(card) return {card.config.center.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = card.config.center.config.mod_conv}} end
            },{
                name = "The Haters",
                text = {
                    "Enhances up to {C:attention}#1#{} selected",
                    "cards into a",
                    "{C:attention}#2#"
                }
            });
        
            GE:add_item(MOD_ID, "Enhanced", "m_mild", {
                max = 500,
                name = "Mild Card", 
                set = "Enhanced", 
                effect = "Mild Card", 
                label = "Mild Card", 
                config = {},
            },{
                name = "Mild Card",
                text = {
                    "Cannot be used",
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
        end,

        on_disable = function()
            GE:disable(MOD_ID)
        end,
    }
)
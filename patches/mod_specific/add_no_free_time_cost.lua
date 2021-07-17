local old_params_fn = Negotiation.MiniGame.ParamsFromParty
function Negotiation.MiniGame.ParamsFromParty( caravan, agent, params, enc )
    local res = old_params_fn(caravan, agent, params, enc)
    res.no_free_time_cost = params.no_free_time_cost
    return res
end
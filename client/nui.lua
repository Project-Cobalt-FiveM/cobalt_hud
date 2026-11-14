local nui <const> = {}

---@param action string
---@param data? table
function nui.send(action, data)
    SendNUIMessage({ action = action, data = data })
end

---Sends the fields of `payload` that differ from `last`, and records them in `last`.
---@param action string
---@param last table
---@param payload table
function nui.sendChanges(action, last, payload)
    local changes

    for key, value in pairs(payload) do
        if last[key] ~= value then
            changes = changes or {}
            changes[key] = value
            last[key] = value
        end
    end

    if changes then nui.send(action, changes) end
end

---@param value number
---@return integer
function nui.round(value)
    return math.floor(value + 0.5)
end

return nui

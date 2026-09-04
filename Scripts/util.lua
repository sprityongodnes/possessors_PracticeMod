function IsValid(obj)
    return obj ~= nil and type(obj.IsValid) == "function" and obj:IsValid()
end

function FindClass(path)
    local cls = StaticFindObject(path)
    if not IsValid(cls) then error("StaticFindObject failed: " .. path) end
    return cls
end

function Construct(classPath, outer, name)
    local cls = FindClass(classPath)
    local obj = StaticConstructObject(cls, outer, FName(name))
    if not IsValid(obj) then error("StaticConstructObject failed: " .. classPath) end
    return obj
end

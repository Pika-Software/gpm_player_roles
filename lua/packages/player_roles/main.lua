module("roles", package.seeall)

local assert = assert

local list = {}

do
    local table_Copy = table.Copy
    function GetList()
        return table_Copy( list )
    end
end

function Get( name )
    return list[ name ]
end

function Set( name, val )
    list[ name ] = val
end

function Remove( name )
    local role = Get( name )
    if (role == nil) then
        return
    end

    role:Remove()
end

do

    local PLAYER = FindMetaTable( "Player" )

    function PLAYER:GetRolesInt()
        return self:GetNWInt( "gpm.player_roles", 0 )
    end

    local bit_band = bit.band

    function PLAYER:GetRole( name )
        local role = Get( name )
        if (role == nil) then
            return
        end

        if (bit_band( self:GetRolesInt(), role.id ) == role.id) then
            return role
        end
    end

    function PLAYER:HasRole( name )
        return self:GetRole( name ) ~= nil
    end

    do

        local pairs = pairs
        local table_insert = table.insert

        function PLAYER:GetRoles()
            local result = {}

            local roles = self:GetRolesInt()
            if (roles == 0) then
                return result
            end

            for name, role in pairs( list ) do
                if (bit_band( roles, role.id ) == role.id) then
                    table_insert( result, role )
                end
            end

            return result
        end

    end

    if (SERVER) then

        function PLAYER:SetRolesInt( int )
            self:SetNWInt( "gpm.player_roles", int )
        end

        function PLAYER:ClearRoles()
            self:SetRolesInt( 0 )
        end

        do
            local bit_bor = bit.bor
            function PLAYER:AddRole( name )
                local role = Get( name )
                if (role == nil) then
                    return
                end

                if (bit_band( self:GetRolesInt(), role.id ) == role.id) then
                    return
                end

                self:SetRolesInt( bit_bor( self:GetRolesInt(), role.id ) )
            end
        end

        do
            local bit_bnot = bit.bnot
            function PLAYER:TakeRole( name )
                local role = Get( name )
                if (role == nil) then
                    return
                end

                self:SetRolesInt( bit_band( self:GetRolesInt(), bit_bnot( role.id ) ) )
            end
        end

    end

end

do

    local ROLE = {}
    ROLE.__index = ROLE

    function ROLE:__tostring()
        return string.format( "Role [%s][%s]", self:GetID(), self:GetName() )
    end

    do

        local player_GetHumans = player.GetHumans
        local setmetatable = setmetatable
        local color_white = color_white
        local pairs = pairs
        local type = type

        -- Add new role here
        function Add( name, color )
            assert( type( name ) == "string", "bad argument #1 (string expected)" )

            local role = Get( name )
            if (role ~= nil) then
                -- print( "A role '" .. name .. "' already exists!" )
                role:SetColor( color )
                return role
            end

            -- max 31 roles (32 bit in glua)
            local id = 1
            for name, role in pairs( list ) do
                if (role.id >= id) then
                    id = role.id * 2
                end
            end

            local new = setmetatable({
                id = id,
                name = name,
                r = color.r or 25,
                g = color.g or 25,
                b = color.b or 25
            }, ROLE )

            Set( name, new )

            return new
        end

    end

    do

        -- Get role id
        function ROLE:GetID()
            return self.id
        end

        -- Get role name
        function ROLE:GetName()
            return self.name
        end

        -- Colors :D
        function ROLE:GetColor()
            return Color( self.r, self.g, self.b, self.a )
        end

        function ROLE:SetColor( color )
            self.r = color.r
            self.g = color.g
            self.b = color.b
            self.a = color.a or 255
        end

        -- Get all players with that role
        do

            local player_GetAll = player.GetAll
            local table_insert = table.insert
            local ipairs = ipairs

            function ROLE:GetPlayers()
                local result = {}
                local name = self:GetName()

                for num, ply in ipairs( player_GetAll() ) do
                    if ply:HasRole( name ) then
                        table_insert( result, ply )
                    end
                end

                return result
            end

        end

        if (SERVER) then

            local ipairs = ipairs

            -- Remove that role, only server side
            function ROLE:Remove()
                local name = self:GetName()
                Set( name, nil )

                for num, ply in ipairs( self:GetPlayers() ) do
                    ply:TakeRole( name )
                end
            end

        end

    end

end
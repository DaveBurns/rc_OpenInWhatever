--[[
        OpenInWhateverObjectFactory.lua
        
        Creates special objects used in the guts of the framework.
        
        This is what you edit to change the classes of framework objects
        that you have extended.
--]]

local OpenInWhateverObjectFactory, dbg = ObjectFactory:newClass{ className = 'OpenInWhateverObjectFactory', register = false }



--- Constructor for extending class.
--
--  @usage  I doubt this will be necessary, since there is generally
--          only one special object factory per plugin, mostly present
--          for the sake of completeness...
--
function OpenInWhateverObjectFactory:newClass( t )
    return ObjectFactory.newClass( self, t )
end



--- Constructor for new instance.
--
function OpenInWhateverObjectFactory:new( t )
    local o = ObjectFactory.new( self, t )
    return o
end



--- Framework module loader.
--
--  @usage      Generally better to handle in other ways,
--              but this method can help when in a jam...
--
--  @return     loaded module return value, or if code is programmed for module to be optional, can return nil to exclude module.
--
function OpenInWhateverObjectFactory:frameworkModule( spec )
    --if spec == 'System/Preferences' then
    --    return nil - at the moment, this is the only way to kill the preference preset manager.
    --else
        return ObjectFactory.frameworkModule( self, spec )
    --end
end



--- Creates instance object of specified class.
--
--  @param      class       class object OR string specifying class.
--  @param      ...         initial table params forwarded to 'new' constructor.
--
function OpenInWhateverObjectFactory:newObject( class, ... )
    if type( class ) == 'table' then
        --if class == Manager then
        --    return OpenInWhateverManager:new( ... )
        --end
    elseif type( class ) == 'string' then
        if class == 'Manager' then
            return OpenInWhateverManager:new( ... )
        elseif class == 'ExportDialog' then
            if gbl:getValue( 'ExtendedPublish' ) then -- export supported with publish service.
                return ExtendedPublish:newDialog( ... )
            else                                       -- export supported without publish service.
                return ExtendedExport:newDialog( ... )
            end
        elseif class == 'Export' then
            if gbl:getValue( 'ExtendedPublish' ) then
                return ExtendedPublish:newExport( ... ) -- export supported with publish service.
            else
                return ExtendedExport:newExport( ... ) -- export supprted without publish service.
            end
        elseif class == 'ExportFilter' then -- note: there could be more than one export-filter defined for a single plugin, so somehow, which object to create will need to be resolved...
            return ExtendedExportFilter:new( ... )
        end
    end
    return ObjectFactory.newObject( self, class, ... )
end



return OpenInWhateverObjectFactory 
-- the end.
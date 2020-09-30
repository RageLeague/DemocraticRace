local filepath = require "util/filepath"
local db = QuipDatabase(  )
for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/quips/", "*.yaml", true )) do
    -- local name = filepath:match( "(.+)[.]yaml$" )
    db:AddFilename(filepath)
end
Content.AddQuips(db)
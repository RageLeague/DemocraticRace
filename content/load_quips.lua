local filepath = require "util/filepath"

for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/quips/", "*.yaml", true )) do
    -- local name = filepath:match( "(.+)[.]yaml$" )
    local db = QuipDatabase(  )
    db:AddFilename(filepath)
    Content.AddQuips(db)
end

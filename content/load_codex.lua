local filepath = require "util/filepath"
local cdx = Codex(  )
for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/codex/", "*.yaml", true )) do
    -- local name = filepath:match( "(.+)[.]yaml$" )
    cdx:AddFilename(filepath)
end
Content.AddCodex(cdx)
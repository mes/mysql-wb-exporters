-- standard plugin functions
--
-- this function is called first by MySQL Workbench core to determine number of
-- plugins in this module and basic plugin info
-- see the comments in the function body and adjust the parameters as appropriate
--
function getModuleInfo()

    -- module properties
    local props =
        {
            -- module name (ID)
            name = "MySQLTextileMarkupExporter",

            -- module author(s)
            author = "Ralf Schaeftlein, Christian Becker",

            --module version
            version = "1.0.2",

            -- interface implemented by this module
            implements = "PluginInterface",

            -- plugin functions exposed by this module
            -- l looks like a parameterized list, i instance, o object, @ fully qualified class name
            functions =
                {
                    "getPluginInfo:l<o@app.Plugin>:",
                    "exportMarkupToClipboard:i:o@db.Catalog"
                }
        }

    -- can't assign inside declaration
    props.name = props.name .. props.version

    return props
end

function objectPluginInput(type)

    return grtV.newObj("app.PluginObjectInput", {objectStructName = type})

end

function getPluginInfo()

    -- list of plugins this module exposes (list object of type app.Plugin?)
    local l = grtV.newList("object", "app.Plugin")

    -- plugin instances
    local plugin

    local props = getModuleInfo()

    -- new plugin: export to clipboard
    plugin = createNewPlugin("wb.catalog.util.exportMarkupToClipboard" .. props.version,
                             "Textile Markup Exporter " .. props.version .. ": Copy to Clipboard",
                             props.name,
                             "exportMarkupToClipboard",
                             {objectPluginInput("db.Catalog")},
                             {"Catalog/Utilities", "Menu/Catalog"})

    -- append to list of plugins
    grtV.insert(l, plugin)

    return l
end

function createNewPlugin(name, caption, moduleName, moduleFunctionName, inputValues, groups)

    -- create dictionary, Lua seems to handle keys and values right...
    local props =
        {
            name = name,
            caption = caption,
            moduleName = moduleName,
            pluginType = "normal",
            moduleFunctionName = moduleFunctionName,
            inputValues = inputValues,
            rating = 100,
            showProgress = 0,
            groups = groups
        }

    local plugin = grtV.newObj("app.Plugin", props)

    -- set owner???
    plugin.inputValues[1].owner = plugin

    return plugin
end

--
-- Print some version information and copyright to the output window
function printVersion()
    print("\n\n\MySQL Schema to Textile Markup Exporter v" .. getModuleInfo().version .. "\nCopyright (c) 2011 Ralf Schaeftlein - License: LGPLv3");
end

-- export function #1
function exportMarkupToClipboard(catalog)

    printVersion()
    local markup = generateTextileMarkup(catalog)

    Workbench:copyToClipboard(markup)

    print('\n > Textile Markup  copied to clipboard')

    return 0
end

--
-- generates the textile markup
function generateTextileMarkup(cat)
    local i, j, schema, tbl
    local markup = ""
    local optionsSetFlag = false

    for i = 1, grtV.getn(cat.schemata) do
        schema = cat.schemata[i]

        --print(schema)

        for j = 1, grtV.getn(schema.tables) do
            tbl = schema.tables[j]

            --
            -- do not export *_translation tables
            if (tbl.name ~= nil and tbl.name ~= "" and string.ends(tbl.name, "_translation") == false ) then
                markup = buildMarkupForSingleTable(tbl, schema, markup)
            end
        end
    end

    --print(markup)

    return markup
end

function buildMarkupForSingleTable(tbl, schema, markup)
    local k, l, col, index, column
    local actAsPart = ""
    local actAs = ""

    --
    -- start of adding a table
	markup = markup .. "h4. " .. tbl.name .. "\n"
	
	markup = markup .. "\n"
	
	if ( tbl.comment ~= nil and tbl.comment ~= "" ) then
		markup = markup .. tbl.comment .. "\n"
	end	

	markup = markup .. "\n"
	
	if (     tbl.tableEngine ~= nil and tbl.tableEngine ~= "") then
		markup = markup .. "* Engine: " .. tbl.tableEngine .. "\n"
	end
	
	if ( tbl.defaultCharacterSetName ~= nil and tbl.defaultCharacterSetName ~= "" ) then
        markup = markup .. "* Charset: " .. tbl.defaultCharacterSetName .. "\n"
	end	
	if ( tbl.defaultCollationName ~= nil and tbl.defaultCollationName ~= "" ) then
		markup = markup .. "* Collation: " .. tbl.defaultCollationName .. "\n"
    end

	markup = markup .. "\n"
	
    markup = markup .. "|_. Column |_. Type |_. Null |_. autoincrement |_. default |_. Primary |_. Unique |_. Description |\n"	
	
    --
    -- iterate through the table columns
    for k = 1, grtV.getn(tbl.columns) do
        col = tbl.columns[k]
        markup = buildMarkupForSingleColumn(tbl, col, markup)
    end

	markup = markup .. "\n"
	
	-- table index
    local indexes = ""
    for k = 1, grtV.getn(tbl.indices) do
        index = tbl.indices[k]
        if ( index.indexType == "INDEX" ) then
            indexes = indexes .. "| " .. index.name .. " | "
            for l = 1, grtV.getn(index.columns) do
                column = index.columns[l]
                indexes = indexes .. column.referencedColumn.name
                if ( l < grtV.getn(index.columns) ) then
                    indexes = indexes .. ", "
                end
            end
            indexes = indexes .. " | INDEX |\n"
        end
    end
    
	if ( indexes ~= nil and indexes ~= "") then
		markup = markup .. "h5. Indexes\n\n"
		markup = markup .. "|_. Name |_. Columns |_. Type |\n" 
		markup = markup .. indexes
	end
    
    -- final line break
    return markup .. "\n"
end

function buildMarkupForSingleColumn(tbl, col, markup)
    local l, m, p, u, n

	-- column name
	markup = markup .. "| " .. col.name .. " | " 
	
	-- column type
	markup = markup .. col.simpleType.name 
	
	if ( col.length ~= -1 ) then
        markup = markup.. " (" ..col.length.. ")"
    end
	
	markup = markup .. " | "
	
	-- column not null?
	if ( col.isNotNull == 1 ) then
		markup = markup .. " NOT NULL " .. " | "
	else
	    markup = markup .. " NULL " .. " | "
	end
	
	-- autoincrement
	if ( col.autoIncrement == 1 ) then
		markup = markup ..  " true |"
	else 
	   markup = markup ..  " false |"
	end
	
	-- default
	if ( col.defaultValue ~= '') then
		markup = markup .. col.defaultValue .. " | " 
	else 
		markup = markup .. " | " 
	end 
	
	p = " false "
	u = " false "
	for m = 1, grtV.getn(tbl.indices) do
        index = tbl.indices[m]
        --
        -- checking for primary index
        if ( index.indexType == "PRIMARY" ) then
            for l = 1, grtV.getn(index.columns) do
                column = index.columns[l]
                if ( column.referencedColumn.name == col.name ) then
                    p = " true "
                end
            end
        end
        --
        -- checking for unique index
        if ( index.indexType == "UNIQUE" ) then
            -- check if just one column in index
            if ( grtV.getn(index.columns) == 1 ) then
                for l = 1, grtV.getn(index.columns) do
                    column = index.columns[l]
                    if ( column.referencedColumn.name == col.name ) then
                        u = " true "
                    end
                end
            end
        end
    end
	
	-- primary key?
	markup = markup .. p .. " | "
	
	-- unique key?
	markup = markup .. u .. " | "
	
	-- description
    if ( col.comment ~= nil and col.comment ~= '') then
		markup = markup .. col.comment 
	end
	
  	-- fk?
	for n = 1, grtV.getn(tbl.foreignKeys) do
		fk = tbl.foreignKeys[n]
		if ( fk.columns[1].name == col.name ) then
			markup = markup .. " (foreign key to table  " .. fk.referencedColumns[1].owner.name .. " column " .. fk.referencedColumns[1].name .. " ) "
		end 
	end
	
	markup = markup .. " | \n"
	
	
    return markup
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

--[[

 Radio-Browser.info 0.5 lua script (search window)

 Copyright © 2020 Andrew Jackson (https://github.com/ceever ... ceever@web.de)

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.



--- BUGS & REQUESTS: ---

Send me an email or open a ticket on github.



--- INSTALLATION ---:

Put the according .lua file in the according subfolder of the VLC lua directory. VLC lua directory by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\
* Windows (current user): %APPDATA%\VLC\lua\
* Linux (all users): /usr/lib/vlc/lua/ or /usr/lib/x86_64-linux-gnu/vlc/lua/
* Linux (current user): ~/.local/share/vlc/lua/
(create directories if they don't exist)

According .lua file and according subfolder:
* ex_Radio-Browser_info.lua => ...\lua\extensions\
* sd_Radio-Browser_info.lua => ...\lua\sd\
* pl_Radio-Browser_info.lua => ...\lua\playlist\

Restart VLC.



--- EXPLANATION & USAGE ---:

pl_Radio-Browser_info.lua:
* This plugin is needed by sd_Radio-Browser_info.lua (!)
* It converts Radio-Browser.info api specific links into lists or readable radio links
* Generally you would not add such links manually

sd_Radio-Browser_info.lua:
* Radio-Browser.info Service Discovery plugin for VLC ... i.e. listed on the left panel under "Internet"
* Explore and crawls through all radio stations classified by categories
* Depends on the previous pl_Radio-Browser_info.lua for it to work
* After having found one or more list(s) of specific stations it is best to copy them into the playlist and continue searching and sorting there, since the Service Discovery zone is a little limited in its capabilities, especially after having found several list of sub categories.

ex_Radio-Browser_info.lua:
* Works standalone without the other two plugins
* A simple search to retrieve the search specific radio stations
* Search results are added to the existing (empty or non-empty) playlist
* The more specific a search the less results, even 0
* The dropdown lists will not update if one of the others dropdown is selected. This means you can have a situation where two or more selections of dropdown list produce 0 results, even though they specify existing stations in brackets, e.g. "Codec: AAC+ (102)" and "Language: Albania (27)".

--]]

function descriptor()
	return { title="Radio-Browser.info (Search)",
		description = "Radio-Browser.info (Search)",
		version = "0.5",
		author = "Andrew Jackson (ceever@web.de)",
		capabilities = {},
		url = "https://github.com/ceever"
	}
end

-- Parse CSV line ... from http://lua-users.org/wiki/LuaCsv
function ParseCSVLine(line,sep) 
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do 
		::continue::
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				if not endp then -- We won't fail on incomplete quotes
					pos = pos + 1
					goto continue
				end
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end

-- Getting a csv from Radio-Browser.info .. since xml breaks
function csv_request(path)
	local shuffled = {} -- The api demands a better handling here, but lua does not come with dns (reverse) lookup, so we have to rely on the current (Dec 2020) three servers.
	math.randomseed(os.time())
	for i, v in ipairs( {"fr1", "nl1", "de1"} ) do
		table.insert(shuffled, math.random(1, #shuffled+1), v)
	end
	csv = nil
	for _, ip in pairs( shuffled ) do
		-- Fuck that broken vlc xml streaming (!)
		csv = vlc.stream( "https://" .. ip .. ".api.radio-browser.info/csv/" .. path )
		server = ip
		if csv then
			break
		end
	end
	return csv
end

function add_dropdown(d, path, row)
	local csv = csv_request(path)
	if csv then
		csv:readline() -- Drop the headers
		obj = d:add_dropdown( 2, row, 1, 1 )
		i = 1
		obj:add_value( "", i ) -- Empty line at the beginning
		if "codecs" ~= path then obj:add_value( "<EMPTY> (?)", i ) end -- The empty option
		while true do
			tmp = csv:readline()
			if tmp then
				i = i + 1
				obj:add_value( tmp:gsub(",%d+", ""):gsub("\"", "") .. " (" .. tmp:match(",%d+"):sub(2, nil) .. ")", i )
			else
				break
			end
		end
	else 
		obj = d:add_text_input( "", 2, row, 1, 1 )
	end
	return obj
end

-- Creating the interaction windows
function activate()
	server = "fr1"
    d = vlc.dialog("Radio-Browser.info (Search)")

	d:add_label( "Name (the shorter, the more):", 1, 1, 1, 1 )
	d:add_label( "Tags (the less, the more):", 1, 2, 1, 1 )
	d:add_label( "Codec:", 1, 3, 1, 1 )
	d:add_label( "Country:", 1, 4, 1, 1 )
	d:add_label( "Language:", 1, 5, 1, 1 )
	
	d:add_label( "&nbsp; &nbsp; loading ...", 2, 3, 1, 1 )
	d:add_label( "&nbsp; &nbsp; loading ...", 2, 4, 1, 1 )
	d:add_label( "&nbsp; &nbsp; loading ...", 2, 5, 1, 1 )
	
	name = d:add_text_input( "", 2, 1, 1, 1 )
	tags = d:add_text_input( "", 2, 2, 1, 1 )

    button = d:add_button("Search", main, 2, 6, 1, 1)
    d:show()
	
	d:update()
	codec = add_dropdown(d, "codecs", 3)
	d:update()
	country = add_dropdown(d, "countries", 4)
	d:update()
	language = add_dropdown(d, "languages", 5)
end

-- Getting the HTML search string with nice "&"s to be placed after "...search?"
function get_strg()
	strg = ""
	if "" ~= name:get_text() then
		strg = strg .. "&name=" .. vlc.strings.encode_uri_component( name:get_text() )
	end
	if "" ~= tags:get_text() then
		strg = strg .. "&tagList=" .. vlc.strings.encode_uri_component( tags:get_text():gsub(" ", ",") )
	end
	if codec:get_text() then
		strg = strg .. "&codec=" .. vlc.strings.encode_uri_component( codec:get_text():gsub(" %(%d+%)", "") )
	end
	if country:get_text() then
		strg = strg .. "&country=" .. vlc.strings.encode_uri_component( country:get_text():gsub(" %([%d%?]+%)", ""):gsub("<EMPTY>", "") )
	end
	if language:get_text() then
		strg = strg .. "&languageExact=true&language=" .. vlc.strings.encode_uri_component( language:get_text():gsub(" %([%d%?]+%)", ""):gsub("<EMPTY>", "") )
	end
	
	return strg
end

function close()
	vlc.deactivate()
end

function deactivate()
	if d then
		d:hide() 
	end
end

-- Let's check for too large searches
function main()
	if "" == get_strg() then
		d:del_widget( button )
		button = d:add_button("Empty searches produce many results and take long! ... CHANGE or/and CONTINUE?", mainer, 2, 6, 1, 1)
		button_c = d:add_button("Cancel", close, 1, 6, 1, 1)
	else
		mainer()
	end
end

-- Let's search and fill the playlist ... this strongly depends on a stable/fixex csv structure (as of Dec 2020)
function mainer()
	d:del_widget( button )
	if button_c then d:del_widget( button_c ) end
	search = d:add_label( "<center><h3>Searching ...</h3></center>", 2, 6, 1, 1 )
	d:update()

	local csv = csv_request( "stations/search" .. get_strg():gsub("^&", "?") )

	tmp = csv:readline()
	if tmp then
		local size = 1
		local headers = {}
		for i, head in ipairs( ParseCSVLine(tmp) ) do
			headers[head] = i
			size = i
		end
		
		k = 1
		while true do
			search:set_text( "<center><h3>Searching ... " .. k .. "</h3></center>" )
			d:update()
			tmp = csv:readline()
			if tmp then
				line = ParseCSVLine( tmp )
				while not line[size] do
					tmp = tmp .. csv:readline()
					line = ParseCSVLine( tmp )
				end
						
				local cstrg = "     " .. line[headers["clickcount"]]
				local cstrlen = string.len(cstrg)
				local bstrg = "     " .. line[headers["bitrate"]]
				local bstrlen = string.len(bstrg)

				vlc.playlist.enqueue( {{
					path = "https://" .. server .. ".api.radio-browser.info/m3u/url/" .. line[headers["stationuuid"]], 
					title = line[headers["name"]],
					artist = "Clicks:" .. cstrg:sub(cstrlen-5, cstrlen),
					album = "Bitrate:" .. bstrg:sub(bstrlen-5, bstrlen) .. " / " .. line[headers["codec"]] .. " / " .. line[headers["language"]] .. " / " .. line[headers["country"]],
					copyright = line[headers["homepage"]],
					arturl = line[headers["favicon"]],
					description = line[headers["tags"]]
				}} )
				
				k = k + 1
			else
				break
			end
		end
		close()
	else
		d:del_widget( search )
		button_c = d:add_button("Cancel", close, 1, 6, 1, 1)
		button = d:add_button( "Nothing found! ... Retry with different parameters? ... CHANGE and GO!", main, 2, 6, 1, 1)
	end
	
	--vlc.playlist.enqueue( {{path="https://" .. server .. ".api.radio-browser.info/xml/stations/search" .. get_strg():gsub("^&", "?"), title = "Retrieving search ... please be patient!"}} )

end

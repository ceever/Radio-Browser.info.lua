--[[

 Radio-Browser.info lua script (playlist, i.e. URL conversion)

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
* Linux (all users): /usr/lib/vlc/lua/
* Linux (current user): ~/.local/share/vlc/lua/
(create directories if they don't exist)

According .lua file and according subfolder:
* ex_Radio-Browser_info.lua => ...\lua\extensions\
* sd_Radio-Browser_info.lua => ...\lua\sd\
* pl_Radio-Browser_info.lua => ...\lua\playlist\

Restart VLC.



--- EXPLANATION & USAGE ---:

pl_Radio-Browser_info.lua:
...* Converts Radio-Browser.info api specific links into lists or readable radio links
...* Generally you would not add such links manually, put this plugin is needed for sd_Radio-Browser_info.lua

sd_Radio-Browser_info.lua:
   * Radio-Browser.info Service Discovery plugin for VLC ... i.e. listed on the left panel under "Internet"
   * Explore and crawls through all radio stations classified by categories
   * Depends on the previous pl_Radio-Browser_info.lua for it to work
   * After having found one or more list(s) of specific stations it is best to copy them into the playlist and continue searching and sorting there, since the Service Discovery zone is a little limited in its capabilities, especially after having found several list of sub categories.

ex_Radio-Browser_info.lua:
...* Works standalone without the other two plugins
...* A simple search to retrieve the search specific radio stations
...* Search results are added to the existing (empty or non-empty) playlist
...* The more specific a search the less results, even 0
...* The dropdown lists will not update if one of the others dropdown is selected. This means you can have a situation were two or more selections of dropdown list produce 0 results, even though they specify existing stations in brackets, e.g. "Codec: AAC+ (102)" and "Language: Albania (27)".

--]]

require "simplexml"

function probe()
	return (( vlc.access == "http" or vlc.access == "https" )
	and string.match(vlc.path, ".+%.api%.radio%-browser%.info/xml/")
	)
end

function parse()
	local tracks = {}

	if string.match(vlc.path, ".+%.api%.radio%-browser%.info/xml/stations") then
		-- This part parses the final sub category URL (including the "All stations" option) that comes up with all stations. All stations have an URL like: api.radio-browser.info/m3u/url/UUID ... which lets the server count clicks and ultimately delivers the actual stations URL (not "url_resolved" however).
		-- We cannot vlc.stream() because the function breaks on long xml lines, not to mention json. Furthermore, we need to gsub() some weird characters that would otherwise break the xml parsing with simplexml.
		local tree = simplexml.parse_string( string.gsub(vlc.read(200000000), "[%z%c%s]+\"", "\"") )
		local base_url = vlc.access .. "://" .. string.sub( vlc.path, 1, string.find( vlc.path, "/xml") )

		for _, result in ipairs( tree.children ) do
			simplexml.add_name_maps( result )

			-- Making clickcount (Arist column) and bitrate (Album column) sortable, we have to make them the same length (6 chars) and add spaces before shorter numbers.
			local cstrg = "     " .. result.attributes["clickcount"]
			local cstrlen = string.len(cstrg)
			local bstrg = "     " .. result.attributes["bitrate"]
			local bstrlen = string.len(bstrg)

			table.insert( tracks, {
				path = base_url .. "m3u/url/" .. result.attributes["stationuuid"], 
				title = result.attributes["name"],
				artist = "Clicks:" .. cstrg:sub(cstrlen-5, cstrlen),
				album = "Bitrate:" .. bstrg:sub(bstrlen-5, bstrlen) .. " / " .. result.attributes["codec"] .. " / " .. result.attributes["language"] .. " / " .. result.attributes["country"],
				copyright = result.attributes["homepage"],
				arturl = result.attributes["favicon"],
				description = result.attributes["tags"]
			} )
		end
	else
		-- This part parses the categories options ("By country", etc) and comes up the available sub categories. "codecs" might be skipped here, because we potentially parsed it already with the creation of the categories to obtain the overall station count.
		local cats = { ["codecs"] = "bycodecexact/", ["tags"] = "bytagexact/", ["languages"] = "bylanguageexact/", ["countries"] = "bycountryexact/" }
		local cat = string.gsub( string.gsub(vlc.path, ".+%.api%.radio%-browser%.info/xml/", ""), "/", "" )
		local which = vlc.access .. "://" .. string.gsub(vlc.path, cat .. "/*", "") .. "stations/" .. cats[ cat ]

		-- Except for codecs the "empty" subcategory is always missing from the server answer, so we have to add it manually.
		if "codecs" ~= cat then table.insert( tracks, {path = which, title = "<EMPTY>", artist = "    ?"} ) end
		
		local tree = simplexml.parse_string( string.gsub(vlc.read(200000000), "[%z%c%s]+\"", "\"") )
		for _, result in ipairs( tree.children ) do
			simplexml.add_name_maps( result )
			strg = "     " .. result.attributes["stationcount"]
			strlen = string.len(strg)
			table.insert( tracks, {path = which .. vlc.strings.encode_uri_component(result.attributes["name"]), title = result.attributes["name"], artist = "Count:" .. strg:sub(strlen-5, strlen)} )
		end
	end
	
	return tracks
end
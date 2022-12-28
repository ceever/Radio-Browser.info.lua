--[[

 Radio-Browser.info 0.59 lua script (service discovery playlist plugin)

 Copyright © 2020 Andrew Jackson (https://github.com/ceever)

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

Put the according .lua file in the according subfolder (see below) of the VLC lua directory. VLC lua directory by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\
* Windows (current user): %APPDATA%\VLC\lua\
* Linux (all users): /usr/share/vlc/lua/
* Linux (current user): ~/.local/share/vlc/lua/
(create directories if they don't exist)

According .lua file and according subfolder:
* ex_Radio_Browser_info.lua => ...\lua\extensions\
* sd_Radio_Browser_info.lua => ...\lua\sd\
* pl_Radio_Browser_info.lua => ...\lua\playlist\

(In case you want a nice picture with the search extension, place the "Radio-Browser.png" picture from the Github "/gfx" folder into "...\lua\extensions\" and change the absolute path of the picture inside "ex_Radio_Browser_info.lua"—search for "d:add_image(..." in the lua code.)

Restart VLC.


--- EXPLANATION & USAGE ---:

**Important**: The (VLC) columns *Album*, *Genre* and *Description* will hold relevant information for each station, namely: 1) Album: either *Count: XXXX* or *Clicks: XXXX* (to sort on number of stations or popularity), 2) Genre: a genre desciption, and 3) Description: sortable Bitrate information.

However, you are better off importing all (relevant) stations into the playlist first (right click), before trying to sort anything. Sorting on items and folders at the same in the Service Discover is not so intuitive.

pl_Radio-Browser_info.lua:
* This plugin is needed by sd_Radio-Browser_info.lua (!)
* It converts Radio-Browser.info api specific links into lists or readable radio links
* Generally you would not add such links manually

sd_Radio-Browser_info.lua:
* Radio-Browser.info Service Discovery plugin for VLC ... i.e. listed on the left panel under "Internet"
* Explore and crawls through all radio stations classified by categories
* Depends on the previous pl_Radio-Browser_info.lua for it to work
* After having found one or more list(s) of specific stations it is best to copy them into the playlist and continue searching and sorting there, since the Service Discovery zone is a little limited in its capabilities, especially after having found several list of sub categories.
* Be careful trying to load "All stations (..." !. This might fail due to the cheer size of the request, or it will let VLC crash, depending on you system ressources.

ex_Radio-Browser_info.lua:
* Works standalone without the other two plugins
* A simple search to retrieve the search specific radio stations
* Search results are added to the existing (empty or non-empty) playlist
* The more specific a search the less results, even 0
* The dropdown lists will not update if one of the others dropdown is selected. This means you can have a situation where two or more selections of dropdown list produce 0 results, even though they specify existing stations in brackets, e.g. "Codec: AAC+ (102)" and "Language: Albania (27)".

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

			-- Making clickcount and bitrate sortable, we have to make them the same length (6 chars) and add spaces before shorter numbers.
			local cstrg = "     " .. result.attributes["clickcount"]
			local cstrlen = string.len(cstrg)
			local bstrg = "     " .. result.attributes["bitrate"]
			local bstrlen = string.len(bstrg)

			-- We cannot work with "m3u/url/stationuuid" paths for click counting, because VLC just resolves them and does not continue playing in SD. In playlist they get resolved, but the player jumps to the next item, which would be the resolved url unless VLC is in random—then it goes mental. ... >> base_url .. "m3u/url/" .. result.attributes["stationuuid"] <<
			local path = result.attributes["url"]
			if string.match(string.lower(result.attributes["url"]), ".pls$")
			or string.match(string.lower(result.attributes["url"]), ".m3u$")
			or string.match(string.lower(result.attributes["url"]), ".m3u8$")
			or string.match(string.lower(result.attributes["url"]), ".xspf$")
			or string.match(string.lower(result.attributes["url"]), ".asx$")
			or string.match(string.lower(result.attributes["url"]), ".smil$")
			or string.match(string.lower(result.attributes["url"]), ".vlc$")
			or string.match(string.lower(result.attributes["url"]), ".wpl$") then
				path = result.attributes["url_resolved"]
			end
			table.insert( tracks, {
				path = path,
				title = result.attributes["name"],
				album = "Clicks:" .. cstrg:sub(cstrlen-5, cstrlen),
				description = "Bitrate:" .. bstrg:sub(bstrlen-5, bstrlen) .. " / " .. result.attributes["codec"] .. " / " .. result.attributes["language"] .. " / " .. result.attributes["country"],
				copyright = result.attributes["homepage"],
				arturl = result.attributes["favicon"],
				genre = result.attributes["tags"]
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
			table.insert( tracks, {path = which .. vlc.strings.encode_uri_component(result.attributes["name"]), title = result.attributes["name"], album = "Count:" .. strg:sub(strlen-5, strlen)} )
		end
	end
	
	return tracks
end

--[[

 Radio-Browser.info 0.59 lua script (service discovery)

 Copyright © 2022 Andrew Jackson (https://github.com/ceever)

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

ex_Radio-Browser_info.lua:
* Works standalone without the other two plugins
* A simple search to retrieve the search specific radio stations
* Search results are added to the existing (empty or non-empty) playlist
* The more specific a search the less results, even 0
* The dropdown lists will not update if one of the others dropdown is selected. This means you can have a situation where two or more selections of dropdown list produce 0 results, even though they specify existing stations in brackets, e.g. "Codec: AAC+ (102)" and "Language: Albania (27)".

--]]

function descriptor()
	return { title="Radio-Browser.info",
		description = "Radio-Browser.info (Service Discovery)",
		version = "0.59",
		author = "Andrew Jackson",
		capabilities = {},
		url = "https://github.com/ceever"
	}
end

function main()
	local count = 0
	local cats = {}

	local shuffled = {}
	-- The api demands a better handling here, but lua does not come with dns (reverse) lookup, so we have to rely on the current (Dec 2020) three servers.
	math.randomseed(os.time())
	for i, v in ipairs( {"at1", "nl1", "de1"} ) do
		local pos = math.random(1, #shuffled+1)
		table.insert(shuffled, pos, v)
	end

	-- We pre-read codecs (if possible) to built a first list of subcateories (under "By codec") and to obtain the overall station count. The count only works for codecs, since for all other categories the "empty" subcategory is missing from the subcategory listin the server answer.
	local part = shuffled[1]
	for _, ip in pairs( shuffled ) do
		-- Fuck that broken vlc xml streaming (!)
		csv = vlc.stream( "https://" .. ip .. ".api.radio-browser.info/csv/codecs" )
		if csv then
			part = ip
			break
		end
	end

	local base_url = "https://" .. part .. ".api.radio-browser.info/xml/"

	if csv and csv:readline() then -- Drop the headers and validate at the same time
		local node = vlc.sd.add_node( {title = "By codec ... (pre-read)", path = ""} )
		while true do
			tmp = csv:readline()
			if tmp then
				count = count + tonumber(tmp:match(",%d+"):sub(2, nil))
				strg = "     " .. tmp:match(",%d+"):sub(2, nil)
				strlen = string.len(strg)
				node:add_subitem( { title = tmp:gsub(",%d+", ""):gsub("\"", ""), album = "Count:" .. strg:sub(strlen-5, strlen), path = base_url .. "stations/bycodecexact/" .. vlc.strings.encode_uri_component(tmp:gsub(",%d+", ""):gsub("\"", "")) } )
			else
				break
			end
		end
	else
		table.insert( cats, {"By codec ...", base_url .. "codecs"} )
	end
	
	-- Now the other categories
	table.insert( cats, {"By tag ...", base_url .. "tags"} )
	table.insert( cats, {"By language ...", base_url .. "languages"} )
	table.insert( cats, {"By country ...", base_url .. "countries"} )
	
	for _, item in ipairs( cats ) do
		vlc.sd.add_item( {title = item[1], path = item[2]} )
	end

	-- Also an "All stations" category separate because here we add the overall count of stations from the (hopefully worked) "By codec" part.
	tmp = ""
	if 0 < count then tmp = "Count: " .. tostring(count) end
	vlc.sd.add_item( {title = "All stations (Careful! Might timeout due to length ...)", path = base_url .. "stations", album = tmp} )
end

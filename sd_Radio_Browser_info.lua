--[[

 Radio-Browser.info 0.59 add-on/lua script for VLC (Service Discovery / Internet)

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

Send me a mail or a ticket on github: https://github.com/ceever/Radio-Browser.info.lua
In case you use LXQt, Lubuntu or Gnome, checkout my other project: https://github.com/ceever/PCManFM-Qt-Context-Menu


--- INSTALLATION ---:

Put the relevant .lua file(s) into the according subfolder (see below) of the VLC lua directory. VLC lua directory by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\
* Windows (current user): %APPDATA%\VLC\lua\
* Linux (all users): /usr/share/vlc/lua/
* Linux (current user): ~/.local/share/vlc/lua/
(create directories if they don't exist)

.lua files and according subfolder:
* ex_Radio_Browser_info.lua => ...\lua\extensions\
* sd_Radio_Browser_info.lua => ...\lua\sd\
* pl_Radio_Browser_info.lua => ...\lua\playlist\

(In case you want the nice smiley with the search extension as in the screenshots, place the "Radio-Browser.png" picture from the Github "gfx/" folder or the zip repository into "...\lua\extensions\" and change the path of the picture 'd:add_image("PATH")' in the "ex_Radio_Browser_info.lua" script.
Note, under MS Windows you may need to use double backslashes, e.g. 'd:add_image("C:\\Program Files\\VideoLAN\\VLC\\lua\\extensions\\Radio-Browser.png")')

Restart VLC.


--- EXPLANATION & USAGE ---:

**Important**: With these add-ons the VLC columns *Album*, *Genre* and *Description* will hold relevant information for each radio station, namely: 1) Album: either *Count: XXXX* or *Clicks: XXXX* (to sort on number of stations or popularity), 2) Genre: a genre desciption, and 3) Description: sortable Bitrate information. So, have them displayed and try to use them if feasible.

Inside the Service Discover / Internet tab of VLC you are better off transferring all (relevant) stations into the regular VLC playlist first (right click >> "Add to Playlist"), before trying to sort anything.

pl_Radio-Browser_info.lua (playlist plugin for Service Discovery):
* This plugin is needed by sd_Radio-Browser_info.lua (!).
* It converts Radio-Browser.info API specific links into lists or readable radio links.
* Generally you would not add such links manually.

sd_Radio-Browser_info.lua (Service Discovery / Internet):
* Service Discovery / Internet add-on for VLC ... i.e. listed on the left panel under "Internet".
* Explore and crawls through all radio stations classified by categories (codec, language, country, tag).
* It depends on pl_Radio-Browser_info.lua—both need to be installed at the same time.
* After having found one or more stations in the Service Discovery / Internet, it is best to copy them into the playlist (right click >> "Add to Playlist") and continue searching and them sorting there. The Service Discovery is a little limited in its sorting capabilities, especially after having explored several sub categories.

ex_Radio-Browser_info.lua (Search window):
* Found under the VLC menu: View >> "Radio-Browser.info (Search)"
* This can work standalone, without the other two add-ons/lua scripts.
* Found radio stations are counted, and can be added to the regular (empty or non-empty) VLC playlist.
* Dropdown lists will not update (counts nor values) if one of the others search parameters is specified. Thus, even when specific stations exist, e.g. "Codec: AAC+ (102)" and "Language: Albania (27)", together they might not produce any results.
* In general, the more specific the search the less radio stations—some search parameters might exclude each other, e.g. language=afrikaans and country=Russia.

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

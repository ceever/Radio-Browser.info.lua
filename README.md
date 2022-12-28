## Radio-Browser.info Addons for VLC

**VLC Service discovery, playlist and search addons (aka lua scripts) for the Radio-Browser.info database**

Website / DB: https://www.radio-browser.info/

Various apps and add-ons: https://www.radio-browser.info/users

<img src="gfx/Radio-Browser.png"/>

---
 Copyright © 2022 Andrew Jackson (https://github.com/ceever)

 This program is free software; you can redistribute it and/or modify
 it under the terms of the **GNU General Public License** as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.

---
**The search window:**
<p style="align:center">
<img src="gfx/search.png" width="675"/>
</p>
 
 **The service discovery and category lists:** 
<p style="vertical-align:top;white-space:nowrap;">
<img src="gfx/sd.png" width="320"/>
<img src="gfx/sd_list.png" width="350"/>
</p>

---
**BUGS & REQUESTS:**

Send me an email or open a ticket on github.

---
**INSTALLATION:**

Put the according .lua file in the according subfolder (see below) of the VLC lua directory. VLC lua directory by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\
* Windows (current user): %APPDATA%\VLC\lua\
* Linux (all users): /usr/lib/vlc/lua/ or /usr/lib/x86_64-linux-gnu/vlc/lua/
* Linux (current user): ~/.local/share/vlc/lua/
(create directories if they don't exist)

According .lua file and according subfolder:
* ex_Radio_Browser_info.lua => ...\lua\extensions\
* sd_Radio_Browser_info.lua => ...\lua\sd\
* pl_Radio_Browser_info.lua => ...\lua\playlist\

(In case you want a nice picture with the search extension, place the "Radio-Browser.png" picture from the Github "/gfx" folder into "...\lua\extensions\" and change the absolute path of the picture inside "ex_Radio_Browser_info.lua"—search for "d:add_image(..." in the lua code.)

Restart VLC.

---
**EXPLANATION & USAGE:**

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

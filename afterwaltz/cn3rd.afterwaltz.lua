--[[
	Use Aegisub to time and translate type for your typesetters,
	And run this utility script to create AE-ready typesets.
]]--

local tr = aegisub.gettext
local re = require 'aegisub.re';

script_description=tr"Converts timed TS to video files you can work on using AFX"
script_author="cN3d"
script_version="0.1"
script_namespace="cnrd.afterwaltz"

-- Settings
afterwaltzFolder = aegisub.decode_path("?data").."\\automation\\autoload\\afterwaltz\\"
vDubExe = afterwaltzFolder.."vdb\\vdub64.exe";
batPath = afterwaltzFolder.."batch.bat"
scriptPath = afterwaltzFolder.."script.vdscript"

-- DO NOT EDIT BELOW
function afterwaltz_vprep(str)
	return string.gsub(str, "\\", "\\\\")
end

function afterwaltz_prepare()
	-- Information gathering based on AegisubMotion script ("TrimHandler.moon")
	autoGetFN = true;
	video_folder = aegisub.decode_path("?video");
	video_path,video_fName = "";
	if autoGetFN then
		video_path = aegisub.project_properties().video_file;
		video_fName = aegisub.project_properties().video_file:gsub("^[A-Z]:\\", "", 1):gsub(".+[^\\/]-[\\/]", "", 1):match("(.+)%.[^%.]+$"):gsub("_"," ")
		if trimGroupName then video_fName = video_fName:gsub("^[%s_]*%[.-%][%s_]*","") end
		if trimCRC then video_fName = video_fName:gsub("[%s_]*%[%w-%]$","") end
	end
	
	-- prepare bat file
	local executable = "\""..vDubExe.."\"";
	local command = executable.." /s \""..scriptPath.."\""
	
	file = io.open(batPath,"w")
	file:write(command);
	file:close();
end

function afterwaltz_waltz(subtitles,selected_lines,active_line)
	-- todo: read the script from template file, replace in neccesary places
	local vdscript = [[
VirtualDub.audio.SetSource(0);
VirtualDub.audio.SetMode(0);
VirtualDub.audio.SetInterleave(1,500,1,0,0);
VirtualDub.audio.SetClipMode(1,1);
VirtualDub.audio.SetEditMode(1);
VirtualDub.audio.SetConversion(0,0,0,0,0);
VirtualDub.audio.SetVolume();
VirtualDub.audio.SetCompression();
VirtualDub.audio.EnableFilterGraph(0);
VirtualDub.video.SetInputFormat(0);
VirtualDub.video.SetOutputFormat(7);
VirtualDub.video.SetMode(1);
VirtualDub.video.SetSmartRendering(0);
VirtualDub.video.SetPreserveEmptyFrames(0);
VirtualDub.video.SetFrameRate2(0,0,1);
VirtualDub.video.SetIVTC(0, 0, 0, 0);
VirtualDub.video.SetCompression(0x7367616c,0,10000,0);
VirtualDub.video.SetCompData(1,"AA==");
VirtualDub.video.filters.Clear();
VirtualDub.audio.filters.Clear();

VirtualDub.Open("]]..afterwaltz_vprep(video_path)..[[");]]
	
	-- waltz all lines together in one file
	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		local startFrm = aegisub.frame_from_ms(l.start_time)
		local endFrm = aegisub.frame_from_ms(l.end_time)

		vdscript = vdscript..[[
VirtualDub.video.SetRangeFrames(]]..startFrm..[[,]]..endFrm..[[);
VirtualDub.project.ClearTextInfo();

VirtualDub.SaveAVI("]]..afterwaltz_vprep(video_folder.."\\")..startFrm..", "..(endFrm-1)..".avi"..[[");]];
	end
	vdscript = vdscript.."VirtualDub.Close();"
	
	-- write to file
	file = io.open(scriptPath,"w")
	file:write(vdscript);
	file:close();
	
	-- run!
	os.execute(batPath);
end

function afterwaltz(subtitles, selected_lines, active_line)
	-- check if a video file is loaded (we "could" guess the current frame but we prefer Aegisub's battle-tested framework to do so for us)
	if (aegisub.project_properties().video_file == "") then
		aegisub.log(0,tr"You must load a video file!");
		return
	end
	
	afterwaltz_prepare();
	
	-- prepare YV12 rendering
	os.execute("reg add HKEY_CURRENT_USER\\Software\\Lagarith   /v Mode /t REG_SZ /d YV12  /f");
	
	afterwaltz_waltz(subtitles, selected_lines, active_line);
	
	-- set it as RGBA for AFX
	os.execute("reg add HKEY_CURRENT_USER\\Software\\Lagarith   /v Mode /t REG_SZ /d RGBA  /f");

end

-- AFTER POLKA
-- Print anything - including nested tables
function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, "{\n");
        table.insert(sb, table_print (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end


function afterpolka_loadSettings()
	local cttt = {polka=1}
	aegisub.log(0,to_string(cttt))
end

function afterpolka(subtitles, selected_lines, active_line)
	afterpolka_loadSettings()
	config = {
		{class = "label", label="abs",x=0,y=0}, {class = "edit", name="" ,text="aaa",x=1,y=0}

	}
	btn,result = aegisub.dialog.display(config,
        {"Frobulate", "Nevermind"})
	if btn then aegisub.log(result) end
end

-- TODO future versions
function aftertango(subtitles, selected_lines, active_line)
end

aegisub.register_macro("After Waltz/Waltz (export AFX raws)",script_description,afterwaltz)
--aegisub.register_macro("After Waltz/Tango (prepare avisynth file)",script_description,aftertango)
aegisub.register_macro("After Waltz/Polka (plugin settings)",script_description,afterpolka)
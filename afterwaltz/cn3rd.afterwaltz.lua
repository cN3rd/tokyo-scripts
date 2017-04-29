--[[
	Use Aegisub to time and translate type for your typesetters,
	And run this utility script to create AE-ready typesets.
]]--

local tr = aegisub.gettext
local re = require 'aegisub.re';

script_description=tr"Converts timed TS to video files you can work on using AFX"
script_author="cN3d"
script_version="0.2"
script_namespace="cnrd.afterwaltz"

-- Settings
config = {}
config["awFold"] = aegisub.decode_path("?data").."\\automation\\autoload\\afterwaltz\\"
config["vDubExe"] = config["awFold"].."vdb\\vdub64.exe";
config["batPath"] = config["awFold"].."batch.bat"
config["scriptPath"] = config["awFold"].."script.vdscript"
config["debugMode"] = false;

-- GENERAL FUNCTIONS

-- AFTER.WALTZ
function afterwaltz_vprep(str)
	return string.gsub(str, "\\", "\\\\")
end

function afterwaltz_frm(ms)
	return aegisub.frame_from_ms(ms);
end

function afterwaltz_readf(path)
	local f = io.open('tmp.txt')
	if not f then return nil end
	fContent =f:read "*a";
	f:close();
	return fContent;
end

function afterwaltz_execute(command)
   if debugMode then
		if pcall(function () os.execute(command..' > tmp.txt') end) then
			fContent = afterwaltz_readf('tmp.txt');
			aegisub.log(0,"\n------------------");
			aegisub.log(0,fContent);
			return true, fContent
		else
			aegisub.log(0,">"..command..' > tmp.txt');
			aegisub.log(0,"\nFailed");
			return false;
		end
	else
		return pcall(function () os.execute(command) end)
	end
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
	local executable = "\""..config["vDubExe"].."\"";
	local command = executable.." /s \""..config["scriptPath"].."\""
	
	f = assert(io.open(config["batPath"], "w"));
	f:write(command);
	f:close();
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
VirtualDub.Open("]]..afterwaltz_vprep(video_path)..[[");
]]
	
	-- waltz all lines together in one file
	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		local startFrm = afterwaltz_frm(l.start_time)
		local endFrm = afterwaltz_frm(l.end_time)

		vdscript = vdscript..[[VirtualDub.video.SetRangeFrames(]]..startFrm..[[,]]..endFrm..[[);
VirtualDub.SaveAVI("]]..afterwaltz_vprep(video_folder.."\\")..startFrm..", "..(endFrm-1)..".avi"..[[");
]];
	end
	vdscript = vdscript..[[VirtualDub.project.ClearTextInfo();
VirtualDub.Close();]]
	
	-- write to file
	f = io.open(config["scriptPath"],"w")
	f:write(vdscript);
	f:close();
	
	-- run!
	afterwaltz_execute("\""..config["batPath"].."\"");
end

function afterwaltz(subtitles, selected_lines, active_line)
	-- check if a video file is loaded (we "could" guess the current frame but we prefer Aegisub's battle-tested framework to do so for us)
	if (aegisub.project_properties().video_file == "") then
		aegisub.log(0,tr"You must load a video file!");
		return
	end
	
	afterwaltz_prepare();
	
	-- prepare YV12 rendering
	afterwaltz_execute("reg add HKEY_CURRENT_USER\\Software\\Lagarith   /v Mode /t REG_SZ /d YV12  /f");
	
	afterwaltz_waltz(subtitles, selected_lines, active_line);
	
	-- set it as RGBA for AFX
	afterwaltz_execute("reg add HKEY_CURRENT_USER\\Software\\Lagarith   /v Mode /t REG_SZ /d RGBA  /f");

end

function aw_evaltokens(str)
	return str
		:gsub("{autofold}", aegisub.decode_path("?data").."\\automation\\autoload")
		:gsub("{awfold}", config["awFold"])
		:gsub("{vdbexe}",config["vdbexe"])
		:gsub("{sfold}","")
		:gsub("{vfold}","")
end

-- AFTER.POLKA
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function afterpolka_loadSettings()
	local cttt = {polka=1}
end

function afterpolka(subtitles, selected_lines, active_line)
	afterpolka_loadSettings()
	config = {
		{width=15,height=1,y=0,class="label",label="AfterWaltz base path:"},
		{width=15,height=1,y=1,class="textbox",name="awFold",value="{autofold}\\afterwaltz"},
		{width=15,height=1,y=2,class="label",label="VirtualDub executeable path:"},
		{width=15,height=1,y=3,class="textbox",name="vdbExePath",value="{awfold}\\vdb\\vdub64.exe"},
		{width=15,height=1,y=4,class="label",label="Full path template for exported types:"},
		{width=15,height=1,y=5,class="textbox",name="txPath",value="{vfold}\\{start}, {end}.avi"},
		{width=15,height=1,y=6,class="checkbox", name="debugMode",label="Allow debug mode (debug prints)										",value=false},
		{width=15,height=1,y=7,class="label", label=[[
		
Allowed Tokens:
{autofold}: Aegisub Automation4 autoload folder (full path)
{awfold}: AfterWaltz folder (full path)
{end}: End frame (for a given TS)
{start}: Start frame  (for a given TS)
{sfold}: Subtitles folder (full path)
{vdbexe}: VirtualDub executable (full path)
{vfold}: Video folder]]}
	}
	btn, result = aegisub.dialog.display(config,
			{tr"Ok", tr"cancel"})
	--if btn then aegisub.log(0,dump(result)) end
end

-- TODO future versions
function aftertango(subtitles, selected_lines, active_line)
end

aegisub.register_macro("After Waltz/Waltz (export AFX raws)",script_description,afterwaltz)
--aegisub.register_macro("After Waltz/Tango (prepare avisynth file)",script_description,aftertango)
aegisub.register_macro("After Waltz/Polka (plugin settings)",script_description,afterpolka)
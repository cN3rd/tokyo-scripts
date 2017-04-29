--------------------------------
-- Utils
---------------------------------
function msfix(t)
	return math.ceil(t/fDur)*fDur
end

function relfrm(l,s)
	return frm(l.start_time+s.start_time)-frm(l.start_time)
end

function relfrm2(l,s)
	return frm(s.start_time)-frm(l.start_time)
end

function frm(t)
	return math.floor(msfix(t)/fDur)
end

function round(n)
  return math.floor((math.floor(n*2) + 1)/2)
end


function clrtag(text)
  --[[ Move first \k tag in override blocks to the front ]]
  return string.gsub(text, "{([^{}]-)(.-)}","") 
end

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
function calculateM(max)
  frClr = {}
  color = yellow
  for i=1,max do
    if next(kf) and i > kf[1][3] then table.remove(kf,1) end
    if next(kf) and (i <= kf[1][3] and kf[1][1] <= i) then
        progress = (i-kf[1][1])/(kf[1][3]-kf[1][1])
        color = utils.interpolate(progress,kf[1][2],kf[1][4])
    end
    table.insert(frClr,color)
  end
  return frClr
end

--------------------------------
-- Pixelization
---------------------------------
squareSize = 5;
fps = 24000/1001;
fDur = 1000/fps;
fOut = 1000
amp = 3;
bezel = 12;

correctY = {}
correctY["EDKara-Romaji"] = 889
correctY["EDKara-TL"] = 967
correctY["EDTalk-Romaji"]=60
correctY["EDTalk-TL"]=126

yellow = "&H56FBFF&"
blue = "&HDE1429&"
kf = {{565,yellow,568,blue},{857,blue,858,yellow},{1577,yellow,1581,blue},{1683,blue,1688,yellow}}
colors = calculateM(2182)

function pixelize(syl, l, inverse, type, relfrm, showshape, rtl)
	-- initializing matrix
	bezel = 0.05*syl.width
	lines = {}
	deltas = {}
	grWidth = math.ceil((syl.width+bezel*2)/squareSize)
	grHeight = math.ceil((syl.height+5)/squareSize)
	for i=0,grHeight-1 do
		lines[i] = 0
		deltas[i] = 0
	end
	
	-- initializing relative values
	if rtl then
		sX = syl.right + bezel;
	else
		sX = syl.left - bezel;
	end
	sY = correctY[l.style]
	ss = l.start_time
	se = l.end_time

	-- initializing lines texts
	preStr = string.format("{\\%s(m %d %d",inverse and "iclip" or "clip",sX,sY-bezel)
	postStr = string.format(" l %d %d)}",sX-bezel,sY+grHeight*squareSize)
	shapeStr = "{\\bord0\\shad0\\p1\\pos(0,0)}"
	txt = string.format("{\\pos(%d,%d)}%s", syl.x, syl.y, syl.text)
		
	-- do pixelization
	for s, e, i, n in utils.frames(ss, se, fDur) do
			-- fixing times to prevent frame drops
			l.start_time = msfix(s)
			l.end_time = msfix(e)
			thold = type=="syl" and math.ceil(grWidth/n/1.5) or math.ceil(grWidth/n)
			
			-- initialize strings again
			str = preStr
			shape = shapeStr
			
			for j=0, grHeight-1 do
				-- add previous deltas to lines
				lines[j] = lines[j] + deltas[j]
				
				-- calculate deltas for next round
				deltas[j] = round(math.random())*thold+thold
				deltas[j] = lines[j] + deltas[j] > grWidth and 0 or deltas[j]
				if rtl then
					lX = sX-lines[j]*squareSize
				else
					lX = sX+lines[j]*squareSize
				end
				lY = sY+j*squareSize

				-- add to mask
				str = str.. string.format(" l %d %d l %d %d",lX,lY,lX,(lY+squareSize))
								
				-- add to shape
				wdth = math.floor(deltas[j]/thold)*squareSize
				if rtl then
					lxEnd = lX
					lX = lX-wdth
				else
					lxEnd = lX+wdth
				end
				shape = shape.. string.format(" m %d %d l %d %d l %d %d l %d %d l %d %d",lX,lY, lxEnd,lY, lxEnd,(lY+squareSize), lX,(lY+squareSize), lX,lY)
			end
			
			-- create lines
			str = str..postStr
			l.text = str..txt
			sh = table.copy(l)
			sh.style = "FFFF"
			sh.text = string.format("{\\c%s}",colors[frm(l.start_time)+1])..shape
			
			-- FFFFFFFF it
			if showshape then io.write_line(sh) end
			io.write_line(l)
	end
	
	return color
end

---------------------------------
-- Line proccessors
---------------------------------
-- Prefrernces
fadSub = 25
fadRom = 40
ddd = 2/3 -- duration of pixelization (relative to syllable time) (perhaps test value)
atRom = 1000
atSub = 1000 -- additional time for subs

-- Romaji
function romaji(line, l)
	--TODO
	charCnt = 0
	l2 = table.copy(l)
	l2.layer = 0
	l2.text = "{\\1a&HFF&\\3a&H7F&}"..line.text
	l2.start_time = l2.start_time - 250
	l2.end_time = l2.end_time - 750
	sub(l2,table.copy(l2),false, false)
	l.layer = 2
	for syl_index, syl in ipairs(line.syls) do
		if syl.text ~= "" then
			-- init values
			ltag = table.copy(l)
						
			-- pix-in
			ltag.start_time = msfix(line.start_time+syl.start_time)
			ltag.end_time = msfix(line.start_time+syl.start_time+syl.duration*ddd)
			color = pixelize(syl,ltag,false,"syl",relfrm(line,syl),true,false);
			
			-- line duration
			ltag.start_time = ltag.end_time
			ltag.end_time = msfix(line.end_time + atRom - (line.text:len()-charCnt)*fadRom)
			ltag.text = string.format("{\\pos(%d,%d)}%s", syl.x, syl.y, syl.text)
			io.write_line(ltag)
			charCnt = charCnt + syl.text:len()
		end
	end
	
	-- line fadeouts
	charCnt = 0
	for syl_index, syl in ipairs(line.syls) do
		if syl.text ~= "" then
			ltag = table.copy(l)
			ltag.end_time = msfix(line.end_time + atRom - (line.text:len()-charCnt)*fadRom)
			ltag.start_time = ltag.end_time
			ltag.end_time = ltag.end_time + syl.text:len()*fadRom	
			color = pixelize(syl,ltag,true,"syl",relfrm2(line,ltag),true,false);
			charCnt = charCnt + syl.text:len()
		end
	end
end


-- Subtitle
function sub(line, l, rtl)
	ltag = table.copy(l)
	
	-- pix-in
	ltag.start_time = msfix(line.start_time)
	ltag.end_time = msfix(line.start_time+fadSub*line.text:len())
	pixelize(l,ltag,false,"line",0,true,rtl)
	
	-- line duration
	ltag.text = string.format("{\\pos(%d,%d)}%s",line.x,line.y,line.text)
	ltag.start_time = msfix(ltag.end_time)
	ltag.end_time = msfix(msfix(line.end_time+atSub-fadSub*clrtag(line.text):len()+fDur*2)-fDur*2,true)
	io.write_line(ltag)
	
	-- pix-out
	ltag.text = line.text
	ltag.start_time = ltag.end_time
	ltag.end_time = msfix(line.end_time+atSub)
	pixelize(l,ltag,true,"line",relfrm2(line,ltag),true,rtl)
end

---------------------------------
-- Actual Processor
---------------------------------
for li, line in ipairs(lines) do
	if not line.comment then
		local l = table.copy(line);
		if (line.styleref.name == "EDKara-Romaji") then
			romaji( line, table.copy(line) )
		else
			if line.styleref.name == "EDKara-TL" or line.styleref.name == "EDTalk-TL" then
				sub( line, table.copy(line), true )
			else
				sub( line, table.copy(line), false )
			end
		end
	end
end
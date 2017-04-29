-- Global variables for character twitching
boMax = 100
boMin = 97
fDur = 1000/(24000/1001)
fSkip = 5
fadSpacing = 10
fadDur = fDur*3

-- rtl 
function twitchChars(line, l, rtlFad, maxRot, deltaDivisor, heb)
	st = l.start_time
	et = l.end_time
	
	-- handle syls
	for _, syl in ipairs(line.chars) do
		if heb then
			syl.x = 1920-syl.x
		end
	
		-- fade in
		l.text = string.format("{\\pos(%d,%d)\\alpha&HFF&\\blur10\\t(\\blur0\\alpha&H0&)}%s",syl.x,syl.y,syl.text)
		fadSp = rtlFad and math.floor((syl.i)*fadSpacing/fDur)*fDur or math.floor((#line.chars-syl.i)*fadSpacing/fDur)*fDur
		l.start_time = st-fadSp-fDur
		l.end_time = l.start_time+fadDur
		io.write_line(l)
	
		-- setting up twitch times
		stt = l.end_time
		ett = et-fadSp
		
		-- effect
		for s, e, i, n in utils.frames(stt, ett, fDur*fSkip) do
			-- fixing times to prevent frame drops
			l.start_time = math.ceil(s/fDur)*fDur
			l.end_time = math.ceil(e/fDur)*fDur
			
			-- calculating random rotation and delta x
			rot = math.random(maxRot)-maxRot/2
			deltaX = rot/deltaDivisor
			
			-- initial text

			l.text = string.format("{\\frz%d\\pos(%d,%d)}%s",rot,syl.x-deltaX,syl.y,syl.text)
			
			-- random "stroke"-ing
			if math.random(boMax) > boMin then
			l.text = "{\\1a&HFF&\\2a&HFF&\\bord3\\3c&HFFFFFF&}"..l.text
			end
			
			-- writing line
			io.write_line(l)
		end
		
		-- fade out
		l.start_time = l.end_time
		l.end_time = l.end_time+fadDur
		l.text = "{\\t(\\be10\\alpha&HFF&)}"..l.text
		io.write_line(l)
	end
end

crgb = convert.rgb_to_ass -- just because I don't wanna copy it every time.
scaleFactorX = 1.05
scaleFactorY = 1.1
colors = {
	-- http://www.color-hex.com/color-palette/21926
	crgb(0,255,236),
	crgb(0,184,255),
	crgb(214,0,255),
	crgb(253,0,242),
	crgb(255,0,206),
	
	-- http://www.color-hex.com/color-palette/22324
	crgb(175,61,255),
	crgb(85,255,225),
	crgb(255,59,148),
	crgb(166,253,41),
}
function sylShow(line, l)
	-- global vars
	scalePerX = scaleFactorX*100
	scalePerY = scaleFactorY*100
	scaleDivY = (scalePerY-100)*2
	
	for _, syl in ipairs(line.syls) do
		w, h = utils.text_extents(syl.text, line.styleref)
		-- time setup
		l.start_time = line.start_time+syl.start_time
		l.end_time = line.start_time+syl.end_time
		
		-- effect setup
		col = colors[math.random(#colors)]
		l.text = string.format("{\\fscx%d\\fscy%d\\pos(%d,%d)\\blur10\\c%s\\fad(0,100)}%s",scalePerX,scalePerY,syl.x,syl.y-h/scaleDivY,col,syl.text)
		
		-- to make the effect even stronger
		io.write_line(l)
		io.write_line(l)
		io.write_line(l)
	end
end

-- Romaji
function romaji(line,l)
	sylShow(line,table.copy(l))
	twitchChars(line,table.copy(l), false,15,2, false);
end

-- Hebrew
function hebrew(line,l)
	--sylShow(line,table.copy(l))
	twitchChars(line,table.copy(l), false,4,8, true);
end

-- Process
for li, line in ipairs(lines) do
	if not line.comment then
		if line.style == "Subete OP Rom" then
			romaji( line, table.copy(line))
		else
			hebrew( line, table.copy(line))
		end
	end
	io.progressbar(li / #lines)
end
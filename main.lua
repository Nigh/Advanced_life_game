

local font26,font12,font120
font26 = love.graphics.newFont( 26 )
font12 = love.graphics.newFont( 12 )
font120 = love.graphics.newFont( 120 )

map={w=25,h=25,piexl_height=20,pp=0,deadgrid=0,day=0}

function love.load()
	love.graphics.setNewFont("msyh.ttc",16)
	love.math.setRandomSeed( 286949592617342+love.timer.getTime( ) )
	grids={}
	for i=1,map.w do
		table.insert(grids,{})
		for j=1,map.h do
			table.insert(grids[i],rand_init_grid())
		end
	end
	map_canvas = drawMapCanvas()
end

local t=0
function love.update( dt )
	t=t+dt
	if t>0.03 then
		updateRes(1.4)
		updatePopulation()
		updateNice()
		updateMigration()
		statistics()
		t=t-0.03
	end
end

function love.draw( ... )
	love.graphics.translate(450, 100)
	drawPopulation()
	drawResource()
	drawMap()
	love.graphics.translate(-150, 0)
	drawText()
end

function statistics()
	local pp,deadgrid=0,0
	for i=1,#grids do
		for j=1,#grids[i] do
			pp = pp + grids[i][j].pp
			if grids[i][j].resource==0 then deadgrid = deadgrid+1 end
		end
	end
	map.pp = pp
	map.deadgrid = deadgrid
	map.day = map.day+1
end

function updateRes( k )
	for i=1,#grids do
		for j=1,#grids[i] do
			if grids[i][j].resource>0 then
				local c = 0.2-(0.2-0.07)/3.37*(math.log(grids[i][j].pp+13)-2.63)
				grids[i][j].resource = grids[i][j].resource - k*(grids[i][j].pp * c)
				if grids[i][j].resource<0 then grids[i][j].resource=0
				else
					grids[i][j].resource = grids[i][j].resource + 0.05 + math.min(24,0.06*grids[i][j].resource)
					if grids[i][j].resource > grids[i][j].res_max then
						grids[i][j].resource = grids[i][j].res_max
					end
				end
			end
		end
	end
end

function updatePopulation( ... )
	for i=1,#grids do
		for j=1,#grids[i] do
			if grids[i][j].pp>0 then
				local nat = math.log10(grids[i][j].rp*5+1)/10-0.104
				grids[i][j].pp = (1+nat) * grids[i][j].pp
				if grids[i][j].pp<1 then grids[i][j].pp=0 end
				grids[i][j].rp = grids[i][j].resource / (grids[i][j].pp+1)
			end
		end
	end
end

function getNice( grid )
	if grid.resource>0 then
		local krp = -((20/grid.rp)*0.15)
		local kpp = math.log((grid.pp+1)/10)
		return kpp+krp
	else
		return -10000
	end
end

function updateNice( ... )
	for i=1,#grids do
		for j=1,#grids[i] do
			grids[i][j].nice = getNice(grids[i][j])
		end
	end
end

function updateMigration( ... )
	getGrid=function(x,y)
		if grids[x] then return grids[x][y]
		else return nil
		end
	end
	for i=1,#grids do
		for j=1,#grids[i] do
			if grids[i][j].pp > 0 then
				-- 计算迁移人口
				local mig_pp

				local _={
							getGrid(i-1,j-1),getGrid(i,j-1),	getGrid(i+1,j-1),
							getGrid(i-1,j),	getGrid(i,j),	getGrid(i+1,j),
							getGrid(i-1,j+1),getGrid(i,j+1),	getGrid(i+1,j+1),
					}
				if grids[i][j].resource==0 or love.math.random(1, 100)>90 then
					-- 随机迁移
					if grids[i][j].pp>20 then
						mig_pp = love.math.randomNormal( 2, 10 )
					else
						mig_pp = grids[i][j].pp
					end
					local r=love.math.random(1, 9)
					if _[r] then
						_[r].pp = _[r].pp + mig_pp
						grids[i][j].pp = grids[i][j].pp - mig_pp
					end
				else
					-- 理性迁移
					if grids[i][j].pp>20 then
						mig_pp = love.math.randomNormal( 2, math.min(20, grids[i][j].pp/2) )
					else
						mig_pp = grids[i][j].pp
					end
					table.sort( _, function(n1,n2)
						if n1==nil then return false end
						if n2==nil then return true end
						return n1.nice > n2.nice
					end )
					_[1].ontheway = _[1].ontheway + mig_pp
					grids[i][j].ontheway = grids[i][j].ontheway - mig_pp
				end
			end
		end
	end

	for i=1,#grids do
		for j=1,#grids[i] do
			grids[i][j].pp = grids[i][j].pp+grids[i][j].ontheway
			grids[i][j].ontheway = 0
		end
	end
end

function rand_init_grid( ... )
	local grid={}
	if love.math.random(1, 100)>97 then
		grid.pp = love.math.randomNormal( 20, 62 )
	else
		grid.pp = 0
	end
	grid.resource = love.math.randomNormal( 40, 220 )
	grid.res_max = grid.resource*1.8
	grid.rp = grid.resource / (grid.pp+1)
	grid.ontheway = 0
	return grid
end

function drawResource( ... )
	for i=1,#grids do
		for j=1,#grids[i] do
			local green = grids[i][j].resource/400*255
			love.graphics.setColor( green*0.2, green, green*0.6, 255 )
			love.graphics.rectangle("line", (i-1)*map.piexl_height+2, (j-1)*map.piexl_height+2, map.piexl_height-4, map.piexl_height-4)
		end
	end
end

function drawPopulation( ... )
	for i=1,#grids do
		for j=1,#grids[i] do
			if grids[i][j].pp>0 then
				local red = grids[i][j].pp/150*255
				love.graphics.setColor( red, red*0.6, red*0.2, 255 )
				love.graphics.rectangle("fill", (i-1)*map.piexl_height+4, (j-1)*map.piexl_height+4, map.piexl_height-8, map.piexl_height-8)
				if grids[i][j].resource==0 then
					love.graphics.setColor( 255, 173, 182, 230 )
					love.graphics.rectangle("line", (i-1)*map.piexl_height+2, (j-1)*map.piexl_height+2, map.piexl_height-4, map.piexl_height-4)
				end
			end
		end
	end
end

function drawMapCanvas( ... )
	local canvas = love.graphics.newCanvas(map.w*map.piexl_height+10, map.h*map.piexl_height+10)
	love.graphics.setCanvas(canvas)
		love.graphics.setColor( 255, 255, 255, 150 )
		for i=1,#grids do
			for j=1,#grids[i] do
				love.graphics.rectangle("line", (i-1)*map.piexl_height, (j-1)*map.piexl_height, map.piexl_height, map.piexl_height)
			end
		end
	love.graphics.setCanvas()
	return canvas
end

function drawMap(  )
	love.graphics.setColor( 177, 188, 255, 20 )
	love.graphics.draw(map_canvas)
end

function drawText()
	love.graphics.setColor( 255, 255, 255, 220 )
	love.graphics.print("Days: "..map.day .. "\nPopulation: "..round(map.pp).."\nWasteland: "..map.deadgrid,0,0)
end

function round(num, idp)
	if idp and idp>0 then
		local mult = 10^idp
		return math.floor(num * mult + 0.5) / mult
	end
	return math.floor(num + 0.5)
end

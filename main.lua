-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
local tiled= require("com.ponywolf.ponytiled")
local json= require("json")

local physics=require('physics')
physics.start()

local mapData= json.decodeFile(system.pathForFile("GAME PROGRAMMING PROGETTO/map/map.json"))
local map = tiled.new(mapData,"map")
physics.setDrawMode('normal')
--physics.setDrawMode('debug')
physics.setGravity(0,9.8)


--grafica
local bg= map:findLayer("background")
bg.anchorY=0
bg.anchorX=0
bg:setFillColor(0,0,1)

local ground1=display.newRect(20,0,100,-20)
ground1.anchorY=0
ground1.anchorX=0
ground1:setFillColor(0,1,0)
ground1.y=display.contentHeight-100

local ground2=display.newRect(20,0,100,-20)
ground2.anchorY=0
ground2.anchorX=0
ground2:setFillColor(0,1,0)
ground2.y=display.contentHeight-200
ground2.x=200

local ground3=display.newRect(20,0,100,-20)
ground3.anchorY=0
ground3.anchorX=0
ground3:setFillColor(0,1,0)
ground3.y=display.contentHeight-300
ground3.x=120

local hero=display.newRect(0,0,40,40)
hero.anchorX=0
hero.anchorY=0
hero:setFillColor(1,0,0)
hero.y=display.contentHeight-150
hero.x=30
--offsetX e offsetY rappresentano le distanze rispetto agli assi X e Y
--del punto in cui si tocca l'oggetto da spostare gold rispetto al suo centro

hero.offsetX = 0
hero.offsetY = 0

--creazione parte fisica
physics.addBody(hero,'dynamic',{density=3.0,friction=0.2,bounce=0.0})
--il corpo non ruoterà mai
hero.isFixedRotation=true
--terreno statico
physics.addBody(ground1,'static',{friction=0.5,bounce=0.2})
physics.addBody(ground2,'static',{friction=0.5,bounce=0.2})
physics.addBody(ground3,'static',{friction=0.5,bounce=0.2})

--Evento spostamento
local function moveMedal(event)
  
    -- memorizzo in medal la medaglia sulla quale è richiamato
    -- l'ascoltatore (i.e. la medaglia che ha riconosciuto l'evento touch) 
    local medal = event.target
  
    --all'inizio della fase di touch...
    if event.phase=="began" then
         -- calcolo la distanza fra il punto di contatto e il centro della
         -- medaglia
         medal.offsetX = event.x - medal.x
         medal.offsetY = event.y - medal.y	
         -- setto il focus dell'intero evento sulla medaglia che sto toccando
         -- (i.e. tutti i prossimi eventi touch saranno gestiti dall'oggetto 
         -- (in medal)
         display.currentStage:setFocus(medal)
         -- metto in primo piano sullo stage la medaglia da spostare
         medal:toFront()
      
    --durtante lo spostamento della medaglia...	
    elseif event.phase=="moved" then
          --cambio le coordinate della medaglia
          --tenendo conto dell'offset calcolato
          medal.x = event.x - medal.offsetX
          medal.y = event.y - medal.offsetY
    --quando termina la fase di touch		
    elseif event.phase =="ended" or event.phase=="cancelled" then
        --elimino il focus dell'evento sulla medaglia che stavo spostando
        --ora altre medaglie possono riservare la gestione dell'evento touch
        display.currentStage:setFocus(nil)
    end	  
    -- il comando return true permette di far gestire l'evento touch da un singolo oggetto. In altre parole l'evento non è propagato af altri oggetti o allo stage.
    return true
  end
  local function shoot(xForce,yForce)
    hero:applyLinearImpulse(xForce,yForce,hero.x,hero.y)
end

-- Funzione che permette di andare al replay
local function goToreplay()
	composer.removeScene("replay")
	local options = {
	effect = "zoomInOutFade",
	time = 1000,
	}
	composer.gotoScene("replay",options)
end
-----------------------------------------------------------------------------------
-- drawLine è una funzione ascoltatore per l'evento touch. Genera un segmento 
-- dal centro dello smile fino al punto toccato sul display.
-- Quando l'evento touch finisce, il segmento viene rimosso e viene richiamata 
-- la funzione shoot con valore xForce e yForce pari alla x e y del segmento
-- disegnato.
-----------------------------------------------------------------------------------
 	
local line 
local function drawLine(event)
	if event.phase=="moved" then
		if line ~= nil then
			display.remove(line)
			line = nil
		end
		line = display.newLine(hero.x,hero.y,event.x,event.y)
		line.strokeWidth = 8
		line:setStrokeColor(0,0,0)
		line:toBack()
	end
	if event.phase=="ended" then
		display.remove(line)
		line=nil
		xForce = (hero.x-event.x)/3.85
		yForce = (hero.y-event.y)/3.85
		shoot(xForce,yForce)
		
		-- 3 secondi dopo la funzione shoot viene richiamata
		-- la funzione per il replay
		timer.performWithDelay(2000)
	end	
end
 Runtime:addEventListener("touch",drawLine)
 -- on precollison disable the collision between hero and ladderEnd
	-- to allow hero to pass through the final part of the ladder
	local function onPreCollision(self,event)
		local heroBottom = self.y+16
		local collisionPlatforms=event.other
		local collisionPlatformsTop = collisionPlatforms.y-collisionPlatforms.height/2
	 
		if (collisionPlatforms.type == "ladderEnd" ) then	
			if (heroBottom >= collisionPlatformsTop) then
		       event.contact.isEnabled = false  --disable this specific collision   		
			end	  
		end
	end
	
	-- Function onCollision is the local collision handler attached to hero. 
	-- It controls collision between hero and
	-- 1. the evil cats (when this collision occurs, we stop the music, hero animationam physics,
	--    and we play the evil sfx)
	-- 2. an egg (if collision is with an egg, we make the egg invisible and play the bonus sfx)
	-- 3. the exit door (if collision is with the door, we stop bgMusic, pause hero animation and physics,
	--    and play the exit sfx) 
	-- 4. barriers (when this kind of collision is recognized, hero movement is inverted automatically)
	-- 5. platform (this collision is used to allow jumps only when hero is touching the top edge
	--              of a platform. We use the variables collidedObjTop and heroBottom to check
	--              this last condition. When this is the case, we also guarantee that hero is moving
	--              by setting his linear velocity)
	-- 6. ladderStart (when hero collides with the beginning of the ladder, we stop hero horizontal speed, we apply a vertical force to hero to make him climb up the ladder, and we set
	-- the flag hero.isOnLadder to true. We also play the ladder sound and we change the hero sprite
	-- animation sequence to climbUp)

	-- Note that when hero ended to climb up the ladder (i.e., collision hero-ladderEnd ends)
	-- we change the hero animation sequence to walk and we apply a non-zero horizontal speed to hero
	-- (i.e., we make hero walking again)
	-- Also, when a collision hero-platform ends, hero is falling or jumping, hence new jumps are not 
	-- allowed.
	-- Finally, note that when collision hero-egg terminates, we remove the egg from the device memory. 

	local function onCollision(self,event)
		local collisionPlatforms = event.other
		local collisionPlatformsTop= collisionPlatforms.y-collisionPlatforms.height/2
		local heroBottom=hero.y+16
	
	
		
	
		
			
			-- Collision hero-barrier
		    if (collisionPlatforms.type=="barrier") then --and (heroBottom>=collidedObjTop) then
			  self.speedDir = -self.speedDir
	          self:setLinearVelocity(self.speedDir*self.speed,0)
	  	      self.xScale = self.speedDir
			  --insaudio
			end  
			-- Collision hero-platform
		    if collisionPlatforms.type=="platform" then
				if event.contact.isTouching == true and heroBottom<=collisionPlatformsTop then
					self.jumpAllowed=true
				    self:setSequence("walk")
					self:play()
					self:setLinearVelocity(self.speedDir*self.speed,0)
				end	
		    end		
	     
		 -- when the collision between hero and the end of the ladder ends, hero starts walking again
		 -- and jumps are forbidden
		 if event.phase=="ended" then
			 --print("CollidedObj end:"..collidedObj.type)
			 if collisionPlatforms.name=="ladderEnd" then
				 hero.isOnLadder = false
				 self.jumpAllowed = false
				 self:setSequence("walk")
				 self:play()
				 self:setLinearVelocity(self.speedDir*self.speed,0)	 
		 -- when collision between hero and platform ends, hero is jumping or falling,
		 -- hence we disable jumps. 	 
			 elseif collisionPlatforms.type == "platform" then
					 self.jumpAllowed = false	 	
		 -- when collision hero-egg terminates, we remove the egg object from the memory, if any.		 
			 elseif collisionPlatforms.name == "egg" then
				 if collisionPlatforms~= nil then
			    	display.remove(collisionPlatforms)
				    collisionPlatforms=nil
				 end	
			end		
	end
	end


--sprite
local opt={width= 93, height=140, numFrames=60}
local badGuySheet= graphics.newImageSheet("img/badGuySheet.png",opt)
local seqs={{
	name= "runLeft",
	start=1,
	count= 30,
	time =300,
	loopCount= 1,
	loopDirection= "forward"
},
{
	name="runRight",
	start=31,
	count= 30,
	time =300,
	loopCount= 0,
	loopDirection= "forward"
}}

local badGuy= display.newSprite(badGuySheet, seqs)
badGuy.x= 100
badGuy.y= display.contentHeight-232
badGuy: setSequence("runRight")

--------


-- END: GENERATION OF THE GAME GRAPHICS ---------------------

-- BEGIN: GENERATION OF THE PHYSICS WORLD

-- turn ground, leftBarrier, rightBarrier, platform1, platform2
-- into static physical bodies with high friction  and no bounce. 
-- alienYellow is a static sensor
physics.addBody(ground,"static",{friction=1.0,bounce=0.0,density=1.8})
physics.addBody(leftBarrier,"static",{friction=1.0,bounce=0.0,density=1.8})
physics.addBody(rightBarrier,"static",{friction=1.0,bounce=0.0,density=1.8})
physics.addBody(platform1,"static",{friction=1.0,bounce=0.0,density=1.3})
physics.addBody(platform2,"static",{friction=1.0,bounce=0.0,density=1.3})
physics.addBody(alienYellow,"static",{isSensor=true})

-- add a dynamic physical body to badGuy, with high friction
-- and bounce 0 (no bounce at all)
physics.addBody(badGuy,"dynamic",{friction=1.0,bounce=0.0,density=1.3})

-- badGuy is not affected by rotational forces provoked by collisions
badGuy.isFixedRotation=true


-- We pause the sprite animation
badGuy:pause()

-- Five actions are possiblee
--    stand: badguy is not moving
--    moveLeft: badguy is movingLeft
--    moveRight: badguy is movingRight
--    Jump: badguy is jumping
--    fall: badguy is falling from a platform

-- initially, the badGuy is not moving: i.e. we set the user-defined action property to "stand"
badGuy.action="stand"
-- Moreover, we set the initial badGuy speed to 0
badGuy.speed = 0

-- END: GENERATION OF THE PHYSICS WORLD


-- BEGIN: IMPLEMENTATION OF  BADGUY JUMPS

-- badGuyJump is a tap listener associated with arrowUp button.
-- When arrowUp is tapped this listener is invoked to make
-- badGuy jump.

local function badGuyJump(event)
	--if badGuy is not junmping or falling...
	if badGuy.action ~= "jump" and badGuy.action ~= "fall"  then		
		-- select the direction of the jump and jump!
		if badGuy.action=="moveRight" or (badGuy.action=="stand" and badGuy.sequence=="runRight") then 
	       badGuy:applyLinearImpulse(80,-450,badGuy.x,badGuy.y)
		elseif badGuy.action=="moveLeft" or (badGuy.action=="stand" and badGuy.sequence=="runLeft")then  
		   badGuy:applyLinearImpulse(-80,-450,badGuy.x,badGuy.y)
		end   
		-- set the badGuy action to "jump", pause the running animation sequence,
		-- and set its horizontal speed to 0
		badGuy.action = "jump"
		badGuy.speed = 0 
		badGuy:pause()
	end  
end
	
-- activate the tap listener badGuyJump on the arrowUp button
arrowUp:addEventListener("tap",badGuyJump)	
-- END: IMPLEMENTATION OF  BADGUY JUMPS

-- START: IMPLEMENTATION OF  BADGUY COLLISIONS
local function onCollision(self,event)
  -- self is badGuy
  -- event.other might be a platform, an alien, the ground, or a barrier
  
  -- if a collision between badguy and another object begins...	
  if event.phase=="began" then

	  
	  -- if the collision is between badguy and ground or platform...	  
	  if event.other.name == "ground"  or  event.other.name == "platform" then
		   -- calculate the bottom of the badguy and the top of the other object...
           local selfBottom =self.y+self.height/2
           local collidedObjectTop =event.other.y-event.other.height/2
		   -- if badguy is on the other object...
	  elseif collidedObjectTop>selfBottom then 
			    -- this means that badguy landed on the ground or on a platform  
				-- so, set its action to "stand" and pause the running sprite animation  
				-- and set its speed to 0
		        self.action="stand"	
				badGuy.speed = 0
	 		    badGuy:pause()
           end	
  -- if the collision between badGuy and another object has ended...	  	
  elseif event.phase=="ended" then
	 
	 -- if the collision was with the platform...
	 if event.other.name=="platform" then
	   -- this means that badguy is falling so
	   -- pause the running animation and change its action to "fall"
	   -- set the horitzonal speed to 0
	   badGuy:pause()	
	   badGuy.action="fall"
	   badGuy.speed=0
	 end
	end		 	 		
  	   
  return true
end


-- Activate the local collision listener for badGuy  
badGuy.collision=onCollision
badGuy:addEventListener("collision",badGuy)  

-- END: IMPLEMENTATION OF  BADGUY COLLISIONS  	 	 	  	 	 	


-- START: IMPLEMENTATION OF  BADGUY MOVEMENTS

-- this function is a touch listener that moves badGuy
local function moveBadGuy(event)
	-- select the touched arrow

	  -- if the touch event has started..
       if event.phase=="began"  then
		  -- give the focus to the current touched arrow
		  display.getCurrentStage():setFocus(arrow)
          
		   -- if badGuy is not jumping or falling...
    	   if badGuy.action ~= "jump" and badGuy.action ~= "fall" then
	 		  -- set badGuy speed to 4 (that  is, 4 pixel per frame)
	 		  badGuy.speed = 4
			    -- ... and the left arrow has been touched	
		      
		  end   
					
	    elseif event.phase=="ended"  then
			-- if arrow touch has ended
			-- free the touch focus
			display.getCurrentStage():setFocus(nil)
			-- set the badGuy action to stand if he's not falling or jumping
			-- and then  pause its running animation a set his speed to 0
			if badGuy.action~="jump" and badGuy.action~="fall" then
			   badGuy.action="stand"
			end   
			badGuy:pause()
			-- set its speed to 0
			badGuy.speed=0
	  end	 
 	return true
end
	

-- this enterFrame listener, at every frame, 
-- moves and animates badguy if
-- its associated action is moveLeft or moveRight
function applyContinuosMovingSpeed(event)   
	   if badGuy.action=="moveLeft" then 
		   if badGuy.isPlaying == false then	
			 badGuy:play()
		   end	 	 
		   badGuy.x=badGuy.x-badGuy.speed	 
	   elseif badGuy.action=="moveRight" then
		   if badGuy.isPlaying == false then	
			 badGuy:play()
		   end
			badGuy.x=badGuy.x+badGuy.speed						
	   end		 
	return true
end		

-- activate the enterFrame Listener applyContinuosMovingSpeed
Runtime:addEventListener("enterFrame",applyContinuosMovingSpeed)

-- END: IMPLEMENTATION OF  BADGUY MOVEMENTS

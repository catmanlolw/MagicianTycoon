local module = {}

--// Variables \\ --
local Plots = game.Workspace:WaitForChild("Plots") -- Grabs all plots folder
local RE = game:GetService("ReplicatedStorage") -- Defines Replicated Storage Service 
local Modules = RE:WaitForChild("Modules") -- Grabs Modules folder from Replicated Storage
local HatDroppers = RE:WaitForChild("HatDroppers") -- GRabs HatDroppers folder from ReplicatedStorage

--// Variable Settings for Hat placement \\--
module.PerLayer = 8 -- Used to tell the script how many hats per layer/floor 
module.XPosition = 0 -- Tracks XPosition for hat placing purposes
module.YPosition = 0 -- Tracks YPosition for hat placing purposes

module.XPositionIncrement = 10 --Space between hats when placed
module.YPositionIncrement = 10 -- Space between layer/floors

local CurrentYPosition = 0 --Changes when new layer/floor is added
 
module.MaxLayers = 10 -- Cap placed so player does not create infinite floors

local FloorPosition = 18 -- Roof Position that increases each time a layer is created (idk why its named floor but okay 2022 me)

local NeedsLayer = false -- Lets the script know if the player needs to merge 
local Layer --Keeps track of what layer the player is on

--[[This is a table that stores the tables we have.
	The "Amount" key inside the dictionary indicates how many hats are needed to Merge
	The "ConvertTo" key shows the string value of the cat that this hat merges into]]--
module.MergeInfo = {
	["Red"] = 
		{
			Amount = 5,
			ConvertTo = "Yellow"
		};
	["Yellow"] = 
		{
			Amount = 4,
			ConvertTo = "Blue"
		};
	["Blue"] = 
		{
			Amount = 4,
			ConvertTo = "Orange"
		};
	["Green"] = 
		{
			Amount = 3,
			ConvertTo = "Orange"
		};
	["Orange"] = 
		{
			Amount = 3,
			ConvertTo = "White"
		};
	["White"] = 
		{
			Amount = 2,
			ConvertTo = "Purple"
		};
	["Purple"] = 
		{
			Amount = 2,
			ConvertTo = "Pink"
		};
}


--[[This table holds the prices of the Slot Machine.
	These are used to buy more hats]]--
module.SlotMachinePrices = {
	CommonBtn = --gives 1-6 hats when bought 
		{
			Price = 600
		};
	RareBtn = -- gives 3-9 hats when bought
		{
			Price = 1800
		};
	EpicBtn = --gives 6-25 hats when bought
		{
			Price = 3800
		}
}

--[[This function finds the tycoon of the player passed in the arguments]]--
function module.FindPlayerTycoon(Player,Plots)
	for _,FindTycoon in pairs(Plots:GetDescendants()) do
		if FindTycoon:IsA("StringValue") and FindTycoon.Value == Player.Name then
			return FindTycoon.Parent.Parent
		end
	end
end

--[[This function checks whether the player has enough hats spawned in
	to create a new story for the hats]]--
function CheckLayers(Folder)
	Layer = ""
	for i,Podiums in pairs(Folder:GetChildren()) do
		if #Podiums:GetChildren() < module.PerLayer then
			NeedsLayer = false
			Layer = Podiums
		else
			NeedsLayer = true
			Layer = Podiums
		end
	end
	return NeedsLayer,Layer
end

--[[This function loops through the plot of a player and deletes everything
	except the first layer and roof, then places the roof back to the position of Layer 1]]--
function module.TurnFloorsBackToNormal(Plot)
	local FindLayersFolder = Plot:WaitForChild("Floors")
	local Roof = FindLayersFolder:WaitForChild("Roof")
	
	for _,Parts in pairs(FindLayersFolder:GetDescendants()) do
		if Parts:IsA("MeshPart") and Parts.Parent.Name ~= "Layer 1" and Parts.Parent.Name ~= "Roof" then
			Parts.Transparency = 1
		end
	end
	Roof.Primary.Position = Vector3.new(Roof.Primary.Position.X,20,Roof.Primary.Position.Z)
end

--[[Activates newly cloned floor and re-positions the roofs position accordingly]]--
function EnableNewFloor(LayerName,plot,LayerNumber)
	local FindLayersFolder = plot:WaitForChild("Floors") -- Waiting for Layers/Floors
	local Roof = FindLayersFolder:WaitForChild("Roof") -- Waiting for roof
	local FindLayer = FindLayersFolder:FindFirstChild(LayerName) -- Looking for newly unlocked Layer/Floor
	local NewFloorPosition = Roof.Primary.Position.Y + FloorPosition -- Adding the FloorPosition (18) to the current Floor Position to position in correctly on the new layer/floor
	if FindLayer then -- Checking if Layer/Floor actually exists
		for _,Parts in pairs(FindLayer:GetChildren()) do -- Looping through Layers children
			if Parts.Material == Enum.Material.SmoothPlastic then
				Parts.Transparency = 0
			end
			if Parts.Material == Enum.Material.Glass then
				Parts.Transparency = 0.4
			end
		end
		Roof.Primary.Position = Vector3.new(Roof.Primary.Position.X,NewFloorPosition,Roof.Primary.Position.Z) --Positions the roof to the position of the new layer/floor
	end
end

--[[Adds a hat to the players plot. It takes into account the layers the plot already has,
	the position the hats already are in (to avoid hats inside each other),
	It also makes sure to correct any Positions depending on the side the plot is in]]--
function AddHat(Layer,Hat,PlacedHats)
	local Podium = Layer:FindFirstChild("Podium") -- The pedestal the hat is placed on top of
	local Row = Layer.Parent.Parent:FindFirstChild("OtherRow") -- Lets the script know which side of the game the player is in. (Tycoon 5-8 is considered the 'OtherRow')
	
	if Podium then --Making sure the player has podiums avaliable
		if module.XPosition == 0 then -- Checks if the player has no hats
			local NewHat = Hat:Clone()
			NewHat.Parent = PlacedHats
			NewHat:MoveTo(Podium.Position)
			
			module.XPosition += 10
		else--if the player has hats, we then clone everything and move them forward accoreding to the modules above settings
			
			--[[Clone podium to place hat,
				Clone Hat to able to spawn mini hats,
				Parent hat clone to workspace]]--
			local NewPodium = Podium:Clone()
			local NewHat = Hat:Clone()
			NewPodium.Parent = Layer
			if Row.Value == true then -- If row is true means the player is currently in tycoons 5-8
				
				--[[Setting and moving hats position by Position settings with a Y offset of -1 and -3.
					This is done because of how the hats are placed
					(the names are horrendous ik, 2022 me was on something)]]--
				NewPodium.Position = Podium.Position - Vector3.new(module.XPosition,module.YPosition,0)
				NewHat.Parent = PlacedHats
				NewHat:MoveTo(NewPodium.Position)
				NewHat.PickUp2.Position = Podium.Position - Vector3.new(module.XPosition,module.YPosition-3,0)
				NewHat.PickUp.Position = Podium.Position - Vector3.new(module.XPosition,module.YPosition-3,0)
				NewHat.PickUp.Position = Vector3.new(NewHat.PickUp.Position.X,NewHat.PickUp.Position.Y - 1,NewHat.PickUp.Position.Z)
			else
				--[[Same as above but with an offest of +1,+3. 
				This is why the OtherRow BoolValue is useful]]--
				NewPodium.Position = Podium.Position + Vector3.new(module.XPosition,module.YPosition,0)
				NewHat.Parent = PlacedHats
				NewHat:MoveTo(NewPodium.Position)
				NewHat.PickUp2.Position = Podium.Position + Vector3.new(module.XPosition,module.YPosition+3,0)
				NewHat.PickUp.Position = Podium.Position + Vector3.new(module.XPosition,module.YPosition+3,0)
				NewHat.PickUp.Position = Vector3.new(NewHat.PickUp.Position.X,NewHat.PickUp.Position.Y - 1,NewHat.PickUp.Position.Z)
			end
			module.XPosition += 10 -- Increasing the X position to keep track of the position we have on the hats
	end
		
	end
end


--[[Function runs when a player has enough placed hats to create a new layer]]--
function AddLayer(Layer,Hat,PlacedHats)
	--Previous Layer Podium (OldPodium), Checking whether the tycoon is 1-4 or 5-8 (Row)
	local OldPodium = Layer:FindFirstChild("Podium")
	local Row = Layer.Parent.Parent:FindFirstChild("OtherRow")
	if OldPodium then -- Checks if the Previous Layer podium is not nil
		local NewLayer = Layer:Clone() -- Creates new Layer from Previous Layer
		local SplitName = string.gsub(NewLayer.Name,"Layer ","") -- Splits the number from the Layers name
		local NewNumber = tonumber(SplitName) + 1 --Takes SplitName's result and adds it by 1
		local NewName = "Layer "..NewNumber --Sets the new layer names as the Previous Layers number + 1 (Found out by Last two Variables above)
		if NewNumber - 1 == module.MaxLayers then -- IF statement check to make sure the player hasnt hit Layer limit
			return NewLayer.Name,NewNumber,false -- Returns false to let the player know the reached the Layer Limit
		else
			--Comments below describe what lines below do--
			
			--[[Cleans previous layer so the player does not have duplicate hats,
				Parents NewLayer to the players plot,
				Sets its name to "Layer #",
				Places down a hat and resets X yalues but Adds on to Y Values (To let the script know there is a new layer)]]--
			module.XPosition = 0
			module.YPosition += 17
			NewLayer.Parent = Layer.Parent
			NewLayer.Name = NewName
			NewLayer:ClearAllChildren()
			local NewHat = Hat:Clone()
			local NewPodium = OldPodium:Clone()
			NewPodium.Parent = NewLayer
			NewPodium.Position = OldPodium.Position + Vector3.new(module.XPosition,module.YPosition,0)
			NewHat.Parent = PlacedHats
			NewHat:MoveTo(NewPodium.Position)
			module.YPosition = 0
			module.XPosition += 10
			return NewLayer.Name,NewNumber,true -- Lets script know that the layer has been made and returns the New layer/floor
		end
	end
	
end

--[[Main function that handles everything hat related when button is pressed]]--
function module.PlaceOneHat(Player,Plot,Hat)
	
	--Checks if the player exists still, and If the tycoon where the button was touched belongs to the player
	if Player and Plot:FindFirstChild("Owner",true).Value == module.FindPlayerTycoon(Player,Plots):FindFirstChild("Owner",true).Value then
		local Hat = HatDroppers:WaitForChild(Hat) -- Finds which hat the player is trying to place down (Red by default, only changes color when player merges hats)
		local PlacedHat = Plot:WaitForChild("PlacedHats") -- Gets the folder of the players hats inside their plot
		local PodiumsFolder = Plot:WaitForChild("Podiums") -- Gets all players podiums
		
		local LayerCheck,LastLayer = CheckLayers(PodiumsFolder) -- Runs CheckLayers function to return true (if a layer can be merged) and return current layer
		if LayerCheck then -- Checks whether a new layer is needed
			local LayerName,Number,Check = AddLayer(LastLayer,Hat,PlacedHat) -- Runs function that handles new layer creation
			if Check then -- If the player is not at max layers then proceeds to enable New Layer
				EnableNewFloor(LayerName,Plot,Number)	
			else --if player is at the max layer then all hats continously merge and merge until they cant
				local ButtonModule = require(Player.Character:WaitForChild("ButtonModule"))
				module.TurnFloorsBackToNormal(Plot)
				ButtonModule.Merge(Player,Plot)
			end
		else
			AddHat(LastLayer,Hat,PlacedHat) -- continues adding hats since a layer is needed yet
		end
		end
	end
return module

local module = {}

--// Variables \\--
local Plots = game.Workspace:WaitForChild("Plots")
local RE = game:GetService("ReplicatedStorage")
local Modules = RE:WaitForChild("Modules")
local HatDroppers = RE:WaitForChild("HatDroppers")
local GameFunctions -- 	left blank to require in functions below
local Events = RE:WaitForChild("RemoteEvents")
local IsRunning = false

--Weirdly named datastores
local DS = game:GetService("DataStoreService"):GetDataStore("meowmeowmeow")
local DS2 = game:GetService("DataStoreService"):GetDataStore("hiiithereimcoolmeow")
local DS3 = game:GetService("DataStoreService"):GetDataStore("lolllllhiiiiejdnd")

-- //Buy functions\\--

--[[Updates button prices every time a purchase is made]]--
function UpdateButton(Plot,ButtonToChange,Hat)
	local Button = Plot:FindFirstChild(ButtonToChange,true).Parent
	if Button then
		local Misc = Button.GuiHolder:WaitForChild("Misc")
		local Price = Misc:WaitForChild("Price")
		local Prices = Button:FindFirstChild("Prices",true)
		local OriginalPrice = Button:FindFirstChild("OriginalPrice",true)
		if Prices then -- Checks if button exists
			Price.Text = "$"..tostring(Prices.Value) 
		end
	end
end

--[[Returns true if the player has enough money to buy hats]]--
function CheckPrice(PlayerMoney,Plot,Hat,ButtonToChange)
	local Button = Plot:FindFirstChild(ButtonToChange,true).Parent
	local Prices = Button:FindFirstChild("Prices",true)
	local OriginalPrice = Button:FindFirstChild("OriginalPrice",true)
	if Prices.Value and Prices.Value <= PlayerMoney.Value then
		game.Workspace.Sounds.buy:Play()
		RE.RemoteEvents.Particles:FireClient(PlayerMoney.Parent.Parent,Button[ButtonToChange])
		PlayerMoney.Value -= Prices.Value
		Prices.Value += OriginalPrice.Value
		return true
	end
end

--[[When player touches tycoon:
	if the desired tycoon is not taken then
	All their data loads,
	The owner Tag is changed to their name,
	Button prices are set back to the way they were before player left]]--
function module.ClaimTycoon(Player,Tycoon)
	GameFunctions = require(Player.Character:WaitForChild("GameFunctions"))
	local ButtonsFolder = Tycoon:WaitForChild("Buttons")
	local ClaimTycoonPart = ButtonsFolder:WaitForChild("ClaimTycoon")
	local OwnerInfo = Tycoon:WaitForChild("OwnerInfo") 
	local OwnerLabel = OwnerInfo:FindFirstChild("OwnerLabel",true)
	local OwnerTag = OwnerInfo:FindFirstChild("Owner")
	if Player and Tycoon and ButtonsFolder and ClaimTycoonPart and OwnerTag.Value == "" then -- Checks if the tycoon isnt taken and if the player who touched exists still
		if GameFunctions.FindPlayerTycoon(Player,Plots) then -- FUnction is called to make sure a player hasnt claimed a tycoon yet
			
		else

			ClaimTycoonPart.CanCollide = false
			OwnerLabel.Text = Player.Name.."'s Tycoon"
			OwnerTag.Value = Player.Name
			local PlrSavedData = DS2:GetAsync(Player.UserId) -- Datastore that stores placed down hats
			local PlrSavedValues = DS3:GetAsync(Player.UserId) -- Datastore that stores button prices, players cash, gamepasses, etc
			if PlrSavedData then -- checks if a player has saved hats
				
				--[[the key (i) contains the name of the hat (red, yellow, Orange, etc)
					the value (v) contains how many of those hats the player had]]--
				for i,v in pairs(PlrSavedData) do -- Loop through Data for hats
					repeat wait()
						v.Amount -= 1 -- Removing hats from saved data (to prevent duplication when saving)
						GameFunctions.PlaceOneHat(Player,Tycoon,i) -- Calls module function to place down hat
					until v.Amount == 0 -- repeats until the player has no hats left 
				end
			end
			if PlrSavedValues then -- checks if player has saved data 
				
				local BuyOne = ButtonsFolder:FindFirstChild("BuyOneHat",true)
				local BuyFiveHats = ButtonsFolder:FindFirstChild("BuyFiveHats",true)
				local Sell = ButtonsFolder:FindFirstChild("TwoPerSale",true)
				local OtherSell = ButtonsFolder:FindFirstChild("Sell",true)
				if BuyOne and BuyFiveHats and Sell and OtherSell then
					BuyOne.Prices.Value = PlrSavedValues[1]
					BuyOne.OriginalPrice.Value = PlrSavedValues[2]
					BuyFiveHats.Prices.Value = PlrSavedValues[3]
					Sell.RateOfSelling.Value = PlrSavedValues[4]
					Sell.Prices.Value = PlrSavedValues[5]
					Tycoon.DroppedCollector.CollectorPart.TotalHats.Value = PlrSavedData[6]
					OtherSell.Hats.Value = PlrSavedValues[7]
					Sell.WandsPerSale.Value = PlrSavedValues[8]
				end
			else -- if player does not have saved data, then default data is put in its place
			
				local BuyOne = ButtonsFolder:FindFirstChild("BuyOneHat",true)
				local BuyFiveHats = ButtonsFolder:FindFirstChild("BuyFiveHats",true)
				local Sell = ButtonsFolder:FindFirstChild("TwoPerSale",true)
				local OtherSell = ButtonsFolder:FindFirstChild("Sell",true)
				if BuyOne and BuyFiveHats and Sell and OtherSell then -- checks if current tycoon has these buttons
				
					BuyFiveHats.Prices.Value = 25
					BuyOne.Prices.Value = 0
					BuyOne.OriginalPrice.Value = 5
					Sell.RateOfSelling.Value = 1
					Sell.Prices.Value = 50
					OtherSell.Hats.Value = 0
					Tycoon.DroppedCollector.CollectorPart.TotalHats.Value = 0
					Sell.WandsPerSale.Value = 1
				end
			end
			local Ownerlbl = Tycoon.plot:WaitForChild("ownerlbl")
			local bbguiv2 = Ownerlbl:WaitForChild("bbguiv2")
			local Name = bbguiv2:WaitForChild("Name")
			local user = Name:WaitForChild("user")
			game.Workspace.Sounds.buy:Play() -- Play sound of successful claiming
			RE.RemoteEvents.Particles:FireClient(Player,ClaimTycoonPart) --Calls client to display particles
			Player.PlayerGui.Popup.TextLabel.Visible = true -- Informs player of successful claim
			user.Text = Player.Name.." 's Plot"
			Events.ChangeThumbnail:FireAllClients(Tycoon.plot.ownerlbl.bbguiv2.Img.icon) -- Calls all clients and gets a headshot of players avatar
			wait(0.88)
			Player.PlayerGui.Popup.TextLabel.Visible = false -- gets pop up off players screen
		end
	end
end

--//Merge functions\\--

local PlayerItems = {} -- Stores players hats


--Quick check to find out if the player has enough hats to merge them to the next tier
function MergeCheck(PlrHats)
	for i,Hats in pairs(PlrHats:GetChildren()) do -- Loops through players hats in workspace
		if PlayerItems[Hats.Name].Amount >= GameFunctions.MergeInfo[Hats.Name].Amount then  --if the amount of hats is equal or greater than the merge requirement the function returns true
			return true 
		end
	end
end

-- function updates PlayerItems table to match the hats the player has in workspace
function CheckItems(Plrhats)
	for i,Hats in pairs(Plrhats:GetChildren()) do
		if PlayerItems[Hats.Name] then
			PlayerItems[Hats.Name].Amount += 1
		else
			PlayerItems[Hats.Name] = {Amount = 1}
		end
	end
	if MergeCheck(Plrhats) then
		return true -- returns true to tell the server that the player is ready to merge
	end
end
--Destroys all Podiums and hats (usually called when a player is merging or leaving the game)
function module.ClearPodiums(Tycoon)
	for i,v in pairs(Tycoon.Podiums:GetChildren()) do -- Looping through Podium Layers (folders that contain the podiums in each layer)
		if v.Name ~= "Layer 1" then -- Checks for everything except Layer 1 (deleting layer one means no more tycoon lel)
		    v:Destroy() -- Destroys every Layer except for the ones in the first layer
		end
		
		for Place,Podium in pairs(v:GetChildren()) do -- Loops through the podiums of each layer 
			if Podium:IsA("MeshPart") and Place ~= 1 then -- Checks if the podium is a MeshPart and isnt the first podium in the row
				Podium:Destroy() -- Destroys podium
			end
		end
	end
end

--Checks players hats and refers to the GameFunctions Module for merging Hats in the tables
function MergeTables()
	for Name,Value in pairs(PlayerItems) do
		repeat wait()
			
			if GameFunctions.MergeInfo[Name] and GameFunctions.MergeInfo[Name].Amount <= PlayerItems[Name].Amount  and GameFunctions.MergeInfo[Name].Amount then -- Looks if the amount of hats a player has is enough to merge to the next tier
				if PlayerItems[GameFunctions.MergeInfo[Name].ConvertTo] and PlayerItems[GameFunctions.MergeInfo[Name].ConvertTo].Amount then -- Checks if the hat can be merged further (to avoid errors in case that the hats they have are already fully merged)
					PlayerItems[GameFunctions.MergeInfo[Name].ConvertTo].Amount += 1 -- Adds the hat from the next tier (Example: if the merged here is 5 red then the player just recieved one yellow hat)
				else -- if the hats are fully merged we leave them alone
					PlayerItems[GameFunctions.MergeInfo[Name].ConvertTo] = {Amount = 1}
				end
				PlayerItems[Name].Amount -= GameFunctions.MergeInfo[Name].Amount --Subtracts required merging amount from the amount of hats the player owns
			end
		until PlayerItems[Name].Amount < GameFunctions.MergeInfo[Name].Amount -- until player has no more hats to merge

	end
end

--Handles all the frontend and backend merging
function Merge(Player,Tycoon)
	MergeTables() -- Merges Hats inside tables
	if MergeCheck(Tycoon.PlacedHats) then -- runs merge check to update hat amount in tables and returns true if hats are enough amount
		MergeTables() -- merges tables again in case some hats are missed after merge (rare but yeah)
	end
	Tycoon.PlacedHats:ClearAllChildren() --Removes all current hats placed
	module.ClearPodiums(Tycoon) -- Removes Podiums that they hats sit on
	GameFunctions.XPosition = 0 -- resets X position (to re-place)
	GameFunctions.YPosition = 0 -- resets Y position (also to re-place)
	GameFunctions.TurnFloorsBackToNormal(Tycoon) -- turns tycoon plot back to original (like how it was before it was claimed)
	for Name,Value in pairs(PlayerItems) do -- loops through Players table 
		repeat wait() -- repeats until all hats have been placed
			if PlayerItems[Name].Amount >= 1 then -- checks if the player has one or more Hats left inside the table
				GameFunctions.PlaceOneHat(Player,Tycoon,Name) -- Places hat and sends the key as the argument
				PlayerItems[Name].Amount -= 1 -- Takes away hat from table to keep track of placed down hats
			else
				break -- breaks out of loop if player is out and moves on to the next key
			end
		until PlayerItems[Name].Amount <= 0
	end
end

--when pressed, the server checks the players currency then places a hat if the player has enough money
function module.BuyOneHat(Player,Tycoon)
	GameFunctions = require(Player.Character:WaitForChild("GameFunctions")) -- Requires GameFunctions to access Important functions
	if Tycoon:FindFirstChild("Owner",true).Value == GameFunctions.FindPlayerTycoon(Player,Plots):FindFirstChild("Owner",true).Value then -- Makes sure the button pressed by the player was sent from THEIR tycoon (to avoid stealing or pressing others buttons)
		local leaderstats = Player:WaitForChild("leaderstats") -- Grabs players currency stats
		local Money = leaderstats:WaitForChild("Wands") -- Players Currency
		local HasEnough = CheckPrice(Money,Tycoon,"One Hat","BuyOneHat") -- Runs function that returns whether the player has enough money or not
		if HasEnough then -- if the player has enough then a hat is placed
			GameFunctions.PlaceOneHat(Player,Tycoon,"Red") -- hat placement function is called
		end
	else -- if this button does not belong to the player then nothing happens 
	
	end
end

--function that is called when a player steps on this button
function module.Merge(Player,Tycoon)
	GameFunctions = require(Player.Character:WaitForChild("GameFunctions")) -- requires gamefunctions module 
	if Tycoon:FindFirstChild("Owner",true).Value == GameFunctions.FindPlayerTycoon(Player,Plots):FindFirstChild("Owner",true).Value then
		local PlacedHats = Tycoon:WaitForChild("PlacedHats") -- Grabs players placedhats folder from workspace
		PlayerItems = {} -- Empties PlayersItems to update them below
		local Check = CheckItems(PlacedHats) -- Updates players hats in case more has been added
		if Check then -- if more has been added then hats are merged 
			local MergeButton = Tycoon:FindFirstChild("Merge",true)
			if Merge then -- if player can merge then a sound is played and the client is called to display particles
				game.Workspace.Sounds.buy:Play()
				RE.RemoteEvents.Particles:FireClient(Player,MergeButton)
			end
			Merge(Player,Tycoon) -- calls function above to merge tables and hats
		else -- if they cannot merge then the table is emptied again
			PlayerItems = {} 
		end
	end
end

--Calls PlaceOneHat 5 times when pressed 
function module.BuyFiveHats(Player,Tycoon)
	GameFunctions = require(Player.Character:WaitForChild("GameFunctions")) -- requires module
	local Amount = 0 -- keeps track of how many hats placed
	if Tycoon:FindFirstChild("Owner",true).Value == GameFunctions.FindPlayerTycoon(Player,Plots):FindFirstChild("Owner",true).Value then -- tycoon ownership check
		local leaderstats = Player:WaitForChild("leaderstats") -- grabs players stats 
		local Money = leaderstats:WaitForChild("Wands") -- players currency
		local HasEnough = CheckPrice(Money,Tycoon,"One Hat","BuyFiveHats") -- checks price of 5 hats combined
		if HasEnough then -- if player has enough to buy all 5 then the PlaceOnHat function is called 5 times
			repeat wait() 
				GameFunctions.PlaceOneHat(Player,Tycoon,"Red")
				Amount += 1
			until Amount == 5
		end
	else -- if player does not have enough then the function ends
		
	end
end

--Upgrades selling part to sell hats faster
function module.TwoPerSale(Player,Tycoon)
	local PlayerStats = Player:WaitForChild("leaderstats") -- grabs player stats
	if CheckPrice(PlayerStats.Wands,Tycoon,"Hat","TwoPerSale") then -- checks upgraders price
		local RateOfSelling = Tycoon:FindFirstChild("RateOfSelling",true) -- grabs the Value that tracks players selling hats rate
		if RateOfSelling then
			RateOfSelling.Value += 2 -- adds two to value 
		end
	end
end

function module.Sell(Player,Tycoon)
	GameFunctions = require(Player.Character:WaitForChild("GameFunctions")) -- requiring module
	if Tycoon:FindFirstChild("Owner",true).Value == GameFunctions.FindPlayerTycoon(Player,Plots):FindFirstChild("Owner",true).Value then -- ownership check
		local PlayerStats = Player:FindFirstChild("leaderstats") -- gets players stats
		local Button = Tycoon:FindFirstChild("Sell",true) -- gets sell Part
		local Button2 = Tycoon:FindFirstChild("TwoPerSale",true) -- gets hat selling rate NumberValue
		local SellMulti = Player:FindFirstChild("SellMulti") -- Checks NumberValue to check if player owns 2x sell gamepass
		local WandsMulti = Player:FindFirstChild("WandsMulti") -- checks Value below if player owns 2x wands
		local Hats
		local Wands 
		local RateOfSell 
		local ButtonGui
		local HatsTag
		local TotalHats
		
		-- ^ above empty variables get addressed below 
		if PlayerStats and Button and Button2 and SellMulti and WandsMulti then
			RE.RemoteEvents.Particles:FireClient(Player,Button.Parent.GuiHolder) -- CLient is called for particle effects
			Hats = PlayerStats:WaitForChild("Hats") -- Players Hats stat
			Wands = PlayerStats:WaitForChild("Wands") -- Players Wands Stat
			RateOfSell = Button2:WaitForChild("RateOfSelling") -- Buttons hat selling again
			WandsPer = Button2:WaitForChild("WandsPerSale") -- Result payment for selling hats
			ButtonGui = Button.Parent.GuiHolder:WaitForChild("Misc") -- UI that informs player of hats remaning
			HatsTag = Button:WaitForChild("Hats") -- Holds hats value until sold
			TotalHats = PlayerStats:WaitForChild("TotalWands") 
			HatsTag.Value += Hats.Value * WandsMulti.Value -- Adds to selling queue
			Hats.Value = 0 -- Resets hats value
			
			task.spawn(function() -- Spawns in to not yield the whole server
				if IsRunning == false and HatsTag.Value >= 1 then -- checks if the selling is active
					IsRunning = true -- lets the script know the selling is active
					repeat wait(1) -- repeats below once per second
						ButtonGui.Label.Text = "Hats: "..HatsTag.Value -- Displays the current amount of hats left
						if Player:FindFirstChild("AutoSale") and Player.AutoSale.Value == true then -- Checks for gamepass to insta sell
							ButtonGui.Label.Text = "Hats: "..HatsTag.Value -- Updates UI to the hats currently
							Wands.Value += HatsTag.Value -- Gives player all wands in form of wands
							TotalHats.Value += HatsTag.Value -- the hats are added to total hands value for leaderboard purposes
							Events.PopUpCurrency:FireClient(Player,"-"..HatsTag.Value) -- Calls client to update UI that tells the client of the exchange 
							HatsTag.Value = 0 -- Selling is emptied
						else -- if player does not own gamepass then manually takes it time
							
							if RateOfSell.Value * SellMulti.Value * WandsPer.Value >= HatsTag.Value then --[[if the upcoming hat subtraction is more than the hats 
																											avaliable then empties all the hats to avoid negatives (Sell rate 34 but the amount of hats is 12)]]--
								Wands.Value += HatsTag.Value
								TotalHats.Value += HatsTag.Value
								Events.PopUpCurrency:FireClient(Player,"-"..HatsTag.Value) -- Calls client to update UI that tells the client of the exchange 
								
								HatsTag.Value = 0
							else -- if the sell rate is lower than the hats avaliable then the sell machine continues as normal
								--[[TotalHats is added with all gamepass chances (if not then values default to 1),
									HatsTag is emptied with all potential gamepass values,
									The player is awarded Wands in exchange with all potential gamepass benefits]]--
								TotalHats.Value += RateOfSell.Value*SellMulti.Value*WandsPer.Value 
								Wands.Value += RateOfSell.Value * SellMulti.Value*WandsPer.Value
								HatsTag.Value -= RateOfSell.Value * SellMulti.Value*WandsPer.Value
								Events.PopUpCurrency:FireClient(Player,"-"..RateOfSell.Value * SellMulti.Value*WandsPer.Value) -- Calls client to update UI that tells the client of the exchange with all gamepass additions
							end
						end
						ButtonGui.Label.Text = "Hats: "..HatsTag.Value
					until HatsTag.Value == 0 -- Runs until the player has no hats inside left
					ButtonGui.Label.Text = "Hats: "..HatsTag.Value -- Updates machine one more time to show no more hats are there
					IsRunning = false -- Notifies script that selling machine is no longer running
				end
			end)
		end	
	end
end

--When stepping on Teleporter then player is warped to obby
function module.TycoonToObby(Player,Tycoon)
	local ParkourFolder = game.Workspace:WaitForChild("Parkour") -- Retrieves Tycoon folder 
	local TP = ParkourFolder.MagicTP --Grabs Teleporter part located in obby
	local Character = Player.Character -- Creates Character variable
	local HRP = Character:FindFirstChild("HumanoidRootPart") -- Grabs Characters HumanoidRootPart
	if HRP then -- if the player has a HRP then teleports character
		HRP.CFrame = TP.CFrame + Vector3.new(0,3,0) -- Teleports the characters HRP to the teleporters CFrame with an offset of 3 studs on the Y axis
		RE.RemoteEvents.TpToObby:FireClient(Player) -- communicates with client to create a UI transition background from plot to obby
	end
end

return module

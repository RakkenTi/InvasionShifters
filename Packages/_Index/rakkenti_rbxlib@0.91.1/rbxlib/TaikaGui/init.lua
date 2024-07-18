--[[

@rakken
TaikaGui
Expansive gui framework with a chainable-architecture inspired by TopbarPlus.

TaikaGui is a gui framework that aims to make gui's on runtime through script instead of studio.
It uses a chainable command architecture such that you can chain methods.

For example:

Instead of:
self:X()
self:Y()
self:Z()

You can do:
self:X():Y():Z()

Basic Rundown:
TaikaGui works by basically creating a wrapper between all common functions that are used for creating gui in roblox, and automating all the boring work

Structure and Use:

To start, create a gui class using the .new constructor. It will take an ID paramater that is required and two optional parameters that are self-explanatory.
It will return an instance of the class. You will most likely want to store it in a variable.

Now the fun part!
You have access to all methods, and you can chain them.
A website for documentation will be created, but you can also just search for each function and read the comments, if the method name isn't explaining enough.
The method names aim to be self-explantory.

Features:
- Components: are prebuilt assets that make advanced-gui behaviour easier.

]]

--~~/// [[ TYPES ]] ///~~--
--~~[[ Effect Data ]]~~--
type TYPE_EFFECT_HIGHLIGHTTEXT = { color: Color3, tweeninfo: TweenInfo }
type TYPE_EFFECT_HIGHLIGHT = { color: Color3, transparency: number, tweeninfo: TweenInfo }
type TYPE_EFFECT_EXPANSION = { tweeninfo: TweenInfo, scale: number }
--~~[[ Motion Effects Data ]]~~--
type TYPE_MOTION_EFFECT_SPIN = { speed: number }
--~~[[ Live Effects Data ]]~~--
type TYPE_LIVE_EFFECT_EFFECTS = "Strobe"
type TYPE_LIVE_EFFECT_STROBE = {
	backgroundcolor: Color3,
	strobecolor: Color3,
	speedmul: number,
	min: number,
	max: number,
	rotation: number,
	direction: Vector2,
}

--~~[[ General ]]~~--
type TYPE_EFFECTS = "Expansion" | "ColourBackground" | "ColourText"
type TYPE_EFFECT_SIGNALS = "Mouse.Hover" | "Mouse.Click"
type TYPE_PRESETS = "Taika" | "Minima" -- Presets listed in Presets folder
type TYPE_ELEMENT_CLASS = {
	states: { any: any },
	values: { any: any },
	instance: Instance,
	lastStateUsed: string,
	lastPropertySetTable: { any? },
}
type PossibleElements =
	"Frame"
	| "ScrollingFrame"
	| "ScreenGui"
	| "ImageLabel"
	| "ImageButton"
	| "TextButton"
	| "TextLabel"
	| "TextBox"
	| "UIAspectRatioConstraint"
	| "UICorner"
	| "UIStroke"
	| "UIPadding"
	| "UIGradient"
	| "CanvasGroup"
	| "Folder"
	| "UIGridLayout"
	| "UIListLayout"
	| "UIPageLayout"
	| "UITableLayout"
	| "ViewportFrame"

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

--// Modules
local reference = require(script.Parent.Utils.reference)
local Utils = require(script.Parent.Utils)
local Presets = require(script.Presets)

--// Module-Constants
local Log = Utils.log.new("[TaikaGui]")

--~~/// [[ Private Functions ]] ///~~--

local function PrintTrace(message: string?)
	Log:warnheader(`Error Trace`)
	if message then
		Log:warn(message)
	end
	Log:printheader("[2]")
	print(debug.info(2, "s"), debug.info(2, "l"))
	Log:printheader("[3]")
	print(debug.info(3, "s"), debug.info(3, "l"))
	Log:printheader("[4]")
	print(debug.info(4, "s"), debug.info(4, "l"))
end

local function SearchForClass(
	self: CLASS,
	element: Instance
): { element: Instance, key: number, class: TYPE_ELEMENT_CLASS } | nil
	local classDict = self.elements.classes
	for key, class: TYPE_ELEMENT_CLASS in pairs(classDict) do
		if class.instance == element then
			return { element = element, key = key, class = class }
		end
	end
	return nil
end

local function GetEmptyElementClass(): TYPE_ELEMENT_CLASS
	return {
		lastStateUsed = "",
		states = {},
		values = {},
		lastPropertySetTable = {},
	} :: TYPE_ELEMENT_CLASS
end

--~~/// [[ Main Module ]] ///~~--

--[=[
	@class Base
	
	Class containing general functions for TaikaGui instances.

	:::note

	In the API documentation, ignore the first parameter **self**.
	It is also there because the functions are created using the dot notation instead of the colon noation.

	For example:
	```lua
	-- What should usually be done:
	function x:foo()
		-- code
	end

	-- What's being done:
	function x.foo(self: Class)
		-- code
	end
	```

	:::

	:::tip

	TaikaGui uses a similar chainable-method archiecture as **[TopbarPlus](https://github.com/1ForeverHD/TopbarPlus)**.
	You can call methods as such:

	```lua
		local gui = TaikaGui.new(...)
		gui:SomeFunction()
			:AnotherFunction()
			:MoreFunctionss()
	```

	:::

]=]
local TaikaGui = {}
TaikaGui._globals = {}
TaikaGui._globals.guis = {}
TaikaGui._globals.elements = {}
TaikaGui._globals.values = {}
TaikaGui.__index = TaikaGui

--[=[
@within Base
@param id -- Serves as name and id of the gui class
@param preset -- Preset to use for preset related functions
@return CLASS
Creates a new of instance of the TaikaGui class.
]=]
function TaikaGui.new(id: string, preset: TYPE_PRESETS)
	if not id then
		Log:warn(`[TaikaGui.new] missing param 'id'`)
		PrintTrace()
	end

	local self = setmetatable({}, TaikaGui) :: CLASS
	local empty = GetEmptyElementClass()

	self.elements = {
		maingui = empty :: TYPE_ELEMENT_CLASS,
		stored = empty :: TYPE_ELEMENT_CLASS,
		previous = empty :: TYPE_ELEMENT_CLASS,
		selected = empty :: TYPE_ELEMENT_CLASS,
		classes = {} :: { [any]: TYPE_ELEMENT_CLASS },
		groups = {} :: { { TYPE_ELEMENT_CLASS } },
		selected_group = nil :: {}?,
	}

	self.data = {
		events = {},
		publicstates = {},
		presetname = preset or "Minima",
	}

	self:Construct("ScreenGui", id):ParentToInstance(Utils.reference.Client.PlayerGui)
	self.elements.maingui = self:RetrieveSelectedClass() :: TYPE_ELEMENT_CLASS

	TaikaGui._globals.guis[id] = self

	return self
end

--~~/// [[ Class Type ]] ///~~---
type CLASS = typeof(TaikaGui.new(...))

--~~/// [[ Base Functions ]] ///~~--

--[=[
A primary function of the class.
Use this function to create a new element (Instance instance).

Example use:
```lua
gui:Construct("Frame", "Container") -- Create a Frame instance with id "Container"
```
@within Base
]=]
function TaikaGui.Construct(self: CLASS, elementClass: PossibleElements, id: string?): CLASS
	-- Auto-set id if not given
	if not id then
		id = HttpService:GenerateGUID()
	end

	-- Check if element already exists
	if self.elements.classes[id] then
		Log:error(`Element with id: [{id}] already exists.`)
		PrintTrace()
	end

	local ElementClass = GetEmptyElementClass()
	ElementClass.instance = Instance.new(elementClass) :: Instance

	if id then
		ElementClass.instance.Name = id
	end

	self.elements.classes[id] = ElementClass
	self.elements.previous = self:RetrieveSelectedClass()
	self.elements.selected = ElementClass
	return self
end

function TaikaGui.ClearChildren(self: CLASS): CLASS
	self:RetrieveSelectedElement():ClearAllChildren()
	return self
end

function TaikaGui.SelectGui(self: CLASS): CLASS
	self:Select(self.elements.maingui)
	return self
end

function TaikaGui.GetElementValue(self: CLASS, value: string): any
	local SelectedClass = self:RetrieveSelectedClass()
	if not SelectedClass then
		PrintTrace("No selected class.")
		return nil
	else
		return SelectedClass.values[value]
	end
end

function TaikaGui.SetElementValue(self: CLASS, valueIndex: string, newValue: any): CLASS | nil
	local SelectedClass = self:RetrieveSelectedClass()
	if not SelectedClass then
		PrintTrace("No selected class.")
		return nil
	else
		SelectedClass.values[valueIndex] = newValue
	end
	return self
end

function TaikaGui.SetGui(self: CLASS, state: boolean): CLASS
	(self.elements.maingui.instance :: ScreenGui).Enabled = state
	return self
end

--[=[
@within Base
@return string
Retrieve the last state name the selected element was in.
]=]
function TaikaGui.GetLastState(self: CLASS)
	local SelectedClass = self:RetrieveSelectedClass()
	return SelectedClass.lastStateUsed
end

--[=[
Selects an element given either a class id, the class itself, or the class.instance
@within Base
@return CLASS
]=]
function TaikaGui.Select(self: CLASS, element: string): CLASS
	local class = {} :: TYPE_ELEMENT_CLASS

	if typeof(element) == "string" then
		class = self.elements.classes[element]
		print(self.elements.classes)
	elseif typeof(element) == "table" then
		class = element
	elseif typeof(element) == "Instance" then
		local SearchResult = SearchForClass(self, element)
		if SearchResult then
			class = SearchResult.class
		end
		if not class then
			Log:warn(`Element: [{element}] exists outside of a class. Creating a class for element [{element}]..`)
			class = GetEmptyElementClass() :: TYPE_ELEMENT_CLASS
			self:AppendClass(class, element.Name)
		end
	else
		print(debug.info(2, "s"), "|", debug.info(3, "s"))
		print(debug.info(2, "l"), "|", debug.info(3, "l"))
		Log:error(`Wrong type given for element parameter of :Select() function. | [{element}] | [{typeof(element)}]`)
	end

	self.elements.previous = self:RetrieveSelectedClass()
	self.elements.selected = class
	return self
end

--[=[
Alias for print() via the Log:print() function found in the Utils.log class.
@within Base
@param ... any -- print function arguments
@return CLASS
]=]
function TaikaGui.Print(self: CLASS, ...: any)
	Log:print(...)
	return self
end

--[=[
Stores an element. Can be retrieved (reselected) later by calling `obj:RetrieveFromStore()`
@within Base
@return CLASS
]=]
function TaikaGui.Store(self: CLASS)
	self.elements.stored = self:RetrieveSelectedClass()
	return self
end

--[=[
Selects the stored element. Element is stored by calling :Store()
@within Base
@return CLASS
]=]
function TaikaGui.RetrieveFromStore(self: CLASS)
	self:Select(self.elements.stored)
	return self
end

--[=[
@within Base
@return CLASS
Adds a class to the `obj.elements.classes` dictionary given a random id.
:::warning
**This method should not be called in most circumstances, as there is no reason for it. This is a function built for internal use.**
However, there should be no danger in calling this function in most cases.
:::
]=]
function TaikaGui.AppendClass(self: CLASS, Class: TYPE_ELEMENT_CLASS, newId: string?)
	self.elements.classes[newId or HttpService:GenerateGUID()] = Class
	return self
end

--[=[
@within Base
@return CLASS
Duplicates a class given its id, and automatically selects the class.
:::info
This method internally calls `:AppendClass()` and `:Select()` on the clone.
:::
]=]
function TaikaGui.Duplicate(self: CLASS, id: string?): CLASS
	local ToClone = id and self.elements.classes[id] or self.elements.selected :: TYPE_ELEMENT_CLASS
	local ElementToBeCloned = ToClone.instance
	local ClonedClass = Utils.table.DeepCopy(ToClone)

	local OriginalDescendants = ElementToBeCloned:GetDescendants()
	local OriginalRefTable = {}

	for _, element in ipairs(OriginalDescendants) do
		local ID = HttpService:GenerateGUID()
		element:SetAttribute("CloneID", ID)
		OriginalRefTable[ID] = element
	end

	ClonedClass.instance = ElementToBeCloned:Clone() :: Instance

	for _, element in ClonedClass.instance:GetDescendants() do
		local CloneID = element:GetAttribute("CloneID")
		element:SetAttribute("CloneID", nil)
		local OriginalElement = OriginalRefTable[CloneID]
		local SearchResult = SearchForClass(self, OriginalElement)
		if SearchResult and SearchResult.class then
			local Class = SearchResult.class
			local DescendantClonedClass = Utils.table.DeepCopy(Class)
			DescendantClonedClass.instance = element
			self:AppendClass(DescendantClonedClass)
		end
	end

	self:AppendClass(ClonedClass):Select(ClonedClass)
	return self
end

--[=[
@within Base
@param name -- key of value
@param value -- value to set
@return CLASS
Values are substitutes to attributes, created to be able to be called witnin a method-chain.
:::note
**Global** means it can be accessed by any object of the class, and is not limited to the scope of any particular object.
_Values are also not an alias of attributes, and instead uses an internal table._
:::
]=]
function TaikaGui.SetGlobalValue(self: CLASS, name: string, value: any)
	TaikaGui._globals.values[name] = value
	return self
end

--[=[
@within Base
@param alsoSetName -- if true, also sets the **`.Name`** property of the element instance to the **`newId`**
@return CLASS
Sets the ID of the element to the provided `newId`
]=]
function TaikaGui.SetId(self: CLASS, newId: string, alsoSetName: boolean): CLASS
	local Classes = self.elements.classes
	local SelectedClass = self:RetrieveSelectedClass()
	local SelectedInstance = SelectedClass.instance
	local SearchResult = SearchForClass(self, SelectedInstance)
	local OldIndex = SearchResult and SearchResult.key

	if not OldIndex then
		PrintTrace("Search result yielded nothing.")
	end

	Classes[OldIndex] = nil
	self.elements.classes[newId] = SelectedClass
	if alsoSetName then
		self.Util:SetName(newId)
	end
	return self
end

--[=[
@within Base
@return CLASS
Set a new preset to use for preset-related functions
]=]
function TaikaGui.SetPreset(self: CLASS, preset: TYPE_PRESETS)
	self.data.presetname = preset
	return self
end

--[=[
@within Base
@return Instance
Returns the element instance given the id of the element class.
]=]
function TaikaGui.RetrieveElementFromId(self: CLASS, id: string)
	return self.elements.classes[id].instance :: Instance
end

--[=[
@within Base
@return CLASS
Clones any UIBase instances from the children of given id's element instance.
Cloned UIBase instances are parented to the currently selected element's intsance.
:::tip
The **`UIBase`** class contains instances such as **UICorner**, **UIGradient**, **UIAspectRatioConstraint**, and others.
:::
]=]
function TaikaGui.DuplicateDecorationFromId(self: CLASS, id: string)
	local SelectedClass = self:RetrieveSelectedClass()
	local ElementToCloneFrom = self:RetrieveElementFromId(id)

	for _, UIDecoration in ElementToCloneFrom:GetChildren() do
		if UIDecoration:IsA("UIBase") then
			local new = UIDecoration:Clone()
			new.Parent = SelectedClass.instance
		end
	end

	return self
end

--[=[
@within Base
@param parent -- The instance to set as the selected element's new parent.
@return CLASS
Sets the current selected elements **`.instance`** to the _**`parent`**_ parameter.
]=]
function TaikaGui.ParentToInstance(self: CLASS, parent: GuiObject)
	local SelectedElement = self:RetrieveSelectedElement() :: GuiObject
	SelectedElement.Parent = parent
	pcall(function()
		SelectedElement.ZIndex = parent.ZIndex
	end)
	return self
end

--[=[
@within Base
@return CLASS
Parents the selected element to the previously selected element.
]=]
function TaikaGui.ParentToPreviousElement(self: CLASS)
	local SelectedElement = self:RetrieveSelectedElement() :: GuiObject
	SelectedElement.Parent = self.elements.previous.instance
	pcall(function()
		SelectedElement.ZIndex = (self.elements.previous.instance :: GuiObject).ZIndex
	end)
	return self
end

--[=[
@within Base
@return CLASS
Parents the selected element to the previously selected element's parent.
]=]
function TaikaGui.ParentToPreviousElementsParent(self: CLASS)
	self.elements.selected.instance.Parent = self.elements.previous.instance.Parent
	pcall(function()
		(self.elements.selected.instance :: GuiObject).ZIndex = (self.elements.previous.instance.Parent :: GuiObject).ZIndex
	end)
	return self
end

--[=[
@within Base
@param self 
@param propertyTable {property=value} -- Dictionary of properties following this format: ```{[property] =[value]}```
@param tweenInfo? -- Optional **`TweenInfo`** paramater. If one is given, it will tween the properties being set instead of applying all immediately.
@param doNotSave? -- Optional: if true, saves the propertyTable as the lastPropertySetTable.
@return CLASS
Given a table of properties, sets the selected element's properties to each defined property in the table.
:::tip
This will be one of the more-used functions in an object.
Here is an example:
```lua
local TWEEN_INFO = TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) -- some tween info
local gui = TaikaGui.new("MainMenu", "Minima")

gui:Construct("Frame", "Container") -- Let's create a Frame and give it the id "Container"
	:LoadPreset() -- Load the Minima preset properties for the instance class "Frame"
	:SetProperty({ -- Now let's manually set the properties we want.
	
		Size = UDim2.fromScale(1, 1)

	}, TWEEN_INFO) -- Let's add a TweenInfo so it becomes animated too.
```
:::
]=]
function TaikaGui.SetProperty(self: CLASS, propertyTable: {}, tweenInfo: TweenInfo?, doNotSave: boolean?)
	local SelectedClass = self:RetrieveSelectedClass()
	local SelectedElement = SelectedClass.instance

	Utils.property.SetTable(SelectedElement, propertyTable, tweenInfo)

	if not doNotSave then
		for key, value in pairs(propertyTable) do
			SelectedClass.lastPropertySetTable[key] = value
		end
	end

	return self
end

--[=[
@within Base
@return CLASS
Parents the selected element to the element referenced by the given **`id`** parameter.
]=]
function TaikaGui.ParentToElement(self: CLASS, id: string): CLASS
	self:RetrieveSelectedElement().Parent = self:RetrieveElementFromId(id)
	return self
end

function TaikaGui.ParentToGui(self: CLASS)
	self:ParentToInstance(self.elements.maingui.instance)
	return self
end

--[=[
@within Base
@param index -- name of custom preset index to load in the selected element. You will have to look in the preset modules to find/add the custom ones.
@return CLASS
Load's a custom instance preset data.
:::warning
The preset **`Key`** argument is not the same one you can pass to :SetPreset().
The key is used to index the **selected preset**.

For example:
```lua
local gui = TaikaGui.new("MainMenu", "Minima") -- Minima is the preset.
gui:Construct("Frame")
	:LoadCustomInstancePreset("Container")
	-- Let's say the container preset is:
	-- "Container" = {
	
	-- 	BackgroundTransparency = 1,
	-- 	Size = UDim2.fromScale(1, 1),
	
	-- }
	-- It would load these properties unto the selected element, which is the Frame we constructed.
```
:::
]=]
function TaikaGui.LoadCustomPreset(self: CLASS, index: string, tweenInfo: TweenInfo?)
	local PresetData = self.data.presetname and Presets[self.data.presetname]
	local PropertyTable = PresetData["Custom"][index]
	self:SetProperty(PropertyTable, tweenInfo)
	return self
end

--[=[
@within Base
@return CLASS
Load the preset selecting when **`TaikaGui.new`** was called or when **`gui:SetPreset()`** was called.
]=]
function TaikaGui.LoadPreset(self: CLASS, tweenInfo: TweenInfo?)
	local PresetTable = self.data.presetname and Presets[self.data.presetname]
	Log:assert(PresetTable, `No preset found with name [{self.data.presetname}]`)
	local SelectedElement = self:RetrieveSelectedElement()
	local PresetData = PresetTable[SelectedElement.ClassName]
	Log:assert(
		PresetData,
		`No preset in Preset: [{self.data.presetname}] exists for Instance Class: [{SelectedElement.ClassName}}`
	)
	self:SetProperty(PresetData, tweenInfo, true)
	return self
end

--[=[
@within Base
@return CLASS
Calls a function whenever the element is clicked.
]=]
function TaikaGui.OnClick(self: CLASS, func: (Instance, any?) -> any?, ...: any): CLASS
	local SelectedElement = self:RetrieveSelectedElement()
	local args = { ... }

	if not SelectedElement:IsA("GuiButton") then
		SelectedElement.InputBegan:Connect(function(input: InputObject)
			if SelectedElement.Active ~= true then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				func(SelectedElement, unpack(args))
			end
		end)
	else
		SelectedElement.Activated:Connect(function()
			func(SelectedElement, unpack(args))
		end)
	end
	return self
end

--[=[
@within Base
@param func -- callback, function to be called when mouse is hovering on element
@return CLASS
@tag Hover
Calls a function when the mouse is hovering on the element.
]=]
function TaikaGui.OnHover(self: CLASS, func: (Instance) -> any?)
	local SelectedElement = self:RetrieveSelectedElement()
	SelectedElement.MouseEnter:Connect(function()
		if SelectedElement.Active ~= true then
			return
		end
		func(SelectedElement)
	end)
	return self
end

--[=[
@within Base
@param func -- callback, function to be called when mouse is leaving the element
@return CLASS
@tag Hover
Calls a function when the mouse leaves the element.
]=]
function TaikaGui.OnUnhover(self: CLASS, func: (Instance) -> any?)
	local SelectedElement = self:RetrieveSelectedElement()
	SelectedElement.MouseLeave:Connect(function()
		func(SelectedElement)
	end)
	return self
end

--[=[
@yields
@within Base
@param time -- amount of time to yield for in seconds
@return CLASS
Calls **`task.wait(time)`**.
]=]
function TaikaGui.Yield(self: CLASS, time: number)
	task.wait(time or 0)
	return self
end

--[=[
@within Base
@return TYPE_ELEMENT_CLASS | { states: { any: any }, instance: Instance, lastStateUsed: string }
Returns the currently selected class table.
]=]
function TaikaGui.RetrieveSelectedClass(self: CLASS): TYPE_ELEMENT_CLASS
	return self.elements.selected
end

--[=[
@within Base
@return Instance
Returns the selected element instance.
]=]
function TaikaGui.RetrieveSelectedElement(self: CLASS): Instance?
	local SelectedClass = self:RetrieveSelectedClass()
	if not SelectedClass then
		PrintTrace(`No selected class.`)
		return nil
	end
	return SelectedClass.instance
end

--[=[
@within Base
@return CLASS
Yields until the value exists within the Global Values Table

Set through **`gui:SetGlobalValue()`**
]=]
function TaikaGui.YieldUntilPublicValueExists(self: CLASS, value: string)
	repeat
		task.wait()
	until TaikaGui._globals.values[value]
	return self
end

--~~/// [[ Group Class]] ///~~--

--[=[
@within Base
@param id -- id group id
@return CLASS
Create a new Group given an **`id`**.
]=]
function TaikaGui.CreateGroup(self: CLASS, id: string)
	Log:assert(not self.elements.groups[id], `Group with id: [{id}] already exists.`)
	self.elements.groups[id] = {}
	self:SelectGroup(id)
	return self
end

--[=[
@within Base
@param id -- group id
@return CLASS
Select a group using its id
]=]
function TaikaGui.SelectGroup(self: CLASS, id: string)
	self.elements.selected_group = self.elements.groups[id]
	return self
end

--[=[
@within Base
@param ... -- argument to pass to function. `function(...)`
@return CLASS
Iterate through each element class in a group and call the method on it.
]=]
function TaikaGui.GroupCall(self: CLASS, method: string, ...: any): CLASS
	local SelectedGroup = self:RetrieveSelectedGroup()
	self:Store()
	for _, element: Instance in pairs(SelectedGroup) do
		self:Select(element)
		self[method](self, ...)
	end
	self:RetrieveFromStore()
	return self
end

--[=[
@within Base
@return CLASS
Return the table of the currently selected group.
]=]
function TaikaGui.RetrieveSelectedGroup(self: CLASS)
	return self.elements.selected_group
end

--[=[
@within Base
@return CLASS
Adds the selected element to the selected groups array.
]=]
function TaikaGui.AddToGroup(self: CLASS): CLASS
	table.insert(self:RetrieveSelectedGroup(), self:RetrieveSelectedElement())
	return self
end

--~~/// [[ State Functions ]] ///~~---

--[=[
@within Base
@param state -- name of the state to load, as created through ~Base.Create(name: string)
@param tweenInfo -- Optional TweenInfo paramter that will tween the properties using the provided TweenInfo.
@return CLASS
Creates a public state accessible by all objects wihin the object scope.
]=]
function TaikaGui.LoadPrivateState(self: CLASS, state: string, tweenInfo: TweenInfo): CLASS
	local SelectedClass = self:RetrieveSelectedClass()
	local StateTable = SelectedClass.states
	local Element = SelectedClass.instance
	SelectedClass.lastStateUsed = state
	Utils.property.SetTable(Element, StateTable[state], tweenInfo)
	return self
end

--[=[
@within Base
@param name -- serves as identifier for loading a state through ~Base.Load(state: string)
@param stateTable -- a dictionary of properties and values following the structore of { [property] = [value] }
Creates a public state accessible by all objects wihin the object scope.
:::note Note
Creating a state does not load it automatically.

Use **`Base:Load(STATE_NAME)`** to actually load the state.
:::
]=]
function TaikaGui.CreatePrivateState(self: CLASS, name: string, stateTable: {}): CLASS
	local SelectedClass = self:RetrieveSelectedClass()
	Log:assert(not SelectedClass.states[name], `State with name: [{name}] already exists.`)
	SelectedClass.states[name] = stateTable
	return self
end

function TaikaGui.CreatePublicState(self: CLASS, name: string, stateTable: {}): CLASS
	self.data.publicstates[name] = stateTable
	return self
end

function TaikaGui.LoadPublicState(self: CLASS, state: string, tweenInfo: TweenInfo): CLASS
	local StateTable = self.data.publicstates
	local SelectedClass = self:RetrieveSelectedClass()
	local SelectedElement = SelectedClass.instance
	SelectedClass.lastStateUsed = state
	Utils.property.SetTable(SelectedElement, StateTable[state], tweenInfo)
	return self
end

--~~/// [[ Util Class ]] ///~~--

function TaikaGui.ToggleGuiOnClick(self: CLASS, gui: string): CLASS
	local guiClass = self._globals.guis[gui]
	local screenGui = guiClass.elements.maingui.instance :: ScreenGui

	self:OnClick(function()
		screenGui.Enabled = not screenGui.Enabled
	end)

	return self
end

function TaikaGui.Call(self: CLASS, func: (any?) -> any?, ...): CLASS
	func(...)
	return self
end

function TaikaGui.SetFont(self: CLASS, font: Enum.Font): CLASS
	self:RetrieveSelectedElement().FontFace = Font.fromEnum(font)
	return self
end

function TaikaGui.SetText(self: CLASS, newText: string): CLASS
	self:RetrieveSelectedElement().Text = newText
	return self
end

function TaikaGui.SetIgnoreInset(self: CLASS, bool: boolean): CLASS
	local maingui = self.elements.maingui.instance :: ScreenGui
	maingui.IgnoreGuiInset = bool
	return self
end

--[=[
@within Base
@param name -- new value to set the element's `.Name` property to
@return CLASS
Set's the name of the selected element to the argument given.
]=]
function TaikaGui.SetName(self: CLASS, name: string): CLASS
	self:RetrieveSelectedElement().Name = name
	return self
end

--[=[
@within Base
@param ratio -- number representating the ratio of **`width/length`**
@return CLASS
Creates a UIConstraint and sets the ratio to the parameter **`ratio`** then parents it to the currently selected element.

:::note
Can also be done like this:
```lua
gui:Construct("UIAspectRatioConstraint")
	:SetProperty({ratio = SOME_RATIO_HERE})
	:ParentToPreviousElement()
```
Though note that it does not do the same thing internally when calling **`:AddConstraint()`**
:::
]=]
function TaikaGui.AddConstraint(self: CLASS, ratio: number): CLASS
	local Constraint = Instance.new("UIAspectRatioConstraint")
	Constraint.AspectRatio = ratio
	Constraint.Parent = self:RetrieveSelectedElement()
	return self
end

function TaikaGui.SetImage(self: CLASS, image: string): CLASS
	self:RetrieveSelectedElement().Image = image
	return self
end

--[=[
@within Base
@return CLASS
@tag Text
Sets the text property of the selected element to only asterisks "*".

Internally saves the unobfuscated text as an attribute.

To restore, see  **`:DeobfuscateText()`**

:::warning CAUTION
Only call this method if the selected element has a **`.Text`** property.
:::
]=]
function TaikaGui.ObfuscateText(self: CLASS)
	local SelectedElement = self:RetrieveSelectedElement()
	SelectedElement:SetAttribute("DeobfuscatedText", SelectedElement.Text)
	SelectedElement.Text = string.rep("*", #SelectedElement.Text)
	return self
end

--[=[
@within Base
@return CLASS
@tag Text
:::warning CAUTION
Only call this method if the selected element has a **`.Text`** property.
:::
Restores the obfuscated text that was set by calling :ObfuscateText()
]=]
function TaikaGui.DeobfuscateText(self: CLASS)
	local SelectedElement = self:RetrieveSelectedElement()
	local DeobfuscatedText = SelectedElement:GetAttribute("DeobfuscatedText")
	SelectedElement.Text = DeobfuscatedText or ""
	return self
end

--[=[
@within Base
@return CLASS
Sets the **`Enabled/Active`** property to true for the selected element.
]=]
function TaikaGui.Enable(self: CLASS)
	pcall(function()
		self:RetrieveSelectedElement().Enabled = true
	end)
	pcall(function()
		self:RetrieveSelectedElement().Active = true
	end)
	return self
end

--[=[
@within Base
@return CLASS
Sets the **`Enabled/Active`** property to false for the selected element.
]=]
function TaikaGui.Disable(self: CLASS)
	pcall(function()
		self:RetrieveSelectedElement().Enabled = false
	end)
	pcall(function()
		self:RetrieveSelectedElement().Active = false
	end)
	return self
end

--[=[
@within Base
@return CLASS
Sets the **`Enabled/Visible`** property to false for the selected element.
]=]
function TaikaGui.Hide(self: CLASS): CLASS
	pcall(function()
		self:RetrieveSelectedElement().Visible = false
	end)
	pcall(function()
		self:RetrieveSelectedElement().Enabled = false
	end)
	return self
end

--[=[
@within Base
@return CLASS
Sets the **`Enabled/Visible`** property to true for the selected element.
]=]
function TaikaGui.Show(self: CLASS)
	pcall(function()
		self:RetrieveSelectedElement().Visible = true
	end)
	pcall(function()
		self:RetrieveSelectedElement().Enabled = true
	end)
	return self
end

--[=[
@within Base
@param amount -- multiplier
@return CLASS
Multiplies the **`element.Size.X.Scale`** and **`element.Size.Y.Scale`** by the number provided.
]=]
function TaikaGui.Scale(self: CLASS, amount: number, tweenInfo: TweenInfo)
	local TargetElement = self:RetrieveSelectedElement()
	local CurrentScaleSizeX = TargetElement.Size.X.Scale
	local CurrentScaleSizeY = TargetElement.Size.Y.Scale
	local NewSize = UDim2.fromScale(CurrentScaleSizeX * amount, CurrentScaleSizeY * amount)
	self:SetProperty({
		Size = NewSize,
	}, tweenInfo, true)
	return self
end

--[=[
@within Base
@param eventName -	name of event function to call/fire
@param ... -- arguments to pass to function/event
@return CLASS
Calls any function binded to the event name.
]=]
function TaikaGui.FireEvent(self: CLASS, eventName: string, ...: any?)
	local SelectedElement = self:RetrieveSelectedElement()
	local EventTable = self.data.events[eventName]

	if not EventTable then
		PrintTrace(`No [{eventName}] in self.data.events`)
		return self
	end

	for _, func in ipairs(EventTable) do
		func(SelectedElement, ...)
	end

	return self
end

function TaikaGui.ListenToProperty(self: CLASS, propertyName: string, callback: (Instance, any) -> any?): CLASS
	local SelectedElement = self:RetrieveSelectedElement()
	SelectedElement:GetPropertyChangedSignal(propertyName):Connect(function()
		callback(SelectedElement, SelectedElement[propertyName])
	end)
	return self
end

--[=[
@within Base
@param eventName -- name of event to listen to
@param func -- function to call when event is fired
@return CLASS
Calls a function when an event is fired through **`.Signal:Fire(...)`**.
]=]
function TaikaGui.ListenToEvent(self: CLASS, eventName: string, func: (Instance, any?) -> any?)
	local EventTable = self.data.events[eventName]

	if not EventTable then
		self.data.events[eventName] = {}
		EventTable = self.data.events[eventName]
	end

	table.insert(EventTable, func)
	return self
end

--[=[
@within Base
@param signalName -- name of instance signal to connect to
@param func -- function to call when signal is fired
@return CLASS
Listens to an element's signal. For example: **`humanoid.HealthChanged():Connect()`**
]=]
function TaikaGui.ListenToSignal(self: CLASS, signalName: string, func: (Instance, any?) -> any?)
	local SelectedElement = self:RetrieveSelectedElement()

	SelectedElement[signalName]:Connect(function(...)
		func(SelectedElement, ...)
	end)

	return self
end

--[=[
@within Base
@param property -- Name of property to listen to
@param func -- Callback function
@return CLASS
Listens for changes in a property and calls the function given, passing the element as the first argument, and the value second.
]=]
function TaikaGui.GetPropertyChangedSignal(self: CLASS, property: string, func: (Instance, any?) -> any?)
	local SelectedElement = self:RetrieveSelectedElement()

	SelectedElement:GetPropertyChangedSignal(property):Connect(function()
		func(SelectedElement, SelectedElement[property])
	end)

	return self
end

--[=[
@within Base
@param attribute -- Name of attribute to listen to
@param func -- Callback function
@return CLASS
Listens for changes in an attribute and calls the function provided, passing the element, and the attribute value.
]=]
function TaikaGui.GetAttributeChangedSignal(self: CLASS, attribute: string, func: (Instance, any?) -> any?)
	local SelectedElement = self:RetrieveSelectedElement()

	SelectedElement:GetAttributeChangedSignal(attribute):Connect(function()
		func(SelectedElement, SelectedElement:GetAttribute(attribute))
	end)

	return self
end

--~~/// [[ Effects Class ]] ///~~--
--~~[[ Effects ]]~~--

-- [[ Effects ]] --
-- What sets effects apart is that they are in pairs, and each pair cannot be stacked.
-- For example, you cannot apply grow consecutively on the same element, you have to use the counterpart shrink first to use grow again.

--// Text Highlight

function TaikaGui.HighlightText(self: CLASS, data: TYPE_EFFECT_HIGHLIGHTTEXT)
	local SelectedElement = self:RetrieveSelectedElement()
	local isHighlighted = SelectedElement:GetAttribute("isHighlighted")
	local TargetColour = data.color :: Color3
	local Ti = data.tweeninfo :: TweenInfo

	if not isHighlighted then
		SelectedElement:SetAttribute("isHighlighted", true)

		if not SelectedElement:GetAttribute("PreviousColour") then
			SelectedElement:SetAttribute("PreviousColour", SelectedElement.BackgroundColor3)
		end

		self:SetProperty({

			TextColor3 = TargetColour,
		}, Ti, true)
	end

	return self
end

function TaikaGui.RemoveTextHighlight(self: CLASS, data: TYPE_EFFECT_HIGHLIGHTTEXT)
	local SelectedElement = self:RetrieveSelectedElement()

	local PreviousColour = SelectedElement:GetAttribute("Previous")
	local isHighlighted = SelectedElement:GetAttribute("isHighlighted")
	local Ti = data.tweeninfo :: TweenInfo

	if isHighlighted then
		SelectedElement:SetAttribute("isHighlighted", nil)

		self:SetProperty({

			TextColor3 = PreviousColour,
		}, Ti, true)
	end

	return self
end

--// Background Highlight

function TaikaGui.Highlight(self: CLASS, data: TYPE_EFFECT_HIGHLIGHT)
	local SelectedElement = self:RetrieveSelectedElement()
	local isHighlighted = SelectedElement:GetAttribute("isHighlighted")
	local TargetColour = data.color :: Color3
	local transparency = data.transparency :: number
	local Ti = data.tweeninfo :: TweenInfo

	if not isHighlighted then
		SelectedElement:SetAttribute("isHighlighted", true)

		if not SelectedElement:GetAttribute("PreviousTranparency") then
			SelectedElement:SetAttribute("PreviousTranparency", SelectedElement.Transparency)
			SelectedElement:SetAttribute("PreviousColour", SelectedElement.BackgroundColor3)
		end

		self:SetProperty({

			BackgroundColor3 = TargetColour,
			BackgroundTransparency = transparency,
		}, Ti, true)
	end

	return self
end

function TaikaGui.RemoveHighlight(self: CLASS, data: TYPE_EFFECT_HIGHLIGHT)
	local SelectedElement = self:RetrieveSelectedElement()

	local PreviousColour = SelectedElement:GetAttribute("Previous")
	local isHighlighted = SelectedElement:GetAttribute("isHighlighted")
	local Ti = data.tweeninfo :: TweenInfo

	if isHighlighted then
		SelectedElement:SetAttribute("isHighlighted", nil)

		self:SetProperty({

			BackgroundTransparency = SelectedElement:GetAttribute("PreviousTranparency"),
			BackgroundColor3 = PreviousColour,
		}, Ti, true)
	end

	return self
end

--// Expansion

function TaikaGui.Grow(self: CLASS, data: TYPE_EFFECT_EXPANSION)
	local SelectedElement = self:RetrieveSelectedElement()
	local isGrown = SelectedElement:GetAttribute("isGrown")

	if not isGrown then
		SelectedElement:SetAttribute("isGrown", true)
		SelectedElement:SetAttribute("GrownAmount", data.scale)

		self:Scale(data.scale, data.tweeninfo)
	end

	return self
end

function TaikaGui.Shrink(self: CLASS, data: TYPE_EFFECT_EXPANSION)
	local SelectedElement = self:RetrieveSelectedElement()
	local isGrown = SelectedElement:GetAttribute("isGrown")
	local LastSetSize = self:GetOriginalProperty(SelectedElement, "Size")

	if isGrown then
		SelectedElement:SetAttribute("isGrown", nil)

		self:SetProperty({
			Size = LastSetSize,
		}, data.tweeninfo, true)
	end

	return self
end

--~~[[ Effect Data Builder ]]~~--
function TaikaGui.getTextHighlightData(color: Color3, tweenInfo: TweenInfo)
	return { color = color, tweeninfo = tweenInfo }
end

function TaikaGui.getHighlightData(color: Color3, transparency: number, tweenInfo: TweenInfo)
	return { color = color, transparency = transparency, tweeninfo = tweenInfo }
end

function TaikaGui.getExpansionData(scale: number, tweenInfo: TweenInfo)
	return { scale = scale, tweeninfo = tweenInfo }
end

--~~[[ Effect Binders ]]~~--

--[=[
@within Base
@return CLASS
]=]
function TaikaGui.BindEffectToSignal(
	self: CLASS,
	signal: TYPE_EFFECT_SIGNALS,
	effect: TYPE_EFFECTS,
	data: { any }
): CLASS
	local SelectedElement = self:RetrieveSelectedElement()

	--// Get Functinos
	local Enable, Disable

	if effect == "Expansion" then
		Enable = self.Grow
		Disable = self.Shrink
	end

	if effect == "ColourText" then
		Enable = self.HighlightText
		Disable = self.RemoveTextHighlight
	end

	if effect == "ColourBackground" then
		Enable = self.Highlight
		Disable = self.RemoveHighlight
	end

	--// Behaviour

	if signal == "Mouse.Hover" then
		self:OnHover(function()
			self:Store()
			self:Select(SelectedElement)
			Enable(self, data)
			self:RetrieveFromStore()
		end)
		self:OnUnhover(function()
			self:Store()
			self:Select(SelectedElement)
			Disable(self, data)
			self:RetrieveFromStore()
		end)
	end

	return self
end

--~~/// [[ Motion Effects ]] ///~~--
-- [[ Motion Effects ]] --

function TaikaGui:AddMotionEffect(MotionEffect: "Spin", data: TYPE_MOTION_EFFECT_SPIN): CLASS
	local SelectedElement = self:RetrieveSelectedElement()

	if MotionEffect == "Spin" then
		local SpinId = HttpService:GenerateGUID() .. "_SPIN"

		SelectedElement:SetAttribute("SPIN_ID", SpinId)

		RunService:BindToRenderStep(SpinId, Enum.RenderPriority.Camera.Value, function(deltaTime)
			SelectedElement.Rotation += deltaTime * 20 * (data.speed or 1)
		end)
	end

	return self
end

function TaikaGui:RemoveMotionEffect(MotionEffect: "Spin"): CLASS
	local SelectedElement = self:RetrieveSelectedElement()

	if MotionEffect == "Spin" then
		RunService:UnbindFromRenderStep(SelectedElement:GetAttribute("SPIN_ID"))
	end

	return self
end

--~~/// [[ Live Effects ]] ///~~--

-- [[ Decorative Effects ] --

function TaikaGui.AddLiveDecorationEffect(
	self: CLASS,
	DecorativeEffect: TYPE_LIVE_EFFECT_EFFECTS,
	data: TYPE_LIVE_EFFECT_STROBE
): CLASS
	local SelectedElement = self:RetrieveSelectedElement()

	if DecorativeEffect == "Strobe" then
		local ID = HttpService:GenerateGUID() .. "_GRADIENTSTROBE"

		SelectedElement:SetAttribute("GRADIENTSTROBE_ID", ID)

		local BACKGROUND_COLOR = data.backgroundcolor or reference.Colors.LightGray :: Color3
		local STROBE_COLOR = data.strobecolor or reference.Colors.White :: Color3
		local SPEED_MULTIPLIER = data.speedmul :: number
		local START = data.min or -0.5 :: number
		local END = data.max or 1.5 :: number
		local Rotation = data.rotation :: number
		local Direction = data.direction :: Vector2

		local Gradient = Instance.new("UIGradient")
		local Sequence = ColorSequence.new({

			ColorSequenceKeypoint.new(0, BACKGROUND_COLOR),
			ColorSequenceKeypoint.new(0.5, STROBE_COLOR),
			ColorSequenceKeypoint.new(1, BACKGROUND_COLOR),
		})

		Gradient.Rotation = Rotation or 0
		Gradient.Color = Sequence
		Gradient.Parent = SelectedElement

		local offset = START

		RunService:BindToRenderStep(ID, Enum.RenderPriority.Camera.Value, function(deltaTime)
			offset += deltaTime * (SPEED_MULTIPLIER or 1)

			if offset >= END then
				offset = START
			end

			local offsetX = offset
			local offsetY = offset

			if Direction then
				offsetX *= Direction.X
				offsetY *= Direction.Y
			end

			Gradient.Offset = Vector2.new(offsetX, offsetY)
		end)
	end

	return self
end

function TaikaGui.RemoveLiveDecorationEffect(self: CLASS, DecorativeEffect: TYPE_LIVE_EFFECT_EFFECTS): CLASS
	local SelectedElement = self:RetrieveSelectedElement()

	if DecorativeEffect then
		local ID = SelectedElement:GetAttribute("GRADIENTSTROBE_ID")
		local Gradient = SelectedElement:FindFirstChildOfClass("UIGradient")

		if not ID then
			return self
		end

		SelectedElement:SetAttribute("GRADIENTSTROBE_ID", nil)

		Gradient:Destroy()
		RunService:UnbindFromRenderStep(ID)
	end

	return self
end

--~~[[ Retrieval ]]~~--
function TaikaGui.GetOriginalProperty(self: CLASS, elementRef: string | Instance, property: string)
	local ElementClass = nil :: TYPE_ELEMENT_CLASS?
	if typeof(elementRef) == "string" then
		local SearchResult = SearchForClass(self, self:RetrieveElementFromId(elementRef))
		ElementClass = SearchResult and SearchResult.class
	else
		local SearchResult = SearchForClass(self, elementRef)
		ElementClass = SearchResult and SearchResult.class
	end
	return ElementClass.lastPropertySetTable[property]
end

return TaikaGui

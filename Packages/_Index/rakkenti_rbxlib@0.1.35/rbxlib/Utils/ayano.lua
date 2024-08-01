--[[

@rakken
Cleanup module.
Use something like maid if you care about the best. This is for fun, but it does work!

]]

--// Services
local HttpService = game:GetService("HttpService")

--// Modules
local Log = require(script.Parent.log)

--// Module-Constants

--// Variables

--// Main
local Ayano = {}
Ayano.__index = Ayano

--~~/// [[ Public Functions ]] ///~~--

function Ayano.new()
	local self = setmetatable({}, Ayano)
	self._connections = {}
	self._threads = {}
	self._instances = {}
	self.logger = Log.new("[Ayano]")
	return self
end

type Class = typeof(Ayano.new())

function Ayano.DelayClean(self: Class, time: number)
	task.delay(time, self.Clean, self)
end

function Ayano.Clean(self: Class, id: string?)
	self:CleanConnections(id)
	self:CleanInstances(id)
	self:CleanThreads(id)
end

function Ayano.SetDebugMode(self: Class, bool: boolean)
	if bool then
		self.logger:enable()
	else
		self.logger:disable()
	end
end

function Ayano.Connect(self: Class, signal: RBXScriptSignal, callback: () -> nil, id: string?)
	local _id = id or HttpService:GenerateGUID()
	if id then
		self:CleanConnections(id)
	end
	self.logger:print("Tracking RBXScriptSignal..")
	local connection = signal:Connect(callback)
	self._connections[_id] = connection
	return connection
end

function Ayano.TrackThread(self: Class, thread: thread, id: string?)
	local _id = id or HttpService:GenerateGUID()
	if id then
		self:CleanThreads(id)
	end
	self.logger:print("Tracking thread..")
	self._threads[_id] = thread
	return thread
end

function Ayano.TrackInstance<i>(self: Class, i: i, id: string?): i
	local _id = id or HttpService:GenerateGUID()
	if id then
		self:CleanInstances(id)
	end
	self.logger:print("Tracking instance..")
	self._instances[_id] = i
	return i
end

--~~/// [[ Cleanup Functions ]] ///~~--
function Ayano.CleanInstances(self: Class, specific_id: string?)
	local AllInstances = self._instances
	self.logger:print("Cleaning Instances")
	if not specific_id then
		for id, instance: Instance in pairs(AllInstances) do
			local success = pcall(function()
				instance:Destroy()
			end)
			if not success then
				Log:warn(`Failed to destroy instance: [{instance}]`)
			end
			self._instances[id] = nil
		end
	else
		local instance = AllInstances[specific_id]
		local success = pcall(function()
			instance:Destroy()
		end)
		if not success then
			Log:warn(`Failed to destroy instance: [{instance}]`)
		end
		self._instances[specific_id] = nil
	end
end

function Ayano.CleanThreads(self: Class, specific_id: string?)
	local AllThreads = self._threads
	self.logger:print("Cleaning Threads")
	if not specific_id then
		for id, thread: thread in pairs(AllThreads) do
			local success = pcall(function()
				task.cancel(thread)
			end)
			if not success then
				Log:warn(`Failed to disconnect connection: [{id}]`)
			end
			self._threads[id] = nil
		end
		table.clear(AllThreads)
	else
		local thread = AllThreads[specific_id]
		local success = pcall(function()
			task.cancel(thread)
		end)
		if not success then
			Log:warn(`Failed to disconnect connection: [{specific_id}]`)
		end
		self._threads[specific_id] = nil
	end
end

function Ayano.CleanConnections(self: Class, specific_id: string?)
	local AllConnections = self._connections
	self.logger:print("Cleaning Connections")
	if not specific_id then
		for id, connection: RBXScriptConnection in pairs(AllConnections) do
			local success = pcall(function()
				connection:Disconnect()
			end)
			if not success then
				Log:warn(`Failed to disconnect connection: [{id}]`)
			else
				Log:print(`Disconnected connection: [{id}}`)
			end
			self._connections[id] = nil
		end
		table.clear(AllConnections)
	else
		local connection = AllConnections[specific_id]
		local success = pcall(function()
			connection:Disconnect()
		end)
		if not success then
			Log:warn(`Failed to disconnection connection: [{specific_id}]`)
		else
			Log:print(`Cancelled connection: [{specific_id}]`)
		end
		self._connections[specific_id] = nil
	end
end

--~~/// [[ Private Functions ]] ///~~--

warn([[
                                    Ayano@rakken/rbxlib/util                                                                                        
                                                     on.                                            
                                                 .663nz6a1                                          
                                                36;      3uo                                        
                                               ;a         !13                                       
                                            *vvu833!1z;.   z!i                                      
                                        i!!ii!u133iu1u1!36ai3ui                                     
                                     i!uu1uui8866683338666666!u8.                                   
                                  +!uu1uu13a1!ii86863633336333ai66                                  
                                 nuuuuuu3az1z111!!!!3!336!336!ia366!                                
                               ^^auuuuuiuuizizo11uau1!uai13!33!u33336                               
                              ^~;ouuuuuuuu1u!u1azza!1auiui1ii1!1!!!ii6                              
                             +nnnnovazvuzuiu1ui1u!a!1i11iuuuiuz!i!iii!8                             
                             zzzannnavzzz31iauiiiiui3u1u1iuuz1a31i3iii3z                            
                            uzzuazzvzvzvu11!aui111!u$uu1u1iaaai!iu!iii16                            
                           ^auziuuaaaazv1~13vai11uuu%1auaai1ai6i16i3!iiiz                           
                           i1uu!uuuuuvvi;.u3nauu1uu!8;auzvni11i!i!i3iiiu6                           
                          oi1uuiuu!uu1u;  v3vuzauuuai.~ziauuu1i3ii6i!ii131                          
                          ii11ui1u!1uu+   -!v3aazaav1..;u!111i!8ii3!3!i138-                         
                         niiu11i113iio     izau1zvnna .nvuu1u!38iii63!i1i86                         
                         ii3uu!!11!u! .....;aa~ua1uuz..-++nz~u68ii1%6!i1186i                        
                        .iii1u!8118un .....-1i*n!i1ua-^---^-^a~%i11%6ii11883+                       
                        zu!i!u!8zi6&$38&&$i^a!o-~!6uuz^;88638va&$iu#6!!116833                       
                        1v!13ui~ia!n~-~3i8iv~!u--n1iua^;183u~.a1u1u18!!116633n                      
                       ~v13u!u1-.uu1 .--nvn-..3*..v^iu~-;zz^^^u1!i!~%i61i6836!                      
                       vzi6u!!!v*+1ia .----....a+..vooin-----+1i!!^u6i8ii36663u                     
                      vn1u813!ii6- ^1z .---......+...o.izv+--v1!!z66u8%i!3%!36i-                    
                     +n1u36i331!863!^u -..............^^.o1uu633%88618%!36%! 36u                    
                     n11a33!!33i!8688!. ................+^^-1!!1%88u%8%!36v!n !6n                   
                    o11v 63%u3!16!636386*.................^836v368u888%868 !1  a!                   
                   ^u1z  !36u13ii3!366868a1;.......-..-n83611zi631!888%888 -3   vi                  
                  .11;   !38;u!3133!i6683u1nu^*n+--~~~~a1!u1aii1i18688$88o  !    *1                 
                  11     336 -u6iui3i138i1vu1^+^^^^*;~~zuuvv1u1!u83688688   !      1                
                -z1      z68-  16uuu!ii8a-nu!.^^^^^^^^^niuun*;!186383.883   i       i*              
                ;~        66!   u3u1u1ii-.o*+...^^^^^^^^z^^*vz168!86 683-  .1        3u             
              .;-         .13n    8111u1i -^......-^^^^^^^~ .u3oi3oza36-   oz         6!+           
             *;             u!ioo~~!!u!1u1 ^..........--+^* z63**3!iiauzzv16          1!!v          
            ^a             ^o;^^~^ni!!1ii3~ *-.......-...*..iuo**u!!3azzzzaaaa.        6i!z         
           ^a-          --+^^^^z+~~~~uniii3 +*^+-....---~  n1u^***!!!!;!zaua1ua        1!13n        
          .uz         ^++-^^^^v-~~~oo~.oii3.u-*;+...-..;.88iuu--**!!!!u3zz111u1        1iii6        
          u!+        *~~;*;;+n+onnnnnv..oi!zv3^.**^...^ 38v1u1n-.-;iz6z;zz;^;nv1       u1!1!3       
         ;i!         ;*^++;^++~ia;-ooz.-n6i+..;$&1+i.-.6!nv1u6~*o~-i1^++^z;;*~*z*      z1111i       
         a!v        -;;+*^*;+++++nn^v3-.a6unzi368%6%88aa8888i6!o.+*6uaz+^o;*^*;~a      v a11i      
]])

return Ayano

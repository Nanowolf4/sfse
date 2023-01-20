-- Original mod: https://github.com/appgurueu/fslib

local formspecs = {}

local id = 1
local max_id = 2^50

minetest.register_on_leaveplayer(function(player)
	formspecs[player:get_player_name()] = nil
end)

-- S-expression formspec AST to string; purely a syntactical string building helper unaware of semantics
local function build_formspec(formspec)
	local rope = {}

	local function write(text)
		return table.insert(rope, text)
	end

	local function write_escaped(text)
		-- return write(minetest.formspec_escape(text))
		return write(text)
	end

	local function write_primitive(param, write_func)
		write_func = write_func or write_escaped
		if param == true then
			return write_func("true")
		end
		if param == false then
			return write_func("false")
		end
		local type_ = type(param)
		if type_ == "number" then
			return write_func(param)
		end
		if type_ == "string" then
			return write_func(param)
		end
		error("primitive type expected, got " .. type_)
	end

	local function write_options(options, delim)
		local options_pushed = false
		for key, value in pairs(options) do
			if type(key) == "string" then
				if options_pushed then
					write(delim)
				end
				write_escaped(key)
				write("=")
				write_primitive(value)
				options_pushed = true
			end
		end
	end

	for i, element in ipairs(formspec) do
		if type(element) == "string" then -- assume top-level elements are simply formspec elements in string form
			write(element)
		else
			write(element[1])
			write("[")
			local len = #element

			for index = 2, len do
				if index > 2 then write(";") end
				local param = element[index]
				if type(param) == "table" then
					for subindex, subparam in ipairs(param) do
						if subindex > 1 then write(",") end
						write_primitive(subparam)
					end
				else
					write_primitive(param)
				end
			end

			if len == 1 then -- options element or empty table
				write_options(element, ";")
			end
			write("]")
			if #formspec ~= i then
				write("\n")
			end
		end
	end

	return table.concat(rope)
end

function sfse.build_formspec(formspec)
	if type(formspec) == "table" then
		return build_formspec(formspec)
	end
	return formspec
end

local nop = function() end
function sfse.show_formspec(player, formspec, handler)
	formspec = sfse.build_formspec(formspec)
	local player_name = player:get_player_name()
	local formspec_name = ("sfse:%d"):format(id)
	formspecs[player_name] = {
		name = formspec_name,
		handler = handler or nop,
	}
	id = id + 1
	if id > max_id then id = 1 end
	minetest.show_formspec(player_name, formspec_name, formspec)
	return formspec_name
end

function sfse.reshow_formspec(player, formspec_name, formspec)
	local player_name = player:get_player_name()
	assert(formspecs[player_name].name == formspec_name)
	minetest.show_formspec(player_name, formspec_name, sfse.build_formspec(formspec))
end

function sfse.close_formspec(player)
	local player_name = player:get_player_name()
	local formspec = assert(formspecs[player_name])
	formspecs[player_name] = nil
	minetest.close_formspec(player_name, formspec.name)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local player_name = player:get_player_name()
	local formspec = formspecs[player_name]
	if formname ~= (formspec or {}).name then return end
	if fields.quit then
		formspecs[player_name] = nil
	end
	local updated_formspec = formspec.handler(fields)
	if updated_formspec then
		if fields.quit then
			sfse.show_formspec(player, updated_formspec, formspec.handler)
		else
			minetest.show_formspec(player_name, formspec.name, sfse.build_formspec(updated_formspec))
		end
	end
	return true -- don't call remaining functions
end)

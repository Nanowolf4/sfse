-- Simple FormSpec Editor

-- Copyright (c) 2022 - 2023 Nanowolf4 (n4w@tutanota.com)
-- License: GPLv3

sfse = {}

local editor_data = {}
local formspec_data = {}


minetest.register_privilege("formspec_editor", {
	description = "Can use formspec editor (SFSE)",
    give_to_singleplayer = true
})

local privs_req = {["formspec_editor"] = true}

local sfse_path = minetest.get_modpath("sfse")
dofile(sfse_path .. "/simple_fslib.lua")
dofile(sfse_path .. "/projects.lua")
dofile(sfse_path .. "/parser.lua")

local projects = sfse.projects or {}
minetest.register_on_mods_loaded(function()
	for n, fs in pairs(projects) do
		if type(fs) == "string" then
			local fstable, err = sfse.formspec_to_table(fs)
			if err then
				minetest.log("warning", "sfse: '" .. n .. "' has a syntax error.")
				projects[n] = nil
			else
				projects[n] = fstable
			end
		end
	end
end)

function sfse.open_formspec(playername, formname, formspec)
	assert(playername, "Missing player name!")
	assert(formname, "Missing formname!")
	if (formspec) and formspec ~= "" then
		local fstable, err = sfse.formspec_to_table(formspec)
		if err then
			minetest.chat_send_player(playername, "Syntax error! You may have missed a square bracket")
		else
			projects[formname] = fstable
		end
	end
	sfse.show_editor(minetest.get_player_by_name(playername), formname)
end

local default_elements = {
	{"formspec_version", 6},
	{"size",{12, 8}},
}

local function find_coords(el, what)
	if (what == "xy") and type(el[2]) == "table" then
		return 2
	elseif (what == "wh") and type(el[3]) == "table" then
		return 3
	else
		local xy_found = false
		for i, v in pairs(el) do
			if type(v) == "table" then
				if type(v[1]) == "number" and type(v[2]) == "number" then
					if (what == "wh") and xy_found then
						return i
					else
						if what == "xy" then
							return i
						end
						xy_found = true
					end
				end
			end
		end
	end
end

local function quick_add(x, y)
	return {x[1] + y[1], x[2] + y[2]}
end

local function main_gui(session_name)

	local last_pos, last_size = {0, -0.5}, {0, 0}
	local blank_space = {0, 0}

	local function el_pos(pos, pos_corr, shift)
		pos = (pos == nil) and {0, 0} or pos
		pos_corr = (pos_corr == nil) and {0, 0} or pos_corr

		last_pos = quick_add(last_pos, {pos[1], pos[2]})
		last_pos[1] = last_pos[1] + (shift or last_size[1])

		if blank_space[1] ~= 0 or blank_space[2] ~= 0 then
			last_pos = quick_add(last_pos, blank_space)
			blank_space = {0, 0}
		end

		local new_pos = table.copy(last_pos)
		new_pos = quick_add(new_pos, {pos_corr[1], pos_corr[2]})

		if shift then
			new_pos[1] = new_pos[1] - shift
		end

		return new_pos
	end

	local function el_size(size)
		last_size = {size[1], size[2]}
		return last_size
	end

	local edata = editor_data[session_name]
	local project = projects[edata.pr_name]

	local mode_on_color = "bgcolor=#72cf00"
	local btn_color = "bgcolor=white"

	local panel_pos = {0, 0}
	local size_h = 0.65
	local panel_size = {11.25, size_h}
	local btn_size = {0.65, size_h}

	local fs = {
		{"container", edata.toolbar_pos},

		{"style_type", "box", "noclip=true"},
		{"style_type", "label", "noclip=true"},
		{"style_type", "button", "noclip=true"},
		{"style_type", "field", "noclip=true"},
		{"style_type", "textarea", "noclip=true"},
		{"style_type", "dropdown", "noclip=true"},
		{"style_type", "image_button", "noclip=true"},
		{"style_type", "checkbox", "noclip=true"},

		{"box", el_pos(panel_pos), panel_size, "black"},
	}

	local function add_elements(e)
		table.insert_all(fs, e)
	end

	add_elements({
		{"label",  quick_add({0, -0.15}, last_pos), session_name},
		{"image_button", el_pos(), el_size(btn_size), "sfse_export_btn.png", "export", ""},
		{"dropdown", el_pos(), el_size({2.5, size_h}), "element", edata.elms_list, edata.selected_el, true},
	})

	table.insert(fs, {"image_button", el_pos(), el_size(btn_size), "sfse_add_new_btn.png", "add_new", ""})
	table.insert(fs, {"image_button", el_pos(), el_size(btn_size), "sfse_add_new_btn.png^[colorize:blue:150", "add_copy", ""})

	table.insert(fs, {"image_button", el_pos(), el_size(btn_size), "sfse_remove_btn.png", "remove_element", ""})

	local el = project[edata.selected_el]
	edata.xy_index = find_coords(el, "xy")
	edata.wh_index = find_coords(el, "wh")

	if not edata.xy_index then
		edata.show_control_buttons = false
	else
		edata.show_control_buttons = true
	end
	if not edata.wh_index then
		edata.show_mv_res_button = false
		edata.modes.resize = false
	else
		edata.show_mv_res_button = true
	end

	add_elements({
		{"field", el_pos(), el_size({0.9, size_h}), "set_step", "", edata.step},
		{"image_button", el_pos(), el_size({0.5, size_h}), "sfse_check.png", "submit_step", ""},
	})

	if edata.show_control_buttons or edata.modes.move_toolbar then
		blank_space[1] = 0.1
		local img_rot = {90, 270, 0, 180}
		for i = 1, 4 do
			table.insert(fs, {"style", "button_" .. i, "bgimg=sfse_arrow.png^[transformR" .. img_rot[i], "noclip=true"})
			if edata.modes.move_toolbar then
				table.insert(fs, {"style", "button_" .. i, mode_on_color})
			end
			table.insert(fs, {"button", el_pos(), el_size(btn_size), "button_" .. i, ""})
		end
		blank_space[1] = 0.1
	end


	if edata.show_mv_res_button and not edata.modes.move_toolbar  then
		local btn_styl
		add_elements({
			{"style", "resize_btn", edata.modes.resize and "bgimg=sfse_resize_btn.png" or "bgimg=sfse_move_btn.png", btn_color},
			{"button", el_pos(), el_size(btn_size), "resize_btn", ""}
		})
	end

	add_elements({
		{"style", "show_text_editor", edata.show_text_editor and mode_on_color or btn_color, "bgimg=sfse_text_editor_btn.png"},
		{"button",  el_pos(), el_size(btn_size), "show_text_editor", ""},
		{"style", "show_quick_text_editor_btn", edata.show_quick_text_editor and mode_on_color or btn_color, "bgimg=sfse_single_line_editor_btn.png"},
		{"button",  el_pos(), el_size(btn_size), "show_quick_text_editor_btn", ""},

		{"style", "move_toolbar_btn", edata.modes.move_toolbar and mode_on_color or btn_color, "bgimg=sfse_move_toolbar_btn.png"},
		{"button", el_pos(), el_size(btn_size), "move_toolbar_btn", ""},
		{"image_button", el_pos(), el_size(btn_size), "sfse_reload_btn.png", "force_update", ""},
		{"image_button", el_pos(), el_size(btn_size), "sfse_exit_button.png", "exit", ""},
	})

	local window_pos = {0, 0}
	local window_size = {panel_size[1], 6}

	local function show_tb2()
		last_pos = {0, 0.15}
		last_size = {0, 0}

		window_pos = quick_add(last_pos, {0, 0.7})
		table.insert(fs, {"box", el_pos(), panel_size, "black"})
	end

	if edata.show_text_editor then
		show_tb2()
		local h = (#project > 15) and window_size[2] + 5 or window_size[2]
		if edata.text_editor_show_background then
			table.insert(fs, {"box", window_pos, {window_size[1], h}, "black"})
		end
		add_elements({
			{"textarea", window_pos, {window_size[1], h}, "text_editor", "", minetest.formspec_escape(formspec_data[session_name].project_formspec)},
			{"button", el_pos(), el_size({3.5, size_h}), "submit",  "Submit"},
			{"checkbox", el_pos(nil, {0, 0.25}), "text_editor_no_trans", "Disable transparency", edata.text_editor_show_background}
		})
	end

	if edata.show_quick_text_editor then
		show_tb2()
		add_elements({
			{"button", el_pos(), el_size({3.5, size_h}), "quick_editor_submit", "Submit"},
			{"field", window_pos, {window_size[1], size_h}, "quick_editor_field", "", minetest.formspec_escape(sfse.build_formspec({project[edata.selected_el]}))},
		})
	end

	table.insert(fs, {"container_end"})

	return fs
end

local function check_default_elements(project)
	project = project or {}
	for i, el_default in ipairs(default_elements) do
		local found = false

		for _, el_project in ipairs(project) do
			if el_default[1] == el_project[1] then
				found = true
			end
		end

		if not found then
			table.insert(project, i, el_default)
		end
	end
	return project
end

local function build_project(session_name)
	local fs = {}
	local edata = editor_data[session_name]
	local project = projects[edata.pr_name]
	project = check_default_elements(project)

	--adding elements from project
	local block_start = 1
	local block_end = #project + block_start - 1

	for k = #project, 1, -1 do
		table.insert(fs, block_start, project[k])
	end

	--forming a list of elements to the dropdown menu
	local el_count = 0
	local list = {}
	for k = block_start, block_end do
		if fs[k] then
			el_count = el_count + 1
			table.insert(list, minetest.formspec_escape(fs[k][1] .. " " .. el_count))
		end
	end
	edata.elms_list = list

	return fs
end

local function get_highlight(session_name)
	local fs = {}
	local edata = editor_data[session_name]
	local el = projects[edata.pr_name][edata.selected_el]
	if edata.highlight_selected then
		if edata.xy_index then
			fs = {
				{"container", {0, 0}},
				{"style_type", "box", "noclip=true"},
				{"box", el[edata.xy_index], (el[edata.wh_index] or {0.3, 0.3}), "#FF6EF28c"},
				{"container_end"}
			}
		end
	end
	return fs
end

local map = {
	a='\a', b='\b', f='\f', n='\n', r='\r', t='\t',
	v='\v', ['\\']='\\', ['\"']='\"', ['\'']='\''
}

local function unescape(str)
	return str:gsub("\\.", function(c1)
		if c1 then
			return map[c1:sub(2)]
		end
	end)
end

local function formatted_dump(t)
	local rope = {}
	for i = 1, #t do
		local ser = minetest.serialize(t[i])
		ser = ser:sub(8, #ser)
		table.insert(rope, ser)
	end
	return unescape(table.concat(rope, ",\n"))
end

local function save_to_file(filename, str)
	local file, err = io.open(sfse_path .. "/" .. filename, "w")
	if file then
		file:write(str)
		file:close()
	end
	return err == nil
end

local function show_export_window(player, session_name, pr_name)
	local export_data = {}

	local output_text = ""
	local function get_efs()
		if export_data.dump_table then
			output_text = formatted_dump(projects[pr_name])
		else
			output_text = formspec_data[session_name].project_formspec or ""
		end

		local export_fs = {
			{"formspec_version", 6},
			{"size", {14, 12}},
			{"no_prepend"},
			{"textarea", {0.5, 1.5}, {13, 10}, "export_text", "", minetest.formspec_escape(output_text)},
			{"button", {10.4, 0.1}, {3.5, 0.6}, "back", "Back"},
			{"button", {2.6, 0.1}, {2, 0.6}, "save_to_file", "Save to file"},
			{"button", {0.5, 0.1}, {2, 0.6}, "print", "Print to log"},
			{"tabheader", {0.5, 1.5}, {8, 0.5}, "export_type", {"Formspec String", "Dump Table (fslib)"}, export_data.dump_table and "2" or "1", "true", "true"},
		}

		return export_fs
	end

	sfse.show_formspec(player, get_efs(), function(fields)
		if fields.back or fields.quit then
			sfse.show_editor(player, pr_name)
		elseif fields.print then
			print(output_text)
		elseif fields.export_type then
			export_data.dump_table = fields.export_type == "2"
			return get_efs()
		elseif fields.save_to_file then
			local path = "/export/" .. session_name .. "_" .. os.date('%Y-%m-%d_%H:%M')
			if save_to_file(path , output_text) then
				minetest.chat_send_player(player:get_player_name(), "Saved to  (modpath)" .. path)
			else
				minetest.chat_send_player(player:get_player_name(), "Failed to save file")
			end
		end
	end)
end

function sfse.show_editor(player, pr_name)
	local name = player:get_player_name()
	local session_name = name .. "_" .. pr_name

	if not projects[pr_name] then
		projects[pr_name] = default_elements
	end

	if not editor_data[session_name] then
		editor_data[session_name] = {
			pr_name = pr_name,
			modes = {
				window_size = false,
				resize = false,
				move_toolbar = false,
			},
			selected_el = 1,
			step = 0.5,
			toolbar_pos = {0, -0.7},
			show_quick_text_editor = false,
			show_control_buttons = true,
			show_mv_res_button = true,
			show_text_editor = false,
			elms_list = {},
			text_editor_show_background = true,
			highlight_selected = true
		}

		formspec_data[session_name] = {}
	end

	local edata = editor_data[session_name]
	local fsd = formspec_data[session_name]

	local function generate_all()
		fsd.project_formspec = sfse.build_formspec(build_project(session_name))
		fsd.gui_formspec = sfse.build_formspec(main_gui(session_name))
		fsd.highlight = edata.highlight_selected and sfse.build_formspec(get_highlight(session_name)) or ""
	end

	local function get_formspec()
		local fsd = formspec_data[session_name]
		if not (fsd.project_formspec or fsd.gui_formspec) then
			generate_all()
		end
		return unescape(fsd.project_formspec) .. "\n\n" ..  fsd.highlight .. "\n\n" .. fsd.gui_formspec
	end

	local project = projects[pr_name]

	local function check_selected_index(sel_index, to_near_index)
		local pr_len = #projects[pr_name]
		if sel_index > pr_len or sel_index < 1 then
			return pr_len
		else
			return sel_index
		end
	end

	sfse.show_formspec(player, get_formspec(), function(fields)
		if not minetest.check_player_privs(player, privs_req) then
			minetest.chat_send_player(name, "sfse: Are you hacker?")
			return false
		end
		local update_gui_layer = false
		local update_project_layer = false


		local selected_el = check_selected_index(tonumber(fields.element) or 1)

		if not project[selected_el] then
			return false
		end

		local mode_name = "move"
		for fn, enabled in pairs(edata.modes) do
			if enabled then
				mode_name = fn
				break
			end
		end

		local cur_element = project[selected_el]
		local xy_index = edata.xy_index
		local wh_index = edata.wh_index

		local function x_or_y(xy)
			local n = 1
			if xy == "y" then
				n = 2
			end
			return n
		end

		local mode = {
			move = function(value, xy)
				if not xy_index then return end
				cur_element[xy_index][x_or_y(xy)] = cur_element[xy_index][x_or_y(xy)] + value
				update_project_layer = true
				if edata.show_text_editor or edata.show_quick_text_editor then
					update_gui_layer = true
				end
			end,
			resize = function(value, wh)
				if not wh_index then return end
				cur_element[wh_index][x_or_y(wh)] = cur_element[wh_index][x_or_y(wh)] + value
				update_project_layer = true
				if edata.show_text_editor or edata.show_quick_text_editor  then
					update_gui_layer = true
				end
			end,
			move_toolbar = function(value, xy)
				edata.toolbar_pos[x_or_y(xy)] = edata.toolbar_pos[x_or_y(xy)] + value
				update_gui_layer = true
			end
		}

		local step = edata.step

		if fields.quit then
			return false
		elseif fields.button_1 then
			mode[mode_name](-step, "x")
		elseif fields.button_2 then
			mode[mode_name](step, "x")
		elseif fields.button_3 then
			mode[mode_name](-step, "y")
		elseif fields.button_4 then
			mode[mode_name](step, "y")

		elseif fields.export then
			show_export_window(player, session_name, pr_name)
			return
		elseif fields.resize_btn then
			edata.modes.resize = not edata.modes.resize
			update_gui_layer = true

		elseif fields.show_quick_text_editor_btn then
			edata.show_quick_text_editor = not edata.show_quick_text_editor
			edata.show_text_editor = false
			update_gui_layer = true
		elseif fields.quick_editor_submit then
			if fields.quick_editor_field:match("%S") then
				local fstable, err = sfse.formspec_to_table(fields.quick_editor_field)
				if err then
					minetest.chat_send_player(name, "Syntax error! You may have missed a square bracket")
				elseif fstable[1] then
					project[selected_el] = fstable[1]
					update_gui_layer = true
				end
			else
				table.remove(project, selected_el)
				selected_el = check_selected_index(selected_el)
				update_gui_layer = true
			end
			update_project_layer = true

		elseif fields.move_toolbar_btn then
			edata.modes.resize = false
			edata.modes.move_toolbar = not edata.modes.move_toolbar
			update_gui_layer = true

		elseif fields.show_text_editor then
			edata.show_text_editor = not edata.show_text_editor
			edata.show_quick_text_editor = false
			update_gui_layer = true
		elseif fields.submit then
			if fields.text_editor then
				local fstable, err = sfse.formspec_to_table(fields.text_editor)
				if err then
					minetest.chat_send_player(name, "Syntax error! You may have missed a square bracket")
				else
					projects[pr_name] = check_default_elements(fstable)
					generate_all()
					sfse.show_editor(player, pr_name)
					return false
				end
				selected_el = check_selected_index(selected_el)
				update_gui_layer = true
			end

		elseif fields.force_update then
			generate_all()
			sfse.close_formspec(player)
			minetest.after(0.1, sfse.show_editor, player, pr_name)
			return false

		elseif fields.submit_step then
			edata.step = tonumber(fields.set_step)
			if not edata.step then edata.step = 0.5 end

		elseif fields.text_editor_no_trans then
			edata.text_editor_show_background = not edata.text_editor_show_background
			update_gui_layer = true

		elseif fields.add_new then
			table.insert(project, {"name"})
			selected_el = #project
			if not edata.show_text_editor then
				edata.show_quick_text_editor = true
			end
			update_project_layer = true
		elseif fields.add_copy then
			if selected_el > 2 then
				table.insert(project, selected_el, table.copy(cur_element))
				if not edata.show_text_editor then
					edata.show_quick_text_editor = true
				end
				update_project_layer = true
				update_gui_layer = true
			else
				minetest.chat_send_player(name, "New elements can be added after size[] only")
			end

		elseif fields.remove_element then
			if selected_el > 2 then
				table.remove(project, selected_el)
				selected_el = selected_el - 1
				update_project_layer = true
			else
				minetest.chat_send_player(name, (cur_element[1] or "[unknown_element]") .. " cannot be removed.")
			end

		elseif fields.exit then
			local exit_fs = {
				{"formspec_version", 6},
				{"size", {9.2, 2}},
				{"no_prepend"},
				{"label",  {1, 0.5}, "Exit the current session: " .. session_name .. "?"},
				{"button", {5, 1}, {1.5, 0.8}, "back","Back"},
				{"button", {3, 1}, {1.5, 0.8}, "exit_confirm", "Confirm"}
			}
			sfse.show_formspec(player, exit_fs, function(fields)
				if fields.exit_confirm then
					editor_data[session_name] = nil
					formspec_data[session_name] = nil
					sfse.close_formspec(player)
					return false
				elseif fields.back or fields.quit then
					sfse.show_editor(player, edata.pr_name)
				end
			end)
		end


		if selected_el ~= edata.selected_el then
			edata.selected_el = selected_el
			update_gui_layer = true
		end

		if not update_gui_layer and not update_project_layer then
			return false
		end

		if update_project_layer then
			fsd.project_formspec = sfse.build_formspec(build_project(session_name))
		end
		if update_gui_layer then
			fsd.gui_formspec = sfse.build_formspec(main_gui(session_name))
		end
		if edata.highlight_selected then
			fsd.highlight = sfse.build_formspec(get_highlight(session_name))
		end

		return get_formspec()
	end)
end

minetest.register_chatcommand("fse_open", {
	privs = privs_req,
	func = function(name, param)
		if param == "" then
			return false, "Project name is missing"
		end
		if projects[param] then
			sfse.show_editor(minetest.get_player_by_name(name), param)
		else
			return false, "This project does not exist"
		end
	end,
})

minetest.register_chatcommand("fse", {
	privs = privs_req,
	func = function(name, param)
		if param == "" then
			return false, "Project name is missing"
		end

		if not projects[param] then
			sfse.open_formspec(name, param)
		else
			sfse.show_editor(minetest.get_player_by_name(name), param)
		end
	end,
})

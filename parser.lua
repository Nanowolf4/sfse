local eschars = {"\\", "^"}

local function match_unescaped(str, i, pattern)
	local escaped = false
	for _, escc in ipairs(eschars) do
		if str:sub(i - #escc, i) == escc .. pattern then
			return false
		end
	end
	return str:sub(i, i) == pattern
end

function sfse.split_formspec(str)
	local d1, d2 = "[", "]"
	local name = {}
	local data = {}
	local name_pos = {}
	local data_pos = {}
	local i = 1
	local data_found = false
	local err = false

	for i = 1, #str do

		if match_unescaped(str, i, d1) then
			if data_pos[1] then
				err = true
				break
			end
			data_pos[1] = i
			data_found = true
		elseif match_unescaped(str, i, d2) then
			if data_pos[2] or not data_pos[1] then
				err = true
				break
			end
			data_pos[2] = i
		end

		if not data_found then
			if not name_pos[1] then
				name_pos[1] = i
			else
				name_pos[2] = i
			end
		end

		if #name_pos == 2 and #data_pos == 2 then
			table.insert(name, str:sub(name_pos[1], name_pos[2]))
			table.insert(data, str:sub(data_pos[1] + 1, data_pos[2] - 1))
			data_found = false
			if d1 ~= d2 then
				data_pos = {}
			end
			name_pos = {}
        end
	end

	return name, data, err
end

function sfse.unEsc_split(str, delim)
	local items = {}
	local prev_pos = 1
	local str_len = #str
	for i = 1, str_len do
		if match_unescaped(str, i, delim) then
			table.insert(items, str:sub(prev_pos, i - 1))
			prev_pos = i + 1
		end
	end
	table.insert(items, str:sub(prev_pos))
	return items
end

function sfse.formspec_to_table(formspec)
	assert(type(formspec) == "string")

	local fs_type, data, missing_bracket = sfse.split_formspec(formspec)
	if missing_bracket then
		return nil, true
	end
	local num_match_pattern = "%-?%d*%.?%d*"
	local elements = {}
	for i = 1, #fs_type do
		local tmp = {}
		table.insert(tmp, fs_type[i]:match("%S*$") or "unknown_element")

		local params_rope = sfse.unEsc_split(data[i], ";")

		for _, v in ipairs(params_rope) do

			local param = sfse.unEsc_split(v, ",")

			if #param >= 2 then

				local pnum1 = tonumber(param[1]:match(num_match_pattern))
				local pnum2 = tonumber(param[2]:match(num_match_pattern))

				if type(pnum1) == "number" or type(pnum2) == "number" then
					if pnum1 and pnum2 then
						table.insert(tmp, {pnum1, pnum2})
					else
						table.insert(tmp, pnum1)
					end
					goto continue
				end

				local key, value = param[1]:match("(%S+)%s*=%s*(%S+)")
				if key and (value == "true" or value == "false") then
					table.insert(tmp, key .. "=" .. value)
					goto continue
				end

				table.insert(tmp, param)

			elseif param[1] then
				table.insert(tmp, param[1])
			elseif #param == 0 then
				table.insert(tmp, "")
			end
			:: continue ::
		end

		table.insert(elements, tmp)
	end

	return elements, false
end
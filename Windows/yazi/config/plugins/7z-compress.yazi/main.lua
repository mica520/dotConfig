local M = {}

-- Extract the tree prefix (if any) from a line
local function get_tree_prefix(line)
	local _, prefix_len = line:find("─ ", 1, true)
	if prefix_len then
		return line:sub(1, prefix_len)
	else
		return ""
	end
end

-- Add a filetype icon to a line
local function line_with_icon(line)
	line = line:gsub("[\r\n]+$", "") -- Trailing newlines mess with filetype detection

	local tree_prefix = get_tree_prefix(line)
	local url = line:sub(#tree_prefix + 1)
	local icon = File({
		url = Url(url),
		cha = Cha({
			mode = tonumber(url:sub(-1) == "/" and "40700" or "100644", 8),
			kind = url:sub(-1) == "/" and 1 or 0,
		}),
	}):icon()

	if icon then
		line = ui.Line({ tree_prefix, ui.Span(icon.text .. " "):style(icon.style), url })
	end

	return line
end

function M:peek(job)
	local cmd = Command("7z"):arg("l")
	if not job.args.list_view then
		cmd:arg("-slt")
	end
	cmd:arg({ tostring(job.file.url) }):stdout(Command.PIPED):stderr(Command.PIPED)

	local child = cmd:spawn()
	local limit = job.area.h
	local archive_icon = job.args.archive_icon or "\u{1f4c1} "
	local file_name = string.match(tostring(job.file.url), ".*[/\\](.*)")
	local lines = { string.format(" %s%s", archive_icon, file_name) }
	local num_skip = 0
	local in_file_list = false

	repeat
		local line, event = child:read_line()
		if event == 1 then
			ya.err(tostring(event))
		elseif event ~= 0 then
			break
		end

		if line and line:find("----------", 1, true) then
			in_file_list = true
			goto continue
		end

		if in_file_list and line and line ~= "" then
			local name_start = 53
			if #line > name_start then
				local filename = line:sub(name_start + 1)
				if filename ~= "" and filename ~= "Name" then
					if num_skip >= job.skip then
						local display_line = filename
						if job.args.show_file_icons then
							display_line = line_with_icon(filename)
						end
						table.insert(lines, ui.Line({ " ", display_line }))
					else
						num_skip = num_skip + 1
					end
				end
			end
		end

		::continue::
	until #lines >= limit

	child:start_kill()
	if job.skip > 0 and #lines < limit then
		ya.emit(
			"peek",
			{ tostring(math.max(0, job.skip - (limit - #lines))), only_if = tostring(job.file.url), upper_bound = "" }
		)
	else
		ya.preview_widget(job, { ui.Text(lines):area(job.area) })
	end
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		local step = math.floor(job.units * job.area.h / 10)
		ya.emit("peek", {
			math.max(0, cx.active.preview.skip + step),
			only_if = tostring(job.file.url),
		})
	end
end

local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

local get_compression_target = ya.sync(function()
	local tab = cx.active
	local default_name
	local paths = {}

	if #tab.selected == 0 then
		if tab.current.hovered then
			local hovered = tab.current.hovered
			default_name = hovered.name
			local path = tostring(hovered.url):gsub("^file://", "")
			table.insert(paths, path)
		else
			return
		end
	else
		default_name = tab.current.cwd.name
		for _, url in pairs(tab.selected) do
			local path = tostring(url):gsub("^file://", "")
			table.insert(paths, path)
		end
		ya.emit("escape", {})
	end
	return paths, default_name
end)

local function invoke_7z_compress_command(paths, archive_name, password, archive_format, compression_level)
	local cmd = Command("7z"):arg("a")
	cmd:arg(archive_name)

	if compression_level and compression_level >= 0 and compression_level <= 9 then
		cmd:arg("-mx=" .. compression_level)
	end

	if archive_format == "zip" then
		cmd:arg("-tzip")
		if password and password ~= "" then
			cmd:arg("-p" .. password)
			cmd:arg("-mem=AES256")
		end
	elseif archive_format == "7z" then
		cmd:arg("-t7z")
		if password and password ~= "" then
			cmd:arg("-p" .. password)
			cmd:arg("-mhe=on")
		end
	elseif archive_format == "tar" then
		cmd:arg("-ttar")
	else
		cmd:arg("-t7z")
		if password and password ~= "" then
			cmd:arg("-p" .. password)
			cmd:arg("-mhe=on")
		end
	end

	for _, path in ipairs(paths) do
		cmd:arg(path)
	end

	cmd:stderr(Command.PIPED)

	local cmd_output, err_code = cmd:output()
	if err_code ~= nil then
		ya.notify({
			title = "Failed to run 7z command",
			content = "Error: " .. tostring(err_code),
			timeout = 5.0,
			level = "error",
		})
		return false
	elseif not cmd_output.status.success then
		ya.notify({
			title = "Compression failed",
			content = cmd_output.stderr or "Unknown error",
			timeout = 5.0,
			level = "error",
		})
		return false
	end

	ya.notify({
		title = "Compression complete",
		content = archive_name,
		timeout = 3.0,
		level = "info",
	})
	return true
end

local function select_format()
	-- Use ya.input for format selection instead of ya.which
	local format_input, event = ya.input({
		title = "Archive format (7z/zip/tar):",
		value = "7z",
		pos = { "top-center", y = 3, w = 40 },
	})

	if event ~= 1 then
		return nil
	end

	local format = format_input:lower()
	if format == "7z" or format == "zip" or format == "tar" then
		return format
	end

	ya.notify({
		title = "Invalid format",
		content = "Using default: 7z",
		timeout = 2.0,
		level = "warning",
	})
	return "7z"
end

local function select_compression_level()
	local level_input, event = ya.input({
		title = "Compression level (0-9, 0=store, 5=normal, 9=ultra):",
		value = "5",
		pos = { "top-center", y = 3, w = 50 },
	})

	if event ~= 1 then
		return 5
	end

	local level = tonumber(level_input)
	if level and level >= 0 and level <= 9 then
		return level
	end

	ya.notify({
		title = "Invalid level",
		content = "Using default: 5",
		timeout = 2.0,
		level = "warning",
	})
	return 5
end

function M:entry(job)
	ya.emit("escape", { visual = true })

	local paths, default_name = get_compression_target()

	if not paths or #paths == 0 then
		ya.notify({
			title = "No files selected",
			content = "Please select files or hover over a file to compress",
			timeout = 3.0,
			level = "error",
		})
		return
	end

	local archive_format = select_format()
	if not archive_format then
		return
	end

	local compression_level = nil
	if archive_format == "7z" or archive_format == "zip" then
		compression_level = select_compression_level()
	end

	local default_archive_name = default_name .. "." .. archive_format
	local output_name, name_event = ya.input({
		title = string.format("Create %s archive:", archive_format:upper()),
		value = default_archive_name,
		pos = { "top-center", y = 3, w = 50 },
	})
	if name_event ~= 1 or not output_name or output_name == "" then
		return
	end

	local password = nil
	if archive_format == "7z" or archive_format == "zip" then
		local use_password, password_event = ya.input({
			title = "Add password protection? (y/N)",
			value = "n",
			pos = { "top-center", y = 5, w = 40 },
		})

		if password_event == 1 and use_password:lower() == "y" then
			local pwd, pwd_event = ya.input({
				title = "Enter password:",
				value = "",
				pos = { "top-center", y = 5, w = 40 },
				password = true,
			})
			if pwd_event ~= 1 then
				return
			end

			local pwd_confirm, confirm_event = ya.input({
				title = "Confirm password:",
				value = "",
				pos = { "top-center", y = 7, w = 40 },
				password = true,
			})
			if confirm_event ~= 1 then
				return
			end

			if pwd ~= pwd_confirm then
				ya.notify({
					title = "Password mismatch",
					content = "Passwords do not match",
					timeout = 3.0,
					level = "error",
				})
				return
			end

			password = pwd
		end
	end

	if file_exists(output_name) then
		local confirm, confirm_event = ya.input({
			title = "Overwrite " .. output_name .. "? (y/N)",
			pos = { "top-center", y = 9, w = 50 },
		})
		if not (confirm_event == 1 and confirm:lower() == "y") then
			return
		end
	end

	invoke_7z_compress_command(paths, output_name, password, archive_format, compression_level)
end

return M

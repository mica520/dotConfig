local M = {}

-- Get the selected files that need to be extracted
local get_selected_archives = ya.sync(function()
	local tab = cx.active
	local paths = {}

	if #tab.selected == 0 then
		if tab.current.hovered then
			local url = tostring(tab.current.hovered.url)
			table.insert(paths, url)
		end
	else
		for _, url in pairs(tab.selected) do
			table.insert(paths, tostring(url))
		end
		ya.emit("escape", {})
	end

	return paths
end)

-- 支持的压缩文件扩展名
local archive_extensions = {
	"%.7z$",
	"%.zip$",
	"%.rar$",
	"%.tar$",
	"%.gz$",
	"%.bz2$",
	"%.xz$",
	"%.tgz$",
	"%.tbz2$",
	"%.txz$",
	"%.zst$",
	"%.lz4$",
	"%.jar$",
	"%.war$",
}

local function is_archive(file_path)
	for _, ext in ipairs(archive_extensions) do
		if file_path:match(ext) then
			return true
		end
	end
	return false
end

-- 检查是否需要密码（使用 timeout 避免卡死）
local function check_needs_password(file_path)
	-- 使用 -- 作为参数分隔符，并使用 echo 提供空输入
	local cmd = string.format('echo "" | 7z l "%s" 2>&1', file_path)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()

	-- 检查是否需要密码
	if result:find("Can't open encrypted") or result:find("Password required") or result:find("Enter password") then
		return true
	end
	return false
end

-- 解压单个文件
local function extract_archive(file, dest, password)
	local cmd
	if password and password ~= "" then
		-- 使用 echo 传递密码，避免 7z 等待输入
		cmd = string.format('echo "%s" | 7z x -y -p"%s" -o"%s" "%s" 2>&1', password, password, dest, file)
	else
		-- 没有密码时也使用 echo 提供空输入，避免卡死
		cmd = string.format('echo "" | 7z x -y -o"%s" "%s" 2>&1', dest, file)
	end

	local handle = io.popen(cmd)
	local result = handle:read("*a")
	local success = handle:close()

	-- 检查密码错误
	if result:find("Wrong password") then
		return false, "wrong_password"
	end

	-- 检查是否成功
	if success == true or result:find("Everything is Ok") or result:find("0 errors") or result:find("100%%") then
		return true, nil
	end

	-- 其他错误
	return false, result
end

-- 获取解压后应该跳转到的目录/文件
local function get_extract_destination(archives, dest)
	-- 如果只有一个压缩文件，尝试找到解压后的文件夹
	if #archives == 1 then
		local archive_name = archives[1]:match("[/\\]([^/\\]+)$") or archives[1]
		-- 去掉扩展名作为可能的文件夹名
		local base_name = archive_name:gsub("%.[^%.]+$", "")

		-- 检查是否解压到指定目录下的同名文件夹
		local potential_dir = dest .. base_name
		local check_cmd
		if package.config:sub(1, 1) == "\\" then
			check_cmd = string.format('if exist "%s" echo EXISTS', potential_dir)
		else
			check_cmd = string.format('test -d "%s" && echo EXISTS', potential_dir)
		end

		local handle = io.popen(check_cmd)
		local result = handle:read("*a")
		handle:close()

		if result and result:find("EXISTS") then
			return potential_dir
		end

		-- 如果同名文件夹不存在，检查压缩包内是否包含单个顶层文件夹
		local list_cmd = string.format('7z l "%s" 2>&1', archives[1])
		handle = io.popen(list_cmd)
		local list_result = handle:read("*a")
		handle:close()

		-- 解析文件列表，检查是否所有文件都在同一个文件夹下
		local top_dirs = {}
		for line in list_result:gmatch("[^\r\n]+") do
			-- 匹配 7z 输出中的文件/文件夹路径
			local path =
				line:match("%d%d%d%d%-%d%d%-%d%d%s%d%d:%d%d:%d%d%s[D.][R.][H.][S.][A.][.R.]%s+%d+%s+%d+%s+(.+)")
			if path then
				local top_dir = path:match("^([^/\\]+)[/\\]")
				if top_dir and top_dir ~= "." and top_dir ~= ".." then
					top_dirs[top_dir] = true
				end
			end
		end

		-- 如果所有文件都在同一个顶层文件夹下
		local unique_dirs = {}
		for dir, _ in pairs(top_dirs) do
			table.insert(unique_dirs, dir)
		end

		if #unique_dirs == 1 then
			return dest .. unique_dirs[1]
		end
	end

	-- 默认返回目标目录
	return dest
end

function M:entry(job)
	local all_files = get_selected_archives()

	if #all_files == 0 then
		ya.notify({
			title = "Error",
			content = "No file selected.",
			timeout = 3,
			level = "error",
		})
		return
	end

	local archives = {}
	for _, file in ipairs(all_files) do
		if is_archive(file) then
			table.insert(archives, file)
		end
	end

	if #archives == 0 then
		ya.notify({
			title = "Error",
			content = "No archive files selected",
			timeout = 3,
			level = "error",
		})
		return
	end

	-- 显示找到的文件
	local file_list = ""
	for i, file in ipairs(archives) do
		local name = file:match("[/\\]([^/\\]+)$") or file
		file_list = file_list .. name
		if i < #archives and i < 3 then
			file_list = file_list .. ", "
		end
	end
	if #archives > 3 then
		file_list = file_list .. " and " .. (#archives - 3) .. " more"
	end

	ya.notify({
		title = "7z Extract",
		content = string.format("Processing %d file(s): %s", #archives, file_list),
		timeout = 2,
		level = "info",
	})

	-- 获取目标目录
	local current_dir = "."
	if archives[1] then
		local dir = archives[1]:match("^(.+)[/\\][^/\\]+$")
		if dir then
			current_dir = dir
		end
	end

	local dest, event = ya.input({
		title = "Extract to:",
		value = current_dir,
		placeholder = "Target directory",
		pos = { "top-center", y = 3, w = 60 },
	})

	if event ~= 1 then
		return
	end

	if not dest or dest == "" then
		dest = current_dir
	end

	dest = dest:gsub("\\", "/")
	if not dest:match("/$") then
		dest = dest .. "/"
	end

	-- 创建目标目录
	local mkdir_cmd
	if package.config:sub(1, 1) == "\\" then
		mkdir_cmd = string.format('if not exist "%s" mkdir "%s"', dest, dest)
	else
		mkdir_cmd = string.format('mkdir -p "%s"', dest)
	end
	os.execute(mkdir_cmd)

	-- 预先检查哪些文件需要密码
	local need_pass_files = {}
	local no_pass_files = {}

	for _, file in ipairs(archives) do
		if check_needs_password(file) then
			table.insert(need_pass_files, file)
		else
			table.insert(no_pass_files, file)
		end
	end

	-- 如果需要密码的文件存在，询问密码
	local global_password = nil
	if #need_pass_files > 0 then
		local pass_list = ""
		for i, file in ipairs(need_pass_files) do
			local name = file:match("[/\\]([^/\\]+)$") or file
			pass_list = pass_list .. name
			if i < #need_pass_files and i < 3 then
				pass_list = pass_list .. ", "
			end
		end
		if #need_pass_files > 3 then
			pass_list = pass_list .. " and " .. (#need_pass_files - 3) .. " more"
		end

		local input_pass, pass_event = ya.input({
			title = string.format("Password Required (%d file(s))", #need_pass_files),
			value = "",
			placeholder = string.format("Enter password for: %s", pass_list),
			pos = { "top-center", y = 3, w = 60 },
		})

		if pass_event ~= 1 then
			ya.notify({
				title = "Cancelled",
				content = "Extraction cancelled",
				timeout = 1,
				level = "info",
			})
			return
		end

		global_password = input_pass or ""
	end

	-- 解压所有文件
	local success_count = 0
	local fail_count = 0
	local failed_files = {}
	local password_wrong_files = {}

	-- 先解压不需要密码的文件
	local all_to_extract = {}
	for _, file in ipairs(no_pass_files) do
		table.insert(all_to_extract, { file = file, need_pass = false })
	end
	for _, file in ipairs(need_pass_files) do
		table.insert(all_to_extract, { file = file, need_pass = true })
	end

	for i, item in ipairs(all_to_extract) do
		local file = item.file
		local filename = file:match("[/\\]([^/\\]+)$") or file

		-- 显示进度
		if #all_to_extract > 1 then
			ya.notify({
				title = "Extracting",
				content = string.format("Progress: %d/%d - %s", i, #all_to_extract, filename),
				timeout = 1,
				level = "info",
			})
		end

		local success, err
		if item.need_pass then
			success, err = extract_archive(file, dest, global_password)
		else
			success, err = extract_archive(file, dest, nil)
		end

		if success then
			success_count = success_count + 1
		else
			fail_count = fail_count + 1
			if err == "wrong_password" then
				table.insert(password_wrong_files, filename)
			else
				table.insert(failed_files, filename)
			end
		end
	end

	-- 显示结果
	if success_count > 0 or fail_count > 0 then
		local message_lines = {}
		if success_count > 0 then
			table.insert(message_lines, string.format("✓ Extracted: %d/%d files", success_count, #archives))
		end
		if #failed_files > 0 then
			table.insert(message_lines, string.format("✗ Failed: %s", table.concat(failed_files, ", ")))
		end
		if #password_wrong_files > 0 then
			table.insert(
				message_lines,
				string.format("🔒 Wrong password: %s", table.concat(password_wrong_files, ", "))
			)
		end

		local title = "Complete"
		local level = "info"
		if fail_count == #archives then
			title = "Extraction Failed"
			level = "error"
		elseif fail_count > 0 then
			title = "Partial Success"
			level = "warning"
		end

		ya.notify({
			title = title,
			content = table.concat(message_lines, "\n"),
			timeout = 5,
			level = level,
		})
	end

	-- 刷新文件列表
	ya.emit("refresh", {})

	-- 跳转到解压后的目录/文件
	if success_count > 0 then
		local target_path = get_extract_destination(archives, dest)
		if target_path then
			-- 转换为 URL 格式
			local target_url = target_path
			-- 确保路径是绝对路径或正确的相对路径
			if not target_url:match("^[A-Za-z]:") and not target_url:match("^/") then
				-- 如果是相对路径，需要获取当前工作目录
				local cwd = io.popen("pwd"):read("*a"):gsub("\n", "")
				if cwd and #cwd > 0 then
					target_url = cwd .. "/" .. target_url
				end
			end

			-- 标准化路径（移除多余的 /./ 和 ..）
			target_url = target_url:gsub("/%.%/", "/")

			-- 使用 ya.emit 跳转到目标目录
			ya.emit("cd", { target_url })
		end
	end
end

return M

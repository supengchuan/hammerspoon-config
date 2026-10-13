local function readFile(path)
	local file = assert(io.open(path, "r"))
	local content = file:read("*a")
	file:close()
	return content
end

local function findLuaFiles(directory)
	local command = string.format("/usr/bin/find %q -type f -name '*.lua' -print", directory)
	local process = assert(io.popen(command))
	local files = {}
	for path in process:lines() do
		table.insert(files, path)
	end
	assert(process:close(), "failed to list Lua files beneath " .. directory)
	return files
end

local function appendAll(target, values)
	for _, value in ipairs(values) do
		table.insert(target, value)
	end
end

local function assertNoImport(path, content, layer)
	local callPrefixes = {
		"require%s*%(%s*",
		"require%s+",
	}
	local moduleLiterals = {
		"[\"']" .. layer .. "%.",
		"%[=*%[" .. layer .. "%.",
	}

	for _, prefix in ipairs(callPrefixes) do
		for _, literal in ipairs(moduleLiterals) do
			assert(not content:match(prefix .. literal), path .. " must not import " .. layer)
		end
	end
end

local function assertRejectsImport(content, layer)
	local ok = pcall(assertNoImport, "fixture.lua", content, layer)
	assert(not ok, "expected forbidden " .. layer .. " import to be rejected: " .. content)
end

assertRejectsImport('local dependency = require("core.feature_manager")', "core")
assertRejectsImport('local dependency = require "core.feature_manager"', "core")
assertRejectsImport("local dependency = require [[features.hotkeys]]", "features")
assertRejectsImport("local dependency = require([=[core.feature_manager]=])", "core")
assertNoImport("fixture.lua", 'local dependency = require("actions.bluetooth")', "core")

local activeFiles = { "README.md", "init.lua" }
for _, directory in ipairs({ "actions", "core", "features", "tests" }) do
	appendAll(activeFiles, findLuaFiles(directory))
end

local legacyModulePrefix = table.concat({ "mod", "ules." })
local legacyDirectory = table.concat({ "mod", "ules/" })

for _, path in ipairs(activeFiles) do
	local content = readFile(path)
	assert(not content:find(legacyModulePrefix, 1, true), path .. " contains a legacy module import")
	assert(not content:find(legacyDirectory, 1, true), path .. " contains a legacy source path")
end

for _, path in ipairs(findLuaFiles("actions")) do
	local content = readFile(path)
	assertNoImport(path, content, "core")
	assertNoImport(path, content, "features")
end

for _, path in ipairs(findLuaFiles("features")) do
	assertNoImport(path, readFile(path), "core")
end

assert(os.execute("/bin/test ! -d modules") == true, "legacy source directory still exists")

print("architecture tests passed")

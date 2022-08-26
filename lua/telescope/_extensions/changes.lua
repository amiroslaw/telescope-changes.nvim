local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local actions_state = require 'telescope.actions.state'
local actions_set = require 'telescope.actions.set'

local function prepare_output_table(last_changes)
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)

	local output_table = {}
	for _, val in pairs(last_changes) do
		table.insert(output_table, {
			value = val.nr,
			display = val.display,
			ordinal = val.display,
			lnum = val.row,
			col = val.col,
			filename = filepath,
			bufnr = bufnr,
		})
	end
	return output_table
end

function get_changes()
	local last_changes = {}
	local changes = vim.api.nvim_command_output 'changes'

	for change in changes:gmatch '[^\r\n]+' do
		local i = 1
		local nr, row, col
		for match in string.gmatch(change, '([^%s]+)') do
			if i == 1 then
				nr = match
			elseif i == 2 and tonumber(match) then
				row = match
			elseif i == 3 then
				col = match
			end
			i = i + 1
		end
		if row then
			last_changes[row] = { row = row, nr = nr, col = col, display = vim.trim(change) }
		end
	end
	return prepare_output_table(last_changes)
end

local function show_changes(opts)
	opts = opts or {}
	pickers.new(opts, {
			prompt_title = 'Changes',
			finder = finders.new_table {
				results = get_changes(),
				entry_maker = function(entry)
					return {
						value = entry.value,
						display = entry.display,
						ordinal = entry.display,
						lnum = tonumber(entry.lnum),
						col = tonumber(entry.col),
						filename = entry.filename,
						bufnr = entry.bufnr,
					}
				end,
			},
			previewer = conf.grep_previewer(opts),
			-- previewer = conf.qflist_previewer(opts),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr)
				actions_set.select:replace(function()
					local entry = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd(string.format('call cursor(%d,%d)', entry.lnum, entry.col + 1))
				end)
				return true
			end,
		}):find()
end

return require('telescope').register_extension {
	-- Default when to argument is given, i.e. :Telescope changes
	exports = {
		changes = show_changes,
	},
}

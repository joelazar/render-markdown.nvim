---@module 'luassert'

local util = require('tests.util')

describe('inlay hint', function()
    local get = vim.lsp.inlay_hint.get
    local ns = vim.api.nvim_create_namespace('render-markdown-test-hints')

    after_each(function()
        vim.lsp.inlay_hint.get = get
    end)

    ---@param lines string[]
    ---@param hints [integer, integer, string][]
    local function setup(lines, hints)
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.lsp.inlay_hint.get = function()
            return vim.tbl_map(function(hint)
                return {
                    inlay_hint = {
                        position = { line = hint[1], character = hint[2] },
                        label = { { value = hint[3] } },
                    },
                }
            end, hints)
        end
        util.setup.text(lines)
        for _, hint in ipairs(hints) do
            vim.api.nvim_buf_set_extmark(0, ns, hint[1], hint[2], {
                virt_text = { { hint[3], 'LspInlayHint' } },
                virt_text_pos = 'inline',
            })
        end
    end

    it('table', function()
        setup({
            '',
            '| Heading | Value |',
            '| ------- | ----- |',
            '| Word    | 1     |',
            '| Other   | 2     |',
        }, { { 3, 2, '[[' }, { 3, 6, ']]' } })
        util.assert_screen({
            '┌─────────────┬───────┐',
            '│ Heading     │ Value │',
            '├─────────────┼───────┤',
            '│ [[Word]]    │ 1     │',
            '│ Other       │ 2     │',
            '└─────────────┴───────┘',
        })
    end)

    it('table wrapped', function()
        local long = ('x'):rep(50)
        setup({
            '',
            '| Heading | Value |',
            '| ------- | ----- |',
            ('| Word %s %s | 1 |'):format(long, long),
        }, { { 3, 2, '[[' }, { 3, 6, ']]' } })
        util.assert_screen({
            '┌──────────────────────────────────────────────────────────────────────┬───────┐',
            '│ Heading                                                              │ Value │',
            '├──────────────────────────────────────────────────────────────────────┼───────┤',
            '│ [[Word]] xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx          │ 1     │',
            '│ xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                   │       │',
            '└──────────────────────────────────────────────────────────────────────┴───────┘',
        })
    end)
end)

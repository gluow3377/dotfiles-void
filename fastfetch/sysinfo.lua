local M = {}

local LEFT = 48
local PICTURE = 28
local WIN = 90
local COLORCOLUMN = 80
local COMMENT_COLUMN = 41

local FILE = 'sysinfo.c'

local P = {
    bg0 = 0x282828, bg1 = 0x3c3836, bg2 = 0x504945, bg3 = 0x665c54, bg4 = 0x7c6f64,
    fg1 = 0xebdbb2, fg4 = 0xa89984, gray = 0x928374,
    red = 0xfb4934, green = 0xb8bb26, yellow = 0xfabd2f, blue = 0x83a598,
    purple = 0xd3869b, aqua = 0x8ec07c, orange = 0xfe8019,
}

local HL = {
    Normal = { fg = P.fg1 },
    Comment = { fg = P.gray, italic = true },
    String = { fg = P.green },
    Number = { fg = P.purple },
    Keyword = { fg = P.red },
    Type = { fg = P.yellow },
    Include = { fg = P.aqua },
    Function = { fg = P.green, bold = true },
    Property = { fg = P.blue },
    Delimiter = { fg = P.orange },
    Operator = { fg = P.orange },
    Constant = { fg = P.purple },
    Special = { fg = P.orange },
    LineNr = { fg = P.bg4 },
    CursorLineNr = { fg = P.yellow, bg = P.bg1 },
    CursorLine = { bg = P.bg1 },
    ColorColumn = { bg = P.bg1 },
    WinSeparator = { fg = P.bg3 },
    EndOfBuffer = { fg = P.bg2 },
    StatusLine = { fg = P.fg1, bg = P.bg2 },
    StatusLineNC = { fg = P.fg4, bg = P.bg1 },
    ModeNormal = { fg = P.bg0, bg = P.fg1, bold = true },
    DiagnosticError = { fg = P.red },
    DiagnosticWarn = { fg = P.yellow },
    DiagnosticInfo = { fg = P.blue },
    DiagnosticHint = { fg = P.aqua },
    Cursor = { fg = 0x665c54, bg = 0xbdae93 },
}

local SIGNS = {
    { name = 'Error', sign = '✘', short = 'E' },
    { name = 'Warn', sign = '▲', short = 'W' },
    { name = 'Info', sign = '»', short = 'I' },
    { name = 'Hint', sign = '⚑', short = 'H' },
}

local ICONS = {
    diagnostics = '\u{f0c3}',
    lsp = '\u{f0c0e}',
    c = '\u{f0671}',
}

local KEYWORDS = {}
for w in ([[auto break case const continue default do else enum extern for goto if
    inline register restrict return sizeof static struct switch typedef union
    volatile while]]):gmatch('%S+') do
    KEYWORDS[w] = true
end

local TYPES = {}
for w in ([[bool char double float int long short signed unsigned void size_t
    int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t]]):gmatch('%S+') do
    TYPES[w] = true
end

local state = {
    lines = 0,
    bytes = 0,
    first = '',
    name = 'machine',
    user = '',
    fields = {},
    diagnostics = { Error = 0, Warn = 0, Info = 0, Hint = 0 },
}

local function rgb(c)
    return (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
end

local function chars(s)
    local t = {}
    for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
        t[#t + 1] = ch
    end
    return t
end

local function width(s)
    return #chars(s)
end

local function put(cells, text, hl)
    for _, ch in ipairs(chars(text)) do
        cells[#cells + 1] = { ch = ch, fg = hl.fg, bg = hl.bg, bold = hl.bold, italic = hl.italic }
    end
end

local function pad(cells, n, hl)
    while #cells < n do
        put(cells, ' ', hl or {})
    end
end

local function sgr(cell)
    local codes = { '0' }
    if cell.bold then codes[#codes + 1] = '1' end
    if cell.italic then codes[#codes + 1] = '3' end
    if cell.fg then codes[#codes + 1] = string.format('38;2;%d;%d;%d', rgb(cell.fg)) end
    if cell.bg then codes[#codes + 1] = string.format('48;2;%d;%d;%d', rgb(cell.bg)) end
    return '\27[' .. table.concat(codes, ';') .. 'm'
end

local function flush(cells)
    local out, prev = {}, nil
    for _, cell in ipairs(cells) do
        if not prev or prev.fg ~= cell.fg or prev.bg ~= cell.bg
            or prev.bold ~= cell.bold or prev.italic ~= cell.italic then
            out[#out + 1] = sgr(cell)
        end
        out[#out + 1] = cell.ch
        prev = cell
    end
    out[#out + 1] = '\27[0m'
    return table.concat(out)
end

local function opposite(c)
    local function lin(x)
        x = x / 255
        return x <= 0.04045 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4
    end
    local r, g, b = rgb(c)
    r, g, b = lin(r), lin(g), lin(b)
    local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
    local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
    local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
    local lightness = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    return lightness > 0.5 and 0x000000 or 0xffffff
end

local function highlight(code)
    local spans = {}
    local function span(text, group)
        if text ~= '' then spans[#spans + 1] = { text, HL[group] } end
    end

    local indent, directive, rest = code:match('^(%s*)(#%s*%a+)(.*)$')
    if directive then
        span(indent, 'Normal')
        span(directive, 'Include')
        local sp, lib, tail = rest:match('^(%s*)(%b<>)(.*)$')
        if lib then
            span(sp, 'Normal')
            span(lib, 'String')
            rest = tail
        end
        code = rest
    end

    local i, prev = 1, nil
    while i <= #code do
        local c = code:sub(i, i)
        local two = code:sub(i, i + 1)
        if two == '//' then
            span(code:sub(i), 'Comment')
            break
        elseif two == '/*' then
            local j = select(2, code:find('*/', i + 2, true)) or #code
            span(code:sub(i, j), 'Comment')
            i = j + 1
        elseif c == '"' then
            local j = i + 1
            while j <= #code and code:sub(j, j) ~= '"' do
                if code:sub(j, j) == '\\' then j = j + 1 end
                j = j + 1
            end
            local str = code:sub(i, j)
            local hex = str:match('^"(#%x%x%x%x%x%x)"$')
            if hex then
                local color = tonumber(hex:sub(2), 16)
                span('"', 'String')
                spans[#spans + 1] = { hex, { fg = opposite(color), bg = color } }
                span('"', 'String')
            else
                span(str, 'String')
            end
            prev, i = '"', j + 1
        elseif c:match('%d') then
            local num = code:match('^0[xX]%x+', i) or code:match('^%d+%.?%d*', i)
            span(num, 'Number')
            prev, i = num, i + #num
        elseif c:match('[%a_]') then
            local id = code:match('^[%w_]+', i)
            local j = i + #id
            local group = 'Normal'
            if KEYWORDS[id] then
                group = 'Keyword'
            elseif TYPES[id] or prev == 'struct' or prev == 'enum' or prev == 'union' then
                group = 'Type'
            elseif id == 'NULL' then
                group = 'Special'
            elseif id == 'true' or id == 'false' then
                group = 'Number'
            elseif prev == '.' then
                group = 'Property'
            elseif code:match('^%s*%(', j) then
                group = 'Function'
            elseif id:match('^[A-Z][A-Z0-9_]+$') then
                group = 'Constant'
            end
            span(id, group)
            prev, i = id, j
        elseif c:match('%s') then
            local ws = code:match('^%s+', i)
            span(ws, 'Normal')
            i = i + #ws
        else
            span(c, c:match('[{}()%[%];,.]') and 'Delimiter' or 'Operator')
            prev, i = c, i + 1
        end
    end
    return spans
end

local function line(code, diagnostic)
    state.lines = state.lines + 1
    state.bytes = state.bytes + #code + 1
    local n = state.lines
    local current = n == 1
    if current then state.first = code end

    local cells = {}
    put(cells, '│', HL.WinSeparator)

    local sign = diagnostic and SIGNS[diagnostic.level]
    if sign then
        put(cells, sign.sign .. ' ', HL['Diagnostic' .. sign.name])
        state.diagnostics[sign.name] = state.diagnostics[sign.name] + 1
    else
        put(cells, '  ', {})
    end

    if current then
        put(cells, string.format('%-4d', n), HL.CursorLineNr)
    else
        put(cells, string.format('%3d ', n - 1), HL.LineNr)
    end

    local text = #cells
    for _, s in ipairs(highlight(code)) do
        put(cells, s[1], s[2])
    end
    if sign then
        put(cells, '    ■ ' .. diagnostic.message, HL['Diagnostic' .. sign.name])
    end
    pad(cells, 1 + WIN)
    while #cells > 1 + WIN do
        table.remove(cells)
    end

    for i = text + 1, #cells do
        local col, cell = i - text, cells[i]
        if current then
            cell.bg = cell.bg or HL.CursorLine.bg
        elseif col == COLORCOLUMN then
            cell.bg = cell.bg or HL.ColorColumn.bg
        end
    end
    if current then
        cells[text + 1].fg, cells[text + 1].bg = HL.Cursor.fg, HL.Cursor.bg
    end

    return flush(cells)
end

local function str(s)
    s = tostring(s or ''):gsub('[\\"]', '\\%0')
    return '"' .. s .. '"'
end

local function join(...)
    local t = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        if v and v ~= '' then t[#t + 1] = tostring(v) end
    end
    return table.concat(t, ' ')
end

local UNITS = { B = 1024 ^ -3, KiB = 1024 ^ -2, MiB = 1024 ^ -1, GiB = 1, TiB = 1024, PiB = 1024 ^ 2 }

local function gib(s)
    local num, unit = tostring(s or ''):match('([%d.]+)%s*(%a+)')
    if not num then return 0 end
    return tonumber(num) * (UNITS[unit] or 1)
end

local function percent(used, total)
    return total > 0 and math.floor(used / total * 100 + 0.5) or 0
end

local function ident(s)
    s = tostring(s or ''):gsub('[^%w_]', '_')
    if s == '' then return 'machine' end
    if s:match('^%d') or KEYWORDS[s] or TYPES[s] then s = '_' .. s end
    return s
end

local function field(name, value, comment, diagnostic)
    local count = (state.fields[name] or 0) + 1
    state.fields[name] = count
    if count > 1 then name = name .. count end

    local code = string.format('    .%-8s = %s,', name, value)
    if comment then
        code = code .. string.rep(' ', math.max(1, COMMENT_COLUMN - 1 - width(code))) .. '/* ' .. comment .. ' */'
    end
    return line(code, diagnostic)
end

function M.header()
    return line('// Cat at Play, Henriëtte Ronner-Knip')
end

function M.include(a)
    return line(string.format('#include <%s/%s.h>', a.id ~= '' and a.id or 'unix', a.sysname:lower()))
end

function M.blank()
    return line('')
end

function M.close()
    return line('};')
end

function M.struct(a)
    state.user = a.userName
    state.name = ident(a.userName)
    return line(string.format('static const struct machine %s = {', state.name))
end

function M.host(a)
    return field('host', str(a.hostName))
end

function M.os(a)
    return field('os', str(join(a.prettyName ~= '' and a.prettyName or a.name, a.arch)))
end

function M.kernel(a)
    return field('kernel', str(a.release))
end

function M.init(a)
    return field('init', str(join(a.name, a.version)))
end

function M.packages(a)
    local managers = {}
    for _, name in ipairs({ 'xbps', 'flatpakAll', 'nixAll', 'pacman', 'dpkg', 'rpm', 'snap', 'brewAll', 'appimage' }) do
        local n = a[name] or 0
        if n > 0 then
            managers[#managers + 1] = { n = n, name = (name:gsub('All$', '')) }
        end
    end
    local comment
    if #managers == 1 then
        comment = managers[1].name
    elseif #managers > 1 then
        local t = {}
        for _, m in ipairs(managers) do t[#t + 1] = m.n .. ' ' .. m.name end
        comment = table.concat(t, ', ')
    end
    return field('packages', tostring(a.all), comment)
end

function M.uptime(a)
    local diagnostic
    if a.days >= 7 then
        diagnostic = { level = 4, message = 'up ' .. a.days .. ' days, xbps-install -Su && reboot?' }
    end
    return field('uptime', str(a.formatted), nil, diagnostic)
end

function M.age(a)
    local days, date, source = tostring(a.result):match('^(%d+) (%d+%-%d+%-%d+) ?(%S*)')
    if not days then
        error('no install date')
    end
    local since = 'since ' .. date .. (source ~= '' and ' (' .. source .. ')' or '')
    return field('age', str(days == '1' and '1 day' or days .. ' days'), since)
end

function M.wm(a)
    local name = join(a.prettyName, a.version)
    if a.protocolName ~= '' then name = name .. ' (' .. a.protocolName .. ')' end
    return field('wm', str(name))
end

function M.terminal(a)
    return field('terminal', str(join(a.prettyName, a.version)))
end

function M.shell(a)
    return field('shell', str(join(a.prettyName, a.version)))
end

function M.font(a)
    local size = tostring(a.size)
    return field('font', str(size ~= '' and a.name .. ' ' .. size .. 'pt' or a.name))
end

function M.cpu(a)
    local freq = a.freqMax ~= '' and a.freqMax or a.freqBase
    local name = a.name .. ' (' .. a.coresLogical .. ')'
    if freq ~= '' then name = name .. ' @ ' .. freq end
    return field('cpu', str(name))
end

function M.gpu(a)
    local kind = a.type:lower()
    local known = kind == 'integrated' or kind == 'discrete'
    return field(kind == 'integrated' and 'igpu' or 'gpu', str(a.name), known and kind or nil)
end

function M.memory(a)
    local used, total = gib(a.used), gib(a.total)
    local pct = percent(used, total)
    local diagnostic
    if pct >= 80 then
        diagnostic = { level = 2, message = string.format('memory is %d%% full', pct) }
    end
    local value = string.format('{ %.2f, %.2f }', used, total)
    return field('memory', value, string.format('GiB, %d%%', pct), diagnostic)
end

function M.zram(a)
    local data, compressed, size, algorithm = tostring(a.result):match('^(%d+) (%d+) (%d+) ?(%S*)')
    if not data then
        error('no zram')
    end
    data, compressed, size = tonumber(data), tonumber(compressed), tonumber(size)
    local pct = percent(data, size)
    local diagnostic
    if pct >= 80 then
        diagnostic = { level = 2, message = string.format('zram is %d%% full', pct) }
    end
    local info = { 'GiB' }
    if algorithm ~= '' then info[#info + 1] = algorithm end
    if compressed > 0 then info[#info + 1] = string.format('%.2fx', data / compressed) end
    local value = string.format('{ %.2f, %.2f }', data / 1024 ^ 3, size / 1024 ^ 3)
    return field('zram', value, table.concat(info, ', '), diagnostic)
end

function M.disk(a)
    local used, total = gib(a.sizeUsed), gib(a.sizeTotal)
    local pct = percent(used, total)
    local diagnostic
    if pct >= 90 then
        diagnostic = { level = 2, message = string.format('%s is %d%% full', a.mountpoint, pct) }
    end
    local value = string.format('{ %.1f, %.1f }', used, total)
    return field('disk', value, join('GiB,', a.filesystem), diagnostic)
end

function M.display(a)
    local value = string.format('{ %d, %d, %d }', a.width, a.height, math.floor(a.refreshRate + 0.5))
    return field('display', value, a.name ~= '' and a.name or nil)
end

local PALETTE = {
    { 'cc241d', '98971a', 'd79921', '458588', 'b16286', '689d6a' },
    { 'fb4934', 'b8bb26', 'fabd2f', '83a598', 'd3869b', '8ec07c' },
}

function M.palette(row)
    if not row then
        return line('static const char *gruvbox[] = {')
    end
    local t = {}
    for _, hex in ipairs(PALETTE[row]) do
        t[#t + 1] = '"#' .. hex .. '"'
    end
    return line('    ' .. table.concat(t, ', ') .. ',')
end

local GREETINGS = {
    { 5, 'good morning' },
    { 12, 'good afternoon' },
    { 17, 'good evening' },
    { 23, 'good night' },
}

function M.main(a)
    local greeting = 'good night'
    for _, g in ipairs(GREETINGS) do
        if a.hour >= g[1] then greeting = g[2] end
    end
    if state.user ~= '' then greeting = greeting .. ', ' .. state.user end
    return line(string.format('int main(void) { puts(%s); return meow(&%s); }', str(greeting), state.name))
end

function M.statusline()
    local function group(cells, hl, ...)
        local t = {}
        for i = 1, select('#', ...) do
            local s = select(i, ...)
            if s and s ~= '' then t[#t + 1] = s end
        end
        if #t > 0 then put(cells, ' ' .. table.concat(t, ' ') .. ' ', hl) end
        return cells
    end

    local counts = {}
    for _, s in ipairs(SIGNS) do
        local n = state.diagnostics[s.name]
        if n > 0 then counts[#counts + 1] = ' ' .. s.short .. n end
    end
    local diagnostics = #counts > 0 and ICONS.diagnostics .. table.concat(counts) or nil
    local size = state.bytes < 1024 and state.bytes .. 'B' or string.format('%.2fKiB', state.bytes / 1024)
    local location = string.format('%d|%d│%2d|%-2d', 1, state.lines, 1, width(state.first))

    local left = {}
    group(left, HL.ModeNormal, 'Normal')
    group(left, HL.StatusLine, diagnostics, ICONS.lsp .. ' +')
    group(left, HL.StatusLineNC, FILE)

    local right = {}
    group(right, HL.StatusLine, ICONS.c .. ' c utf-8[unix] ' .. size)
    group(right, HL.ModeNormal, location)

    pad(left, LEFT + 1 + WIN - #right, HL.StatusLineNC)
    table.move(right, 1, #right, #left + 1, left)

    local rows = {}
    for row = state.lines + 1, PICTURE do
        local cells = {}
        put(cells, '│', HL.WinSeparator)
        put(cells, '~', HL.EndOfBuffer)
        rows[#rows + 1] = (row > state.lines + 1 and '\n\27[' .. LEFT .. 'C' or '') .. flush(cells)
    end
    rows[#rows + 1] = (#rows > 0 and '\n' or '') .. '\r' .. flush(left)
    return table.concat(rows)
end

function M.cmdline()
    local cells = {}
    put(cells, string.format('"%s" %dL, %dB', FILE, state.lines, state.bytes), HL.Normal)
    return '\r' .. flush(cells)
end

return M

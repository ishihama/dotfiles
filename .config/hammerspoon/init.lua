-- Hammerspoon設定
-- 用途: claude-status のジャンプ機能で、別の仮想デスクトップ (Space) にある
-- GhosttyウィンドウへSpace切り替え込みでフォーカスを移す。
-- macOSのアクセシビリティAPI (System Events) は現在のSpaceのウィンドウしか
-- 列挙できないため、hs.spaces を使うHammerspoonが必要になる。

-- hs CLI (claude-statusから `hs -c` で呼び出すためのIPC)
require("hs.ipc")
if not hs.ipc.cliStatus("/opt/homebrew") then
    hs.ipc.cliInstall("/opt/homebrew")
end

-- 全Spaceを対象にGhosttyのウィンドウを追跡するフィルタ。
-- 重要: 購読 (subscribe) しないと受動的スキャンになり現在のSpaceの
-- ウィンドウしか見えない。空コールバックで常時追跡モードにすることで、
-- 一度でも表示したSpaceのウィンドウをキャッシュし続ける。
local ghosttyFilter = hs.window.filter.new(false)
    :setAppFilter("Ghostty", {})
    :setCurrentSpace(nil)
ghosttyFilter:subscribe(hs.window.filter.windowCreated, function() end)

-- タイトル前方一致でGhosttyウィンドウを探し、必要ならSpaceを切り替えてフォーカスする。
-- tmuxがウィンドウタイトルを「セッション名: ディレクトリ」に設定している前提。
-- claude-status から `hs -c 'claudeFocusGhosttyWindow("セッション名: ")'` で呼ばれ、
-- 見つかれば true、なければ false を返す。
function claudeFocusGhosttyWindow(titlePrefix)
    -- フィルタのキャッシュ (全Space) とAXの直接列挙 (現在のSpace) を統合して検索
    local candidates = {}
    local seen = {}
    for _, win in ipairs(ghosttyFilter:getWindows()) do
        candidates[#candidates + 1] = win
        local id = win:id()
        if id then seen[id] = true end
    end
    local ghostty = hs.application.get("Ghostty")
    if ghostty then
        for _, win in ipairs(ghostty:allWindows()) do
            local id = win:id()
            if not (id and seen[id]) then
                candidates[#candidates + 1] = win
            end
        end
    end
    for _, win in ipairs(candidates) do
        local title = win:title() or ""
        if title:sub(1, #titlePrefix) == titlePrefix then
            local ok, spaces = pcall(hs.spaces.windowSpaces, win)
            if ok and spaces and #spaces > 0
                and spaces[1] ~= hs.spaces.focusedSpace() then
                pcall(hs.spaces.gotoSpace, spaces[1])
                -- Space切り替えアニメーション中のfocus失敗を避ける
                hs.timer.usleep(300000)
            end
            win:focus()
            return true
        end
    end
    return false
end

-- デバッグ用: Hammerspoonから見えているGhosttyウィンドウの一覧を返す
-- `hs -c 'claudeListGhosttyWindows()'` で確認する
function claudeListGhosttyWindows()
    local out = {}
    for _, win in ipairs(ghosttyFilter:getWindows()) do
        local _, spaces = pcall(hs.spaces.windowSpaces, win)
        out[#out + 1] = string.format("[filter] spaces=%s title=%s",
            hs.inspect(spaces or {}), win:title() or "(no title)")
    end
    local ghostty = hs.application.get("Ghostty")
    if ghostty then
        for _, win in ipairs(ghostty:allWindows()) do
            local _, spaces = pcall(hs.spaces.windowSpaces, win)
            out[#out + 1] = string.format("[ax]     spaces=%s title=%s",
                hs.inspect(spaces or {}), win:title() or "(no title)")
        end
    end
    out[#out + 1] = "focusedSpace=" .. tostring(hs.spaces.focusedSpace())
    return table.concat(out, "\n")
end

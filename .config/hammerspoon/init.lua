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

-- 全Spaceを対象にGhosttyのウィンドウを追跡するフィルタ
local ghosttyFilter = hs.window.filter.new(false)
    :setAppFilter("Ghostty", {})
    :setCurrentSpace(nil)

-- タイトル前方一致でGhosttyウィンドウを探し、必要ならSpaceを切り替えてフォーカスする。
-- tmuxがウィンドウタイトルを「セッション名: ディレクトリ」に設定している前提。
-- claude-status から `hs -c 'claudeFocusGhosttyWindow("セッション名: ")'` で呼ばれ、
-- 見つかれば true、なければ false を返す。
function claudeFocusGhosttyWindow(titlePrefix)
    for _, win in ipairs(ghosttyFilter:getWindows()) do
        local title = win:title() or ""
        if title:sub(1, #titlePrefix) == titlePrefix then
            local ok, spaces = pcall(hs.spaces.windowSpaces, win)
            if ok and spaces and #spaces > 0
                and spaces[1] ~= hs.spaces.focusedSpace() then
                pcall(hs.spaces.gotoSpace, spaces[1])
            end
            win:focus()
            return true
        end
    end
    return false
end

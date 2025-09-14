local WinnerType = require("utils.utils").WinnerType


local game_state = {
}

game_state.board_state = {}

for i = 1, 3 do
    game_state.board_state[i] = {}
    for j = 1, 3 do
        local board = {
            completed = false,
            selected = false,
            winner = WinnerType.NONE,
            state = {
                { WinnerType.NONE, WinnerType.NONE, WinnerType.NONE },
                { WinnerType.NONE, WinnerType.NONE, WinnerType.NONE },
                { WinnerType.NONE, WinnerType.NONE, WinnerType.NONE },
            }
        }
        game_state.board_state[i][j] = board
    end
end

function game_state:set_state(new_state)
    game_state.board_state = new_state
end

return game_state;

Input@ game_input;

void Main() {
    @game_input = Input();
}

void Update(float dt) {
    if (game_input !is null) {
		game_input.Update(dt);
	}
}

void RenderInterface() {
    if (DebugOverlayEnabled) {
        renderDebugOverlay();
    }
}
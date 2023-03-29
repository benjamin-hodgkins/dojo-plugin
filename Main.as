TMDojo@ game_input;

void Main() {
    @game_input = Input();
}

void Update(float dt) {
    if (game_input !is null && Enabled) {
		game_input.Update(dt);
	}
}

void RenderInterface() {
    if (game_input.authWindowOpened) {
        renderAuthWindow();
    }
    if (DebugOverlayEnabled) {
        renderDebugOverlay();
    }
}
TMDojo@ game_input;

void Main() {
    print("Hello, world")
    @game_input = Input();
}

void Update(float dt) {
    if (game_input !is null && Enabled) {
		game_input.Update(dt);
	}
}

void RenderInterface() {
    if (DebugOverlayEnabled) {
        renderDebugOverlay();
    }
}
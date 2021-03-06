import std.range;
import std.algorithm;
import gfm.math.vector;
import derelict.sdl2.sdl;

import render_utils;
import misc.rect;
import misc.coords;
import state.state;
import widget.widget;
import widget.menu_widget;
import widget.main_menu_widget;
import widget.experiment_widget;

class UI {
	private Widget focus;

	Widget[] widgets;
	MenuWidget[] menuStack;

	RenderCoords dimensions;

	this(RenderCoords dimensions) {
		this.dimensions = dimensions;
		this.widgets ~= new ExperimentWidget(
			RenderCoords(0, 0),
			dimensions
		);
	}

	void render(State state) {
		auto renderState = state.renderState;

		// clear screen
		SDL_RenderSetViewport(renderState.renderer, null);
		renderState.renderClear();

		foreach (widget; widgets) {
			auto clipRect = getRectFromVectors(
				widget.offset,
				widget.offset + widget.dimensions
			);
			SDL_RenderSetViewport(renderState.renderer, &clipRect);
			widget.render(state);
		}

		SDL_RenderPresent(renderState.renderer);
	}

	void removeWidget(Widget widget) {
		if (widget is focus) {
			focus = null;
		}
		widgets = widgets.remove(widgets.countUntil(widget));
	}

	@property focusedWidget() {
		scope (failure) return null;
		if (focus is null) {
			focus = widgets[0];
		}

		return focus;
	}

	void handleEvent(State state, SDL_Event event) {
		switch (event.type) {
			case SDL_QUIT:
				state.simState.running = false;
				break;
			case SDL_KEYDOWN:
				handleKey(state, event.key.keysym.sym);
				break;
			case SDL_MOUSEBUTTONUP:
			case SDL_MOUSEBUTTONDOWN:
				handleClick(state, event.button);
				break;
			default:
				focusedWidget.handleEvent(state, event);
				break;
		}
	}

	void handleKey(State state, SDL_Keycode keycode) {
		// TODO add focus to the mix
		auto renderState = state.renderState;
		switch (keycode) {
			case SDLK_q:
				// quit
				state.simState.running = false;
				break;

			case SDLK_p:
				// toggle pause
				state.simState.paused = !state.simState.paused;
				break;

			case SDLK_d:
				// toggle debug rendering
				renderState.debugRender = !renderState.debugRender;
				break;

			case SDLK_ESCAPE:
				// open main menu
				if (menuStack.length == 0) {
					pushMenu(
						new MainMenuWidget(
							RenderCoords(0, 0),
							state.renderState.windowDimensions
						)
					);
				} else {
					popMenu();
				}
				break;

			default:
				break;
		}
	}

	void handleClick(State state, SDL_MouseButtonEvent event) {
		foreach (widget; retro(widgets)) {
			if (widget.containsPoint(event)) {
				event.x -= widget.offset.x;
				event.y -= widget.offset.y;

				focus = widget;
				widget.handleClick(state, event);
				return;
			}
		}
	}

	void pushMenu(MenuWidget menu) {
		// disable rendering of existing menu
		if (menuStack.length > 0) {
			widgets = widgets.remove(
				widgets.countUntil(menuStack[$ - 1])
			);
		}

		menuStack.assumeSafeAppend() ~= menu;
		widgets ~= menu;
		focus = menu;
	}

	MenuWidget popMenu() {
		assert(menuStack.length > 0);

		// pop and remove from widget list
		auto currentMenu = menuStack[$ - 1];
		menuStack.length--;
		removeWidget(currentMenu);

		// turn on rendering for next menu in stack
		if (menuStack.length > 0) {
			widgets ~= menuStack[$ - 1];
		}

		return currentMenu;
	}
}

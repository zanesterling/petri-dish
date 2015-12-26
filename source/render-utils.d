module render_utils;

import std.conv;
import std.stdio;
import gfm.math.vector;
import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

import misc.transforms;
import state.render_state;

void setRenderDrawColor(
	SDL_Renderer *renderer,
	SDL_Color color,
	ubyte alpha
) {
	SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, alpha);
}

void renderClear(RenderState state) {
	SDL_SetRenderDrawColor(state.renderer, 0, 0, 0, 0xff);
	SDL_RenderClear(state.renderer);
}

void drawText(
	RenderState state,
	string text,
	TTF_Font *font,
	int x,
	int y
) {
	drawText(state, text.dup ~ '\0', font, x, y);
}

void drawText(
	RenderState state,
	char[] text,
	TTF_Font *font,
	int x,
	int y
) {
	auto color = SDL_Color(0xff, 0xff, 0xff, 0xff);
	auto textTexture = getTextTexture(state, text, font, color);
	if (textTexture is null) {
		writeln(to!string(SDL_GetError()));
		return;
	}

	int w, h;
	SDL_QueryTexture(textTexture, null, null, &w, &h);
	auto targetLoc = SDL_Rect(x, y, w, h);
	SDL_RenderCopy(state.renderer, textTexture, null, &targetLoc);
	SDL_DestroyTexture(textTexture);
}

void drawTextCentered(
	RenderState state,
	string text,
	TTF_Font *font,
	int x,
	int y
) {
	drawTextCentered(state, text.dup ~ '\0', font, x, y);
}

void drawTextCentered(
	RenderState state,
	char[] text,
	TTF_Font *font,
	int x,
	int y
) {
	auto color = SDL_Color(0xff, 0xff, 0xff, 0xff);
	auto textTexture = getTextTexture(state, text, font, color);
	if (textTexture is null) {
		writeln(to!string(SDL_GetError()));
		return;
	}

	int w, h;
	SDL_QueryTexture(textTexture, null, null, &w, &h);
	auto targetLoc = SDL_Rect(x - w / 2, y - h / 2, w, h);
	SDL_RenderCopy(state.renderer, textTexture, null, &targetLoc);
	SDL_DestroyTexture(textTexture);
}

SDL_Texture *getTextTexture(
	RenderState state,
	char[] text,
	TTF_Font *font,
	SDL_Color color
) {
	auto textSurface = TTF_RenderText_Solid(font, text.ptr, color);
	if (textSurface is null) {
		writeln(to!string(SDL_GetError()));
		return null;
	}
	scope(exit) SDL_FreeSurface(textSurface);

	auto textTexture = SDL_CreateTextureFromSurface(
		state.renderer,
		textSurface
	);
	if (textTexture is null) {
		writeln(to!string(SDL_GetError()));
		return null;
	}

	return textTexture;
}

void drawRect(Vec_T)(
	RenderState state,
	Vec_T topLeft,
	Vec_T dimensions,
	SDL_Color color,
	ubyte alpha,
) {
	auto drawRect = getRectFromVectors(
		topLeft,
		topLeft + dimensions
	);
	setRenderDrawColor(state.renderer, color, alpha);
	SDL_RenderFillRect(state.renderer, &drawRect);
}

void drawRectWorldCoords(Vec_T)(
	RenderState state,
	Vec_T topLeft,
	Vec_T dimensions,
	SDL_Color color,
	ubyte alpha,
) {
	drawRect(
		state,
		state.worldToRenderCoords(cast(vec2d)topLeft),
		dimensions,
		color,
		alpha
	);
}

void drawLine(Vec_T)(
	RenderState state,
	Vec_T point1,
	Vec_T point2,
	SDL_Color color,
	ubyte alpha,
) {
	point1 = state.worldToRenderCoords(cast(vec2d)point1);
	point2 = state.worldToRenderCoords(cast(vec2d)point2);

	setRenderDrawColor(state.renderer, color, alpha);
	SDL_RenderDrawLine(
		state.renderer,
		cast(int)point1.x,
		cast(int)point1.y,
		cast(int)point2.x,
		cast(int)point2.y
	);
}

void drawLineWorldCoords(Vec_T)(
	RenderState state,
	Vec_T point1,
	Vec_T point2,
	SDL_Color color,
	ubyte alpha,
) {
	drawLine(
		state,
		state.worldToRenderCoords(cast(vec2d)point1),
		state.worldToRenderCoords(cast(vec2d)point2),
		color,
		alpha
	);
}
import std.stdio;
import std.random;
import std.algorithm;

import cell;
import food;
import sim_state;

const double VISCOSITY = 1.1;
const double VISCOSITY_SLOWING_FACTOR = 1 / VISCOSITY;

void update(SimulationState *state) {
	auto FIELD_RAD = state.FIELD_RAD;

	// update cell positions
	foreach (ref Cell cell; state.cells) {
		updatePos(state, cell);
	}

	// TODO check for collision

	// check for food consumption
	foreach (ref Cell cell; state.cells) {
		foreach (i, food; state.food) {
			auto posDiff = cell.pos - food.pos;
			auto radSum = cell.rad + food.rad;
			if (posDiff.squaredLength() < radSum ^^ 2) {
				cell.gainMass(food.amount);
				food.shouldDie = true;
			}
		}
	}

	Cell[] newCells;
	for (int i = 0; i < state.cells.length; i++) {
		// drain cells' energy
		Cell *cell = &state.cells[i];
		cell.foodLevel -= cell.foodConsumption();

		if (cell.foodLevel <= Cell.MIN_FOOD) {
			state.cells.remove(i--);
			state.cells.length--;
		} else if (cell.foodLevel >= cell.mode.splitThreshold) {
			// if you have enough food, reproduce!
			newCells ~= cell.reproduce();
		}
	}

	foreach (ref Cell cell; newCells) {
		state.cells ~= cell;
	}

	for (int i = 0; i < state.food.length; i++) {
		if (state.food[i].shouldDie) {
			state.food.remove(i--);
			state.food.length--;
		}
	}

	// generate new food
	state.foodGenStatus += state.foodGenRate;
	while (state.foodGenStatus > 1) {
		auto x = uniform(-FIELD_RAD, FIELD_RAD);
		auto y = uniform(-FIELD_RAD, FIELD_RAD);
		state.food ~= new Food(x, y);
		state.foodGenStatus--;
	}
}

void updatePos(SimulationState *state, ref Cell cell) {
	auto FIELD_RAD = state.FIELD_RAD;
	auto pos = &cell.pos;

	// update position
	cell.pos += cell.vel;

	// simulate viscosity
	cell.vel *= VISCOSITY_SLOWING_FACTOR;

	// constrain cell to field bounds
	if (pos.x < -FIELD_RAD) {
		pos.x = -pos.x - 2 * FIELD_RAD;
		cell.vel.x *= -1;
	} else if (pos.x > FIELD_RAD) {
		pos.x = 2 * FIELD_RAD - pos.x;
		cell.vel.x *= -1;
	}

	if (pos.y < -FIELD_RAD) {
		pos.y = -pos.y - 2 * FIELD_RAD;
		cell.vel.y *= -1;
	} else if (pos.y > FIELD_RAD) {
		pos.y = 2 * FIELD_RAD - pos.y;
		cell.vel.y *= -1;
	}
}

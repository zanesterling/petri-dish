import std.stdio;
import std.random;
import std.algorithm;
import std.parallelism;

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

	Cell[] newCells;
	foreach (ref Cell cell; parallel(state.cells)) {
		// handle collisions
		foreach (ref Cell otherCell; state.cells) {
			// don't collide with yourself
			if (&cell == &otherCell) {
				continue;
			}

			auto posDiff = cell.pos - otherCell.pos;
			auto radSum = cell.rad + otherCell.rad;
			auto diffSquared = posDiff.squaredLength();
			if (diffSquared < radSum ^^ 2) {
				cell.vel += posDiff / diffSquared;
			}
		}

		// handle food consumption
		foreach (food; state.food) {
			auto posDiff = cell.pos - food.pos;
			auto radSum = cell.rad + food.rad;
			if (posDiff.squaredLength() < radSum ^^ 2) {
				cell.gainMass(food.amount);
				food.shouldDie = true;
			}
		}

		cell.mass -= cell.massConsumption();

		if (cell.mass <= Cell.MIN_MASS) {
			cell.shouldDie = true;
		} else if (cell.mass >= cell.mode.splitThreshold) {
			// if you have enough food, reproduce!
			newCells ~= cell.reproduce();
		}
	}

	foreach (ref Cell cell; newCells) {
		state.cells ~= cell;
	}

	// clean up dead food and cells
	for (int i = 0; i < state.food.length; i++) {
		auto food = state.food[i];
		if (food.shouldDie || food.age++ >= Food.MAX_AGE) {
			state.food[i] = state.food[$ - 1];
			state.food.length--;
		}
	}
	for (int i = 0; i < state.cells.length; i++) {
		if (state.cells[i].shouldDie) {
			state.cells[i] = state.cells[$ - 1];
			state.cells.length--;
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

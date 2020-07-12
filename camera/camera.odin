package camera

import "core:math"
import "core:math/linalg"

Camera :: struct {
	// Position Vectors
	position: linalg.Vector3,

	// Direction Vectors
	front: linalg.Vector3,
	worldUp: linalg.Vector3,
	right: linalg.Vector3,
	up: linalg.Vector3,

	// Euler Angles
	pitch: f32,
	yaw: f32,

	// Other
	movementSpeed: linalg.Vector3,
	mouseSensitivity: f32,
	update: bool,
	cachedViewMatrix: linalg.Matrix4
}

MovementDirection :: enum {
	FORWARD,
	BACKWARD,
	LEFT,
	RIGHT,
	UP,
	DOWN
}

DEFAULT_PITCH : f32 : 0.0;
DEFAULT_YAW : f32 : -90.0;
DEFAULT_MOVEMENT_SPEED : f32 : 3;
DEFAULT_MOUSE_SENSITIVITY : f32 : 0.1;

create :: proc(position, worldUp: linalg.Vector3, pitch: f32 = DEFAULT_PITCH, yaw: f32 = DEFAULT_YAW, movementSpeed: f32 = DEFAULT_MOVEMENT_SPEED, mouseSensitivity: f32 = DEFAULT_MOUSE_SENSITIVITY) -> (camera: Camera) {
	camera.position = position;
	camera.worldUp = worldUp;
	camera.pitch = pitch;
	camera.yaw = yaw;

	camera.front = linalg.Vector3{0.0, 0.0, -1.0};

	camera.movementSpeed = linalg.Vector3{movementSpeed, movementSpeed, movementSpeed};
	camera.mouseSensitivity = mouseSensitivity;

	updateVectors(&camera);

	return camera;
}

updateVectors :: proc(camera: ^Camera) {
	camera.front = linalg.normalize(vector_from_euler_angles(linalg.radians(camera.pitch), linalg.radians(camera.yaw)));
	camera.right = linalg.normalize(linalg.vector_cross(camera.front, camera.worldUp));
	camera.up = linalg.normalize(linalg.vector_cross(camera.right, camera.front));

	camera.update = true;
}

updateMouseMovement :: proc(camera: ^Camera, xOffset, yOffset: f32, constrainPitch := true) {
	camera.yaw = math.mod_f32((camera.yaw + (xOffset * camera.mouseSensitivity)), 360.0);
	camera.pitch = math.mod_f32((camera.pitch + (yOffset * camera.mouseSensitivity)), 360.0);

	// make sure that when pitch is out of bounds, screen doesn't get flipped
	if (constrainPitch) {
		if camera.pitch > 89.0 do camera.pitch = 89.0;
		if camera.pitch < -89.0 do camera.pitch = -89.0;
	}

	updateVectors(camera);
}

updateMovement :: proc(camera: ^Camera, direction: MovementDirection, deltaTime: f64) {
	velocity := linalg.Vector3{cast(f32) (cast(f64) camera.movementSpeed.x * deltaTime), cast(f32) (cast(f64) camera.movementSpeed.y * deltaTime), cast(f32) (cast(f64) camera.movementSpeed.z * deltaTime)};

	switch direction {
		case .FORWARD: camera.position += camera.front * velocity;
		case .BACKWARD: camera.position -= camera.front * velocity;
		case .LEFT: camera.position -= camera.right * velocity;
		case .RIGHT: camera.position += camera.right * velocity;
		case .UP: camera.position += camera.up * velocity;
		case .DOWN: camera.position -= camera.up * velocity;
	}

	camera.update = true;
}

getViewMatrix :: proc(camera: ^Camera) -> linalg.Matrix4 {
	if camera.update {
		camera.cachedViewMatrix = linalg.matrix4_look_at(camera.position, camera.position + camera.front, camera.up);
		camera.update = false;
	}
	return camera.cachedViewMatrix;
}

// NOTE: yaw and pitch should be in radians
@private vector_from_euler_angles :: proc(pitch, yaw: linalg.Float) -> (direction: linalg.Vector3) {
	direction.x = math.cos(yaw) * math.cos(pitch);
	direction.y = math.sin(pitch);
	direction.z = math.sin(yaw) * math.cos(pitch);

	return direction;
}


package main

import "camera"

import gl "shared:odin-gl"
import glfw "shared:odin-glfw"
import "shared:odin-stb/stbi"

import "core:fmt"
import "core:math"
import "core:math/linalg"

cameraDefaultPos :: linalg.Vector3{0.0, 0.0, 3.0};
worldUp :: linalg.Vector3{0.0, 1.0, 0.0};
mainCamera := camera.create(cameraDefaultPos, worldUp);

deltaTime := 0.0;
lastFrame := 0.0;

main :: proc() {
	windowWidth: f32 = 800.0;
	windowHeight: f32 = 600.0;

	glfw.init();
	glfw.window_hint(glfw.Window_Attribute.CONTEXT_VERSION_MAJOR, 3);
	glfw.window_hint(glfw.Window_Attribute.CONTEXT_VERSION_MINOR, 3);
	glfw.window_hint(glfw.Window_Attribute.OPENGL_PROFILE, cast(int) glfw.OpenGL_Profile.OPENGL_CORE_PROFILE);
	// glfw.window_hint(glfw.Window_Attribute.OPENGL_FORWARD_COMPAT, cast(int) glfw.Boolean_State.TRUE); // Required by Mac OS X

	window := glfw.create_window(cast(int) windowWidth, cast(int) windowHeight, "OpenGL", nil, nil);
	if window == nil {
		// Failed
		glfw.terminate();
		fmt.printf("Failed to create window\n");
		return;
	}
	glfw.make_context_current(window);
	gl.load_up_to(4, 5, glfw.set_proc_address);
	gl.Enable(gl.DEPTH_TEST);

	// Sets location of lower left corner of window to (0, 0).
	// Sets width and height of viewport to width and height of
	// window, (800, 600)
	gl.Viewport(0, 0, 800, 600);
	glfw.set_input_mode(window, glfw.CURSOR, cast(int) glfw.CURSOR_DISABLED);
	glfw.set_framebuffer_size_callback(window, cast(glfw.Framebuffer_Size_Proc) framebuffer_size_callback);
	glfw.set_cursor_pos_callback(window, cast(glfw.Cursor_Pos_Proc) mouse_callback);

	shaderProgram, success := gl.load_shaders_file("main.vert", "main.frag");
	lightShader, lightSuccess := gl.load_shaders_file("light.vert", "light.frag");

	// Textures
	stbi.set_flip_vertically_on_load(1);

	texture: u32;
	gl.GenTextures(1, &texture);
	gl.BindTexture(gl.TEXTURE_2D, texture);

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

	width, height, nrChannels: i32;
	data: ^u8 = stbi.load("container.jpg", &width, &height, &nrChannels, 0);
	if data != nil {
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
		gl.GenerateMipmap(gl.TEXTURE_2D);
	} else {
		fmt.println("Failed to load texture1");
	}
	stbi.image_free(data);

	texture2: u32;
	gl.GenTextures(1, &texture2);
	gl.BindTexture(gl.TEXTURE_2D, texture2);

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

	data = stbi.load("awesomeface.png", &width, &height, &nrChannels, 0);
	if data != nil {
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
		gl.GenerateMipmap(gl.TEXTURE_2D);
	} else {
		fmt.println("Failed to load texture2");
	}
	stbi.image_free(data);

	gl.UseProgram(shaderProgram);
	gl.Uniform1i(gl.GetUniformLocation(shaderProgram, "texture1"), 0);
	gl.Uniform1i(gl.GetUniformLocation(shaderProgram, "texture2"), 1);

	// Vertices and Indices for Shapes
	vertices := []f32 {
		// positions      colors         texture coords
// 		 0.5,  0.5, 0.0,  0.9, 0.4, 0.0,  1.0, 1.0, // top right
// 		 0.5, -0.5, 0.0,  1.0, 0.95, 0.0,  1.0, 0.0, // bottom right
// 		-0.5, -0.5, 0.0,  0.9, 0.4, 0.0,  0.0, 0.0, // bottom left
// 		-0.5,  0.5, 0.0,  0.9, 1.0, 1.0,  0.0, 1.0 // top left

		-0.5, -0.5, -0.5,  1.0, 0.6, 0.42,  0.0, 0.0,
	     0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	     0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  1.0, 1.0,
	     0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  1.0, 1.0,
	    -0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	    -0.5, -0.5, -0.5,  1.0, 0.6, 0.42,  0.0, 0.0,

	    -0.5, -0.5,  0.5,  0.76, 0.6, 0.42,  0.0, 0.0,
	     0.5, -0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	     0.5,  0.5,  0.5,  1.0, 0.6, 0.42,  1.0, 1.0,
	     0.5,  0.5,  0.5,  1.0, 0.6, 0.42,  1.0, 1.0,
	    -0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	    -0.5, -0.5,  0.5,  0.76, 0.6, 0.42,  0.0, 0.0,

	    -0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	    -0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  1.0, 1.0,
	    -0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	    -0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	    -0.5, -0.5,  0.5,  0.76, 0.6, 0.42,  0.0, 0.0,
	    -0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,

	     0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	     0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  1.0, 1.0,
	     0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	     0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	     0.5, -0.5,  0.5,  0.76, 0.6, 0.42,  0.0, 0.0,
	     0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,

	    -0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	     0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  1.0, 1.0,
	     0.5, -0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	     0.5, -0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	    -0.5, -0.5,  0.5,  1.0, 0.6, 0.42,  0.0, 0.0,
	    -0.5, -0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,

	    -0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0,
	     0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  1.0, 1.0,
	     0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	     0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  1.0, 0.0,
	    -0.5,  0.5,  0.5,  0.76, 0.6, 0.42,  0.0, 0.0,
	    -0.5,  0.5, -0.5,  0.76, 0.6, 0.42,  0.0, 1.0
	};
	/*indices := []i32 {
		0, 1, 3, // First triangle
		1, 2, 3  // Second triangle
	};*/

	vbo, vao, ebo: u32;
	gl.GenBuffers(1, &vbo);
	//gl.GenBuffers(1, &ebo);
	gl.GenVertexArrays(1, &vao);

	gl.BindVertexArray(vao);
	{
		gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
		gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW);
		//gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
		//gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(i32), &indices[0], gl.STATIC_DRAW);

		// Position Attribute
		gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), cast(rawptr) (cast(uintptr) 0));
		gl.EnableVertexAttribArray(0);
		// Color Attribute
		gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), cast(rawptr) (cast(uintptr) (3 * size_of(f32))));
		gl.EnableVertexAttribArray(1);
		// Texture Coords Attribute
		gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), cast(rawptr) (cast(uintptr) (6 * size_of(f32))));
		gl.EnableVertexAttribArray(2);

		gl.BindBuffer(gl.ARRAY_BUFFER, 0);
	}
	gl.BindVertexArray(0);

	vbo_light, vao_light: u32;
//	gl.GenBuffers(1, &vbo_light);
	gl.GenVertexArrays(1, &vao_light);
	gl.BindVertexArray(vao_light);
	{
		gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
//		gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW);

		// Position Attribute
		gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), cast(rawptr) (cast(uintptr) 0));
		gl.EnableVertexAttribArray(0);
		// Color Attribute
// 		gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), cast(rawptr) (cast(uintptr) (3 * size_of(f32))));
// 		gl.EnableVertexAttribArray(1);
		// Texture Coords Attribute
// 		gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), cast(rawptr) (cast(uintptr) (6 * size_of(f32))));
// 		gl.EnableVertexAttribArray(2);

		gl.BindBuffer(gl.ARRAY_BUFFER, 0);
	}
	gl.BindVertexArray(0);

	// Transformations
	// Note: The order of the transformations being multiplied into one transformation matrix matters.
	// Recommended to do scale, rotate, then translate last.
	identity := linalg.MATRIX4_IDENTITY;
	projection := linalg.matrix4_perspective(linalg.radians(45.0), windowWidth / windowHeight, 0.1, 100.0);

	uniforms := gl.get_uniforms_from_program(shaderProgram);
	modelLocation := uniforms["model"].location;
	viewLocation := uniforms["view"].location;
	projectionLocation := uniforms["projection"].location;
	lightColorLocation := uniforms["lightColor"].location;

	light_uniforms := gl.get_uniforms_from_program(lightShader);
	light_modelLocation := light_uniforms["model"].location;
	light_viewLocation := light_uniforms["view"].location;
	light_projectionLocation := light_uniforms["projection"].location;

	gl.UseProgram(shaderProgram);
	lightColor := linalg.Vector3{1.0, 1.0, 1.0};
	gl.Uniform3fv(lightColorLocation, 1, &lightColor[0]);

	cubePositions := []linalg.Vector3 {
		linalg.Vector3{ 0.0,  0.0,   0.0},
		linalg.Vector3{ 2.0,  5.0, -15.0},
		linalg.Vector3{-1.5, -2.2,  -2.5},
		linalg.Vector3{-3.8, -2.0, -12.3},
		linalg.Vector3{ 2.4, -0.4,  -3.5},
		linalg.Vector3{-1.7,  3.0,  -7.5},
		linalg.Vector3{ 1.3, -2.0,  -2.5},
		linalg.Vector3{ 1.5,  2.0,  -2.5},
		linalg.Vector3{ 1.5,  0.2,  -1.5},
		linalg.Vector3{-1.3,  1.0,  -1.5}
	};

	lightPosition := linalg.Vector3{1.2, 1.0, 2.0};
	//lightModel: linalg.Matrix4 = 1.0;
	lightModel := linalg.matrix4_translate(lightPosition);
	lightModel = linalg.mul(lightModel, linalg.matrix4_scale(linalg.Vector3{0.2, 0.2, 0.2}));
	gl.UseProgram(lightShader);
	gl.UniformMatrix4fv(light_modelLocation, 1, gl.FALSE, cast(^f32) &lightModel[0]);

	for !glfw.window_should_close(window) {
		timeValue := glfw.get_time();
		deltaTime = timeValue - lastFrame;
		lastFrame = timeValue;

		processInput(window);

		gl.ClearColor(0.2, 0.2, 0.2, 1.0);
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

		// Drawing Code
		gl.UseProgram(shaderProgram);

		// Transformations
		view := camera.getViewMatrix(&mainCamera);
		gl.UniformMatrix4fv(viewLocation, 1, gl.FALSE, cast(^f32) &view[0]);
		gl.UniformMatrix4fv(projectionLocation, 1, gl.FALSE, cast(^f32) &projection[0]);

		// Textures
		gl.ActiveTexture(gl.TEXTURE0);
		gl.BindTexture(gl.TEXTURE_2D, texture);
		gl.ActiveTexture(gl.TEXTURE1);
		gl.BindTexture(gl.TEXTURE_2D, texture2);

		// Draw Cubes
		gl.BindVertexArray(vao);
		for i := 0; i < len(cubePositions); i += 1 {
			model := linalg.matrix4_translate(cubePositions[i]);
			angle: f32 = 20.0 * cast(f32) (i + 1);
			model = linalg.mul(model, linalg.matrix4_rotate(cast(f32) timeValue * linalg.radians(angle), linalg.Vector3{1.0, 0.3, 0.5}));
			gl.UniformMatrix4fv(modelLocation, 1, gl.FALSE, cast(^f32) &model[0]);

			gl.DrawArrays(gl.TRIANGLES, 0, 36);
		}
		gl.BindVertexArray(0);

		// Drawing Light Source
		gl.UseProgram(lightShader);
		gl.UniformMatrix4fv(light_viewLocation, 1, gl.FALSE, cast(^f32) &view[0]);
		gl.UniformMatrix4fv(light_projectionLocation, 1, gl.FALSE, cast(^f32) &projection[0]);

		gl.BindVertexArray(vao_light);
		gl.DrawArrays(gl.TRIANGLES, 0, 36);
		gl.BindVertexArray(0);

		glfw.swap_buffers(window);
		glfw.poll_events();
	}

	gl.DeleteVertexArrays(1, &vao);
	gl.DeleteBuffers(1, &vbo);
	gl.DeleteProgram(shaderProgram);

	glfw.terminate();
}

/*
compileShaders :: proc() -> u32 {
	vertexShaderSource : cstring = `#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
out vec3 ourColor;
void main()
{
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
	ourColor = aColor;
}`;
	fragmentShaderSource : cstring = `#version 330 core
out vec4 FragColor;
in vec4 ourColor;
void main()
{
	FragColor = ourColor;
}
`;

	vertexShader := gl.CreateShader(gl.VERTEX_SHADER);
	gl.ShaderSource(vertexShader, 1, cast(^^u8) &vertexShaderSource, nil);
	gl.CompileShader(vertexShader);

	success: i32;
	infoLog: [512]u8;
	gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
	if success == 0 {
		gl.GetShaderInfoLog(vertexShader, 512, nil, &infoLog[0]);
		fmt.printf("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n%s\n", infoLog);
		//return; // TODO
	}

	fragmentShader := gl.CreateShader(gl.FRAGMENT_SHADER);
	gl.ShaderSource(fragmentShader, 1, cast(^^u8) &fragmentShaderSource, nil);
	gl.CompileShader(fragmentShader);

	gl.GetShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
	if success == 0 {
		gl.GetShaderInfoLog(fragmentShader, 512, nil, &infoLog[0]);
		fmt.printf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n%s\n", infoLog);
		//return; // TODO
	}

	shaderProgram := gl.CreateProgram();
	gl.AttachShader(shaderProgram, vertexShader);
	gl.AttachShader(shaderProgram, fragmentShader);
	gl.LinkProgram(shaderProgram);

	gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success);
	if success == 0 {
		gl.GetProgramInfoLog(shaderProgram, 512, nil, &infoLog[0]);
		fmt.printf("ERROR::SHADER::PROGRAM::LINK_FAILED\n%s\n", infoLog);
		//return; // TODO
	}

	gl.DeleteShader(vertexShader);
	gl.DeleteShader(fragmentShader);

	return shaderProgram;
}
*/

getMaxAllowedAttributes :: proc() -> i32 {
	nrAttributes: i32;
	gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, &nrAttributes);

	return nrAttributes;
}

framebuffer_size_callback :: proc(window: glfw.Window_Handle, width, height: i32) {
	gl.Viewport(0, 0, width, height);
}

lastX: f32 = 400.0;
lastY: f32 = 300.0;
firstMouse := true;

mouse_callback :: proc(window: glfw.Window_Handle, xpos, ypos: f64) {
	if firstMouse {
		lastX = cast(f32) xpos;
		lastY = cast(f32) ypos;
		firstMouse = false;
	}

	xOffset: f32 = cast(f32) (xpos - cast(f64) lastX);
	yOffset: f32 = cast(f32) (cast(f64) lastY - ypos); // reversed since y-coordinates range from bottom to top
	lastX = cast(f32) xpos;
	lastY = cast(f32) ypos;

	camera.updateMouseMovement(&mainCamera, xOffset, yOffset);
}

wireframe := false;

processInput :: proc(window: glfw.Window_Handle) {
	if (glfw.get_key(window, glfw.Key.KEY_ESCAPE) == glfw.Key_State.PRESS) {
		glfw.set_window_should_close(window, true);
	} else if (glfw.get_key(window, glfw.Key.KEY_F) == glfw.Key_State.PRESS) {
		if !wireframe {
			gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
			wireframe = true;
		} else {
			gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
			wireframe = false;
		}
	}

	if (glfw.get_key(window, glfw.Key.KEY_DOWN) == glfw.Key_State.PRESS || glfw.get_key(window, glfw.Key.KEY_S) == glfw.Key_State.PRESS) {
		camera.updateMovement(&mainCamera, .BACKWARD, deltaTime);
	} else if (glfw.get_key(window, glfw.Key.KEY_UP) == glfw.Key_State.PRESS || glfw.get_key(window, glfw.Key.KEY_W) == glfw.Key_State.PRESS) {
		camera.updateMovement(&mainCamera, .FORWARD, deltaTime);
	}

	if (glfw.get_key(window, glfw.Key.KEY_LEFT) == glfw.Key_State.PRESS || glfw.get_key(window, glfw.Key.KEY_A) == glfw.Key_State.PRESS) {
		camera.updateMovement(&mainCamera, .LEFT, deltaTime);
	} else if (glfw.get_key(window, glfw.Key.KEY_RIGHT) == glfw.Key_State.PRESS || glfw.get_key(window, glfw.Key.KEY_D) == glfw.Key_State.PRESS) {
		camera.updateMovement(&mainCamera, .RIGHT, deltaTime);
	}

	if (glfw.get_key(window, glfw.Key.KEY_SPACE) == glfw.Key_State.PRESS) {
		camera.updateMovement(&mainCamera, .UP, deltaTime);
	} else if (glfw.get_key(window, glfw.Key.KEY_LEFT_SHIFT) == glfw.Key_State.PRESS) {
		camera.updateMovement(&mainCamera, .DOWN, deltaTime);
	}
}


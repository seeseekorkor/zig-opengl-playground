const std = @import("std");
const fs = std.fs;
const c = @cImport({
    @cInclude("GL/glew.h");
    // @cInclude("GL/gl.h");
    @cInclude("GLFW/glfw3.h");
});

// const vertex_shader =
//     \\#version 330 core
//     \\layout(location = 0) in vec3 position;
//     \\void main() {
//     \\    gl_Position = vec4(position, 1.0);
//     \\}
// ;
// const fragment_shader =
//     \\#version 330 core
//     \\out vec4 FragColor;
//     \\void main() {
//     \\    FragColor = vec4(1.0, 0.5, 0.2, 1.0);
//     \\}
// ;

pub fn loadShader(vertex_file_path: []const u8, fragment_file_path: []const u8) !c.GLuint {
    std.debug.print("[vertex_file_path] ->> {s}\n", .{vertex_file_path});
    std.debug.print("[fragment_file_path] ->> {s}\n", .{fragment_file_path});
    // 메모리 할당자 생성
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Vertex Shader
    // ----------------------------------------------------------------------
    const vertex_shader_id = c.glCreateShader().?(c.GL_VERTEX_SHADER);
    defer c.glDeleteShader().?(vertex_shader_id);
    std.debug.print("[vertex_shader_id] ->> {any}\n", .{vertex_shader_id});

    const vertex_source_file = try fs.cwd().openFile(vertex_file_path, .{ .mode = fs.File.OpenMode.read_only });
    defer vertex_source_file.close();
    std.debug.print("[vertex_source_file] ->> {any}\n", .{vertex_source_file});

    const vertex_read_buffer = try vertex_source_file.reader().readAllAlloc(allocator, 1024);
    defer allocator.free(vertex_read_buffer);
    std.debug.print("[vertex_read_buffer] ->> {s}\n", .{vertex_read_buffer});
    // ----------------------------------------------------------------------

    // Fragment Shader
    // ----------------------------------------------------------------------
    const fragment_shader_id = c.glCreateShader().?(c.GL_FRAGMENT_SHADER);
    defer c.glDeleteShader().?(fragment_shader_id);
    std.debug.print("[fragment_shader_id] ->> {any}\n", .{fragment_shader_id});

    const fragment_source_file = try fs.cwd().openFile(fragment_file_path, .{ .mode = fs.File.OpenMode.read_only });
    defer fragment_source_file.close();
    std.debug.print("[fragment_source_file] ->> {any}\n", .{fragment_source_file});

    const fragment_read_buffer = try fragment_source_file.reader().readAllAlloc(allocator, 1024);
    defer allocator.free(fragment_read_buffer);
    std.debug.print("[fragment_read_buffer] ->> {any} ->> {any}\n", .{ @TypeOf(fragment_read_buffer), fragment_read_buffer });
    // ----------------------------------------------------------------------

    // Compile
    // ----------------------------------------------------------------------
    var result: c.GLint = c.GL_FALSE;
    var info_log_length: c_int = undefined;
    std.debug.print("[Compiling Start]\n", .{});

    const vertex_source: [*c]const c.GLchar = vertex_read_buffer.ptr;
    var ptr_vertex_source: [*c]const [*c]const c.GLchar = &[_][*c]const c.GLchar{ vertex_source, null };
    c.glShaderSource().?(vertex_shader_id, 1, @ptrCast(&ptr_vertex_source), null);
    c.glCompileShader().?(vertex_shader_id);
    c.glGetShaderiv().?(vertex_shader_id, c.GL_COMPILE_STATUS, &result);
    c.glGetShaderiv().?(vertex_shader_id, c.GL_INFO_LOG_LENGTH, &info_log_length);

    if (info_log_length > 0) {
        var vertex_shader_error_message = try std.ArrayList(u8).initCapacity(allocator, @as(usize, @intCast(info_log_length)) + 1);
        defer {
            vertex_shader_error_message.clearAndFree();
            vertex_shader_error_message.deinit();
        }
        c.glGetShaderInfoLog().?(vertex_shader_id, info_log_length, null, vertex_shader_error_message.items.ptr);
        std.debug.print("[vertex_shader_error_message] ->> {any}\n", .{vertex_shader_error_message.items});
    }

    const fragment_source: [*]const c.GLchar = fragment_read_buffer.ptr;
    var ptr_fragment_source: [*c]const [*c]const c.GLchar = &[_][*c]const c.GLchar{ fragment_source, null };
    std.debug.print("[ptr_fragment_source] ->> {any} ->> {any}\n", .{ @TypeOf(ptr_fragment_source), ptr_fragment_source });

    c.glShaderSource().?(fragment_shader_id, 1, @ptrCast(&ptr_fragment_source), null);
    c.glCompileShader().?(fragment_shader_id);
    c.glGetShaderiv().?(fragment_shader_id, c.GL_COMPILE_STATUS, &result);
    c.glGetShaderiv().?(fragment_shader_id, c.GL_INFO_LOG_LENGTH, &info_log_length);

    if (info_log_length > 0) {
        var fragment_shader_error_message = try std.ArrayList(u8).initCapacity(allocator, @as(usize, @intCast(info_log_length)) + 1);
        defer {
            fragment_shader_error_message.clearAndFree();
            fragment_shader_error_message.deinit();
        }
        c.glGetShaderInfoLog().?(fragment_shader_id, info_log_length, null, fragment_shader_error_message.items.ptr);
        std.debug.print("[fragment_shader_error_message] ->> {any}\n", .{fragment_shader_error_message.items});
    }
    // ----------------------------------------------------------------------

    // Linking
    // ----------------------------------------------------------------------
    std.debug.print("[Linking Start]\n", .{});
    const program_id = c.glCreateProgram().?();

    c.glAttachShader().?(program_id, vertex_shader_id);
    defer c.glDetachShader().?(program_id, vertex_shader_id);

    c.glAttachShader().?(program_id, fragment_shader_id);
    defer c.glDetachShader().?(program_id, fragment_shader_id);

    c.glLinkProgram().?(program_id);

    c.glGetProgramiv().?(program_id, c.GL_LINK_STATUS, &result);
    c.glGetProgramiv().?(program_id, c.GL_INFO_LOG_LENGTH, &info_log_length);

    if (info_log_length > 0) {
        var program_error_message = try std.ArrayList(u8).initCapacity(allocator, @as(usize, @intCast(info_log_length)) + 1);
        defer {
            program_error_message.clearAndFree();
            program_error_message.deinit();
        }
        c.glGetShaderInfoLog().?(program_id, info_log_length, null, program_error_message.items.ptr);
        std.debug.print("[program_error_message] ->> {any}\n", .{program_error_message.items});
    }
    // ----------------------------------------------------------------------
    std.debug.print("[Is Vertex GL Shader?] ->> {}\n", .{c.glIsShader().?(vertex_shader_id) == c.GL_TRUE});
    std.debug.print("[Is Fragment GL Shader?] ->> {}\n", .{c.glIsShader().?(fragment_shader_id) == c.GL_TRUE});
    std.debug.print("[loadShader return] ->> {}\n", .{program_id});
    return program_id;
}

pub fn main() !void {
    // GLFW 초기화
    // --------------------------------------------------------------------------------------------
    if (c.glfwInit() != c.GL_TRUE) {
        @panic("Failed to initialize GLFW\n");
    }
    defer c.glfwTerminate();
    // --------------------------------------------------------------------------------------------

    // OpenGL hint 설정
    // --------------------------------------------------------------------------------------------
    c.glfwWindowHint(c.GLFW_SAMPLES, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    // --------------------------------------------------------------------------------------------

    // 윈도우 생성
    // --------------------------------------------------------------------------------------------
    const window = c.glfwCreateWindow(1024, 768, "OpenGL Tutorial", null, null) orelse {
        @panic("Failed to create window GLFW\n");
    };
    defer c.glfwDestroyWindow(window);
    // --------------------------------------------------------------------------------------------

    // GLEW 세팅
    // --------------------------------------------------------------------------------------------
    // 현재 스레드에서 OpenGL 컨텍스트 활성화
    c.glfwMakeContextCurrent(window);

    // Core Profile 세팅
    c.glewExperimental = c.GL_TRUE;

    // GLEW 초기화
    if (c.glewInit() != c.GLEW_OK) {
        @panic("Failed to initialize GLEW\n");
    }
    // --------------------------------------------------------------------------------------------

    // Create Program
    // --------------------------------------------------------------------------------------------
    const program_id: c.GLuint = try loadShader("./glsl/simple_vertex_shader.glsl", "./glsl/simple_fragment_shader.glsl");
    defer c.glDeleteProgram().?(program_id);
    std.debug.print("[Is GL Program?] ->> {}\n", .{c.glIsProgram().?(program_id) == c.GL_TRUE});
    var s_count: c.GLsizei = undefined;
    var shaders: [3]c.GLuint = undefined;
    c.glGetAttachedShaders().?(program_id, 3, &s_count, &shaders);
    std.debug.print("[Attached Shader Count] ->> {}\n", .{s_count});
    std.debug.print("[Shaders] ->> {any}\n", .{shaders});
    std.debug.print("[position_loc] ->> {}\n", .{c.glGetAttribLocation().?(program_id, "position")});
    // --------------------------------------------------------------------------------------------

    // Vertex Array Object
    // --------------------------------------------------------------------------------------------
    var vertex_array_id: c.GLuint = undefined;
    c.glGenVertexArrays().?(1, &vertex_array_id);
    c.glBindVertexArray().?(vertex_array_id);
    // --------------------------------------------------------------------------------------------

    // Vertax Buffer
    // --------------------------------------------------------------------------------------------
    var vertex_buffer_data = [_]c.GLfloat{
        -1.0, -1.0, 0.0,
        1.0,  -1.0, 0.0,
        0.0,  1.0,  0.0,
    };
    var vertex_buffer: c.GLuint = undefined;
    const vertex_buffer_data_ptr: ?*anyopaque = &vertex_buffer_data;

    c.glGenBuffers().?(1, &vertex_buffer);
    c.glBindBuffer().?(c.GL_ARRAY_BUFFER, vertex_buffer);
    c.glBufferData().?(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertex_buffer_data)), vertex_buffer_data_ptr, c.GL_STATIC_DRAW);
    std.debug.print("[vertex_buffer] ->> {}\n", .{vertex_buffer});
    // --------------------------------------------------------------------------------------------

    // 입력 모드 설정
    c.glfwSetInputMode(window, c.GLFW_STICKY_KEYS, c.GL_TRUE); // 키보드 입력 모드

    //
    // --------------------------------------------------------------------------------------------
    while (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) != c.GLFW_PRESS and c.glfwWindowShouldClose(window) == 0) {
        // glClear 초기화 색상 설정
        c.glClearColor(0.0, 0.0, 0.0, 0.0);
        // 화면을 검정색 or glClearColor 설정 색으로 초기화
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        // 프로그램 사용 설정
        c.glUseProgram().?(program_id);

        // Draw
        // ----------------------------------------------------------------------------------------
        c.glEnableVertexAttribArray().?(0);
        c.glBindBuffer().?(c.GL_ARRAY_BUFFER, vertex_buffer);
        c.glVertexAttribPointer().?(
            0,
            3,
            c.GL_FLOAT,
            c.GL_FALSE,
            0,
            null,
        );

        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        c.glDisableVertexAttribArray().?(0);
        // ----------------------------------------------------------------------------------------

        // Swap buffers
        c.glfwSwapBuffers(window);
        // 이벤트 큐에 있는 이벤트 처리
        c.glfwPollEvents();
    }
    // --------------------------------------------------------------------------------------------
}

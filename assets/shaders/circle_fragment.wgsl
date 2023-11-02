@group(1) @binding(0)
var<uniform> normalized_data: array<vec4<f32>, 16>;

@group(1) @binding(1)
var<uniform> viewport_width: f32;
@group(1) @binding(2)
var<uniform> viewport_height: f32;

struct Globals {
    // The time since startup in seconds
    // Wraps to 0 after 1 hour.
    time: f32,
    // The delta time since the previous frame in seconds
    delta_time: f32,
    // Frame count since the start of the app.
    // It wraps to zero when it reaches the maximum value of a u32.
    frame_count: u32,
#ifdef SIXTEEN_BYTE_ALIGNMENT
    // WebGL2 structs must be 16 byte aligned.
    _wasm_padding: f32
#endif
}

@group(0) @binding(1)
var<uniform> globals: Globals;




fn value_to_color(value: f32) -> vec4<f32> {
    // Define colors
    let color1 = vec3<f32>(0.5, 0.0, 1.0); // Purple
    let color2 = vec3<f32>(0.0, 1.0, 1.0); // Cyan
    let color3 = vec3<f32>(1.0, 0.0, 0.0); // Red
    let color4 = vec3<f32>(1.0, 1.0, 0.0); // Yellow

    // Create a gradient based on the value
    var color: vec3<f32>;
    if (value < 0.33) {
        color = mix(color1, color2, value * 3.0);
    } else if (value < 0.66) {
        color = mix(color2, color3, (value - 0.33) * 3.0);
    } else {
        color = mix(color3, color4, (value - 0.66) * 3.0);
    }

    // Return the color with full opacity
    return vec4<f32>(color, 1.0);
}




@fragment
fn fragment(
    @builtin(position) coord: vec4<f32>,
    @location(0) world_position: vec4<f32>,
    @location(1) normals: vec3<f32>,
    @location(2) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    let aspect_ratio = viewport_width / viewport_height;
    
    // Set the center of the circle to be the middle of the UV space, adjusted for aspect ratio
    let center = vec2<f32>(0.5, 0.5);

    // Calculate the angle from the current UV coordinate to the center
    let angle_uv = atan2(uv.y - center.y, uv.x - center.x);
    var angle_uv_positive = angle_uv;
    if (angle_uv < 0.0) {
        angle_uv_positive += 2.0 * 3.14159;
    }

    // Determine the index based on the angle (64 sections)
    let index = i32(angle_uv_positive / (2.0 * 3.14159) * 64.0);

    // Calculate which component of vec4<f32> to use
    let component_index = index % 4;
    let array_index = index / 4;

    // Extract the correct audio value from the normalized_data array
    let audio_value = normalized_data[array_index][component_index];

    // Define a radius based on the audio_value
    let radius = 0.1 + audio_value * 0.2;

    // Correct the UV coordinates based on the aspect ratio
    let uv_corrected = vec2<f32>(uv.x, uv.y * aspect_ratio);

    // Calculate distance from the UV coordinate to the center
    let distance_to_center = distance(center, uv) * aspect_ratio;

    // Determine if the current UV coordinate is within the circle's radius
    if (distance_to_center < radius) {
        return value_to_color(audio_value);
    } else {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0); // Black color
    }
}


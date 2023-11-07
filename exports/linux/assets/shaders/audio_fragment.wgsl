@group(1) @binding(0)
var<uniform> normalized_data: array<vec4<f32>, 16>;

@group(1) @binding(1)
var<uniform> viewport_width: f32;
@group(1) @binding(2)
var<uniform> viewport_height: f32;

@group(1) @binding(4)
var<uniform> monochrome: u32;

@group(1) @binding(5)
var<uniform> colors: array<vec4<f32>, 4>;



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



fn value_to_monochrome(value: f32) -> vec3<f32> {
    // Define a grayscale value by setting all color components to the value
    let grayscale = value; // Value between 0.0 (black) and 1.0 (white)

    // Create a color vector using the grayscale value for all components
    let color = vec3<f32>(grayscale, grayscale, grayscale);

    // Return the color with full opacity
    return color;
}
fn value_to_color(value: f32) -> vec3<f32> {
    // Define start, middle, and end colors for the gradient
    let start_color = vec3<f32>(colors[0].x, colors[0].y, colors[0].z); // Blue
    let middle_color = vec3<f32>(colors[1].x, colors[1].y, colors[1].z); // Green
    let end_color = vec3<f32>(colors[2].x, colors[2].y, colors[2].z); // Red

    // Declare a variable for the color
    var color: vec3<f32>;

    // Use an if statement to determine which gradient range to use
    if (value < 0.5) {
        color = mix(start_color, middle_color, value * 2.0);
    } else {
        color = mix(middle_color, end_color, (value - 0.5) * 2.0);
    }

    // Return the color with full opacity
    return color;
}





@fragment
fn fragment(
    @builtin(position) coord: vec4<f32>,
    @location(0) world_position: vec4<f32>,
    @location(1) normals: vec3<f32>,
    @location(2) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    //return vec4<f32>(uv.x, uv.y, 0.0, 1.0);
    var vec_index = i32(uv.x * 64.0);
    vec_index = clamp(vec_index, 0, 63);

    // Calculate which component of vec4 and which array to use
    let array_index = vec_index / 4;
    let component_index = vec_index % 4;

    // Assuming normalized_data is a two-dimensional array declared as:
    var audio_value: f32 = normalized_data[array_index][component_index];

    // Calculate bar height and flip y coordinate system
    let bar_height = audio_value * 0.8; // Scale the bar height to 80%
    let flipped_y = 1.0 - uv.y;

    // Get the color based on the audio value
    var color: vec3<f32>;
    if (monochrome == 1u){
        color = value_to_color(audio_value * ((-(uv.y * 0.8) + 1.0) + 0.2));

    }else{
        color = value_to_monochrome(audio_value);
    }


    // Calculate the dynamic bar width based on the audio value
    let bar_width = mix(0.02, 0.1, audio_value); // Linearly interpolate between min and max widths
    let half_bar_width = bar_width * 0.5;

    // Calculate the x position relative to the center of the screen
    let centered_x = uv.x - 0.5;


    
    // Soft edges using smoothstep function
    let edge_softness = 0.01; // Edge softness value
    let alpha = smoothstep(0.0, edge_softness, bar_height - flipped_y);
    
    // Draw the bar with soft edges
    if (flipped_y <= bar_height) {
        return vec4<f32>(color.x, color.y, color.z, alpha);
    } else {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0); // Draw black if above the bar height
    }
}

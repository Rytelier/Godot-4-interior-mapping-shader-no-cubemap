shader_type spatial;
render_mode depth_draw_opaque, cull_back;
uniform sampler2D roomTexture : source_color, hint_default_black, filter_linear_mipmap;
uniform sampler2D roomEmit : source_color, hint_default_black, filter_linear_mipmap;
uniform vec4 albedo : source_color = vec4(1,1,1,1);
uniform vec4 emission : source_color;
uniform float emissionEnergy = 1;
uniform ivec2 roomTiles = ivec2(4,2);
uniform vec2 depthRemap = vec2(3,3);
uniform float seed;

varying vec3 tangentViewDir;

void vertex()
{
	vec3 cam_pos = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz; //object space
	vec3 view_dir = VERTEX - cam_pos;
	vec3 bitangent = normalize(cross(TANGENT, NORMAL));

	// get tangent space camera vector
	tangentViewDir = vec3(
		dot(view_dir, TANGENT),
		dot(view_dir, bitangent),
		dot(view_dir, NORMAL));
}

void fragment()
{
	vec2 _Rooms = vec2(float(roomTiles.x), float(roomTiles.y));

	// room uvs
	vec2 roomUV = fract(UV);
	vec2 roomIndexUV = floor(UV);
	vec2 co = roomIndexUV.x + roomIndexUV.y * (roomIndexUV.x + vec2(1));
	vec2 rand2 = fract(sin(co * (vec2(12.9898,78.233))+vec2(seed*0.74352, seed*16.2456)) * (43758.5453));

	// randomize the room
	vec2 n = floor(rand2 * _Rooms.xy);
	roomIndexUV += n;

	// get room depth from room atlas alpha
	float farFrac = texture(roomTexture, (roomIndexUV + 0.5) / _Rooms).a;
	
	float depthMult = mix(depthRemap.y * -1. + 4., depthRemap.x * -1. + 4., farFrac);
	
	float depthScale = 1.0 / (1.0 - farFrac) - 1.0;
	depthScale *= depthMult;

	// raytrace box from view dir
	vec3 view_dir = tangentViewDir;
	
	vec3 pos = vec3(roomUV * vec2(2) - vec2(1), -1.);
	view_dir.z *= -depthScale;
	vec3 id = 1.0 / view_dir;
	vec3 k = abs(id) - pos * id;
	float kMin = min(min(k.x, k.y), k.z);
	pos += kMin * view_dir;

	// 0.0 - 1.0 room depth
	float interp = pos.z * 0.5 + 0.5;

	// account for perspective in room textures
	// assumes camera with an fov of 53.13 degrees (atan(0.5))
	float realZ = clamp(interp, 0, 1) / depthScale + 1.;
	interp = 1.0 - (1.0 / realZ);
	interp *= depthScale + 1.0;

	// iterpolate from wall back to near wall
	vec2 interiorUV = pos.xy * mix(1.0, farFrac, interp);
	interiorUV = interiorUV * 0.5 + 0.5;

	// sample room atlas texture
	vec4 room = texture(roomTexture, (roomIndexUV + interiorUV.xy) / _Rooms);
	vec4 roomem = texture(roomEmit, (roomIndexUV + interiorUV.xy) / _Rooms) * emissionEnergy;
	
	SPECULAR = 0.;
	ALBEDO = room.rgb * albedo.rgb;
	EMISSION = roomem.rgb * emission.rgb;
}

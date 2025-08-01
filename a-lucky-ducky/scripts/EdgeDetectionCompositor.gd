@tool
class_name EdgeDectionCompositor
extends CompositorEffect

var rd: RenderingDevice
var shader: RID
var pipeline: RID
var parameter_storage_buffer := RID()


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()
	RenderingServer.call_on_render_thread(_initialize_compute)
	
	var data := PackedFloat32Array()
	data.resize(20)
	data.fill(0)
	var parameter_data := data.to_byte_array()
	parameter_storage_buffer = rd.storage_buffer_create(parameter_data.size(), parameter_data)
	


# System notifications, we want to react on the notification that
# alerts us we are about to be destroyed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			# Freeing our shader will also free any dependents such as the pipeline!
			rd.free_rid(shader)


#region Code in this region runs on the rendering thread.
# Compile our shader at initialization.
func _initialize_compute() -> void:
	rd = RenderingServer.get_rendering_device()
	if not rd:
		return

	# Compile our shader.
	var shader_file := load("res://shaders/edge_detection_shader.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()

	shader = rd.shader_create_from_spirv(shader_spirv)
	if shader.is_valid():
		pipeline = rd.compute_pipeline_create(shader)


# Called by the rendering thread every frame.
func _render_callback(p_effect_callback_type: EffectCallbackType, p_render_data: RenderData) -> void:
	if rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT and pipeline.is_valid():
		# Get our render scene buffers object, this gives us access to our render buffers.
		# Note that implementation differs per renderer hence the need for the cast.
		var render_scene_buffers := p_render_data.get_render_scene_buffers()
		if render_scene_buffers:
			# Get our render size, this is the 3D render resolution!
			var size = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return

			# We can use a compute shader here.
			@warning_ignore("integer_division")
			var x_groups : int = (size.x - 1.0) / 8.0 + 1.0
			@warning_ignore("integer_division")
			var y_groups : int = (size.y - 1.0) / 8.0 + 1.0
			var z_groups := 1.0


			# Loop through views just in case we're doing stereo rendering. No extra cost if this is mono.
			var view_count: int = render_scene_buffers.get_view_count()
			for view in view_count:
				# Get the RID for our color image, we will be reading from and writing to it.
				var input_image: RID = render_scene_buffers.get_color_layer(view)
				var input_depth: RID = render_scene_buffers.get_depth_layer(view)
				var input_normal: RID = render_scene_buffers.get_texture("forward_clustered","normal_roughness")
			
				var texture_sampler = RDSamplerState.new()
				texture_sampler = rd.sampler_create(texture_sampler)
				
				
				var parameters := PackedFloat32Array([size.x, size.y, 0.0, 0.0])
				var inv_proj_mat := p_render_data.get_render_scene_data().get_cam_projection().inverse()
				var inv_proj_mat_array := PackedVector4Array([inv_proj_mat.x, inv_proj_mat.y, inv_proj_mat.z, inv_proj_mat.w])
	
				var parameter_data := parameters.to_byte_array()
				parameter_data.append_array(inv_proj_mat_array.to_byte_array())
				rd.buffer_update(parameter_storage_buffer, 0, parameter_data.size(), parameter_data)
		
				var uniform_parameter := RDUniform.new()
				uniform_parameter.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
				uniform_parameter.binding = 0
				uniform_parameter.add_id(parameter_storage_buffer)
				
				# Create a uniform set, this will be cached, the cache will be cleared if our viewports configuration is changed.
				var uniform_color := RDUniform.new()
				uniform_color.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				uniform_color.binding = 1
				uniform_color.add_id(input_image)
				
				var uniform_depth := RDUniform.new()
				uniform_depth.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				uniform_depth.binding = 2
				uniform_depth.add_id(texture_sampler)
				uniform_depth.add_id(input_depth)

				var uniform_normal := RDUniform.new()
				uniform_normal.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				uniform_normal.binding = 3
				uniform_normal.add_id(texture_sampler)
				uniform_normal.add_id(input_normal)
				
				
				var uniform_set := UniformSetCacheRD.get_cache(shader, 0, [uniform_parameter, uniform_color, uniform_depth, uniform_normal])
				
 
				# Run our compute shader.
				var compute_list := rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
				rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
				#rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
#endregion

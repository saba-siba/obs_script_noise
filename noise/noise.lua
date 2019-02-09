obs = obslua
bit = require("bit")


source_def = {}
source_def.id = 'filter-noise'
source_def.type = obs.OBS_SOURCE_TYPE_FILTER
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO)

function set_render_size(filter)
    target = obs.obs_filter_get_target(filter.context)

    local width, height
    if target == nil then
        width = 0
        height = 0
    else
        width = obs.obs_source_get_base_width(target)
        height = obs.obs_source_get_base_height(target)
    end

    filter.width = width
    filter.height = height
    width = width == 0 and 1 or width
    height = height == 0 and 1 or height
    filter.pix_size.x = 1.0 / width
    filter.pix_size.y = 1.0 / height
end

source_def.get_name = function()
    return "noise"
end

source_def.create = function(settings, source)
    local effect_path = script_path() .. 'noise.effect'

	--パラメーターの初期化
	--filterに代入する前の値
	--filiter.paramsに代入した値をエフェクトに渡す
    filter = {}
    filter.params = {}
    filter.context = source
    filter.pix_size = obs.vec2()
	filter.distance=0
	filter.distance_min=0
	filter.period=1.0
	filter.speed=1.0
	filter.timer=0

    set_render_size(filter)

    obs.obs_enter_graphics()
    filter.effect = obs.gs_effect_create_from_file(effect_path, nil)
    if filter.effect ~= nil then
        filter.params.pix_size = obs.gs_effect_get_param_by_name(filter.effect, 'pix_size')
		filter.params.distance = obs.gs_effect_get_param_by_name(filter.effect, 'distance')
		filter.params.distance_min = obs.gs_effect_get_param_by_name(filter.effect, 'distance_min')
		filter.params.period = obs.gs_effect_get_param_by_name(filter.effect, 'period')
		filter.params.speed = obs.gs_effect_get_param_by_name(filter.effect, 'speed')
		filter.params.timer = obs.gs_effect_get_param_by_name(filter.effect, 'timer')


    end
    obs.obs_leave_graphics()
    
    if filter.effect == nil then
        source_def.destroy(filter)
        return nil
    end

    source_def.update(filter, settings)
    return filter
end

source_def.destroy = function(filter)
    if filter.effect ~= nil then
        obs.obs_enter_graphics()
        obs.gs_effect_destroy(filter.effect)
        obs.obs_leave_graphics()
    end
end

source_def.get_width = function(filter)
    return filter.width
end

source_def.get_height = function(filter)
    return filter.height
end

source_def.update = function(filter, settings)
    filter.distance=obs.obs_data_get_int(settings, 'distance')
	filter.distance_min=obs.obs_data_get_int(settings, 'distance_min')
	filter.period=obs.obs_data_get_double(settings, 'period')
	filter.speed=obs.obs_data_get_double(settings, 'speed')

end

source_def.video_render = function(filter, effect)
    obs.obs_source_process_filter_begin(filter.context, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
	obs.gs_effect_set_vec2(filter.params.pix_size, filter.pix_size)
    obs.gs_effect_set_int(filter.params.distance,filter.distance)
	obs.gs_effect_set_int(filter.params.timer,filter.timer)
	obs.gs_effect_set_int(filter.params.distance_min,filter.distance_min)
	obs.gs_effect_set_float(filter.params.period,filter.period)
	obs.gs_effect_set_float(filter.params.speed,filter.speed)
    obs.obs_source_process_filter_end(filter.context, filter.effect, filter.width, filter.height)

	filter.timer=filter.timer+1
	if filter.timer > 3600 then
		filter.timer=0
	end
end

source_def.get_properties = function(settings)
	props = obs.obs_properties_create()
	obs.obs_properties_add_int_slider(props,'distance_min','ordinary noise', 0, 150, 1)
    obs.obs_properties_add_int_slider(props,'distance','deviation width max', 0, 500, 1)
	obs.obs_properties_add_float_slider(props,'period','frequency', 0, 40, 0.1)
	obs.obs_properties_add_float_slider(props,'speed','speed', -10, 10, 0.1)
	return props
end

source_def.get_defaults = function(settings)
   obs.obs_data_set_default_int(settings,'distance', 35)
   obs.obs_data_set_default_int(settings,'distance_min', 13)
   obs.obs_data_set_default_double(settings,'period', 1.0)
   obs.obs_data_set_default_double(settings,'speed', 1.0)
end

source_def.video_tick = function(filter, seconds)
    set_render_size(filter)
end

obs.obs_register_source(source_def)

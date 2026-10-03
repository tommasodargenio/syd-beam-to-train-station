--[[
     Beam-To-Train-Station
     a Factorio mod.
     (C) SyDream - 2024/26 - v2.0.2

     https://github.com/tommasodargenio/syd-beam-to-train-station
     https://mods.factorio.com/mod/syd-beam-to-train-station
     
    
    CONTROL.LUA
    -- Core of the mod includes all the runtime scripting
--]]
teleport_ts_win = {type="frame",  name="teleport-ts-gui", direction="vertical", header_filler_style={type="empty_widget_style", parent="draggable_space_header", height=24}, use_header_filler=true}

train_station_filter = ""
teleport_gui = nil
gui_location = nil
last_teleported_station = nil
last_teleported_station_count = 0
is_homonyms = false

function train_station_teleport(player_idx, station_selected)
    local player = game.players[player_idx]
    local destination_surface = player.surface
    local train_stations_list = get_train_stations_list(destination_surface, train_station_filter)
    local train_station_position = nil

    local destination_pos = nil
    if (station_selected > table_size(train_stations_list)) then return end
   
    train_station_position = train_stations_list[station_selected].position

    if last_teleported_station == train_stations_list[station_selected].name then
        train_station_position = get_next_train_station(player.surface, train_stations_list[station_selected].name, last_teleported_station_count)
    else
        last_teleported_station = nil
        last_teleported_station_count = 0
    end

    local filter_toggle = false
    if train_station_filter ~= "" then
        filter_toggle = true
    end

    local player_x_buffer = settings.get_player_settings(player_idx)["teleport-ts-x-distance-displacement"].value
    local player_y_buffer = settings.get_player_settings(player_idx)["teleport-ts-y-distance-displacement"].value

    local player_new_position_search_area = {train_station_position.x + player_x_buffer, train_station_position.y + player_y_buffer}

    if train_station_position ~= nil then
        if player.vehicle and player.vehicle.valid and player.vehicle.type=="spider-vehicle" then
            player.surface.play_sound({path="utility/cannot_build"})
        elseif player.vehicle and player.vehicle.valid and player.vehicle.type=="car" then
            if math.floor(player.vehicle.position.x + 0.5) ~= math.floor(train_station_position.x + 0.5) or
               math.floor(player.vehicle.position.y + 0.5) ~= math.floor(train_station_position.y + 0.5) then
                destination_pos = destination_surface.find_non_colliding_position(player.vehicle.prototype.name, player_new_position_search_area, 10, 1)
                if not destination_pos then destination_pos = train_station_position end
                player.vehicle.teleport(destination_pos, destination_surface)
                last_teleported_station = train_stations_list[station_selected].name
                last_teleported_station_count = get_next_station_count(destination_surface, last_teleported_station, last_teleported_station_count)
            end
        elseif player.character and player.character.valid then
			if math.floor(player.position.x + 0.5) ~= math.floor(train_station_position.x + 0.5) or
               math.floor(player.position.y + 0.5) ~= math.floor(train_station_position.y + 0.5) then
                destination_pos =  destination_surface.find_non_colliding_position(player.character.prototype.name, player_new_position_search_area, 10, 1)
                if not  destination_pos then  destination_pos = train_station_position end
                player.teleport(destination_pos, destination_surface)
                last_teleported_station = train_stations_list[station_selected].name
                last_teleported_station_count = get_next_station_count(destination_surface, last_teleported_station, last_teleported_station_count)
            end
        elseif player and player.valid then
			player.teleport(player_new_position_search_area)
            last_teleported_station = train_stations_list[station_selected].name
            last_teleported_station_count = get_next_station_count(destination_surface, last_teleported_station, last_teleported_station_count)
        end
    end
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function get_next_station_count(player_surface, station_name, current_count)
    current_count = current_count + 1
    if current_count >= count_train_homonyms(player_surface, station_name) then
        current_count = 0
    end  
    return current_count
end


function get_next_train_station(player_surface, station_name, which)
    local t = game.train_manager.get_train_stops({player_surface})
    local count = 0
    for _, train_station in pairs(t) do
        if train_station.backer_name == station_name then
            if count == which then
                return train_station.position
            else
                count = count + 1
            end
        end
    end
end

function count_train_homonyms(player_surface, station_name)
    local t =  game.train_manager.get_train_stops({player_surface})
    local count = 0
    for _, train_station in pairs(t) do
        if train_station.backer_name == station_name then
                count = count + 1
        end
    end

    return count
end


function are_there_station_homonyms(player_surface)
    local t =  game.train_manager.get_train_stops({player_surface})
    local checkerTbl = {}
    for _, element in ipairs(t) do
        if not checkerTbl[element.backer_name] then
            checkerTbl[element.backer_name] = true
        else
            return true
        end
    end
    return false
end


function get_train_stations_list(player_surface, train_filter) 
    if not player_surface or not player_surface.valid then
        return {}
    end

    local train_stations = {}
    local train_stations_ordered = {}
    local train_station_names = {}
    -- Only collect train stops on the current surface.
    local t = game.train_manager.get_train_stops({player_surface})

    for _, train_station in pairs(t) do
		if not has_value(train_station_names,train_station.backer_name) then
			table.insert(train_stations, {name=train_station.backer_name, position=train_station.position})
			table.insert(train_station_names, train_station.backer_name)
		end
	end
    table.sort(train_station_names)

    for _, name in pairs(train_station_names) do 
        for _, train_station in pairs(train_stations) do 
            if (train_station.name == name) then
                if (train_filter and train_filter ~= "") then 
                    if (string.match(train_station.name:lower(), train_filter:lower())) then
                        table.insert(train_stations_ordered, train_station)
                    end
                else
                    table.insert(train_stations_ordered, train_station)
                end
                
                break
            end
        end
    end

    return train_stations_ordered
end

function get_train_stations_name(train_stations_list)
    local train_stations_names = {}

    if (table_size(train_stations_list)>0) then
        for _, train_station in pairs(train_stations_list) do
            table.insert(train_stations_names, train_station.name)
        end 
    end
    return train_stations_names
end


local function is_teleport_gui_open(player_index)
    local player = game.get_player(player_index)
    return player and player.valid and player.gui.screen["teleport-ts-gui"] ~= nil
end

local function close_teleport_gui(player_index)
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end
    local gui = player.gui.screen["teleport-ts-gui"]
    if gui then
        gui_location = gui.location
        gui.destroy()
    end
end

function teleport_ts_shortcut(event) 
    if event.prototype_name == "teleport-ts-button-shortcut" then
        on_hotkey_main(event)
    end
end

function on_hotkey_main(event)
    if is_teleport_gui_open(event.player_index) then
        close_teleport_gui(event.player_index)
    else
        draw_gui(event.player_index, nil, false, true)
    end
end

function draw_gui(player_index, train_station_filter, filter_toggle, firstLoad, is_homonyms)
    local gui = game.get_player(player_index).gui
    local player_surface = game.get_player(player_index).surface
    local train_station_list = nil
    resyncTeleportGui(player_index)

    if train_station_filter then
        train_station_list = get_train_stations_name(get_train_stations_list(player_surface, train_station_filter))
    else
        train_station_list = get_train_stations_name(get_train_stations_list(player_surface))
    end  
        
    teleport_gui_draw(gui, train_station_list, filter_toggle, firstLoad, player_index, is_homonyms)
end

function teleport_gui_draw(gui, train_stations_list, filter_toggle, firstLoad, player_index, is_homonyms)
    local teleport_ts_btn = nil 
    
    if gui.screen["teleport-ts-gui"] then
        return
    end
    local player_surface = game.get_player(player_index).surface
    teleport_gui = gui.screen.add(teleport_ts_win)

    local title_flow = teleport_gui.add{type = "flow", name="title_flow"}
    local title = title_flow.add{type = "label", name="teleport-ts-gui-title-label", caption={"mod-interface.teleport-ts-gui-title-caption"}, style="frame_title"}
    title.drag_target = teleport_gui

    local pusher = nil
    pusher = title_flow.add{type = "empty-widget", name="teleport-ts-gui-draggable-space-header",style="draggable_space_header"}
    pusher.style.vertically_stretchable = true
    pusher.style.horizontally_stretchable = true
    pusher.drag_target = teleport_gui

    if (filter_toggle == true) then
        title_flow.add{type="textfield", name="teleport-ts-gui-dd-filter-query", style="teleport_ts_gui_dd_filter_query"}
        title_flow["teleport-ts-gui-dd-filter-query"].focus()
        title_flow["teleport-ts-gui-dd-filter-query"].text = train_station_filter
    end

    title_flow.add{type="sprite-button", style="frame_action_button", sprite="utility/search", name="teleport-ts-gui-toggle-filter"}
    title_flow.add{type="sprite-button", style="frame_action_button", sprite="utility/close", name="close-teleport-ts-window"}

    if (table_size(train_stations_list)>0) then
        local station_list_size = settings.get_player_settings(player_index)["teleport-ts-station-list-vertical-size"].value
        local ts_dropdown_style = ""
        if ( station_list_size == 10) then
            ts_dropdown_style = "teleport_ts_dropdown_style_10"
        elseif (station_list_size == 20) then
            ts_dropdown_style = "teleport_ts_dropdown_style_20"
        elseif (station_list_size == 30) then
            ts_dropdown_style = "teleport_ts_dropdown_style_30"
        elseif (station_list_size == 40) then
            ts_dropdown_style = "teleport_ts_dropdown_style_40"
        end
       
        local dropdown_items = {{"mod-interface.teleport-ts-select-station"}}
        for _, station_name in ipairs(train_stations_list) do
            table.insert(dropdown_items, station_name)
        end
        local teleport_ts_dropdown = {type="drop-down", name="teleport-ts-gui-dd", style=ts_dropdown_style, items=dropdown_items, selected_index=1}

        local dd_flow = teleport_gui.add{type="flow", name="dd_flow"}            
        dd_flow.add{type="label", name="teleport-ts-gui-dd-label", caption={"mod-interface.teleport-ts-gui-dd-caption"}}
        dd_flow.add(teleport_ts_dropdown)

        local instant_beam = settings.get_player_settings(player_index)["teleport-ts-instant-beam"].value
        if not instant_beam then
            if count_train_homonyms(player_surface, train_stations_list[1]) > 1 or is_homonyms then
                teleport_ts_btn = {type="button", name="teleport-ts-gui-btn", caption={"mod-interface.teleport-ts-button-more"}}
            else
                teleport_ts_btn = {type="button", name="teleport-ts-gui-btn", caption={"mod-interface.teleport-ts-button"}}
            end
            dd_flow.add(teleport_ts_btn)
        end
    else 
        local dd_flow = teleport_gui.add{type="flow", name="dd_flow"}
        dd_flow.add{type="label",  caption={"mod-interface.teleport-ts-gui-dd-empty-caption"}}
    end 
    
    if (firstLoad==true) then  
        teleport_gui.location = {300, 250}    
    elseif (gui_location ~= nil) then 
        teleport_gui.location = gui_location
    end
end


function guiElementContains(haystack, needle)
    for _, item in pairs(haystack) do
        if (item.name==needle) then 
            return true        
        end 
    end  
    return false
end

function cleanGUI()
    if game.get_player(1) == nil then
        return
    end
    local screenGui = game.get_player(1).gui.screen
    if table_size(screenGui.children)>0 then      
        if screenGui["teleport-ts-gui"] ~= nil then   
            local leftoverTSGui = screenGui.children[1]
            leftoverTSGui.destroy()
        end
    end    
    train_station_filter = ""
end

function resyncTeleportGui(player_index)
    if game.get_player(player_index).gui.screen["teleport-ts-gui"] ~= nil then
        teleport_gui = game.get_player(player_index).gui.screen["teleport-ts-gui"]
    end
end



script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    if (event.element.name=="teleport-ts-gui-dd") then
        local gui_win = game.players[event.player_index].gui.screen["teleport-ts-gui"]
        local player_surface = game.players[event.player_index].surface
        local station_selected = gui_win.dd_flow["teleport-ts-gui-dd"].selected_index - 1
        local station_list = get_train_stations_list(player_surface, train_station_filter)
        if station_selected < 1 or not station_list[station_selected] then
            return
        end
        if settings.get_player_settings(event.player_index)["teleport-ts-instant-beam"].value then
            train_station_teleport(event.player_index, station_selected)
            gui_win.dd_flow["teleport-ts-gui-dd"].selected_index = 1
            return
        end
        local total_stations = count_train_homonyms(player_surface, station_list[station_selected].name)
        if total_stations > 1 then
            gui_win.dd_flow["teleport-ts-gui-btn"].caption={"mod-interface.teleport-ts-button-more"}
        else
            gui_win.dd_flow["teleport-ts-gui-btn"].caption={"mod-interface.teleport-ts-button"}
        end
        
    end
end)


script.on_event(defines.events.on_gui_text_changed, function(event)
    if (event.element.name=="teleport-ts-gui-dd-filter-query") then         
        train_station_filter = event.element.text
        resyncTeleportGui(event.player_index)
        if (teleport_gui ~= nil) then 
            gui_location = teleport_gui.location
            teleport_gui.destroy()
        end
        draw_gui(event.player_index, train_station_filter, true, false)      
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    resyncTeleportGui(event.player_index)   
    if (event.element.name=="teleport-ts-gui-btn") then
        local gui_win = game.players[event.player_index].gui.screen["teleport-ts-gui"]
        local station_selected = gui_win.dd_flow["teleport-ts-gui-dd"].selected_index - 1
        if station_selected < 1 then
            return
        end
        train_station_teleport(event.player_index, station_selected)

    elseif (event.element.name=="teleport-ts-gui-toggle-filter") then
        local gui_win = game.players[event.player_index].gui.screen["teleport-ts-gui"].title_flow
        if (guiElementContains(gui_win.children, "teleport-ts-gui-dd-filter-query")) then
            if (teleport_gui ~= nil) then 
                gui_location = teleport_gui.location
                teleport_gui.destroy()
            end
            draw_gui(event.player_index, nil, false, false)
        else
            if (teleport_gui ~= nil) then 
                gui_location = teleport_gui.location
                teleport_gui.destroy()
            end          
            draw_gui(event.player_index, train_station_filter, true, false)
        end
    elseif (event.element.name=="close-teleport-ts-window") then
        if (teleport_gui ~= nil) then 
            teleport_gui.destroy()
            train_station_filter = ""
        else 
            cleanGUI()
        end
    elseif (event.element.name=="toggleTeleportTS") then
        draw_gui(event.player_index, nil, false, true)     
    end    
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
    local player = game.players[event.player_index]
    if player.gui.screen["teleport-ts-gui"] then
        if (teleport_gui ~= nil) then 
            gui_location = teleport_gui.location
            teleport_gui.destroy()
        end          
        draw_gui(event.player_index, nil, false, false)
    end
    
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    if player.gui.screen["teleport-ts-gui"] then
        if (teleport_gui ~= nil) then 
            gui_location = teleport_gui.location
            teleport_gui.destroy()
        end          
        draw_gui(event.player_index, nil, false, false)
    end
    
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    if player.gui.screen["teleport-ts-gui"] then
        if (teleport_gui ~= nil) then 
            gui_location = teleport_gui.location
            teleport_gui.destroy()
        end          
        draw_gui(event.player_index, nil, false, false)
    end
    
end)

script.on_configuration_changed(function (changes)
    cleanGUI() 
end)

script.on_event("teleport-to-train-station-hotkey", on_hotkey_main)

script.on_event(defines.events.on_lua_shortcut, teleport_ts_shortcut)

local function rebuild_teleport_gui(player_index, gui)
    local current_filter = train_station_filter
    local filter_is_visible = gui.title_flow["teleport-ts-gui-dd-filter-query"] ~= nil
    local selected_station_name = nil

    if gui.dd_flow and gui.dd_flow["teleport-ts-gui-dd"] then
        local dropdown = gui.dd_flow["teleport-ts-gui-dd"]
        local current_items = dropdown.items
        if dropdown.selected_index and dropdown.selected_index > 1 and
           current_items and dropdown.selected_index <= #current_items then
            -- Read the selected name from the GUI before rebuilding. The station
            -- list may already have changed (for example after a rename), so
            -- looking it up again by index can select the wrong station.
            selected_station_name = current_items[dropdown.selected_index]
        end
    end

    gui_location = gui.location
    gui.destroy()
    draw_gui(player_index, current_filter, filter_is_visible, false)

    if selected_station_name then
        local new_gui = game.players[player_index].gui.screen["teleport-ts-gui"]
        if new_gui and new_gui.dd_flow and new_gui.dd_flow["teleport-ts-gui-dd"] then
            local new_train_stations_list = get_train_stations_list(game.players[player_index].surface, train_station_filter)
            for i, station in ipairs(new_train_stations_list) do
                if station.name == selected_station_name then
                    -- Index 1 is reserved for the placeholder item.
                    new_gui.dd_flow["teleport-ts-gui-dd"].selected_index = i + 1
                    break
                end
            end
        end
    end
end

function auto_update_gui(player_index)
    local player = game.players[player_index]
    if not player or not player.valid then return end

    local gui = player.gui.screen["teleport-ts-gui"]
    if not gui or not gui.dd_flow then return end

    -- Rebuild the whole frame instead of only assigning dropdown.items. This
    -- also handles the empty-list -> non-empty-list transition and vice versa.
    rebuild_teleport_gui(player_index, gui)
end

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting ~= "teleport-ts-instant-beam" then
        return
    end

    local player = game.players[event.player_index]
    local gui = player and player.gui.screen["teleport-ts-gui"]
    if gui then
        rebuild_teleport_gui(event.player_index, gui)
    end
end)

local function refresh_open_teleport_guis()
    for _, player in pairs(game.players) do
        if player.valid and player.gui.screen["teleport-ts-gui"] then
            auto_update_gui(player.index)
        end
    end
end

local station_refresh_pending = false

local function schedule_station_list_refresh()
    if station_refresh_pending then
        return
    end

    station_refresh_pending = true

    -- TrainManager can finish updating its station index after the entity
    -- event is raised. Refresh on the following tick so the new index is used.
    script.on_event(defines.events.on_tick, function()
        if not station_refresh_pending then
            return
        end

        station_refresh_pending = false
        script.on_event(defines.events.on_tick, nil)
        refresh_open_teleport_guis()
    end)
end

local function on_train_stop_changed(event)
    local entity = event.entity or event.created_entity
    if not entity or not entity.valid or (entity.name ~= "train-stop" and entity.type ~= "train-stop") then
        return
    end
    schedule_station_list_refresh()
end

script.on_event({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.on_pre_player_mined_item,
    defines.events.on_robot_pre_mined,
    defines.events.on_entity_died,
    defines.events.on_entity_renamed,
}, on_train_stop_changed)
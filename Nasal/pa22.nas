######
#
# Fuel system
#
######


# Fuel valve selector

var fuel_valve = props.globals.getNode("/controls/fuel/fuel-valve-pos", 1);

var handle_up = func {
    var handle = fuel_valve.getValue() + 1;
    if (handle == 2) {handle = -1};
    fuel_valve.setValue(handle);
    set_tanks(handle);
}

var handle_down = func {
    var handle = fuel_valve.getValue() - 1;
    if (handle == -2) {handle = 1};
    fuel_valve.setValue(handle);
    set_tanks(handle);
}

var set_tanks = func(position) {
    var valve_left = props.globals.getNode("/consumables/fuel/tank[0]/selected");
    var valve_right = props.globals.getNode("/consumables/fuel/tank[1]/selected");
    var out_of_fuel = props.globals.getNode("/engines/engine/out-of-fuel");
    if (position == -1) {
        valve_left.setValue(0);
        valve_right.setValue(0);
    } elsif (position == 0) {
        valve_left.setValue(1);
        valve_right.setValue(0);
        out_of_fuel.setValue(0);
    } elsif (position == 1) {
        valve_left.setValue(0);
        valve_right.setValue(1);
        out_of_fuel.setValue(0);
    }
}


# Primer

var primer = props.globals.getNode("/controls/engines/engine[0]/primer-pump",1);
var out_of_fuel = props.globals.getNode("/engines/engine/out-of-fuel", 1);

var primer_check = func {
	if(primer.getValue() < 6) {
		out_of_fuel.setValue(1);
		out_of_fuel.setAttribute("writable", 0);
	} else {out_of_fuel.setAttribute("writable", 1);}
	    if(fuel_valve.getValue() != -1) {
	        out_of_fuel.setValue(0);
	}
}

var primer_pump_switch = func (v = 1) {
    if(fuel_valve.getValue() == -1) {
        return;
    } else {primer.setValue(primer.getValue() + v);}
}


# Load saved fuel level on sim initialization

var tank_0 = props.globals.getNode("/consumables/fuel/tank[0]/level-gal_us", 1);
var tank_1 = props.globals.getNode("/consumables/fuel/tank[1]/level-gal_us", 1);
var copy_0 = props.globals.getNode("/sim/model/fuel/tank[0]/level-gal_us", 1);
var copy_1 = props.globals.getNode("/sim/model/fuel/tank[1]/level-gal_us", 1);

var update_fuel = func {

    if (copy_0.getValue() != nil) {
        tank_0.setValue(copy_0.getValue());
    }
    if (copy_1.getValue() != nil) {
        tank_1.setValue(copy_1.getValue());
    }

    setlistener("/consumables/fuel/tank[0]/level-gal_us", func {
        copy_0.setValue(tank_0.getValue());
    });

    setlistener("/consumables/fuel/tank[1]/level-gal_us", func {
        copy_1.setValue(tank_1.getValue());
    });
}

################################################################################

# Record engine's running time

var hours = props.globals.getNode("/engines/engine[0]/hours-running", 1);
var rpm = props.globals.getNode("/engines/engine[0]/rpm", 1);
var magnetos = props.globals.getNode("/controls/engines/engine[0]/magnetos", 1);
var cruise_rpm = 2600;

if (hours.getValue() == nil) {hours.setValue(0);}
if (hours.getValue() >= 10000) {hours.setValue(hours.getValue() - 10000);}

var add_hours = func {
    var rpm = rpm.getValue();
    if (rpm != nil and magnetos.getValue()) {
        var add_time = rpm / cruise_rpm / 3600;
        hours.setValue(hours.getValue() + add_time);
    }
    settimer(add_hours, 1);
}


# Set landing and taxi lights spots intensity according to time of day

var landing_light = props.globals.getNode("systems/electrical/outputs/landing-light", 1);
var taxi_light = props.globals.getNode("systems/electrical/outputs/taxi-lights", 1);
var sun = props.globals.getNode("/sim/time/sun-angle-rad", 1);
var altitude_AGL = props.globals.getNode("/position/altitude-agl-ft", 1);
var landing_lights_intensity = props.globals.getNode("/sim/model/landing_lights-intensity", 1);

landing_lights_intensity.setValue(1.0);

var update_lights_intensity = func {
    if (landing_light.getValue() > 10 or taxi_light.getValue() > 10){
        intensity = -(sun.getValue()) + 1.7;
        if (intensity < 0) {intensity = 0;}
        if (intensity > 1) {intensity = 1;}
        landing_lights_intensity.setValue(intensity + (altitude_AGL.getValue() * 0.003));
    }
    settimer(update_lights_intensity, 0.2);
}

# Autostart

var autostart = func {
    tripacer.master_switch(1);
    set_tanks(0);
    setprop("/controls/fuel/fuel-valve-pos", 0);
    setprop("/controls/engines/engine[0]/mixture", 1);
    setprop("/controls/engines/engine[0]/magnetos", 3);
	setprop("/controls/engines/engine[0]/primer-pump", 6);
	tripacer.start_switch(1);
	settimer(func {tripacer.start_switch(0)}, 2);
}


# Auto Coordination

var auto_coordination_switch = func (v = -1) {
	toggle=getprop("sim/auto-coordination");
  
	if(v == -1)
	{
		toggle=1-toggle;
	}
	else
	{
		toggle = v;
	}
	
	setprop("sim/auto-coordination",toggle);
  
#	if(toggle == 1)
#	{
#		gui.popupTip("Auto Coordination on");
#	}
#	else
#	{
#		gui.popupTip("Auto Coordination off");
#	}
}


# Tyre smoke and rain

# Overwrite default behavior of aircraft.rain class and make rain visible from cockpit.
var  precipitation_enable= props.globals.getNode("sim/rendering/precipitation-aircraft-enable", 1);
precipitation_enable.setBoolValue(1);
precipitation_enable.setAttribute("writable", 0);


var tyresmoke_0 = aircraft.tyresmoke.new(0);
var tyresmoke_1 = aircraft.tyresmoke.new(1);
var tyresmoke_2 = aircraft.tyresmoke.new(2);
aircraft.rain.init();

var smoke_rain_update = func {
    aircraft.rain.update();
    tyresmoke_0.update();
    tyresmoke_1.update();
    tyresmoke_2.update();
    settimer(smoke_rain_update, 0);
}

# Detect precipitation to hide canopy reflections.

var raining = props.globals.getNode("environment/metar/rain-norm", 1);
var snowing = props.globals.getNode("environment/metar/snow-norm", 1);
var precipitation_level = props.globals.getNode("environment/params/precipitation-level-ft", 1);
var altitude_MSL = props.globals.getNode("/position/altitude-ft", 1);
var show_canopy = props.globals.getNode("sim/model/show-canopy", 1);

show_canopy.setBoolValue(0);

var update_canopy_visibility = func {
    if (altitude_MSL.getValue() <= precipitation_level.getValue()) {
        if (raining.getValue() or snowing.getValue()){
            show_canopy.setValue(0);
        }else {show_canopy.setValue(1);}
    }else {show_canopy.setValue(1);}
    settimer(update_canopy_visibility, 0);
}

# Update MP animations

var nav_lights_local = "systems/electrical/outputs/nav-lights";
var landing_light_local = "systems/electrical/outputs/landing-light";
var taxi_light_local = "systems/electrical/outputs/taxi-lights";

var nav_lights_multi = "sim/multiplay/generic/float[0]";
var landing_light_multi = "sim/multiplay/generic/float[1]";
var taxi_light_multi = "sim/multiplay/generic/float[2]";

var MP_update = func {
    setprop(nav_lights_multi, getprop(nav_lights_local));
    setprop(landing_light_multi, getprop(landing_light_local));
    setprop(taxi_light_multi, getprop(taxi_light_local));
    settimer(MP_update, 0.5);
}


# Save configuration

var save_list = ["/engines/engine[0]/hours-running",
                 "/sim/model/fuel/tank[0]/level-gal_us",
                 "/sim/model/fuel/tank[1]/level-gal_us",
                 "/sim/model/move-compass",
                 "/sim/model/yokes-alpha",
                 "/sim/model/show-wheel-pants",
                 "/sim/weight[0]/weight-lb",
                 "/sim/weight[1]/weight-lb",
                 "/sim/weight[2]/weight-lb",
                 "/sim/weight[3]/weight-lb",
                 "/sim/weight[4]/weight-lb",
                 "/sim/model/livery-cabin/name",
                 "/sim/model/livery-fuel-valve/name",
                 "/sim/model/livery-fuselage/name",
                 "/sim/model/livery-wheel-pants/name",
                 "/sim/model/livery-wings/name"];

aircraft.data.add(save_list);

################################################################################
# Initialize systems

var initialize = setlistener("/sim/signals/fdm-initialized", func {
    set_tanks(fuel_valve.getValue());
    update_fuel();
    add_hours();
    update_lights_intensity();
    smoke_rain_update();
    update_canopy_visibility();
    MP_update();
    removelistener(initialize);
});

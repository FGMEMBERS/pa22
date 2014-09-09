var engage = props.globals.getNode("/autopilot/ako64/engage", 1);
var heading = props.globals.getNode("/autopilot/ako64/locks/heading", 1);
var roll = props.globals.getNode("/autopilot/ako64/locks/roll", 1);
var roll_deg = props.globals.getNode("/autopilot/ako64/internal/roll-deg", 1);
var switch = props.globals.getNode("/controls/autoflight/ako64/turn-knob-switch", 1);
var power = props.globals.getNode("/systems/electrical/outputs/autopilot", 1);
var sound = props.globals.getNode("/sim/sound/switch", 1);

engage.setBoolValue(0);
heading.setBoolValue(0);
roll.setBoolValue(0);
roll_deg.setDoubleValue(0);
switch.setDoubleValue(0);
power.setValue(0);

var min_voltage = 8;

# ------------------------------------------------------------------------------

# Play 'click' sound
var click = func {
    if(sound.getValue()) {sound.setBoolValue(0);}
    else {sound.setBoolValue(1);}
}


var power_supply = func {
    power.getValue() >= min_voltage;
}


var autopilot_on = func {
    engage.getValue() and power_supply();
}


var engage_autopilot = func {
    
    if(engage.getValue()) {
        engage.setBoolValue(0);
        roll.setBoolValue(0);
        switch.setDoubleValue(0);
        click();
        gui.popupTip("Autopilot DISENGAGED");
        
    } else {
        if(power_supply()) {
            engage.setBoolValue(1);
            click();
            gui.popupTip("Autopilot ENGAGED");
            
            if(switch.getValue()) {
                roll.setBoolValue(1);
            } else {
                roll.setBoolValue(0);
            }
        } else {roll.setBoolValue(0);}
    }
    heading.setBoolValue(0);
}


var choose_mode = func {
    
    if(switch.getValue() and autopilot_on()) {
        heading.setBoolValue(0);
        roll.setBoolValue(1);
    } elsif(switch.getValue() == 0 and autopilot_on()) {
        heading.setBoolValue(1);
        roll.setBoolValue(0);
    }
}


var power_check = func {

    if(power_supply() == 0) {
        engage.setBoolValue(0);
        heading.setBoolValue(0);
        roll.setBoolValue(0);
        switch.setDoubleValue(0);
    }
#    print(power_supply() ~ ",\t" ~ power.getValue());
    settimer(power_check, 0.5);
}

# ------------------------------------------------------------------------------

var init_power_check = setlistener("/sim/signals/fdm-initialized", func {
    power_check();
    removelistener(init_power_check);
});

print("Nasal AKO64 Autocontrol System initialized.");

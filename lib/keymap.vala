using GLib;

namespace Keymap {
    public string get_key_name(uint keyval) {
        unichar key_unicode = Gdk.keyval_to_unicode(keyval);
        
        if (key_unicode == 0) {
            return Gdk.keyval_name(keyval);
        } else {
            if (key_unicode == 13) {
                return "Enter";
            } else if (key_unicode == 9) {
                return "Tab";
            } else if (key_unicode == 27) {
                return "Esc";
            } else {
                return key_unicode.to_string();
            }
        }
    }

    public string[] get_key_event_modifiers(Gdk.EventKey key_event) {
        string[] modifiers = {};

        if ((key_event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            modifiers += "Ctrl";
        }

        if ((key_event.state & Gdk.ModifierType.SUPER_MASK) != 0) {
            modifiers += "Super";
        }

        if ((key_event.state & Gdk.ModifierType.HYPER_MASK) != 0) {
            modifiers += "Hyper";
        }

        if ((key_event.state & Gdk.ModifierType.MOD1_MASK) != 0) {
            modifiers += "Alt";
        }
        
        return modifiers;
    }

    public string get_keyevent_name(Gdk.EventKey key_event) {
        if ((key_event.is_modifier) != 0) {
            return "";
        } else {
            var key_modifiers = get_key_event_modifiers(key_event);
            var key_name = get_key_name(key_event.keyval);
            
            if (key_name == " ") {
                key_name = "Space";
            }

            if (key_modifiers.length == 0) {
                return key_name;
            } else {
                var name = "";
                foreach (string modifier in key_modifiers) {
                    name += modifier + " + ";
                }
                name += key_name;
                        
                return name;
            }
        }
    }

    public bool has_ctrl_mask(Gdk.EventKey key_event) {
        string[] mask_list = {"Control_L", "Control_R"};
        
        return get_key_name(key_event.keyval) in mask_list;
    }

    public bool has_shift_mask(Gdk.EventKey key_event) {
        string[] mask_list = {"Shift_L", "Shift_R"};
        return get_key_name(key_event.keyval) in mask_list;
    }
}
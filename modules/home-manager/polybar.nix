{inputs, outputs, ...}:
{
  xdg.configFile."/home/theo/.config/polybar/config.ini".text = ''
    [colors]
    background = #1e1e2e
    background-alt = #1e1e2e
    foreground = #cdd6f4
    primary = #f38ba8
    secondary = #89b4fa
    alert = #A54242
    disabled = #707880
    
    [bar/left]
    width = 12.2%
    height = 24pt
    radius = 8
    
    offset-x = 0.5%
    offset-y = 4
    
    dpi = 80
    
    background = $\{colors.background}
    foreground = $\{colors.foreground}
    
    line-size = 0pt
    line-corol = #00000000
    
    border-size = 0pt
    border-color = #00000000
    
    padding-left = 0
    padding-right = 0
    
    module-margin = 0
    
    separator = |
    separator-foreground = $\{colors.disabled}
    
    font-0 = FiraCode Nerd Font;2
    
    modules-center = xworkspaces
    cursor-click = pointer
    cursor-scroll = ns-resize
    
    enable-ipc = true
    
    ; wm-restack = generic
    ; wm-restack = bspwm
    ; wm-restack = i3
    
    ;override-redirect = true
    
    [bar/center]
    width = 31%
    height = 24pt
    radius = 8
    
    offset-x = 34.5%
    offset-y = 4
    
    dpi = 80
    
    background = $\{colors.background}
    foreground = $\{colors.foreground}
    
    line-size = 0pt
    line-corol = #00000000
    
    border-size = 0pt
    border-color = #00000000
    
    padding-left = 0
    padding-right = 0
    
    module-margin = 0
    
    separator = 
    separator-foreground = $\{colors.disabled}
    
    font-0 = FiraCode Nerd Font;2
    
    modules-center = title
    enable-ipc = true
    
    
    [bar/right]
    width = 13%
    height = 24pt
    radius = 8
    
    offset-x = 86.5%
    offset-y = 4
    
    dpi = 80
    
    background = $\{colors.background}
    foreground = $\{colors.foreground}
    
    line-size = 0pt
    line-corol = #00000000
    
    border-size = 0pt
    border-color = #00000000
    
    padding-left = 0
    padding-right = 0
    
    module-margin = 1
    
    separator = |
    separator-foreground = $\{colors.disabled}
    
    font-0 = FiraCode Nerd Font;2
    
    modules-center = memory info-hackspeed date
    enable-ipc = true
    
    [module/xworkspaces]
    type = internal/xworkspaces
    
    label-active = 
    label-active-background = $\{colors.background}
    label-active-underline= $\{colors.primary}
    label-active-padding = 1
    
    label-occupied = 󰺕
    label-occupied-padding = 1
    
    label-urgent = 󰗖
    label-urgent-background = $\{colors.background}
    label-urgent-padding = 1
    
    label-empty = 
    label-empty-foreground = $\{colors.disabled}
    label-empty-padding = 1
    
    [module/date]
    type = internal/date
    interval = 1.0
    label = %time%
    time = %l:%M
    
    [module/memory]
    type = internal/memory
    
    ; Seconds to sleep between updates
    ; Default: 1
    interval = 3
    
    ; Default: 90
    ; New in version 3.6.0
    warn-percentage = 95
    format = <label>
    label = %gb_used% 󰍛 
    
    
    [module/info-hackspeed]
    type = custom/script
    exec = ~/.config/polybar/info-hackspeed.sh
    tail = true
    
    [settings]
    screenchange-reload = true
    pseudo-transparency = false
    ; vim:ft=dosini
    
  '';
  xdg.configFile."/home/theo/.config/polybar/info-hackspeed.sh".text = ''
    #!/bin/sh
    # shellcheck disable=SC2016,SC2059
    
    KEYBOARD_ID="My Super Extra Mega Awesome Keyboard"
    
    # cpm: characters per minute
    # wpm: words per minute (1 word = 5 characters)
    METRIC=wpm
    FORMAT="%d  "
    
    INTERVAL=10
    
    # If you have a keyboard layout that is not listed here yet, create a condition
    # yourself. $3 is the key index. Use `xinput test "AT Translated Set 2 keyboard"`
    # to see key codes in real time.  Be sure to open a pull request for your
    # layout's condition!
    LAYOUT=qwerty
    
    case "$LAYOUT" in
    	qwerty) CONDITION='($3 >= 10 && $3 <= 19) || ($3 >= 24 && $3 <= 33) || ($3 >= 37 && $3 <= 53) || ($3 >= 52 && $3 <= 58)'; ;;
    	azerty) CONDITION='($3 >= 10 && $3 <= 19) || ($3 >= 24 && $3 <= 33) || ($3 >= 37 && $3 <= 54) || ($3 >= 52 && $3 <= 57)'; ;;
    	qwertz) CONDITION='($3 >= 10 && $3 <= 20) || ($3 >= 24 && $3 <= 34) || ($3 == 36) || ($3 >= 38 && $3 <= 48) || ($3 >= 52 && $3 <= 58)'; ;;
        dvorak) CONDITION='($3 >= 10 && $3 <= 19) || ($3 >= 27 && $3 <= 33) || ($3 >= 38 && $3 <= 47) || ($3 >= 53 && $3 <= 61)'; ;;
        dontcare) CONDITION='1'; ;; # Just register all key presses, not only letters and numbers
    	*) echo "Unsupported layout \"$LAYOUT\""; exit 1; ;;
    esac
    
    # We have to account for the fact we're not listening a whole minute
    multiply_by=60
    divide_by=$INTERVAL
    
    case "$METRIC" in
    	wpm) divide_by=$((divide_by * 5)); ;;
    	cpm) ;;
    	*) echo "Unsupported metric \"$METRIC\""; exit 1; ;;
    esac
    
    hackspeed_cache="$(mktemp -p \'\' hackspeed_cache.XXXXX)"
    trap 'rm "$hackspeed_cache"' EXIT
    
    # Write a dot to our cache for each key press
    printf \'\' > "$hackspeed_cache"
    xinput test "$KEYBOARD_ID" | \
    	stdbuf -o0 awk '$1 == "key" && $2 == "press" && ('"$CONDITION"') {printf "."}' >> "$hackspeed_cache" &
    
    while true; do
    	# Ask the kernel how big the file is with the command `stat`. The number we
    	# get is the file size in bytes, which equals the amount of dots the file
    	# contains, and hence how much keys were pressed since the file was last
    	# cleared.
    	lines=$(stat --format %s "$hackspeed_cache")
    
    	# Truncate the cache file so that in the next iteration, we count only new
    	# keypresses
    	printf \'\' > "$hackspeed_cache"
    
    	# The shell only does integer operations, so make sure to first multiply and
    	# then divide
    	value=$((lines * multiply_by / divide_by))
    
    	printf "$FORMAT\\n" "$value"
    
    	sleep $INTERVAL
    done
    
  '';

  xdg.configFile."/home/theo/.config/polybar/launch.sh".text = ''
    polybar left &
    # polybar center &
    polybar right
  '';
}

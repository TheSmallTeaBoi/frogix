{ ... }:
{
  # ACP — the ALSA Card Profile layer inside wireplumber — only binds a hardware
  # volume when the mixer path for the active profile names an element that
  # actually exists on the card. The shipped iec958-stereo-output path lists
  # only [Element IEC958], which my Emotiva Little Ego+ (20ee:0020) does not
  # have, so ACP fell back to software volume: pulsemixer/wpctl moved a fader
  # inside pipewire and never touched the DAC's digitally controlled analog
  # ladder. The analog-output path is no better — it looks for Master, Front,
  # Speaker, Headphone — so switching card profile does not help either.
  #
  # ACP searches $XDG_CONFIG_HOME/alsa-card-profile/mixer/paths before the
  # compiled-in directory (acp/compat.c:get_data_path), so this per-user file
  # wins. It replaces the shipped path file wholesale; the shipped
  # [Element IEC958] block is deliberately dropped, because a mixer path whose
  # element is missing fails to probe and lands back on software volume anyway.
  #
  # The element is the card's USB feature-unit volume: ALSA simple element
  # "Emotiva Little Ego", index 0, 2 channels, 0..127 == 0..-127 dB. Its
  # Playback Switch is the matching mute. PipeWire maps its cubic volume onto
  # the ladder's dB scale and keeps the sub-dB remainder in software
  # (softVolumes), so nothing is lost to the ladder's 1 dB steps.
  #
  # Delete this file to go back to software volume.
  xdg.configFile."alsa-card-profile/mixer/paths/iec958-stereo-output.conf".text = ''
    [Element Emotiva Little Ego]
    switch = mute
    volume = merge
    override-map.1 = all
    override-map.2 = all-left,all-right
  '';
}

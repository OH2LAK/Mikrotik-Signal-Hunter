# Mikrotik signal hunter 'Signal-Alignment-Beeper'
Erik Finskas 2024 <erik@finskas.net

### Requirements
A Mikrotik router which has a beeper

### Why
This script is mainly targeted for PtP link installation to help aiming the antenna towards the AP or bridge party.
The script is not RouterOS license dependant, it just queries information from the wifi interface.

### How
This script will get the Signal-to-Noise (S/N) ratio information from a selected wireless interface
and turn it to an audible tone out of the Routerboard mounted beeper.
The S/N level is updated once a second, so that this tool can be used to adjust the antenna to
the maximum signal and S/N. Higher the tone, better the signal.

The signal alignment tones use a fundamental frequency of 500 Hz by default and the S/N value 
(something between 0 and 70dB maybe) is added and multiplied with 20 on top of the 500 Hz to make
the changes more easily detectable. 1 dB change in the S/N will therefore result in 20 Hz change in the tone.
The best scale depends on your hearing :) 

> [!TIP]
> To enable this script at boot time, you need to add a scheduler to launch the script like this:
> ```
> /system/scheduler/add name="Start_Signal-Alignment-Beeper_at_boot" \
> interval=0 start-time=startup on-event=":delay 20s;\r\n/system script run Signal-Alignment-Beeper"
> ```

### Beebs and boobs
The script outputs several tones and melodies:
* Script startup: raising <sub>ti</sub>-di-<sup>dit</sup> melody.
* Connected: raising ti-<sup>dit</sup> melody (When connection to AP is established)
* Disconnected: descending ti-<sub>dat</sub> melody (When connection to AP is lost)
* Waiting to connect to AP: raising tii-ti-<sup>diii</sup> melody
* Unknown error: raising <sub>tii</sub>-duu-<sup>diii</sup> melody (This occurs when the script can't get anything reasonable out of the wifi interface)
* Script end: descending <sup>ti</sup>-di-<sub>dat</sub> melody
* Boobs:（。 ㅅ 。）

### Disclaimer
The code has been developed with a RB911-5HpND board and RouterOS v7.14.2 but should be quite generic.
If you are still running RouterOS v6, it's time to upgrade

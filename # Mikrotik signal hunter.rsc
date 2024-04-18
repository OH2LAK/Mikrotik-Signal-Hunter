# Mikrotik signal hunter 'Signal-Alignment-Beeper'
# Erik Finskas 2024 <erik@finskas.net>
# Version 18042024

# This script is mainly targeted for PtP link installation to help aiming the antenna towards the AP or bridge party
# The script is not RouterOS license dependant, it just queries information from the wifi interface.

# This script will get the Signal-to-Noise (S/N) ratio information from a selected wireless interface
# and turn it to an audible tone out of the Routerboard mounted beeper.
# The S/N level is updated once a second, so that this tool can be used to adjust the antenna to
# the find the maximum signal and S/N. Higher the tone, better the signal.

# The signal alignment tones use a fundamental frequency of 500Hz by default and the S/N value 
# (something between 0 and 70dB maybe) is added and multiplied with 20 on top of the 500Hz to make
# the changes more easily detectable. 1dB change in the S/N will therefore result in 20Hz change in the tone.
# The best scale depends on your hearing :) 

# To enable this script at boot time, you need to add a scheduler to launch the script like this:
# /system/scheduler/add name="Start_Signal-Alignment-Beeper_at_boot" \ 
# interval=0 start-time=startup on-event=":delay 20s;\r\n/system script run Signal-Alignment-Beeper"

# The script outputs several tones and melodies:
# Script startup: raising ti-di-dit melody.
# Connected: raising ti-dit melody (When connection to AP is established)
# Disconnected: descending ti-dat melody (When connection to AP is lost)
# Waiting to connect to AP: raising tii-ti-diiii melody
# Unknown error: raising tii-duu-diiiii melody (This occurs when the script can't get anything reasonable out of the wifi interface)
# Script end: descending ti-di-dat melody

# The code has been developed with a RB911-5HpND board and RouterOS v7.14.2 but should be quite generic.
# If you are still running RouterOS v6, it's time to upgrade

##########################
# Define script parameters

# Script running time
:local RunTime 10m;

# Delay between measurement cycles
:local DelayTime "500ms";
:log info ("DelayTime = " . $DelayTime);

# Name of wireless interface to monitor
:local InterfaceName "wlan1";
:log info ("InterfaceName = " . $InterfaceName);

# Beeper fundamental frequency in Hz
:local BeepFreq 500;

# Multipier of how much 1dB change in S/N changes the tone frequency. Default is 20 so 20Hz per dB
:local SNToneMultiplier 20

# Define melodies for different occasions
:global PlayStartTone do={
      :beep frequency=500 length=100ms;
      :delay 100ms; # Let the tone play with full lenght before anything else
      :delay 50ms; # Silence between tones
      :beep frequency=600 length=100ms;
      :delay 100ms; # Let the tone play with full lenght before anything else
      :delay 50ms; # Silence between tones
      :beep frequency=800 length=500ms;
      :delay 500ms; # Let the tone play with full lenght before anything else
      :delay 500ms; # Additional silence at end of melody
}
:global PlayStopTone do={
      :beep frequency=800 length=100ms;
      :delay 100ms; # Let the tone play with full lenght before anything else
      :delay 50ms; # Silence between tones
      :beep frequency=600 length=100ms;
      :delay 100ms; # Let the tone play with full lenght before anything else
      :delay 50ms; # Silence between tones
      :beep frequency=500 length=500ms;
      :delay 500ms; # Let the tone play with full lenght before anything else
      :delay 500ms; # Additional silence at end of melody
}
:global PlayWaitingTone do={
      :beep frequency=950 length=650ms;
      :delay 650ms; # Let the tone play with full lenght before anything else
      :delay 325ms; # Silence between tones per specification
      :beep frequency=950 length=325ms;
      :delay 325ms; # Let the tone play with full lenght before anything else
      :beep frequency=1400 length=1300ms;
      :delay 1300ms; # Let the tone play with full lenght before anything else
      :delay 1300ms; # Additional silence at end of melody
}
:global PlaySITTone do={
    :local SITrepeat 3;  # How many times to play diiduudii
    :local N;
    :for N from=1 to=$SITrepeat do={
        :beep frequency=950 length=333ms;
        :delay 333ms; # Let the tone play with full lenght before anything else
        :beep frequency=1400 length=333ms;
        :delay 333ms; # Let the tone play with full lenght before anything else
        :beep frequency=1800 length=333ms;
        :delay 1333ms; # Let the tone play with full lenght before anything else
        :delay 1000ms; # Additional silence at end of melody
    }
}
:global PlayConnectedTone do={
      :beep frequency=523 length=300ms;
      :delay 300ms; # Let the tone play with full lenght before anything else
      :beep frequency=783 length=300ms;
      :delay 300ms; # Let the tone play with full lenght before anything else
      :delay 200ms; # Additional silence at end of melody
}
:global PlayDisconnectedTone do={
      :beep frequency=783 length=300ms;
      :delay 300ms; # Let the tone play with full lenght before anything else
      :beep frequency=523 length=300ms;
      :delay 300ms; # Let the tone play with full lenght before anything else
      :delay 200ms; # Additional silence at end of melody
}

# Play script starting tones
$PlayStartTone

# Define script start, stop & running times in a very strange way
:local StartTime [ :timestamp ];
:local StopTime ($StartTime + $RunTime);

:log info ("Script started at: " . $StartTime);
:log info ("Script will run for: " . $RunTime);
:log info ("Script will stop at: " . $StopTime);

# Set variables needed later
:local OldStatus;
:local CurrentStatus;
:local UnknownStatusEncountered false;
:local KeepLooping true;

# Startup
# Check that we can get data from the wifi interface or that things are not that well
/interface wireless monitor "$InterfaceName" once do={
    :if ($"status" = "connected-to-ess") do={
        $PlayConnectedTone # Play Connected-tone
        :set CurrentStatus $"status";  # Set current status for entering the loop
    } else={
        :if ($"status" = "searching-for-network") do={
            :set CurrentStatus $"status";  # Set current status for entering the loop
        } else={
            :log info ("Status: Unknown status. Exiting script.");
            :set KeepLooping false; # Set to make sure we wont enter the loop
            $PlaySITTone # Play unknown error -tone
            :return; # Exit the script
        }
    }
}

# Main loop
# run the loop until the calculated StopTime is no longer greater than current timestamp and KeepLooping is true
:while ([:timestamp] < $StopTime && $KeepLooping) do={
    /interface wireless monitor "$InterfaceName" once do={
        # Store status of last loop to OldStatus before updating CurrentStatus from the Wifi interface
        :set OldStatus $CurrentStatus;
        :set CurrentStatus $"status";
        # If status has changed to 'connected-to-ess' after last loop, play Connected-tone
        :if ($CurrentStatus = "connected-to-ess" && $OldStatus != "connected-to-ess") do={
            $PlayConnectedTone # Play Connected-tone
        }

        :if ($CurrentStatus = "connected-to-ess") do={
            :if ($OldStatus = "searching-for-network") do={
                :log info ("Status: Connection established!");
            } else {
                # Start beeping S/N tones
                :local SigSN $"signal-to-noise";
                :log info ("Status: Connected to ESS. S/N " . $SigSN . " dB");
                :beep frequency=($BeepFreq + ($SigSN * $SNToneMultiplier)) length=250ms; # Play signal alignment tone
                :delay ($DelayTime);
            }
        } else={
            # If status has changed to 'searching-for-network' after last loop, play Disconnected -tone and Waiting -tone
            :if ($CurrentStatus = "searching-for-network") do={
                :if ($OldStatus = "connected-to-ess") do={
                    :log info ("Status: Connection lost!");
                    $PlayDisconnectedTone # Play Disconnected -tone
                } else {
                    :log info ("Status: Searching for network");
                    $PlayWaitingTone # Play Searching for network -tone
                }
            } else={
                :if ($UnknownStatusEncountered = false) do={
                    :log info ("Status: Unknown status. Everything is doomed.");
                    $PlaySITTone # Play unknown error -tone
                    :set UnknownStatusEncountered true; # Set the flag to true
                    :set KeepLooping false; # Make sure we won't end back to the loop
                }
            }
        }
    }
}

# Play shutdown tones & exit script
:log info ("Bye bye!");
:delay 1s;
$PlayStopTone
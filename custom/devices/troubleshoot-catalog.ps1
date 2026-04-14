# Wildcard groups for interactive Troubleshoot tab (FriendlyName -like).

function Get-TroubleshootGroupCatalog {
    [ordered]@{
        network = [ordered]@{
            Title    = 'Network (Wi-Fi / Ethernet)'
            Patterns = @(
                '*Wi-Fi*',
                '*WiFi*',
                '*Wireless*LAN*',
                '*Ethernet*',
                '*Gigabit*Ethernet*',
                '*Network Adapter*',
                '*WAN Miniport*',
                '*802.11*'
            )
        }
        bluetooth = [ordered]@{
            Title    = 'Bluetooth'
            Patterns = @('*Bluetooth*')
        }
        audio     = [ordered]@{
            Title    = 'Audio / microphone / speakers'
            Patterns = @(
                '*Realtek*Audio*',
                '*Intel*Smart*Sound*',
                '*High Definition Audio*',
                '*Microphone*',
                '*Speaker*'
            )
        }
        camera    = [ordered]@{
            Title    = 'Camera'
            Patterns = @('*Camera*', '*Webcam*', '*UVC*', '*Integrated Camera*')
        }
        pointing  = [ordered]@{
            Title    = 'Mouse / touchpad / pointing'
            Patterns = @(
                '*Mouse*',
                '*TouchPad*',
                '*Touchpad*',
                '*Synaptics*Pointing*',
                '*HID-compliant mouse*',
                '*Precision Touchpad*'
            )
        }
        keyboard  = [ordered]@{
            Title    = 'Keyboard'
            Patterns = @('*Keyboard*', '*HID Keyboard*', '*PS/2*Keyboard*')
        }
    }
}

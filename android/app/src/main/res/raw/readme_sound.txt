Custom notification sound for Sedi alerts
==========================================

FILE NAME (exact):
  sedi_alarm.wav

LOCATION:
  Place the file in this directory:
    android/app/src/main/res/raw/sedi_alarm.wav

RULES:
  - Android references raw resources by name WITHOUT extension.
  - The code uses: RawResourceAndroidNotificationSound('sedi_alarm').
  - So the file must be named exactly: sedi_alarm.wav (or sedi_alarm.mp3;
    the resource name in code stays 'sedi_alarm').
  - Do not use uppercase or extra characters in the file name.

If the file is missing, the system may fall back to the default notification
sound. Channel id is stable: sedi_alerts.

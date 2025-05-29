# VLC

Set preferred audio and subtitle tracks:

1. Open the Preferences.
1. Hit _Show All_.
1. Under _Input/Codecs_, in the _Audio language_ input box, write the language codes in order of preference, separated
   by commas, or `none` to disable it.<br/>
   I.E., set it to `en, it` to try and load the English audio track first, then try Italian if an English track cannot
   be found. Should both tracks cannot be found, VLC will play the default audio track.
1. Under _Input/Codecs_, in the _Subtitle language_ input box, write the language codes in order of preference,
   separated by commas, or `none` to disable it.<br/>
   I.E., set it to `en, it` to try and load the English subtitle track first, then try Italian if an English track
   cannot be found. Should both tracks cannot be found, VLC will play the default subtitle track.

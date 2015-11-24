### How to edit ###

  * You'll need to log in with a Google account to create or edit secrets
  * Anyone can edit secrets created in the last 3 days. You'll always be able to edit secrets you add.

### Suggestions for editors ###

  * Don't include "defaults write" anywhere. Secrets takes care of that
  * Try to phrase things in the positive form. Say "Enable Blah" instead of "Disable blah" and use boolean-neg to negate it if needed.
  * Use sentence case.
  * 

### Icons ###

To add your icon to the database, file a bug on this site and attach a 32x32 png image named as: "com.mybundleid.png"


### Fields ###
  * Title
  * Bundle ID/Path - Bundle for the preference, This can be a bundle ID or a path on disk.  The secret will not be seen unless this or the Display bundle is installed
  * Key - Key in the preferences database
  * Default value
  * Datatype - controls what kind of control is presented
  * Description - for tooltips

  * Placeholder - Placeholder string for a text field
  * Display Bundle - A bundle to masquerade as. This can be a bundle ID or a path on disk.
  * Display Group - A subgrouping within an application list (not currently used)



  * Options
    * This Host - Set for this host only
    * /Library - Set for all users
    * Keypath - Treat the key as a keypath. If this is set, key can be something like "path.to.key"

  * Units - Units for text formatting
  * Widget - Switch to popup for strings
  * Flags
    * Hidden - Should be hidden from the PrefPane
    * Broken - Also hidden from the PrefPane
    * Verified - Not used. Eventually all preferences should be verified
    * Has Application UI - Has a UI already, probably shouldn't be in Secrets
    * Dangerous - Shows red in the prefPane
    * For Debug - Will eventually be used to filter out debugging options

  * Values - Plist of potential values, used to create popups
  * OS Version - Required OS version - not yet implemented
    * App Version - Required App version - not yet implemented
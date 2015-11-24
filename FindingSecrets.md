To find secrets, you can use a tool called [Informer](http://code.google.com/p/blacktree-secrets/downloads/list?q=informer) that logs all user defaults accessed by running apps

Note that this causes a significant performance hit while active.


It will create files in

`~/Library/Caches/Informer/`

Listing the keys used and some additional information about them.


Enabling Informer:

`launchctl setenv DYLD_INSERT_LIBRARIES <pathToInformer>`


Disabling Informer:

`launchctl unsetenv DYLD_INSERT_LIBRARIES`
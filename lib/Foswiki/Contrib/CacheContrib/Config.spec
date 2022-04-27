# ---+ Extensions
# ---++ CacheContrib
# This is the configuration used by the <b>CacheContrib</b>.

# **STRING**
$Foswiki::cfg{CacheContrib}{CacheExpire} = '1 d';

# **STRING EXPERT**
$Foswiki::cfg{CacheContrib}{Driver} = 'File';

# **STRING EXPERT**
$Foswiki::cfg{CacheContrib}{UserAgentString} = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/74.0.3729.169 Chrome/74.0.3729.169 Safari/537.36';

# **PATH EXPERT CHECK="undefok emptyok" **
# path The path to a directory containing files containing Certificate Authority certificates. On linux systems a good default is <code>/etc/ssl/certs</code>.
$Foswiki::cfg{CacheContrib}{SSLCAPath} = '';

# **PERL EXPERT**
# add a handler to purge all caches managed by this contrib
$Foswiki::cfg{SwitchBoard}{purgeCache} = {
    package  => 'Foswiki::Contrib::CacheContrib',
    function => 'cgiPurgeCache',
    context  => { purgeCache => 1 },
};

# **PERL EXPERT**
# add a handler to clear all caches managed by this contrib
$Foswiki::cfg{SwitchBoard}{clearCache} = {
    package  => 'Foswiki::Contrib::CacheContrib',
    function => 'cgiClearCache',
    context  => { clearCache => 1 },
};

1;

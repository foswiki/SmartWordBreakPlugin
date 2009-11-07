# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2009 Michael Tempest
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

=pod

---+ package Foswiki::Plugins::SmartWordBreakPlugin

When developing a plugin it is important to remember that

Foswiki is tolerant of plugins that do not compile. In this case,
the failure will be silent but the plugin will not be available.
See %SYSTEMWEB%.InstalledPlugins for error messages.

__NOTE:__ Foswiki:Development.StepByStepRenderingOrder helps you decide which
rendering handler to use. When writing handlers, keep in mind that these may
be invoked on included topics. For example, if a plugin generates links to the current
topic, these need to be generated before the =afterCommonTagsHandler= is run.
After that point in the rendering loop we have lost the information that
the text had been included from another topic.

=cut

package Foswiki::Plugins::SmartWordBreakPlugin;

# Always use strict to enforce variable scoping
use strict;

use Assert;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version

# $VERSION is referred to by Foswiki, and is the only global variable that
# *must* exist in this package. This should always be in the format
# $Rev: 5154 $ so that Foswiki can determine the checked-in status of the
# extension.
our $VERSION = '$Rev: 5154 $';

# $RELEASE is used in the "Find More Extensions" automation in configure.
# It is a manually maintained string used to identify functionality steps.
# You can use any of the following formats:
# tuple   - a sequence of integers separated by . e.g. 1.2.3. The numbers
#           usually refer to major.minor.patch release or similar. You can
#           use as many numbers as you like e.g. '1' or '1.2.3.4.5'.
# isodate - a date in ISO8601 format e.g. 2009-08-07
# date    - a date in 1 Jun 2009 format. Three letter English month names only.
# Note: it's important that this string is exactly the same in the extension
# topic - if you use %$RELEASE% with BuildContrib this is done automatically.
our $RELEASE = '31 Oct 2009';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION = 'Inserts word-breaks into long words';

# You must set $NO_PREFS_IN_TOPIC to 0 if you want your plugin to use
# preferences set in the plugin topic. This is required for compatibility
# with older plugins, but imposes a significant performance penalty, and
# is not recommended. Instead, leave $NO_PREFS_IN_TOPIC at 1 and use
# =$Foswiki::cfg= entries, or if you want the users
# to be able to change settings, then use standard Foswiki preferences that
# can be defined in your %USERSWEB%.SitePreferences and overridden at the web
# and topic level.
#
# %SYSTEMWEB%.DevelopingPlugins has details of how to define =$Foswiki::cfg=
# entries so they can be used with =configure=.
our $NO_PREFS_IN_TOPIC = 1;

my $core;

###############################################################################
sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    undef $core;

    Foswiki::Func::registerTagHandler( 'SMARTWORDBREAK', \&_SMARTWORDBREAK );
    Foswiki::Func::registerTagHandler( 'WBR',            \&_WBR );

    if (   Foswiki::Func::getPreferencesFlag('SMARTWORDBREAKPLUGIN_WHOLEPAGE')
        or Foswiki::Func::getPreferencesFlag('SMARTWORDBREAKPLUGIN_TABLES') )
    {

        # postRenderingHandler is required
        getCore();
    }

    # Plugin correctly initialized
    return 1;
}

###############################################################################
sub getCore {
    return $core if $core;

    require Foswiki::Plugins::SmartWordBreakPlugin::Core;
    $core = new Foswiki::Plugins::SmartWordBreakPlugin::Core;

    return $core;
}

###############################################################################
# The function used to handle the %SMARTWORDBREAK{...}% macro
sub _SMARTWORDBREAK {
    return getCore()->handleSMARTWORDBREAK(@_);
}

###############################################################################
# The function used to handle the %WBR% macro
sub _WBR {
    return getCore()->handleWBR(@_);
}

###############################################################################
sub postRenderingHandler {
    return unless $core;    # no smart breaks needed
    $core->postRenderingHandler(@_);
}

1;

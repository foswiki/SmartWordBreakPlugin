package SmartWordBreakPluginSuite;

use strict;

use Unit::TestSuite;
our @ISA = 'Unit::TestSuite';

sub name { 'SmartWordBreakPluginSuite' }

sub include_tests { qw(SmartWordBreakPluginTests) }

1;

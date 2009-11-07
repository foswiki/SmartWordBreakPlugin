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

use Foswiki::Func ();       # The plugins API
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

my %optionsFromPreferences;

my $WORDBREAK = '<wbr>';

my %regex;

my $placeholderMarker;

my $hyphen;

my %SWBP_options;
my $SWBP_count;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin topic is in
     (usually the same as =$Foswiki::cfg{SystemWebName}=)

*REQUIRED*

Called to initialise the plugin. If everything is OK, should return
a non-zero value. On non-fatal failure, should write a message
using =Foswiki::Func::writeWarning= and return 0. In this case
%<nop>FAILEDPLUGINS% will indicate which plugins failed.

In the case of a catastrophic failure that will prevent the whole
installation from working safely, this handler may use 'die', which
will be trapped and reported in the browser.

__Note:__ Please align macro names with the Plugin name, e.g. if
your Plugin is called !FooBarPlugin, name macros FOOBAR and/or
FOOBARSOMETHING. This avoids namespace issues.

=cut

###############################################################################
sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    # Example code of how to get a preference value, register a macro
    # handler and register a RESTHandler (remove code you do not need)

    # Set your per-installation plugin configuration in LocalSite.cfg,
    # like this:
    # $Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{ExampleSetting} = 1;
    # See %SYSTEMWEB%.DevelopingPlugins#ConfigSpec for information
    # on integrating your plugin configuration with =configure=.

    # Always provide a default in case the setting is not defined in
    # LocalSite.cfg. See %SYSTEMWEB%.Plugins for help in adding your plugin
    # configuration to the =configure= interface.
    # my $setting = $Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{ExampleSetting} || 0;

    # Register the _EXAMPLETAG function to handle %EXAMPLETAG{...}%
    # This will be called whenever %EXAMPLETAG% or %EXAMPLETAG{...}% is
    # seen in the topic text.
    Foswiki::Func::registerTagHandler( 'SMARTWORDBREAK', \&_SMARTWORDBREAK );
    Foswiki::Func::registerTagHandler( 'WBR', \&_WBR );

    %SWBP_options = ();
    $SWBP_count = 0;

	%optionsFromPreferences = ();

	$optionsFromPreferences{wholePage} = _getOption(pref => 'SMARTWORDBREAKPLUGIN_WHOLEPAGE', 
		                                            default => 0, 
													bool => 1);
	if ($optionsFromPreferences{wholePage}) {
		$optionsFromPreferences{tables} = 0;
	}
	else {
    	$optionsFromPreferences{tables} = _getOption(pref => 'SMARTWORDBREAKPLUGIN_TABLES', 
			                                         default => 0, 
													 bool => 1);
	}

	$optionsFromPreferences{longestUnbrokenWord} = _getOption(pref => 'SMARTWORDBREAKPLUGIN_LONGEST', 
		                                                      default => 8, 
													          checker => sub { $_[0] =~ /^\s*(\d+)\s*$/ and $_[0] > 2 });

	$optionsFromPreferences{splitWikiWords} = _getOption(cfg => 'SplitWikiWords',
		                                                 default => 1,
														 bool => 1);

	$optionsFromPreferences{splitAfterUnderscore} = _getOption(cfg => 'SplitAfterUnderscore',
		                                                       default => 1,
														       bool => 1);

	$optionsFromPreferences{splitAfterPunctuation} = 1;

	$optionsFromPreferences{hyphenate} = _getOption(pref => 'SMARTWORDBREAKPLUGIN_HYPHENATE', 
		                                            default => 1, 
													bool => 1);

	$optionsFromPreferences{splitBeforeNumbers} = 0;

	$optionsFromPreferences{splitAfterNumbers} = 0;

	$optionsFromPreferences{originalInComment} = _getOption(cfg => 'OriginalInComment',
		                                                    default => 1, 
													        bool => 1);

	my $unicodeBrowsers = _getOption(cfg => 'UnicodeBrowsers',
		                             default => '(?i-xsm:Opera|MSIE 8)');

    my $query = Foswiki::Func::getCgiQuery();
	my $ua;
	if ($query) {
        $ua = $query->user_agent();
	}
	if (defined $ua and $ua =~ /$unicodeBrowsers/) {
		$optionsFromPreferences{typeOfWbr} = 'unicode';
	}
	else {
	    $optionsFromPreferences{typeOfWbr} = 'wbr';
	}

	my $wordPunctuation = q/"'!_/;
	my $splitAfterPunctuation = "\\\\" . "\\/" . "\\]" . "[=+:#^,.;(){}-"; # the dash must be last, caret must not be first, / and \ and ] must be escaped

	$regex{lowerAlpha} = _makeRegex($Foswiki::regex{lowerAlpha});
	$regex{notLowerAlpha} = _makeRegex('^', $Foswiki::regex{lowerAlpha});
	$regex{upperAlpha} = _makeRegex($Foswiki::regex{upperAlpha});
	$regex{notUpperAlpha} = _makeRegex('^', $Foswiki::regex{upperAlpha});
	$regex{mixedAlpha} = _makeRegex($Foswiki::regex{mixedAlpha});
	$regex{notMixedAlpha} = _makeRegex('^', $Foswiki::regex{mixedAlpha});
	$regex{wordChar} = _makeRegex($Foswiki::regex{mixedAlphaNum}, $wordPunctuation);
	$regex{notWordChar} = _makeRegex('^', $Foswiki::regex{mixedAlphaNum}, $wordPunctuation);
	$regex{splitAfterPunctuation} = _makeRegex($splitAfterPunctuation);
	$regex{splittable} = _makeRegex($Foswiki::regex{mixedAlphaNum}, $wordPunctuation, $splitAfterPunctuation);
	$regex{numeric} = _makeRegex($Foswiki::regex{numeric});
	$regex{number} = qr/[+-]?$Foswiki::regex{numeric}+(?:\.$Foswiki::regex{numeric}+)?/o;

	$regex{tagPattern} = qr/<[!\/a-z][^>]*?>|&(?:\w+|#\d+);/oi;
	$regex{splittableSequence} = qr/$regex{splittable}+/o;

    # Plugin correctly initialized
    return 1;
}

###############################################################################
sub _getOption
{
	my %params = @_;

	$params{default} = '' if not defined $params{default};
	my $value = $params{default};

	if ($params{cfg}) {
	    my $cfg = $Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{ $params{cfg} };
		$value = $cfg if defined $cfg;
	}

	if ($params{pref}) {
		my $pref = Foswiki::Func::getPreferencesValue( $params{pref} );
		$value = $pref if defined $pref;
	}

	if ($params{bool}) {
		$value = Foswiki::Func::isTrue($value);
	}

	if ($params{checker}) {
		$value = $params{default} unless $params{checker}->($value);
	}

	return $value;
}

###############################################################################
sub _makeRegex
{
	my $string = join( '', 'qr/[', @_, ']/o' );
	my $regex = eval $string;
	die $@ if $@;
	return $regex;
}

###############################################################################
# The function used to handle the %SMARTWORDBREAK{...}% macro
sub _SMARTWORDBREAK {
    my($session, $params, $theTopic, $theWeb) = @_;
    # $session  - a reference to the Foswiki session object (if you don't know
    #             what this is, just ignore it)
    # $params=  - a reference to a Foswiki::Attrs object containing
    #             parameters.
    #             This can be used as a simple hash that maps parameter names
    #             to values, with _DEFAULT being the name for the default
    #             (unnamed) parameter.
    # $theTopic - name of the topic in the query
    # $theWeb   - name of the web in the query
    # Return: the result of processing the macro. This will replace the
    # macro call in the final text.

    # For example, %EXAMPLETAG{'hamburger' sideorder="onions"}%
    # $params->{_DEFAULT} will be 'hamburger'
    # $params->{sideorder} will be 'onions'
	my %options = %optionsFromPreferences;

	if (exists $params->{longest} and $params->{longest} =~ /^(\d+)$/ and $1 > 1) {
    	$options{longestUnbrokenWord} = $1;
	}

	$options{hyphenate} = Foswiki::Func::isTrue( $params->{hyphenate} ) if exists $params->{hyphenate};

	my $instance = $SWBP_count;
	$SWBP_count++;

	$SWBP_options{$instance} = \%options;

	return "<!--swbp$instance$Foswiki::TranslationToken $params->{_DEFAULT} swbp$instance$Foswiki::TranslationToken-->";
}

###############################################################################
# The function used to handle the %WBR% macro
sub _WBR {
	#my($session, $params, $theTopic, $theWeb) = @_;
    # $session  - a reference to the Foswiki session object (if you don't know
    #             what this is, just ignore it)
    # $params=  - a reference to a Foswiki::Attrs object containing
    #             parameters.
    #             This can be used as a simple hash that maps parameter names
    #             to values, with _DEFAULT being the name for the default
    #             (unnamed) parameter.
    # $theTopic - name of the topic in the query
    # $theWeb   - name of the web in the query
    # Return: the result of processing the macro. This will replace the
    # macro call in the final text.

    # browser-dependent check
	if ($optionsFromPreferences{typeOfWbr} eq 'wbr') {
		return '<wbr>';
	}
	if ($optionsFromPreferences{typeOfWbr} eq 'unicode') {
	    return '&#8203;';
	}
	return '';
}


=begin TML

---++ postRenderingHandler( $text )
   * =$text= - the text that has just been rendered. May be modified in place.

*NOTE*: This handler is called once for each rendered block of text i.e. 
it may be called several times during the rendering of a topic.

*NOTE:* meta-data is _not_ embedded in the text passed to this
handler.

Since Foswiki::Plugins::VERSION = '2.0'

=cut

###############################################################################
sub postRenderingHandler {
	#my( $text ) = @_;

    # You can work on $text in place by using the special perl
    # variable $_[0]. These allow you to operate on $text
    # as if it was passed by reference; for example:
    # $_[0] =~ s/SpecialString/my alternative/ge;

	my @tags = qw/head textarea script style/;
	
	my @instances = keys %SWBP_options;
	if (@instances) {
		$placeholderMarker = 0;
		my $removed = {};

		for my $instance (sort @instances) {
			$_[0] =~ s/<!--swbp$instance$Foswiki::TranslationToken (.*) swbp$instance$Foswiki::TranslationToken-->/_processText($1, $removed, $SWBP_options{$instance})/se
				and delete $SWBP_options{$instance};
		}
	}
	
	return unless $optionsFromPreferences{wholePage} or $optionsFromPreferences{tables};

	$placeholderMarker = 0;
	my $removed = {};

	for my $tag (@tags) {
        $_[0] = _takeOutProtected( $_[0], qr/<$tag\b.*?<\/$tag>/si, $tag, $removed );
    }

    $_[0] = _takeOutProtected( $_[0], qr/<table\b.*?<\/table>/si, 'table', $removed )
	  if $optionsFromPreferences{tables};

	$_[0] = _processText($_[0], $removed, \%optionsFromPreferences)
	  if $optionsFromPreferences{wholePage};

    _putBackProtected( \$_[0], 'table', $removed, 
		sub {
			return _processText($_[0], $removed, \%optionsFromPreferences); 
		})
	  if $optionsFromPreferences{tables};

	for my $tag (reverse @tags) {
		_putBackProtected( \$_[0], $tag, $removed );
	}
}

###############################################################################
sub _processText
{
	my ($text, $removed, $options) = @_;

	$text = _takeOutProtected( $text, qr/<[\/!]?[a-z][^>]*>/si, 'anytag', $removed );

	my @text = split /($regex{tagPattern})/o, $text;
	for my $portion (@text) {
		next if $portion =~ /^$regex{tagPattern}$/o;
		$portion =~ s/($regex{splittableSequence})/_smartBreak($1,$options)/ge;
	}
	$text = join('', @text);

    _putBackProtected( \$text, 'anytag', $removed );

	return $text;
}

###############################################################################
sub _smartBreak {
	my ($word, $options) = @_;

	my $original = $word;

	my $isWikiWord = $word =~ /$Foswiki::regex{wikiWordRegex}/;
	my $hasNumber = $word =~ /$regex{number}/;
	my $hasUnderscore = $word =~ /_/;

	if ($options->{splitBeforeNumbers}) {
        $word =~ s/($regex{number})/$WORDBREAK$1/g;
	}

	if ($options->{splitAfterNumbers}) {
		$word =~ s/($regex{number})/$1$WORDBREAK/g;
	}

	if ($options->{splitWikiWords} and $isWikiWord) {
		# split before numbers in WikiWords
		#$word =~ s/((?:$regex{numeric}|$regex{upperAlpha})$regex{mixedAlpha}+)($regex{numeric})/$1$WORDBREAK$2/g;

		# split on Capitals in WikiWords
		$word =~ s/($regex{lowerAlpha})($regex{upperAlpha})/$1$WORDBREAK$2/g;

		# split after numbers in WikiWords
		#$word =~ s/($regex{numeric})($regex{mixedAlpha})/$1$WORDBREAK$2/g;
	}

	if ($options->{splitAfterUnderscore} and $hasUnderscore) {
		# split after underscores
		$word =~ s/([^_]+_+)(?=$regex{wordChar})(?!_)/$1$WORDBREAK/g;
	}

	if ($options->{splitAfterPunctuation}) {
		# split after punctuation
		$word =~ s/($regex{splitAfterPunctuation}+)(?=$regex{wordChar})/$1$WORDBREAK/g;
	}

	my $separator = '&shy;'; # soft hyphen
	$separator = $WORDBREAK if $isWikiWord or $hasUnderscore or $hasNumber;

	# hyphenate
	if ($options->{hyphenate}) {
		my $min = $options->{longestUnbrokenWord} + 1;
		$word =~ s/((?:$regex{wordChar}){$min,})/hyphenate($1, $separator)/ge;
	}

	# split every n characters
	my $n = $options->{longestUnbrokenWord};
	$word =~ s/((?:$regex{wordChar}){$n})(?=$regex{wordChar})/$1$separator/g;

    if ($options->{typeOfWbr} eq 'unicode') { # browser-dependent check
	    $word =~ s/$WORDBREAK/&#8203;/go;
	}

	# Might help search engines
	$word .= "<!-- $original -->" if $word ne $original and $options->{originalInComment};

	return $word;
}

###############################################################################
sub getHyphen {
  return $hyphen if $hyphen;
  
  require TeX::Hyphen;

  my $style = $Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{TeXHyphenStyle}
    || 'czech';
  my @hyphenOptions = ( style => $style );
  push @hyphenOptions, file => $Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{TeXHyphenLanguagePath}
    if $Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{TeXHyphenLanguagePath};

  # TODO - make this more robust
  $hyphen = new TeX::Hyphen @hyphenOptions;

  return $hyphen;
}

###############################################################################
sub hyphenate {
	my ($word, $separator) = @_;

	# Remove any trailing underscore
	my $trailingUnderscore = '';
	if ($word =~ s/(_+)$//) {
		$trailingUnderscore = $1;
	}

	my @places = getHyphen()->hyphenate($word);
	while (@places) {
		my $index = pop @places;
		substr $word, $index, 0, $separator;
	}

	# Put the underscore back if it was there to start with.
	$word .= $trailingUnderscore;

	return $word;
}

###############################################################################
# _takeOutProtected( \$text, $re, $id, \%map ) -> $text
#
#   * =$text= - Text to process
#   * =$re= - Regular expression that matches tag expressions to remove
#   * =\%map= - Reference to a hash to contain the removed blocks
#
# Return value: $text with blocks removed. Unlike takeOuBlocks, this
# *preserves* the tags.
#
# used to extract from $text comment type tags like &lt;!DOCTYPE blah>
#
# WARNING: if you want to take out &lt;!-- comments --> you _will_ need
# to re-write all the takeOuts to use a different placeholder
sub _takeOutProtected {
    my ( $intext, $re, $id, $map ) = @_;

    $intext =~ s/($re)/_replaceBlock($1, $id, $map)/ge;

    return $intext;
}

sub _replaceBlock {
    my ( $scoop, $id, $map ) = @_;
    my $placeholder = $placeholderMarker;
    $placeholderMarker++;
    $map->{ $id . $placeholder }{text} = $scoop;

    return
        '<!--'
      . $Foswiki::TranslationToken
      . $id
      . $placeholder
      . $Foswiki::TranslationToken . '-->';
}

###############################################################################
# _putBackProtected( \$text, $id, \%map, $callback ) -> $text
# Return value: $text with blocks added back
#   * =\$text= - reference to text to process
#   * =$id= - type of taken-out block e.g. 'verbatim'
#   * =\%map= - map placeholders to blocks removed by takeOutBlocks
#   * =$callback= - Reference to function to call on each block being inserted (optional)
#
#Reverses the actions of takeOutProtected.
sub _putBackProtected {
    my ( $text, $id, $map, $callback ) = @_;
    ASSERT( ref($map) eq 'HASH' ) if DEBUG;

    foreach my $placeholder ( keys %$map ) {
        next unless $placeholder =~ /^$id\d+$/;
        my $val = $map->{$placeholder}{text};
        $val = &$callback($val) if ( defined($callback) );
        $$text =~
s/<!--$Foswiki::TranslationToken$placeholder$Foswiki::TranslationToken-->/$val/;
        delete( $map->{$placeholder} );
    }
}


1;

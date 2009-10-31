use strict;

package SmartWordBreakPluginTests;

use base qw(FoswikiFnTestCase);

use strict;
use Foswiki;
use CGI;

my $foswiki;

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

sub loadExtraConfig {
    my $this = shift;
    $this->SUPER::loadExtraConfig();

    $Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{Enabled} = 1;
}

# Set up the test fixture
sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

}

sub tear_down {
    my $this = shift;
    $this->SUPER::tear_down();
}

sub test_noChangeToPlainWords {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{Some plain words}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Some plain words
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_noChangeToTagAttributes {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{
<IgnoreWikiWordsThatLookLikeTags>
</IgnoreWikiWordsThatLookLikeTags>
<tag VeryLooooooooooooooooooooooooooooongName="LoooooooooooooooooooooooooooooooooooooooongValue">
}%
END_SOURCE

    my $expected = <<END_EXPECTED;
<IgnoreWikiWordsThatLookLikeTags>
</IgnoreWikiWordsThatLookLikeTags>
<tag VeryLooooooooooooooooooooooooooooongName="LoooooooooooooooooooooooooooooooooooooooongValue">
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_noSplitAtQuotes {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"Jim's \"simple speech\""}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Jim's "simple speech"
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_split_after_underscore {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{Split_after__Underscore}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Split_<wbr>after__<wbr>Underscore
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_noSplitAfterUnderscoreAtEnd {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{Alpha beta_ Gamma__ Delta__ Chicken}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Alpha beta_ Gamma__ Delta__ Chicken
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_splitWikiWord {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{SplitWikiWord}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Split<wbr>Wiki<wbr>Word
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_splitNoppedWikiWord {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{!JavaScript}%
END_SOURCE

    my $expected = <<END_EXPECTED;
!Java<wbr>Script
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_splitVerylongwordDefault {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{abcdefghijklmnopqrstuvwxyz}%
%SMARTWORDBREAK{protoexistentialist}%
END_SOURCE

    my $expected = <<END_EXPECTED;
abcdefghijklmno<wbr>pqrstuvwxyz
protoexistentia<wbr>list
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_splitVerylongwordAdjustedSetting {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"abcdefghijklmnopqrstuvwxyz" longest="10"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
abcdefghij<wbr>klmnopqrst<wbr>uvwxyz
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_splitVerylongwordMinimumSetting {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"abcdefg" longest="0"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
a<wbr>b<wbr>c<wbr>d<wbr>e<wbr>f<wbr>g
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_splitAfterPunctuation {
    my $this = shift;

    my $source = <<'END_SOURCE';
%SMARTWORDBREAK{Backslash\Forwardslash/Closebracket]Openbracket[Word
Equals=Plus+Colon:Octothorpe#Caret^Word
Comma,Dot.Semicolon;Word
Openparen(Closeparen)Openbrace{Closebrace}Dash-Word}%
END_SOURCE

    my $expected = <<'END_EXPECTED';
Backslash\<wbr>Forwardslash/<wbr>Closebracket]<wbr>Openbracket[<wbr>Word
Equals=<wbr>Plus+<wbr>Colon:<wbr>Octothorpe#<wbr>Caret^<wbr>Word
Comma,<wbr>Dot.<wbr>Semicolon;<wbr>Word
Openparen(<wbr>Closeparen)<wbr>Openbrace{<wbr>Closebrace}<wbr>Dash-<wbr>Word
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_noBreakAfterPunctuationAtEndOfWord {
    my $this = shift;

    my $source = <<'END_SOURCE';
%SMARTWORDBREAK{Backslash\ Forwardslash/ Closebracket] Openbracket[
Equals= Plus+ Colon: Octothorpe# Caret^
Comma, Dot. Semicolon;
Openparen( Closeparen) Openbrace{ Closebrace} Dash-}%
END_SOURCE

    my $expected = <<'END_EXPECTED';
Backslash\ Forwardslash/ Closebracket] Openbracket[
Equals= Plus+ Colon: Octothorpe# Caret^
Comma, Dot. Semicolon;
Openparen( Closeparen) Openbrace{ Closebrace} Dash-
END_EXPECTED

    $this->doTestRegisteredTagHandler( $source, $expected );
}

sub test_noChangeToScriptStyleTextareaHead {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 1);

    my $source = <<END_SOURCE;
<head>WikiWord abcdefghijklmnopqrstuvwxyz</head>
<style>WikiWord abcdefghijklmnopqrstuvwxyz</style>
<script>WikiWord abcdefghijklmnopqrstuvwxyz</script>
<textarea>WikiWord abcdefghijklmnopqrstuvwxyz</textarea>
END_SOURCE

    my $expected = $source;
    $this->doTestPostRenderingHandler( $source, $expected );
}

sub test_wholePageWikiWord {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 1);

    my $source = "WikiWord";

    my $expected = "Wiki<wbr>Word";

    $this->doTestPostRenderingHandler( $source, $expected );
}

sub test_disabledWholePage {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 0);

    my $source = "WikiWord";

    my $expected = $source;

    $this->doTestPostRenderingHandler( $source, $expected );
}

sub test_noChangeToDOCTYPE {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 1);

    my $source = <<END_SOURCE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
END_SOURCE

    my $expected = $source;
    $this->doTestPostRenderingHandler( $source, $expected );
}

sub test_splitWikiWordInTable {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 1);

    my $wikiWord = "VeryLongWikiWordThatMessesUpTableFormatting";
	my $brokenWikiWord = "Very<wbr>Long<wbr>Wiki<wbr>Word<wbr>That<wbr>Messes<wbr>Up<wbr>Table<wbr>Formatting";

    my $table = <<END_TABLE;
%TABLE{columnwidths="5%,95%"}%
| $wikiWord | a |
END_TABLE

    my $source =
      Foswiki::Func::renderText( $table, $this->{test_web}, $this->{test_topic} );

	my $expected = $source;
    $this->assert($expected =~ s/>$wikiWord/>$brokenWikiWord/);

    $this->doTestPostRenderingHandler( $source, $expected );
}

#TODO
# Tests for preferences:
#    * SMARTWORDBREAKPLUGIN_LONGEST
#    * SMARTWORDBREAKPLUGIN_NEEDS_UNICODE_WBR
#    * SMARTWORDBREAKPLUGIN_NEEDS_SPAN_WBR

#======================================================================


sub doTestRegisteredTagHandler {
    my ( $this, $source, $expected, $assertFalse ) = @_;

    _trimSpaces($source);
    _trimSpaces($expected);

	# Force plugin to reread preferences
	Foswiki::Plugins::SmartWordBreakPlugin::initPlugin($this->{test_topic}, $this->{test_web});

    my $actual =
      Foswiki::Func::expandCommonVariables( $source, $this->{test_topic},
        $this->{test_web}, undef );

    if ($assertFalse) {
        $this->assert_str_not_equals( $expected, $actual );
    }
    else {
        $this->assert_str_equals( $expected, $actual );
    }
}

sub doTestPostRenderingHandler {
    my ( $this, $source, $expected, $assertFalse ) = @_;

    _trimSpaces($source);
    _trimSpaces($expected);

	# Force plugin to reread preferences
	Foswiki::Plugins::SmartWordBreakPlugin::initPlugin($this->{test_topic}, $this->{test_web});

	my $actual = $source;
	Foswiki::Plugins::SmartWordBreakPlugin::postRenderingHandler($actual);

    if ($assertFalse) {
        $this->assert_str_not_equals( $expected, $actual );
    }
    else {
        $this->assert_str_equals( $expected, $actual );
    }
}

sub _trimSpaces {

    #my $text = $_[0]

    $_[0] =~ s/^[[:space:]]+//s;    # trim at start
    $_[0] =~ s/[[:space:]]+$//s;    # trim at end
}

1;

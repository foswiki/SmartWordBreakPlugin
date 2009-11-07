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

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{Some plain words}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Some plain words
END_EXPECTED

    $this->doTest( $source, $expected );
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

    $this->doTest( $source, $expected );
}

sub test_noSplitAtQuotes {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"Jim's \"simple speech\""}%
END_SOURCE

    my $expected = <<'END_EXPECTED';
Jim's "simple speech"
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_split_after_underscore {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 99);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{Split_after__Underscore}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Split_<wbr>after__<wbr>Underscore<!-- Split_after__Underscore -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_noSplitAfterUnderscoreAtEnd {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{Alpha beta_ Gamma__ Delta__ Chicken}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Alpha beta_ Gamma__ Delta__ Chicken
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitWikiWord {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{SplitWikiWord}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Split<wbr>Wiki<wbr>Word<!-- SplitWikiWord -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_hyphenateWord {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"representation" longest="5"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
rep&shy;re&shy;sen&shy;ta&shy;tion<!-- representation -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_hyphenateWordOverridePreference {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"representation" hyphenate="1" longest="5"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
rep&shy;re&shy;sen&shy;ta&shy;tion<!-- representation -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_hyphenateWordWithLongest {
    my $this = shift;

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"representation" hyphenate="1" longest="3"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
rep&shy;re&shy;sen&shy;ta&shy;tio&shy;n<!-- representation -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitWikiWordHyphenated {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 1);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', length('Internal'));

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{InternalRepresentation}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Internal<wbr>Rep<wbr>re<wbr>sen<wbr>ta<wbr>tion<!-- InternalRepresentation -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitWordWithUnderscoresHyphenated {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 1);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', length('Internal_'));

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{Internal_Representation}%
END_SOURCE

    my $expected = <<END_EXPECTED;
Internal_<wbr>Rep<wbr>re<wbr>sen<wbr>ta<wbr>tion<!-- Internal_Representation -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_wikiWordLink {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{System.WikiWord}%
END_SOURCE

    my $expected = Foswiki::Func::renderText( 'System.WikiWord', 
		                                      $this->{test_web}, 
											  $this->{test_topic} );
	$this->assert($expected =~ s/>WikiWord</>Wiki<wbr>Word<!-- WikiWord --></);

    $this->doTest( $source, $expected, 1 );
}

sub test_splitNoppedWikiWord {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{!JavaScript}%
END_SOURCE

    my $expected = <<END_EXPECTED;
!Java<wbr>Script<!-- !JavaScript -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitVerylongwordDefault {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{zzzzzzzzzzzzzzzzzzzzzzzzzz}%
END_SOURCE

    my $expected = <<END_EXPECTED;
zzzzzzzz&shy;zzzzzzzz&shy;zzzzzzzz&shy;zz<!-- zzzzzzzzzzzzzzzzzzzzzzzzzz -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitVerylongwordAdjustedSettingPreference {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 10);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{zzzzzzzzzzzzzzzzzzzzzzzzzz}%
END_SOURCE

    my $expected = <<END_EXPECTED;
zzzzzzzzzz&shy;zzzzzzzzzz&shy;zzzzzz<!-- zzzzzzzzzzzzzzzzzzzzzzzzzz -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitVerylongwordAdjustedSettingParameter {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"zzzzzzzzzzzzzzzzzzzzzzzzzz" longest="10"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
zzzzzzzzzz&shy;zzzzzzzzzz&shy;zzzzzz<!-- zzzzzzzzzzzzzzzzzzzzzzzzzz -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitVerylongwordMinimumSetting0 {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 5);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"abcdefg" longest="0"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
abcde&shy;fg<!-- abcdefg -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitVerylongwordMinimumSetting1 {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 5);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"abcdefg" longest="1"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
abcde&shy;fg<!-- abcdefg -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitVerylongwordMinimumSetting2 {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 5);

    my $source = <<END_SOURCE;
%SMARTWORDBREAK{"abcdefg" longest="2"}%
END_SOURCE

    my $expected = <<END_EXPECTED;
ab&shy;cd&shy;ef&shy;g<!-- abcdefg -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_splitAfterPunctuation {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 99);

    my $source = <<'END_SOURCE';
%SMARTWORDBREAK{Backslash\Forwardslash/Closebracket]Openbracket[Word
Equals=Plus+Colon:Octothorpe#Caret^Word
Comma,Dot.Semicolon;Word
Openparen(Closeparen)Openbrace{Closebrace}Dash-Word}%
END_SOURCE

    my $expected = <<'END_EXPECTED';
Backslash\<wbr>Forwardslash/<wbr>Closebracket]<wbr>Openbracket[<wbr>Word<!-- Backslash\Forwardslash/Closebracket]Openbracket[Word -->
Equals=<wbr>Plus+<wbr>Colon:<wbr>Octothorpe#<wbr>Caret^<wbr>Word<!-- Equals=Plus+Colon:Octothorpe#Caret^Word -->
Comma,<wbr>Dot.<wbr>Semicolon;<wbr>Word<!-- Comma,Dot.Semicolon;Word -->
Openparen(<wbr>Closeparen)<wbr>Openbrace{<wbr>Closebrace}<wbr>Dash-<wbr>Word<!-- Openparen(Closeparen)Openbrace{Closebrace}Dash-Word -->
END_EXPECTED

    $this->doTest( $source, $expected );
}

sub test_noBreakAfterPunctuationAtEndOfWord {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 99);

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

    $this->doTest( $source, $expected );
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
    $this->doTest( $source, $expected );
}

sub test_wholePageWikiWord {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 1);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);

    my $source = "WikiWord";

    my $expected = "Wiki<wbr>Word<!-- WikiWord -->";

    $this->doTest( $source, $expected );
}

sub test_disabledWholePage {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 0);

    my $source = "WikiWord";

    my $expected = $source;

    $this->doTest( $source, $expected );
}

sub test_noChangeToDOCTYPE {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 1);

    my $source = <<END_SOURCE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
END_SOURCE

    my $expected = $source;
    $this->doTest( $source, $expected );
}

sub test_splitWikiWordInTable {
    my $this = shift;

	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_WHOLEPAGE', 1);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_HYPHENATE', 0);
	Foswiki::Func::setPreferencesValue('SMARTWORDBREAKPLUGIN_LONGEST', 15);

    my $wikiWord = "VeryLongWikiWordThatMessesUpTableFormatting";
	my $brokenWikiWord = "Very<wbr>Long<wbr>Wiki<wbr>Word<wbr>That<wbr>Messes<wbr>Up<wbr>Table<wbr>Formatting<!-- $wikiWord -->";

    my $table = <<END_TABLE;
%TABLE{columnwidths="5%,95%"}%
| $wikiWord | a |
END_TABLE

    my $source =
      Foswiki::Func::renderText( $table, $this->{test_web}, $this->{test_topic} );

	my $expected = $source;
    $this->assert($expected =~ s/>$wikiWord/>$brokenWikiWord/);

    $this->doTest( $source, $expected, 1 );
}


#======================================================================

sub doTest {
    my ( $this, $source, $expected, $render, $assertFalse ) = @_;

    _trimSpaces($source);
    _trimSpaces($expected);

	# Force plugin to reread preferences
	Foswiki::Plugins::SmartWordBreakPlugin::initPlugin($this->{test_topic}, $this->{test_web});

    my $actual =
      Foswiki::Func::expandCommonVariables( $source, $this->{test_topic},
        $this->{test_web}, undef );
    $actual = Foswiki::Func::renderText( $actual, $this->{test_web}, $this->{test_topic} ) if $render;

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

	# remove leading <nop>
	$_[0] =~ s/\A(?:<nop>[[:space:]]*)+//s;
}

1;

# ---+ Extensions
# ---++ Smart Word Break Plugin
# Settings for the SmartWordBreakPlugin. This plugin splits long words automatically, inserting word breaks or soft hyphens,
# so that the browser can provide better layout for text with long words, especially for pages with tables.
# **SELECT czech,german**
# Selects the hyphenation style for TeX::Hyphen. The "czech" style works just fine for english.
$Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{TeXHyphenStyle} = 'czech';
# **PATH**
# Path to the file that provides the hyphenation rules for TeX::Hyphen.
# If blank, then TeX::Hyphen uses its default rules, which are for english.
# Hyphenation configuration files for additional languages are available from 
# <a href="http://www.ctan.org/tex-archive/language/">http://www.ctan.org/tex-archive/language/</a>
$Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{TeXHyphenLanguagePath} = '';
# **BOOLEAN EXPERT**
# This determines if the original word should be included in an HTML comment, 
# to better support search engines which might be hindered by word breaks and soft hyphens 
$Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{OriginalInComment} = 1;
# **BOOLEAN EXPERT**
# This makes the plugin split WikiWords. If this is enabled, the plugin inserts word breaks before sequences of capital letters.
$Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{SplitWikiWords} = 1;
# **BOOLEAN EXPERT**
# This makes the plugin split Words_With_Underscores. If this is enabled, the plugin inserts word breaks after sequences of underscores.
$Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{SplitAfterUnderscore} = 1;
# **REGEX EXPERT**
# User agents (i.e. browsers) that match this regex get unicode word breaks instead of &lt;wbr&gt; tags.
# See <a href="http://www.quirksmode.org/oddsandends/wbr.html">http://www.quirksmode.org/oddsandends/wbr.html</a> for more information.
$Foswiki::cfg{Plugins}{SmartWordBreakPlugin}{UnicodeBrowsers} = '(?i-xsm:Opera|MSIE 8)';


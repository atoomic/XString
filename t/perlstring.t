#!./perl

use warnings;
use strict;

BEGIN  {
    eval { require threads; threads->import; }
}

use Test::More;

use XString ();
use B ();

for my $do_utf8 (""," utf8") {
    my $max = $do_utf8 ? 1024  : 255;
    my @bad;
    for my $cp ( 0 .. $max ) {
        my $char= chr($cp);
        utf8::upgrade($char) if $do_utf8;
        my $escaped= XString::perlstring($char);
        my $evalled= eval $escaped;
        push @bad, [ $cp, $evalled, $char, $escaped ] if $evalled ne $char;
    }
    is(0+@bad, 0, "Check if any$do_utf8 codepoints fail to round trip through XString::perlstring()");
    if (@bad) {
        foreach my $tuple (@bad) {
            my ( $cp, $evalled, $char, $escaped ) = @$tuple;
            is($evalled, $char, "check if XString::perlstring of$do_utf8 codepoint $cp round trips ($escaped)");
        }
    }
}

# Verify XString::perlstring matches B::perlstring for all codepoints
for my $do_utf8 (""," utf8") {
    my $max = $do_utf8 ? 1024 : 255;
    my @mismatches;
    for my $cp ( 0 .. $max ) {
        my $char = chr($cp);
        utf8::upgrade($char) if $do_utf8;
        my $xs_result = XString::perlstring($char);
        my $b_result  = B::perlstring($char);
        if ($xs_result ne $b_result) {
            push @mismatches, [ $cp, $xs_result, $b_result ];
        }
    }
    is(0+@mismatches, 0,
        "XString::perlstring matches B::perlstring for all$do_utf8 codepoints (0..$max)");
    if (@mismatches) {
        foreach my $tuple (@mismatches) {
            my ( $cp, $xs_result, $b_result ) = @$tuple;
            is($xs_result, $b_result,
                "XString::perlstring vs B::perlstring for$do_utf8 codepoint $cp");
        }
    }
}

# Edge cases: undef and empty string
{
    is XString::perlstring(undef), B::perlstring(undef), "perlstring: undef returns 0";
    is XString::perlstring(""),    B::perlstring(""),    "perlstring: empty string returns \"\"";
}

# Multi-character string comparison against B::perlstring
{
    my @strings = (
        q[OneWord],
        q[with space],
        q[using-dash],
        q['some"quotes],
        q['abcd'],
        q["abcd"],
        qq[new\nlines\n],
        qq[end\0character],
        qq[beep\007],
        qq[\t\r\n mixed whitespace],
        qq[\a\b\f special controls],
        qq[\v vertical tab],
    );
    foreach my $str (@strings) {
        is XString::perlstring($str), B::perlstring($str),
            "perlstring string: " . B::perlstring($str);
    }
}

# Multi-character UTF-8 strings
{
    my @utf8_strings = (
        "hello \x{263A} world",           # ASCII + smiley
        "\x{100}\x{101}\x{102}",          # consecutive Latin Extended-A
        "caf\x{e9}",                       # cafe with e-acute
        "\x{0410}\x{0411}\x{0412}",       # Cyrillic
        "abc\x{0}def\x{263A}",            # mixed with null byte
        "\x{feff}BOM",                     # BOM + ASCII
    );
    for my $str (@utf8_strings) {
        utf8::upgrade($str);
        is XString::perlstring($str), B::perlstring($str),
            "perlstring UTF-8 string: " . B::perlstring($str);
    }
}

# Verify \v behavioral divergence: cstring() emits \v, perlstring() uses octal \013
# This is intentional — \v is a C escape, not a Perl escape
{
    my $vt = chr(11); # vertical tab

    my $ps = XString::perlstring($vt);
    my $cs = XString::cstring($vt);

    like($ps, qr/\\013/, "perlstring: vertical tab uses octal escape (\\013)");
    like($cs, qr/\\v/,   "cstring: vertical tab uses named escape (\\v)");
    isnt($ps, $cs, "perlstring and cstring differ for vertical tab");

    # Both must match B
    is($ps, B::perlstring($vt), "perlstring: vertical tab matches B::perlstring");
    is($cs, B::cstring($vt),    "cstring: vertical tab matches B::cstring");
}

# Verify Latin-1 vs UTF-8 code paths produce distinct escape styles
# Latin-1 (non-upgraded) should use octal escapes (\NNN)
# UTF-8 (upgraded) should use hex escapes (\x{XX})
{
    my $cp = 0xe9; # é - a representative high-byte Latin-1 character
    my $latin1_char = chr($cp);
    my $utf8_char   = chr($cp);
    utf8::upgrade($utf8_char);

    my $latin1_escaped = XString::perlstring($latin1_char);
    my $utf8_escaped   = XString::perlstring($utf8_char);

    like($latin1_escaped, qr/\\351/,
        "Latin-1 chr($cp) uses octal escape (\\351)");
    like($utf8_escaped, qr/\\x\{e9\}/,
        "UTF-8 chr($cp) uses hex escape (\\x{e9})");
    isnt($latin1_escaped, $utf8_escaped,
        "Latin-1 and UTF-8 escapes differ for chr($cp)");
}

done_testing();
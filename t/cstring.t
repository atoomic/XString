#!./perl

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use warnings;
use strict;

use Test::More;

use XString ();

use B ();

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
    map { chr } 0..128
);

{
    #note "testing cstring";
    foreach my $str ( @strings ) {
        is XString::cstring( $str ), B::cstring( $str ), "cstring: " . B::cstring( $str );
    }
}

{
    #note "testing perlstring";
    foreach my $str ( @strings ) {
        is XString::perlstring( $str ), B::perlstring( $str ), "perlstring: " . B::perlstring( $str );
    }
}

# Edge cases: undef and empty string
{
    is XString::cstring(undef), B::cstring(undef), "cstring: undef returns 0";
    is XString::cstring(""),    B::cstring(""),    "cstring: empty string returns \"\"";
}

# UTF-8 tests for cstring()
# cstring() uses the byte-by-byte fallback path even for UTF-8-flagged strings
# (perlstyle=false skips the sv_uni_display branch). Verify XString matches B
# for upgraded strings across Latin-1 and beyond.

{
    # UTF-8 upgraded ASCII + Latin-1 range (0..255)
    my @bad;
    for my $cp ( 0 .. 255 ) {
        my $char = chr($cp);
        utf8::upgrade($char);
        my $got = XString::cstring($char);
        my $expected = B::cstring($char);
        push @bad, [ $cp, $got, $expected ] if $got ne $expected;
    }
    is(0+@bad, 0, "cstring: upgraded codepoints 0..255 match B::cstring")
        or do {
            for my $tuple (@bad) {
                my ( $cp, $got, $expected ) = @$tuple;
                is($got, $expected, "cstring mismatch at codepoint $cp");
            }
        };
}

{
    # Multi-byte UTF-8 codepoints (above Latin-1)
    my @bad;
    for my $cp ( 128 .. 1024 ) {
        my $char = chr($cp);
        my $got = XString::cstring($char);
        my $expected = B::cstring($char);
        push @bad, [ $cp, $got, $expected ] if $got ne $expected;
    }
    is(0+@bad, 0, "cstring: codepoints 128..1024 match B::cstring")
        or do {
            for my $tuple (@bad) {
                my ( $cp, $got, $expected ) = @$tuple;
                is($got, $expected, "cstring mismatch at codepoint $cp");
            }
        };
}

{
    # UTF-8 multi-char strings: mixed ASCII + high codepoints
    my @utf8_strings = (
        "hello \x{263A} world",           # ASCII + smiley
        "\x{100}\x{101}\x{102}",          # consecutive Latin Extended-A
        "caf\x{e9}",                       # cafe with e-acute (Latin-1 range, but upgradeable)
        "\x{0410}\x{0411}\x{0412}",       # Cyrillic А Б В
        "abc\x{0}def\x{263A}",            # mixed with null byte
        "\x{feff}BOM",                     # BOM + ASCII
    );
    for my $str (@utf8_strings) {
        utf8::upgrade($str);
        is XString::cstring($str), B::cstring($str),
            "cstring UTF-8 string: " . B::cstring($str);
    }
}

# Supplementary plane characters (U+10000+) — 4-byte UTF-8
{
    my @astral_strings = (
        "\x{10000}",                          # Linear B Syllable B008 A
        "\x{1F600}",                          # Grinning face emoji
        "\x{1F4A9}",                          # Pile of poo emoji
        "hello \x{1F310} world",              # Globe with meridians
        "\x{10000}\x{10001}\x{10002}",        # Consecutive supplementary chars
        "abc\x{1D11E}def",                    # Musical symbol G clef in ASCII
    );
    for my $str (@astral_strings) {
        utf8::upgrade($str);
        is XString::cstring($str), B::cstring($str),
            "cstring astral: " . B::cstring($str);
    }
}

done_testing();

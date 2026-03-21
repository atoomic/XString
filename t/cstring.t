#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

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
        is XString::cstring( $str ), B::cstring( $str );
    }
}

{
    #note "testing perlstring";
    foreach my $str ( @strings ) {
        is XString::perlstring( $str ), B::perlstring( $str );
    }
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

done_testing();

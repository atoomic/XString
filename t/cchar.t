#!./perl

use warnings;
use strict;

use Test::More;

use XString ();
use B ();

# Compare XString::cchar against B::cchar for all byte values
{
    my @bad;
    for my $cp ( 0 .. 255 ) {
        my $char = chr($cp);
        my $got = XString::cchar($char);
        my $expected = B::cchar($char);
        push @bad, [ $cp, $got, $expected ] if $got ne $expected;
    }
    is(0+@bad, 0, "cchar: all codepoints 0..255 match B::cchar")
        or do {
            for my $tuple (@bad) {
                my ( $cp, $got, $expected ) = @$tuple;
                is($got, $expected, "cchar mismatch at codepoint $cp");
            }
        };
}

# Named escape sequences
{
    is XString::cchar("\n"), B::cchar("\n"), "cchar: newline";
    is XString::cchar("\r"), B::cchar("\r"), "cchar: carriage return";
    is XString::cchar("\t"), B::cchar("\t"), "cchar: tab";
    is XString::cchar("\a"), B::cchar("\a"), "cchar: bell";
    is XString::cchar("\b"), B::cchar("\b"), "cchar: backspace";
    is XString::cchar("\f"), B::cchar("\f"), "cchar: form feed";
    is XString::cchar("\v"), B::cchar("\v"), "cchar: vertical tab";
}

# Special characters
{
    is XString::cchar("'"),  B::cchar("'"),  "cchar: single quote";
    is XString::cchar("\\"), B::cchar("\\"), "cchar: backslash";
    is XString::cchar("\""), B::cchar("\""), "cchar: double quote";
    is XString::cchar(" "),  B::cchar(" "),  "cchar: space";
}

# Printable ASCII
{
    for my $c ('a', 'Z', '0', '~', '!') {
        is XString::cchar($c), B::cchar($c), "cchar: printable '$c'";
    }
}

# NUL byte
{
    is XString::cchar("\0"), B::cchar("\0"), "cchar: NUL byte";
}

# cchar only looks at the first character
{
    is XString::cchar("ab"), B::cchar("ab"), "cchar: multi-char string (uses first char)";
}

done_testing();

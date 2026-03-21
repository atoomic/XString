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
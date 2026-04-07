#!./perl

use warnings;
use strict;

use Test::More;

use Config;

BEGIN {
    if ( !$Config{useithreads} ) {
        plan skip_all => 'no ithreads';
    }
}

use threads;

use XString ();
use B       ();

# Thread-safety test: run cstring/perlstring from multiple threads
# simultaneously and verify all results are correct.

my $NUM_THREADS = 4;

# Each thread gets a range of codepoints to test
my @results;
for my $tid ( 0 .. $NUM_THREADS - 1 ) {
    push @results, threads->create(
        sub {
            my $id    = shift;
            my $start = $id * 64;
            my $end   = $start + 63;
            $end = 255 if $end > 255;
            my @bad;
            for my $cp ( $start .. $end ) {
                my $char = chr($cp);

                my $xs_c = XString::cstring($char);
                my $b_c  = B::cstring($char);
                push @bad, "cstring($cp): got=$xs_c exp=$b_c"
                    if $xs_c ne $b_c;

                my $xs_p = XString::perlstring($char);
                my $b_p  = B::perlstring($char);
                push @bad, "perlstring($cp): got=$xs_p exp=$b_p"
                    if $xs_p ne $b_p;
            }
            return \@bad;
        },
        $tid
    );
}

for my $thr (@results) {
    my $bad = $thr->join();
    is( scalar @$bad, 0, "thread produced correct results" )
        or diag explain $bad;
}

# Also test UTF-8 strings across threads — spread across Unicode planes
# Each thread tests a 64-codepoint slice from a different plane
my @utf8_bases = (
    0x0100,   # Latin Extended-A (2-byte UTF-8)
    0x0900,   # Devanagari (3-byte UTF-8)
    0x4E00,   # CJK Unified Ideographs (3-byte UTF-8)
    0x1F600,  # Emoticons (4-byte UTF-8, astral plane)
);

my @utf8_results;
for my $tid ( 0 .. $NUM_THREADS - 1 ) {
    push @utf8_results, threads->create(
        sub {
            my $id    = shift;
            my $start = $utf8_bases[$id];
            my $end   = $start + 63;
            my @bad;
            for my $cp ( $start .. $end ) {
                my $char = chr($cp);

                my $xs_p = XString::perlstring($char);
                my $b_p  = B::perlstring($char);
                push @bad, "perlstring utf8($cp): got=$xs_p exp=$b_p"
                    if $xs_p ne $b_p;

                my $xs_c = XString::cstring($char);
                my $b_c  = B::cstring($char);
                push @bad, "cstring utf8($cp): got=$xs_c exp=$b_c"
                    if $xs_c ne $b_c;
            }
            return \@bad;
        },
        $tid
    );
}

for my $thr (@utf8_results) {
    my $bad = $thr->join();
    is( scalar @$bad, 0, "thread produced correct multi-plane UTF-8 results" )
        or diag explain $bad;
}

done_testing();

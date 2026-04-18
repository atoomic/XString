#!/usr/bin/perl

# Benchmark: XString vs B module load time and function throughput.
#
# XString's primary advantage is avoiding the cost of loading the full B
# module when you only need cstring() or perlstring(). B pulls in the
# entire B compiler backend; XString loads only the string helpers.
#
# Usage:
#   perl examples/benchmark.pl
#   perl examples/benchmark.pl --iterations=100000

use strict;
use warnings;

use Time::HiRes qw(time);
use Getopt::Long;

my $iterations = 50_000;
GetOptions('iterations=i' => \$iterations);

# --- Module load time ---
# Measure in subprocesses using Time::HiRes inside the child to isolate
# the actual module require cost from Perl startup overhead.

my $trials = 7;

sub measure_load_time {
    my ($module) = @_;
    my @times;
    for (1 .. $trials) {
        my $output = `$^X -MTime::HiRes=time -e 'my \$s = time(); require $module; printf "%.9f\\n", time()-\$s' 2>&1`;
        chomp $output;
        push @times, $output + 0 if $output =~ /^[\d.]+$/;
    }
    @times = sort { $a <=> $b } @times;
    return $times[ int(@times / 2) ]; # median
}

printf "=== Module load time (median of %d runs) ===\n\n", $trials;

my $xs_load = measure_load_time('XString');
my $b_load  = measure_load_time('B');

printf "  XString : %.6f s\n", $xs_load;
printf "  B       : %.6f s\n", $b_load;
if ($b_load > $xs_load && $xs_load > 0) {
    printf "  Ratio   : B is %.1fx slower to load\n", $b_load / $xs_load;
}
print "\n";

# --- Function throughput ---
# Both modules call the same underlying XS logic pattern, so throughput
# should be similar. This confirms no overhead from XString's wrapper.

use XString ();
use B       ();

my @test_strings = (
    "hello world",
    qq[line\nbreak],
    qq[\t\r\n\a\b\f],
    join("", map { chr } 0..127),
    "caf\x{e9}",
    "\x{263A} smiley \x{1F600}",
    '??' . '=' x 50,   # trigraph-heavy
    '$foo @bar',
    "A" x 1000,
);

sub bench {
    my ($label, $code) = @_;
    my $start = time();
    $code->() for 1 .. $iterations;
    my $elapsed = time() - $start;
    printf "  %-28s %8d calls in %.3f s  (%s calls/s)\n",
        $label, $iterations, $elapsed,
        commify(int($iterations / $elapsed));
}

sub commify {
    my $n = reverse $_[0];
    $n =~ s/(\d{3})(?=\d)/$1,/g;
    return scalar reverse $n;
}

printf "=== Function throughput (%s iterations) ===\n\n", commify($iterations);

bench("XString::cstring" => sub {
    XString::cstring($_) for @test_strings;
});

bench("B::cstring" => sub {
    B::cstring($_) for @test_strings;
});

bench("XString::perlstring" => sub {
    XString::perlstring($_) for @test_strings;
});

bench("B::perlstring" => sub {
    B::perlstring($_) for @test_strings;
});

print "\nNote: throughput is expected to be similar — both are XS.\n";
print "XString's advantage is load time, not per-call speed.\n";

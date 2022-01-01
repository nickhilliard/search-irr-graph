#!/usr/bin/perl -w
#
# Copyright Nick Hilliard 2021.  All Rights Reserved.
#
# A script to find out how an AS is hierarchically included in an AS-SET.
#
# Some IRR AS-SETs recursively expand to very large sets of individual ASNs. 
# Often in these cases, it's not clear how an individual AS might be
# included in the expansion tree.  This script finds such a path by slurping
# up as-set lists, converting the data into a directed graph and then using
# the Dijkstra shortest-path algorithm to find the shortest path from the
# source AS to the destination AS-SET.
#
# Note that only a single path is displayed.  There is an option in the perl
# Graph library to perform an exhaustive search of all possible paths
# between the two points using the Floyd Warshall SP algorithm, but this is
# not enabled in the code because the time complexity is O(n^3), which makes
# it unfeasible to do an exhaustive search in any of the major IRRDBs.
#
# IRR data sets can be downloaded from ftp://ftp.radb.net/radb/dbase/
#
# Simple example:
# % gzcat ripe.db.as-set.gz | search-irr-graph.pl --asn as2128 --asset as-inexie
# AS2128 -> AS-INEXIE
# %
#
# More Complex example:
# % gzcat *.db*.gz | search-irr-graph.pl --asn AS19905 --asset AS-RETN --verbose
# internal vertex count: 127029
# internal edge count: 705186
# source asn: AS19905
# destination as-set: AS-RETN
# computed path: AS19905 -> AS-LIMELIGHT-CUST -> AS-LLNW -> AS-SOX-SRB -> AS-MAGYARTELEKOM -> AS-RETN
# %

use strict;
use Data::Dumper;
use Graph;
use Getopt::Long;

my ($asn, $asset);
my $verbose = 0;

GetOptions(
        'asn=s'   => \$asn,
        'asset=s' => \$asset,
        'verbose' => \$verbose,
);

if (!defined ($asn) || !defined ($asset)) {
    die ("need to set both --asn and --asset\n");
}

$asn = uc($asn);
$asset = uc($asset);

$/ = ""; # paragraph mode

my $set;
my $g = Graph->new(directed => 1);

while (<>) {

    next unless (/as-set:\s+(\S+)/);
    my $setname = uc($1);
    my $assetblob = $_;

    local $/ = "\n";

    $set->{$setname} = getmembers($assetblob);

    # add_edge() implicitly creates vertices where needed
    foreach my $member (@{$set->{$setname}}) {
        $g->add_edge($member, $setname);
    }

}

my $vcount = $g->vertices;
my $ecount = $g->edges;
if ($verbose) {
    print <<EOF;
internal vertex count: $vcount
internal edge count: $ecount
source asn: $asn
destination as-set: $asset
EOF
}

my @path = $g->SP_Dijkstra($asn, $asset);
print "computed path: " if ($verbose);
print join  (" -> ", @path). "\n";

exit;

sub getmembers
{
    my ($asset) = @_;
    my @lines = split(/\n/, $asset);

    my $inmembers = 0;
    my $memberline = "";

    # parsing as-sets is complicated by comments and run-on lines
    foreach my $line (@lines) {
        $line =~ s/\s*(#.*)//;
        if ($line =~ /^members:/) {
            $inmembers = 1;
        } elsif ($line =~ /^\S+:/i) {
            $inmembers = 0;
        }

        next unless ($inmembers);

        chomp ($line);
        if ($line =~ /^members:\s+(.*)\s*$/) {
            $line = $1;
        }

        $memberline .= " ".$line;
    }
    return undef unless ($memberline);

    # irrdb entries are case insensitive
    $memberline = uc($memberline);
    $memberline =~ s/\s*,*\s+/ /g;
    $memberline =~ s/^\s+//;

    # deduplicate the list of members in this as-set
    my $set;
    foreach my $asobj (sort split (/ /, $memberline)) {
        $set->{$asobj} = 1;
    }
    my @dedupelist = sort keys %{$set};

    return \@dedupelist;
}

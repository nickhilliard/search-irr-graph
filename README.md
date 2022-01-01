search-irr-graph
==

A script to find out how an AS is hierarchically included in an AS-SET.

Some IRR AS-SETs recursively expand to very large sets of individual ASNs.
Often in these cases, it's not clear how an individual AS might be
included in the expansion tree.  This script finds such a path by slurping
up as-set lists, converting the data into a directed graph and then using
the Dijkstra shortest-path algorithm to find the shortest path from the
source AS to the destination AS-SET.

Note that only a single path is displayed.  There is an option in the perl
Graph library to perform an exhaustive search of all possible paths
between the two points using the Floyd Warshall SP algorithm, but this is
not enabled in the code because the time complexity is O(n^3), which makes
it unfeasible to do an exhaustive search in any of the major IRRDBs.

IRR data sets can be downloaded from ftp://ftp.radb.net/radb/dbase/

Simple example:
```
% gzcat ripe.db.as-set.gz | search-irr-graph.pl --asn as2128 --asset as-inexie
AS2128 -> AS-INEXIE
%
```

More Complex example:
```
% gzcat *.db*.gz | search-irr-graph.pl --asn AS19905 --asset AS-RETN --verbose
internal vertex count: 127029
internal edge count: 705186
source asn: AS19905
destination as-set: AS-RETN
computed path: AS19905 -> AS-LIMELIGHT-CUST -> AS-LLNW -> AS-SOX-SRB -> AS-MAGYARTELEKOM -> AS-RETN
%
```

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use JSON;


use_ok('Soulmate::Loader');
use_ok('Soulmate::Matcher');
my $loader  = Soulmate::Loader->new(namespace => 'venues', debug => 0);
my $matcher = Soulmate::Matcher->new(namespace => 'venues', debug => 0);
isa_ok($loader, 'Soulmate::Loader');
isa_ok($matcher, 'Soulmate::Matcher');

{
    note "integration can load values and query";
    open my $fh, '<', "$Bin/samples/venues.json" or die "Error opening data file: $!";
    my @items   = map { chomp $_; decode_json $_; } <$fh>;
    my $loaded  = $loader->load(\@items);
    is $loaded,             6,              "Loaded 6 venues";
   
    my $results = $matcher->matches_for_term('stad', limit => 5); 
    is scalar @$results,    5,              "Got 5 matches back";
    is $results->[0]{term}, 'Citi Field',   "Top term";
}
  
{
    note "integration can load values and query via aliases";
    open my $fh, '<', "$Bin/samples/venues.json" or die "Error opening data file: $!";
    my @items   = map { chomp $_; decode_json $_; } <$fh>;
    my $loaded  = $loader->load(\@items);
    is $loaded,             6,              "Loaded 6 venues";

    my $term = 'land shark stadium';
    my $results = $matcher->matches_for_term($term, limit => 5);
    is scalar @$results,    1,                  "Got 1 match back for '$term'";
    is $results->[0]{term}, 'Sun Life Stadium', "Found $term";

    $term = 'stadium';
    $results = $matcher->matches_for_term($term, limit => 5);
    is scalar @$results,    5,              "Got 5 results for $term";
}

{
    note "can remove items";
    $loader->load(); 

    my $results = $matcher->matches_for_term('te', cache => 0);
    is scalar @$results,    0,              "No results for 'te'";

    $loader->add({id => 1, term => "Testing this", score => 10});
    $results = $matcher->matches_for_term("te", cache => 0);
    is scalar @$results,    1,              "Now have 1 match for 'te'";

    $loader->remove({"id" => 1});
    $results = $matcher->matches_for_term("te", cache => 0);
    is scalar @$results,    0,              "Now no matches for 'te'";
}
  
{
    note "can update item";
    $loader->load(); 

    # initial data
    $loader->add({id => 1, term => "Testing this", score => 10});
    $loader->add({id => 2, term => "Another Term", score => 9});
    $loader->add({id => 3, term => "Something different", score => 5});
    
    my $results = $matcher->matches_for_term("te", cache => 0);
    is scalar @$results, 2, "Got to results for 'te'";
    is $results->[0]{term},     "Testing this",     "'Testing this' matches term";
    is $results->[0]{score},    10,                 "  score is 10";
    
    # update id:1
    $loader->add({id => 1, term => 'Updated', score => 5});
    
    $results = $matcher->matches_for_term("te", cache => 0);
    is scalar @$results,        1,                  "'te' matched 1 item";
    is $results->[0]{term},     'Another Term',     "First result not 'Another Term'";
    is $results->[0]{score},    9,                  "First result score is 9";
}
  
{
    note "prefixes for phrase";
    Soulmate->clear_stopwords;
    Soulmate->add_stopword('the', 1);
    
    is_deeply ["kn", "kni", "knic", "knick", "knicks"],
        [ $loader->prefixes_for_phrase("the knicks") ], "prefixes: the knicks";
    is_deeply ["te", "tes", "test", "testi", "testin", "th", "thi", "this"],
        [ $loader->prefixes_for_phrase("testin' this") ], "prefixes: testin' this";
    is_deeply ["te", "tes", "test"],
        [ $loader->prefixes_for_phrase("test test") ], "prefixes: test test";
    is_deeply ["so", "sou", "soul", "soulm", "soulma", "soulmat", "soulmate"],
        [ $loader->prefixes_for_phrase("SoUlmATE") ], "prefixes: SoUlmATE";
}

done_testing;

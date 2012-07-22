package Soulmate::Loader;
use Moose;
extends 'Soulmate';
__PACKAGE__->meta->make_immutable;
use JSON;


sub load {
    my ($self, $items) = @_;
    $items ||= [];

    # delete the sorted sets for this namespace
    my $r = $self->redis;
    my @phrases = $r->smembers($self->base);
    #$self->log("phrases [@phrases]");
    $r->del($self->base($_), sub {}) foreach @phrases;
    $r->del($self->base, sub {});
    $r->wait_all_responses;

    # Redis can continue serving cached requests for this type while the reload is
    # occuring. Some requests may be cached incorrectly as empty set (for requests
    # which come in after the above delete, but before the loading completes). But
    # everything will work itself out as soon as the cache expires again.

    # delete the data stored for this type
    $self->log("Deleting database");
    $r->del($self->database);

    for my $item (@$items) {
        $self->add($item, skip_duplicate_check => 1);
    }
    return scalar @$items;
}

# Item is a hashref with keys "id", "term", "score", "aliases", "data"
sub add {
    my $self = shift;
    my $item = shift;
    my %options = (skip_duplicate_check => 0, @_);

    die "Item missing id and term keys" unless $item->{id} and $item->{term};

    $self->remove($item) unless $options{skip_duplicate_check};
   
    my $r = $self->redis;
    $r->hset($self->database, $item->{id}, encode_json($item), sub{});
    my @aliases = @{ $item->{aliases} || [] };
    my $phrase  = join ' ', $item->{term} || '', @aliases;
    $self->log("Adding id: $item->{id}");
    for my $prefix ($self->prefixes_for_phrase($phrase)) {
        $r->sadd($self->base, $prefix, sub {});
        $r->zadd($self->base($prefix), $item->{score} || 0, $item->{id}, sub {});
    } 
    $r->wait_all_responses;
}  

# remove only cares about an item's id, but for consistency takes an object
sub remove {
    my ($self, $item) = @_;

    my $r = $self->redis;
    my $prev_item = $r->hget($self->database, $item->{id});
    return unless $prev_item;

    $prev_item = decode_json $prev_item;
    $r->hdel($self->database, $prev_item->{id});
    my @aliases = @{ $prev_item->{aliases} || [] };
    my $phrase  = join ' ', $prev_item->{term} || '', @aliases;
    $self->log("Deleting id: $prev_item->{id} phrase: $phrase");
    for my $prefix ($self->prefixes_for_phrase($phrase)) {
        $r->srem($self->base, $prefix, sub {});
        $r->zrem($self->base($prefix), $prev_item->{id}, sub {});
    } 
    $r->wait_all_responses;
}

1;


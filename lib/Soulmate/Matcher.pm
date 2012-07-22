package Soulmate::Matcher;
use Moose;
extends 'Soulmate';
__PACKAGE__->meta->make_immutable;
use JSON;

sub matches_for_term {
    my $self = shift;
    my $term = shift;
    my %options = (limit => 5, cache => 1, @_); 

    my @words = sort grep { length $_ >= $self->min_complete }
        $self->split_and_normalize($term); 

    return [] unless @words;

    my $r = $self->redis;
    my $cachekey = $self->cachebase(join '|', @words);
    $self->log("cache key [$cachekey]");
    if (!$options{cache} || !$r->exists($cachekey)) {
        my @interkeys = map { $self->base($_) } @words;
        $self->log("Cachekey [$cachekey] Keys: [@interkeys]");
        $r->zinterstore($cachekey, scalar @interkeys, @interkeys);
        $r->expire($cachekey, 10 * 60) # 10 minute expiration
    }

    my @ids = $r->zrevrange($cachekey, 0, $options{limit} - 1);
    $self->log("found [@ids]");
    if (@ids) {
        my @results = grep { defined $_ }
            $r->hmget($self->database, @ids);
        return [ map { decode_json $_ } @results ];
    }
    return [];
}

sub data_for_item {
    my ($self, $id) = @_;
    my $value = $self->redis->hget($self->database, $id);
    return unless $value;
    return decode_json($value);
}

1;


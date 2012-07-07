package Soulmate::Matcher;
use Moose;
with 'Soulmate::Role::Helpers';
use JSON;

sub matches_for_term {
    my $self = shift;
    my $term = shift;
    my %options = (limit => 5, cache => 1, @_); 

    my @words = sort grep { length $_ >= $self->min_complete }
        $self->split_and_normalize($term); 

    return [] unless @words;

    my $cachekey = $self->cachebase(join '|', @words);

    if (!$options{cache} || !self->redis->exists($cachekey)) {
        my @interkeys = map { $self->base($_) } @words;
        $self->redis->zinterstore($cachekey, @interkeys);
        $self->redis->expire($cachekey, 10 * 60) # 10 minute expiration
    }

    my @ids = $self->redis->zrevrange($cachekey, 0, $options{limit} - 1);
    if (@ids) {
        my @results = grep { defined $_ }
            $self->redis->hmget($self->database, @ids);
        return [ map { decode_json $_ } @results ];
    }
    return [];
}


1;


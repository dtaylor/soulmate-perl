package Soulmate::Role::Helpers;
use Moose::Role;
use Text::Trim;
use List::MoreUtils qw(uniq);

sub prefixes_for_phrase {
    my ($self, $phrase) = @_;
   
    my @words = $self->split_and_normalize($phrase);
    my @prefixes;
    for my $word (@words) {
        push @prefixes, map {
            substr $word, 0, $_ 
        } ($self->min_complete - 1 .. length $word - 1); 
    }
    @prefixes = uniq @prefixes;
    warn "Prefixes for [$phrase] are [@prefixes]\n";
    return @prefixes;
}

sub base {
    my ($self, $key) = @_;
    return "soulmate-index:". $self->namespace . $key ? ":$key" : '';
}

sub database {
    my ($self, $key) = @_;
    return "soulmate-data:". $self->namespace . $key ? ":$key" : '';
}

sub cachebase {
    my ($self, $key) = @_;
    return "soulmate-cache:". $self->namespace . $key ? ":$key" : '';
}

sub split_and_normalize {
    my ($self, $term) = @_;

    return grep { $self->is_stopword($_) } 
        split / /, $self->normalize($term); 
}

sub normalize {
    my ($self, $str) = @_;
    $str = lc $str;
    $str =~ s/[^a-z0-9 ]//gi;
    return trim $str;
}

1;


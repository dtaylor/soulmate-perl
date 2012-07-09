package Soulmate::Role::Helpers;
use Moose::Role;
use Text::Trim;
use List::MoreUtils qw(uniq);

sub prefixes_for_phrase {
    my ($self, $phrase) = @_;
   
    my @words = $self->split_and_normalize($phrase);
    my @prefixes;
    for my $word (@words) {
        # $self->log("prefixes_for_phrase() [$word]");
        for my $x ($self->min_complete .. length $word) {
            my $fragment =  substr($word, 0, $x);
            # $self->log("  fragment [$fragment]");
            push @prefixes, $fragment;
        }
    }
    @prefixes = uniq @prefixes;
    warn "Prefixes for [$phrase] are [@prefixes]\n";
    return @prefixes;
}

sub log {
    my ($self, $msg) = @_;
    $self->debug and print "$msg\n";
}

sub base {
    my ($self, $key) = @_;
    return "soulmate-index:". $self->namespace . ($key ? ":$key" : '');
}

sub database {
    my ($self, $key) = @_;
    return "soulmate-data:". $self->namespace . ($key ? ":$key" : '');
}

sub cachebase {
    my ($self, $key) = @_;
    return "soulmate-cache:". $self->namespace . ($key ? ":$key" : '');
}

sub split_and_normalize {
    my ($self, $term) = @_;

    return grep { ! $self->is_stopword($_) } 
        split / /, $self->normalize($term); 
}

sub normalize {
    my ($self, $str) = @_;
    $str = lc $str;
    $str =~ s/[^a-z0-9 ]//gi;
    return trim $str;
}


1;


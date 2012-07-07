package Soulmate;
use Moose;
with 'Soulmate::Role::Helpers';
use Moose::Util::TypeConstraints;
use Redis;

# ABSTRACT: a perl port of the ruby Soulmate Redis autocompleter

has min_complete => (is => 'ro', is => 'Int', default => 2);
has redis_url => (is => 'rw', is => 'Str', required => 1);
has namespace => (is => 'ro', is => 'Str', required => 1);
subtype 'Sugar::Redis'
    => as class_type('Redis');
coerce 'Sugar::Redis'
    => from 'Str'
    => via { Redis->new( 
        server    => $_, 
        reconnect => 60, 
        every     => 250, 
        encoding  => undef
    )};
 
has redis => (
    is      => 'ro',
    lazy    => 1,
    coerce  => 1,
    isa     => 'Sugar::Redis',
    default => sub { Redis->new }
);

has stopwords => (
    is => 'rw', is => 'HashRef', lazy_build => 1,
    traits => ['Hash'], handles => { is_stopword => 'exists' },
);

sub _build_stopwords {
    my @stop = qw( at the );
    return { map { $_ => 1 } @stop };
}

1;


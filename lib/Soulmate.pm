package Soulmate;
use Moose;
use MooseX::ClassAttribute;
with 'Soulmate::Role::Helpers';
use Moose::Util::TypeConstraints;
use Redis;

# ABSTRACT: a perl port of the ruby Soulmate Redis autocompleter

has debug => (is => 'rw', isa => 'Bool', default => 0);
has min_complete => (is => 'ro', isa => 'Int', default => 2);
has namespace => (is => 'ro', isa => 'Str', required => 1);

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

class_has stopwords => (
    is => 'rw', isa => 'HashRef', lazy_build => 1,
    traits => ['Hash'],
    handles => { 
        is_stopword => 'exists',
        add_stopword => 'set',
    },
);
no Moose;
no MooseX::ClassAttribute;
__PACKAGE__->meta->make_immutable;

sub _build_stopwords {
    my @stop = qw( at the );
    return { map { $_ => 1 } @stop };
}

1;


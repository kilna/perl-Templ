package Templ::Tag;

use strict;
use warnings;

use Carp qw(carp croak);
use Data::Dumper;

# Keyed by start char, value of end char
my %char_pairs = (
   '(' => ')',
   '{' => '}',
   '[' => ']',
   '<' => '>',
);
my %invalid_chars = map { $_ => 1 } ( '+', '-', '=', '/' );

sub add {
    my $class = shift;
    if ( not defined $class || ref $class || $class !~ m/^(\w+\:\:)*\w+$/ ) {
        croak "Can only be called as ".__PACKAGE__."->new";
    }
    if ( $class eq 'Templ::Tag' ) {
        croak "Can't instantiate a Templ::Tag object, please use a subclass";
    }
    my $char = shift;
    if ( not defined $char ) {
        croak "No character specification";
    }
    unless (length($char) == 1) {
        croak "Tag object character specification can only be 1 character long";
    }
    if ($char !~ m/[[:print:]]/ || $char =~ m/[[:alnum:]]/i || $char !~ m/[[:ascii:]]/) {
        croak "Tag object specification must be a printable non-alphanumeric ASCII character";
    }
    if ($invalid_chars{$char}) {
        croak "Tag object character specification cannot be $char";
    }
    my $self = bless { 'char' => $char, 'params' => [ @_ ] }, $class;
    no strict 'refs';
    no warnings 'once';
    push @{ caller().'::TEMPL_TAGS' }, $self;
    return $self;
}

*new = *add;

sub char {
    my $self = shift;
    return $self->{'char'};
}

sub end_char {
    my $self = shift;
    if (exists $char_pairs{$self->{'char'}}) {
        return $char_pairs{$self->{'char'}}
    }
    return $self->{'char'};
}

sub params {
    my $self = shift;
    if (not defined $self->{'params'}) { $self->{'params'} = [] }
    return wantarray ? @{$self->{'params'}} : $self->{'params'};
}

# Regex for matching the beginning of the tag, with optional
# whitespace removal greediness
#
# <?+ Don't trim preceding whitespace
# <?- Trim all preceding whitespace
# <?= Keep indentation
# <?  Default, trim tabs and space only if there's a preceding newline
sub pre_rx {
    my $self = shift;
    if ( not defined $self->{'_pre_rx'} ) {
        my $char = qr/\Q${\$self->char}\E/;
        $self->{'_pre_rx'} = qr/
            (?:                                  < $char \+ |
                \s*                              < $char \- |
                [ \t]*                           < $char \= |
                (?:(?:(?<=\r\n)|(?<=\n))[\t ]*)? < $char
             ) \s+
        /x;
    }
    return $self->{'_pre_rx'};
}

# Regex for matching the end of the tag, with optional
# whitespace removal greediness
#
# +?> Don't trim any trailing whitespace
# -?> Trim all trailing whitespace
#  ?> Default, trim trailing whitespace including a newline, only if
#     there's a newline
sub post_rx {
    my $self = shift;
    if ( not defined $self->{'_post_rx'} ) {
        my $char = qr/\Q${\$self->end_char}\E/;
        $self->{'_post_rx'} = qr/
            \s+
            (?:
                \+ $char >                  |
                \- $char > \s*              |
                   $char > (?:[\t ]*\r?\n)?
            )
        /x;
    }
    return $self->{'_post_rx'};
}

sub perl {
    die "Cannot call ->perl() method of Templ::Tag (must be subclassed)";
}

# For the given template input string, change any appearance of the tag
# into the appropriate substitution
sub process {
    my $self   = shift;
    my $perl   = shift; # Perl version of the template
    my $parser = shift;

    my $pre_rx  = $self->pre_rx;
    my $post_rx = $self->post_rx;
    
    my $append = $parser->append;

    $perl =~ s{ ($pre_rx) (.*?) $post_rx }
         {
             my $pre     = $1;
             my $content = $2;
             $content =~ s|\\\\|\\|gs;
             $content =~ s|\\'|'|gs;
             my $indent  = '';
             if ($pre =~ m/^([ \t]*).*\=/) { $indent = $1; }
             "';\n".$self->perl($content,$indent,$append)."\n$append'"
         }egsx;

    return $perl;
}

sub dump {
    my $self = shift;
    return Data::Dumper->Dump( [$self], ['tag'] );
}

1;

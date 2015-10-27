package Templ::Tag;

use strict;
use warnings;

use Carp qw(carp croak);
use Data::Dumper;
use Templ::Util qw(unquote);

my $valid_chars = '`~!&^*_|;.,#?@$';

sub new {
    my $class = shift;
    if ( not defined $class || ref $class || $class !~ m/^(\w+\:\:)*\w+$/ ) {
        croak "Can only be called as __PACKAGE__->new";
    }
    if ( $class eq 'Templ::Tag' ) {
        croak "Can't instantiate a Templ::Tag object, please use a subclass";
    }

    my $self = bless {@_}, $class;
    $self->check;

    return $self;
}

sub check {
    my $self = shift;
    unless ( index( $valid_chars, $self->char )
        && length( $self->char ) == 1 )
    {

        # The above $self->char statement will croak if the char didn't get
        # set or was not defaulted.  If we got into this block, then the char
        # wasn't a valid settable character
        croak "Invalid character in 'char' specification of tag object";
    }
}

sub char {
    my $self = shift;
    if ( not defined $self->{'char'} ) { croak "No 'char' specification"; }
    return $self->{'char'};
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
        my $char = $self->char;
        $self->{'_pre_rx'}
            = qr/(?:<\Q$char\E\+|\s*<\Q$char\E\-|[ \t]*<\Q$char\E\=|(?:(?:(?<=\r\n)|(?<=\n))[\t ]*)?<\Q$char\E)\s+/;
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
        my $char = $self->char;
        $self->{'_post_rx'}
            = qr/\s+(?:\+\Q$char\E>|\-\Q$char\E>\s*|\Q$char\E>(?:[\t ]*\r?\n)?)/;
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

    $perl =~ s{ ($pre_rx) (.*?) ($post_rx) }
		{
			my $pre     = $1;
			my $content = unquote($2);
			my $indent  = '';
			if ($pre =~ m/^([ \t]*).*\=/)
			{
				$indent = $1;
			}
			"';\n".$self->perl($content,$indent,$append)."\n$append'"
		}egsx;

    return $perl;
}

sub dump {
    my $self = shift;
    return Data::Dumper->Dump( [$self], ['tag'] );
}

1;

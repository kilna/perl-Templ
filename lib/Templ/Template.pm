package Templ::Template;

use Exporter;
push @ISA, 'Exporter';
@EXPORT = qw(add_header add_tag);

use strict;
use warnings;

use Carp qw(carp croak confess);
use Scalar::Util qw(blessed openhandle);
use File::Spec::Functions qw(rel2abs);
use IO::File;
use Data::Dumper;
use Templ::Parser::Print;
use Templ::Parser::Return;
use Templ::Util qw(expand_isa);
use Digest::MD5 qw(md5);
use overload '""' => \&as_perl, '&{}' => \&as_sub;

my %templ_cache = ();

##############################################################################
# Subclass import functions

sub add_header ($) {

    my $target_class = caller;    # The class name of the template we are
                                  #   adding a header to
    my $header       = shift;     # Header to associate with the template

    no strict 'refs';
    no warnings 'once';
    push @{ $target_class . '::TEMPL_HEADERS' }, $header;

}

sub add_tag ($$;%) {

    my $target_class = caller;    # The class name of the template we are
                                  #   adding a tag to
    my $char         = shift;     # Character to associate with the tag
    my $tag_class    = shift;     # The tag's class name we're adding to
                                  #   the calling template

    no strict 'refs';
    eval "
		require Templ::Tag::$tag_class;
		require $tag_class;
	";
    if ( scalar keys %{ 'Templ::Tag::' . $tag_class . '::' } ) {
        $tag_class = 'Templ::Tag::' . $tag_class;
    }
    elsif ( not scalar keys %{ $tag_class . '::' } ) {
        croak "Unable to resolve Templ::Tag class $tag_class";
    }

    push @{ $target_class . '::TEMPL_TAGS' },
		$tag_class->new( 'char' => $char,  @_ );

}

##############################################################################
# Class methods

sub new {

    my $class = shift; # Might be a partial class if called from get()
    if ( not defined $class || ref $class || $class !~ m/^(\w+\:\:)*\w+$/ ) {
        croak "Can only be called as __PACKAGE__->new";
    }
	eval "require Templ::Template::$class; require $class;";
    no strict 'refs';
    if ( scalar keys %{ 'Templ::Template::' . $class . '::' } ) {
        $class = 'Templ::Template::' . $class;
    }
    elsif ( not scalar keys %{ $class . '::' } ) {
        croak "Unable to resolve Templ::Template class $class";
    }

    my $self = bless {}, $class;
    $self->resolve_source( @_ );

    return $self;
}

# Creates a new Templ::Template* object of the passed type
sub get {
    my $class = shift;
    no warnings 'uninitialized';
    my $id = md5( join "\n", ( caller(1), @_ ) );
    if ( not defined $templ_cache{$id} ) { $templ_cache{$id} = new( @_ ); }
    return $templ_cache{$id};
}

##############################################################################
# Hybrid class/object methods

sub tags {
    my $class = ref( $_[0] ) || $_[0];
    my @tags = ();
    foreach my $this_class ( expand_isa($class) ) {
        no strict 'refs';
        next unless scalar( @{ $this_class . '::TEMPL_TAGS' } );
        push @tags, @{ $this_class . '::TEMPL_TAGS' };
    }
    return wantarray ? @tags : \@tags;
}

sub header {
    my $class = ref( $_[0] ) || $_[0];
    my @headers = ();
    foreach my $this_class ( expand_isa($class) ) {
        no strict 'refs';
        next unless scalar( @{ $this_class . '::TEMPL_HEADERS' } );
        push @headers, @{ $this_class . '::TEMPL_HEADERS' };
    }
    return join '', map {"$_\n"} @headers;
}

##############################################################################
# Object methods

# Get the template contents of the object
sub templ_code {
    my $self = shift;
    return $self->{'templ_code'};
}

sub resolve_source {
    
    my $self = shift;
    my $source = shift;
    
    return unless defined $source;
    
    $self->clear;

    if (not ref $source) {
        $self->{'templ_code'} = $source;
    }
    elsif (ref($source) eq 'ARRAY') {
        $self->{'templ_code'} = join '', @{$source};
    }
    elsif ( ref($source) eq 'SCALAR' ) {
        croak "Unable to stat file '$source'" unless -f $$source;
        my $fh = IO::File->new($$source, 'r');
        defined($fh) || croak "Unable to open file ".$$source.": $!";
        $self->{'templ_code'} = join '', $fh->getlines;
        $fh->close;
    }
    elsif ( openhandle($source) || eval { $source->can('getline') }) {
        local $/ = undef;
        $self->{'templ_code'} = <$source>;
        close $source;
    }
    else {
        croak "Unrecognized Templ source parameter: ".Dumper($source);
    }
}

# Returns an eval-able string perl block which returns the output of the
# template
sub as_perl {
    my $self = shift;
    if ( not defined $self->{'as_perl'} ) {
        $self->{'as_perl'} = '{'
            . Templ::Parser::Return->new()->parse($self)
            . '}';
    }
    return $self->{'as_perl'};
}

# Returns an eval-able string perl block which returns the output of the
# template, with newline-spanning strings split into multiple perl code lines
sub as_pretty_perl {
    my $self = shift;
    if ( not defined $self->{'as_pretty_perl'} ) {
        $self->{'as_pretty_perl'} = '{'
            . Templ::Parser::Return->new( 'prettyify' => 1 )->parse($self)
            . '}';
    }
    return $self->{'as_pretty_perl'};
}

# Returns a code reference to a block-based handler for the template
sub as_sub {
    my $self = shift;
    if ( not defined $self->{'as_sub'} ) {
        my $sub;
        eval '$sub = sub {' . Templ::Parser::Return->new()->parse($self) . '}';
        $@ && croak $@;
        $self->{'as_sub'} = $sub;
    }
    return $self->{'as_sub'};
}

# Runs the return handler on the passed params...  in other words, executes
# the template and returns the results
sub render {
    my $self = shift;
    $self->as_sub->(@_);
}

# Runs the print handler on the passed params...  in other words it executes
# the template in such a way that the output is sent to the select()ed FH
sub as_print {
    my $self = shift;
    if ( not defined $self->{'as_print'} ) {
        $self->{'as_print'} = '{'
            . Templ::Parser::Print->new()->parse($self)
            . '}';
    }
    return $self->{'as_print'};
}

# Returns an eval-able string perl block which returns the output of the
# template, with newline-spanning strings split into multiple lines
sub as_pretty_print {
    my $self = shift;
    if ( not defined $self->{'as_pretty_print'} ) {
        $self->{'as_pretty_print'} = '{'
            . Templ::Parser::Print->new( 'prettyify' => 1 )->parse($self)
            . '}';
    }
    return $self->{'as_pretty_print'};
}

# Returns a code reference to a printing handler for this template
sub as_print_sub {
    my $self = shift;
    if ( not defined $self->{'as_print_sub'} ) {
        my $sub;
        eval '$sub = sub {' . Templ::Parser::Print->new()->parse($self) . '}';
        $@ && croak $@;
        $self->{'as_print_sub'} = $sub;
    }
    return $self->{'as_print_sub'};
}

# Prints the output of this template with the passed params
sub run {
    my $self = shift;
    $self->as_print_sub->(@_);
}

sub clear {
    my $self = shift;
    delete $self->{$_} foreach grep { m/^as_/ } keys %{$self};
}

sub dump {
    my $self = shift;
    local $Data::Dumper::Deparse = 1;
    return Data::Dumper->Dump( [$self], ['template'] );
}

1;

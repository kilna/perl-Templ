package Templ::Spec;

use strict;
use warnings;

use Carp qw(carp croak confess);
use Scalar::Util qw(openhandle);
use IO::File;
use Data::Dumper;
use Class::ISA;
use Templ;
use overload '""' => \&as_perl, '&{}' => \&as_sub;

my $PKG = __PACKAGE__;

sub _subclass_loaded ($) {
    my $class = shift;
    no strict 'refs';
    my %pkg = %{$class.'::'};
    return 1 if exists $pkg{'TEMPL_TAGS'};
    return 1 if exists $pkg{'TEMPL_HEADERS'};
    return 0;
}

# Resolves, checks and loads a subclass of Templ::Spec
sub _load_subclass ($) {
    my $class = shift;
    my $caller = $class.'->'.caller();
    defined($class)
        || croak "Undefined class in call to $caller";
    ref($class) && $class->isa($PKG)
        && croak "Class method $caller called as object method";
    ref($class)
        && croak "Unknown parameter found in class position for $caller";
    $class =~ m/^(\w+\:\:)*\w+$/
        || croak "Invalid first string parameter: not a class for $caller";
    $class eq $PKG
        && croak "$PKG must be subclassed!";
    unless ( _subclass_loaded($class) ) {
        eval "require $class;";
        unless ( _subclass_loaded($class) ) {
            croak "Unable to load $PKG subclass $class (have you not added headers or tags?)";
        }
    }
    $class->isa($PKG)
        || croak "Class $class does not inherit from $PKG";
    return $class;
}

# Attempts to determine the non-Templ context from which a call came
sub _ext_caller () {
    my $context = 0;
    while ( $context <= 5 ) {
        my @info = caller($context);
        my $pkg = defined($info[0]) ? $info[0] : '';
        next if !$pkg || $pkg eq 'Templ::Spec' || $pkg eq 'Templ';
        return wantarray ? @info : $pkg;
    } continue { ++$context }
    croak "Deep frame stack for _ext_caller";
}

sub _load_templ_code_from_file ($$) {
    my $self = shift;
    my $fh;
    if (not ref $_[0]) {
        # We were passed a filename
        my $filename = shift;
        croak "Unable to stat file '$filename'" unless -f $filename;
        $fh = IO::File->new($filename, 'r');
        defined($fh) || croak "Unable to open file ".$filename.": $!";
    }
    else {
        # We were passed a filehandle
        $fh = shift;
    }
    unless ( openhandle($fh) || eval { $fh->can('getline') } ) {
        croak "$PKG filehandle parameter doesn't behave like a filehandle";
    }
    local $/ = undef;
    $self->{'templ_code'} = <$fh>;
    close $fh;
}

##############################################################################
# Class methods
#
# These use used by consumers of Templ::Spec's (packages and other code)
# in order to instantiate templates, or import methods which in turn
# instantiate templates

sub templ {
    my $class = _load_subclass(shift @_); # Might be a partial class if called from get()
    my $self = bless {}, $class;
    if (scalar(@_) == 1) {
        my $source = shift || croak "Must provide source for ".caller();
        if (ref $source) {
            $self->_load_templ_code_from_file($source);
        }
        else {
            $self->{'templ_code'} = $source;
        }
    }
    elsif (scalar(@_) == 2) {
        my $type = shift || croak "Must provide type for ".caller();
        my $source = shift || croak "Must provide source for ".caller();
        if ($type eq 'file') {
            $self->_load_templ_code_from_file($source);
        }
        else {
            croak "Unknown $PKG source type $type";
        }
    }
    else {
        croak "Incorrect new $class parameters: ".Dumper(\@_);
    }
    return $self;
}

# Alias ->templ() to ->new()
*new = *templ;

sub templ_method ($$$;$) {
#print Dumper(\@_);
    my $class = _load_subclass(shift @_);
    my $method_name = shift;
    my $templ = $class->templ( @_ );
    no strict 'refs';
    *{ _ext_caller().'::'.$method_name } = $templ->as_method();
    return $templ;
}

sub templ_sub ($$$;$) {
    my $class = _load_subclass(shift @_);
    my $sub_name = shift;
    my $templ = $class->templ( @_ );
    no strict 'refs';
    *{ _ext_caller().'::'.$sub_name } = $templ->as_sub();
    return $templ;
}

##############################################################################
# Hybrid class/object methods

sub tags {
    my $class = ref( $_[0] ) || $_[0];
    my @tags = ();
    foreach my $this_class ( Class::ISA::self_and_super_path($class) ) {
        no strict 'refs';
        next unless scalar( @{ $this_class.'::TEMPL_TAGS' } );
        push @tags, @{ $this_class.'::TEMPL_TAGS' };
    }
    return wantarray ? @tags : \@tags;
}

sub header {
    my $class = ref( $_[0] ) || $_[0];
    my @headers = ();
    foreach my $this_class ( Class::ISA::self_and_super_path($class) ) {
        no strict 'refs';
        next unless scalar( @{ $this_class.'::TEMPL_HEADERS' } );
        push @headers, @{ $this_class.'::TEMPL_HEADERS' };
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
        eval '$sub = sub {'
            . Templ::Parser::Return->new()->parse($self)
            . '}';
        $@ && croak $@;
        $self->{'as_sub'} = $sub;
    }
    return $self->{'as_sub'};
}

# Returns a code reference to a block-based handler for the template
sub as_method {
    my $self = shift;
    if ( not defined $self->{'as_method'} ) {
        my $method;
        eval '$method = sub {'
            . 'my $self = shift; '
            . Templ::Parser::Return->new()->parse($self)
            . '}';
        $@ && croak $@;
        $self->{'as_method'} = $method;
    }
    return $self->{'as_method'};
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
        eval '$sub = sub {'
            . Templ::Parser::Print->new()->parse($self)
            . '}';
        $@ && croak $@;
        $self->{'as_print_sub'} = $sub;
    }
    return $self->{'as_print_sub'};
}

# Runs the return handler on the passed params...  in other words, executes
# the template and returns the results
sub render {
    my $self = shift;
    $self->as_sub->(@_);
}

# Prints the output of this template with the passed params
sub run {
    my $self = shift;
    $self->as_print_sub->(@_);
}

sub dump {
    my $self = shift;
    local $Data::Dumper::Deparse = 1;
    return Data::Dumper->Dump( [$self], ['template'] );
}

1;

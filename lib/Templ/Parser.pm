package Templ::Parser;

use strict;
use warnings;

use Carp qw(cluck croak);
use Data::Dumper;
use Templ::Util qw(quote attempt default number_lines);

my $can_tidy = attempt { require Perl::Tidy; require File::Temp };
my $can_say = attempt { require v5.10; };

sub new {
    my $class = shift;
    if ( not defined $class || ref $class || $class !~ m/^(\w+\:\:)*\w+$/ ) {
        croak "Can only be called as Templ::Parser::...->new";
    }
    if ($class eq __PACKAGE__) {
        croak "__PACKAGE__ cannot be instantiated directly, use a subclass";
    }
    my $self = bless {@_}, $class;
    return $self;
}

sub parse {
    my $self  = shift;
    my $templ = shift;

    # The template is assumed to be starting as printing output, so
    # wrap the whole template in a header/footer, escaping the contents
    my $perl = '';
    if ($self->prettify) { $perl .= $self->pretty_header; }
    $perl .= $templ->header;
    $perl .= $self->header;
    $perl .= "'".quote($templ->templ_code)."'";
    $perl .= $self->footer;

    # Loop over all of the remaining <* ... *> tag types, performing the
    # prescribed replacements...  run in reverse to process latest / deepest
    # subclass tags first
    #
    # $self->debug && print Data::Dumper->Dump([[$templ->tags]],['tags']);
    # $self->debug && print Data::Dumper->Dump([$templ],['templ']);
    foreach my $tag ( $templ->tags ) {
        $perl = $tag->process( $perl, $self );
    }

    if ( $self->prettify ) {
        # Change any standalone single-quote print statements with
        # literal newlines in them to a series of individual print
        # or say statements for readability
        $perl =~ s{
				(?:
					# $1 = Previous statement separator
					( (?: ^ | \; | \{ | \} ) [ \t]*? (?:\r?\n)? )
					# $2 = Print statement indentation
					( \s*? )
					# $3 = Double quote contents
					print \s* '(.*?)(?<!\\)'
					# $4 = Closing brace or semicolon
					( \s* (?: (?:\;|\}) (?:\r?\n)? | $ ) )
				)
			}
			{ $self->prettify_lines($1, $2, $3, $4) }egsx;
    }

    if ( $self->tidy ) {
        if ($can_tidy) {
            require File::Temp;
            require Perl::Tidy;

            # Using a temp file because the output is weird when we don't
            ( undef, my $tmp ) = File::Temp::tempfile();
            Perl::Tidy::perltidy(
                'source'      => \$perl,
                'destination' => $tmp,
                'argv'        => [ split /\s+/, $self->tidy_options ],
            );
            open my $FH, '<', $tmp
                || die "Unable to open file for reading $tmp: $!";
            local $/ = undef;
            $perl = <$FH>;
            close $FH;
        }
        else {
            warn "Unable to load Perl::Tidy and/or File::Temp\n";
        }
    }

    if ( $self->tidy || $self->prettify ) {

        # Remove blank append statements
        my $append = $self->append;
        $perl =~ s/(?:^|(?<=\n)[ \t]*)\Q$append\E'';[ \t]*(?:\r?\n|$)//;
    }

    if ( $self->debug ) {
        print STDERR number_lines($perl);
    }

    return $perl;
}

# Breaks a print statement with newlines in it into multiple statements
# Helps with formatting code to preserve indentation (used when prettify is
# enabled)
sub prettify_lines {
    my $self     = shift;
    my $pre      = shift;    # Previous opening brace or semicolon
    my $indent   = shift;    # Indentation spacing of the print statement
    my $contents = shift;    # Contents of the single quotes of the print
    my $post     = shift;    # Closing brace or semicolon

    my $out = $pre;

    # Create a list of lines (and the ending partial line) in the print
    my @chunks = split /(.*?\n)/, $contents;

    # print "CHUNK <<$_>>\n" foreach @chunks;
    foreach ( 0 .. $#chunks ) {
        my $is_last_chunk = ( $_ == $#chunks );
        my $chunk         = $chunks[$_];
        next if ( ( $chunk eq '' ) && ( not $is_last_chunk ) );

        my $nl = '';
        if    ( $chunk =~ s/\r\n$// ) { $nl = '\r\n'; }
        elsif ( $chunk =~ s/\n$// )   { $nl = '\n'; }

        my $statement;
        if ($nl) {
            if ($self->append_pretty) {
                $statement = $self->append_pretty . "'$chunk'";
            }
            else {
                $statement = $self->append . "'$chunk'" . '."$nl"';
            }
        }
        else {
            $statement = $self->append . "'$chunk'";
        }
        $statement .= $is_last_chunk ? $post : ";\n";

        $out .= $statement;
    }

    return $out;
}

##############################################################################
# Some override-able functions for subclasses

sub pretty_header { return ''; }
sub header        { die "Subclass must override Templ::Parser->header"; }
sub append        { die "Subclass must override Templ::Parser->append"; }
sub append_pretty { return ''; }
sub footer        { die "Subclass must override Templ::Parser->footer"; }

##############################################################################
# Accessors...
sub debug {
    my $self = shift;
    if ( defined $_[0] ) { $self->{'debug'} = shift; }
    return default $self->{'debug'}, $Templ::Parser::debug, 0;
}

sub tidy {
    my $self = shift;
    if ( defined $_[0] ) { $self->{'tidy'} = shift; }
    return default $self->{'tidy'}, $Templ::Parser::tidy, 0;
}

sub tidy_options {
    my $self = shift;
    if ( defined $_[0] ) { $self->{'tidy_options'} = shift; }
    return default $self->{'tidy_options'}, $Templ::Parser::tidy_options,
        '-pbp -nst -b -aws -dws -dsm -nbbc -kbl=0 -asc -npro -sbl';
}

sub prettify {
    my $self = shift;
    if ( defined $_[0] ) { $self->{'prettify'} = shift; }
    return default $self->{'prettify'}, $Templ::Parser::prettify,
        ( $self->tidy ? 1 : 0 );
}

1;

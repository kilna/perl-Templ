#!perl

use strict;
use warnings;

use FindBin;
use Test::More 'tests' => 10;

BEGIN {
    use_ok('Templ');
    use_ok('Templ::Template::HTML');
}

my $t = Templ::Template::HTML->new( \"$FindBin::Bin/main.templ" );

isa_ok( $t, 'Templ::Template::HTML' );

my $captured = '';
{
    binmode STDOUT, ':utf8';
    local *STDOUT;
    open STDOUT, '>', \$captured
         || BAIL_OUT("Unable to redirect STDOUT to variable");    
    $t->run();
}

like( $captured, qr/(  <num>0\d<\/num>\n){3,3}/, 'perl code executed on file' );

$t = templ 'HTML' => <<'EOF';
<* my %info = @_; *>
<* while (my ($k,$v) = each(%info) ) { *>
<#- Testing commenting -#>
  <kv key="<% uc($k) %>" entity="<; $v ;>" html="<& $v &>"/>
<* } *>
EOF
isa_ok( $t, 'Templ::Template::HTML' );

my $out = $t->render( 'smile?' => "\x{263A}" );
my $find = '<kv key="SMILE%3F" entity="&#x263A;" html="'."\x{263A}".'"/>'."\n";
is( $out, $find, 'uri / entities 1' );

$out = $t->render( 'space bar!' => "&" );
$find = '<kv key="SPACE+BAR%21" entity="&amp;" html="&amp;"/>'."\n";
is( $out, $find, 'uri / entities 2' );

##############################################################################
package TestObj;

use Templ;
use Templ::Util qw(undent);
use Carp qw(confess);

sub new    { my $class = shift; return bless { @_ }, $class; }
sub name   { shift->{'name'}   }
sub rank   { shift->{'rank'}   }
sub serial { shift->{'serial'} }

sub as_xml {
    my $self = shift;
    return eval templ('HTML', undent <<'    EOF') // confess $@;
        <xml>
            <name><& lc($self->name) &></name>
            <rank><& uc($self->rank) &></rank>
            <serial><& $self->serial &></serial>
        </xml>
    EOF
}

##############################################################################

package main;

my $thing = TestObj->new(
    'name'   => 'ASDF',
    'rank'   => 'colonel.',
    'serial' => '1234',
);
                    
my $table = $thing->as_xml;
my $exp_table = <<'EOF';
<xml>
    <name>asdf</name>
    <rank>COLONEL.</rank>
    <serial>1234</serial>
</xml>
EOF

is( $table, $exp_table, 'table returned by object is good' );

$t = templ 'Basic', \*DATA;
isa_ok( $t, 'Templ::Template::Basic' );

$out = $t->render();
my $exp_out = <<'EOF';
  [0 - 00]
  [1 - 00]
  [2 - 01]
  [3 - 01]
  [4 - 02]
  [5 - 02]
  [6 - 03]
EOF

is( $out, $exp_out, 'filehandle output correct' );

__DATA__
<* foreach (0..6) { *>
  [<@ $_ @> - <@ sprintf('%0.2d', ($_ / 2) ) @>]
<* } *>

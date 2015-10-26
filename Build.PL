use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Templ',
    license             => 'artistic_2',
    dist_author         => q{Anthony Kilna <anthony@kilna.com>},
    dist_version_from   => 'lib/Templ.pm',
    dist_abstract       => 'A lightweight, pure perl system for building templating systems',
    release_status      => 'unstable',
    configure_requires => {
        'perl' => 5.008,
        'Module::Build' => 0,
    },
    build_requires => {
        'perl' => 5.008,
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.008,
        'Scope::Upper' => 0,
        'Class::ISA' => 0,
        'Exporter' => 0,
        'File::Spec::Functions' => 0,
        'Scalar::Util' => 0,
        'IO::File' => 0,
        'File::Find' => 0,
        'Carp' => 0,
        'Data::Dumper' => 0,
    },
    add_to_cleanup     => [ 'Templ-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Debian::Perl::Utils',
    AUTHOR              => q{Jeremiah C. Foster <jeremiah@jeremiahfoster.com>},
    VERSION_FROM        => 'lib/Debian/Perl/Utils.pm',
    ABSTRACT_FROM       => 'lib/Debian/Perl/Utils.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Debian-Perl-Utils-*' },
);

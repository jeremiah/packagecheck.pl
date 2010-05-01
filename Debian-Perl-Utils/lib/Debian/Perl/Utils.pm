package Debian::Perl::Utils;

=head1 NAME

Debian::Perl::Utils - Utility functions used in the debian-perl group.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Various useful functions for munging repository, deb, and module data.
Probably not a very useful module outside of the debian-perl group.

    use Debian::Perl::Utils;
    my $module = Debian::Perl::Utils->new();

=head1 SUBROUTINES/METHODS

=over 4

=item _svn_check

Checks to see if we can find a .svn directory. Dies if we can't.

=cut

use Moose;

has 'repo' => ( is => 'rw', isa => 'Str',);

sub _svn_check {
  my ($self, $dir) = @_;
  $dir .= "/.svn";
  if (not -d "$dir") {
    die "Cannot find subversion directory.\n$!";
  }
  else {
    $self->repo($dir);
  }
  return $self->repo;
}

no Moose;
__PACKAGE__->meta->make_immutable;


=back

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Jeremiah C. Foster, C<< <jeremiah at jeremiahfoster.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-debian-perl-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debian-Perl-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debian::Perl::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Debian-Perl-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debian-Perl-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Debian-Perl-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Debian-Perl-Utils/>

=back

=head1 ACKNOWLEDGEMENTS



=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jeremiah C. Foster.

This program is released under the following license: GPL v.2 or greater

=cut

1; # End of Debian::Perl::Utils

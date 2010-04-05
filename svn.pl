#!/usr/bin/perl

# Perlification Copyright 2009, 2010 Jeremiah C. Foster <jeremiah@jeremiahfoster.com>
# Copyright 2007, 2008, 2009 gregor herrmann <gregoa@debian.org>
# Copyright 2007, 2008 Damyan Ivanov <dmn@debian.org>
# Copyright 2007 David Paleino <d.paleino@gmail.com>
# Released under the terms of the GNU GPL version 2
#
# To be run one directory above trunk/
# (package name can be specified as the first argument in a
# different directory with --current)

##  TODO: Make this script work in a git repository as well as svn

=head1 NAME

packagecheck.pl - A debian-perl housekeeping tool

=head1 VERSION

This document describes packagecheck.pl version 0.2

=cut

our $VERSION = '0.3';

=head1 DESCRIPTION

This tool is used inside the debian-perl group for checking packages
maintained by that group. As a consequence, it is very debian-perl centric,
and certain assumptions are made, like that you have the debian-perl svn repository
checked out.

Caveat Emptor: The script might not be of much use outside the debian-perl group.
But you are welcome to use whatever code you find useful here.

=head1 SYNOPSIS

     Run this script in a subversion repo above trunk/

     packagecheck.pl [-c module] [-h] [-v]

     # check a package in the current directory
     packagecheck.pl --current libfoo-bar-perl

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message, then exit.

=item B<--current> package

Test a package that is in the current working directory.

=back

=cut

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use Cwd;
use Carp qw(croak);
use IPC::System::Simple qw(system capturex EXIT_ANY);
use Perl6::Slurp;

my $fullpath;      # variable to hold path information
my $control_file;  # The control file of our package
my %config;        # hash holding configuration options

# Options
my ($automatic,    # flag for when this script gets called by other scripts
    $vcs,          #
    $version,      # Version of this file
    $current,      # Check for a svn controlled module in the current dir
    $all,          # All checks
    $homepage, $maintainer, $depends, $watch,
    $create, $rules, $quilt, $package, $help,  );

GetOptions ( 'help' => \$help,                # print help message
	     'current|c' => \$current,        # look for debian package in current dir
	     'version' => \$version,          # the version of this script
	     'auto' => \$automatic,           # make assumptions about our environment
	     'all|A' => \$all,                # run all checks
	   );

# Print usage if there is no option or if the option is help
pod2usage(1) if $help;
print "$0 version: $VERSION\n" if $version;
# pod2usage(1) unless $version || $help;

=head1 FUNCTIONS

=over 8

=item sanity_check

Checks to see if we are in a directory. (Takes a directory as an arg.)

=cut

sub sanity_check {
  my $sane = shift;
  if (not -d $sane) { # we're not sane, so die
    die "Cannot find working directory $sane: $!";
  }
}

=item append_control

Append missing files to debian/control files in the correct locations

=cut

sub append_control {
  my ($orig, $replacement, $ctrl_ref) = @_;
  open my $fh, '>', $orig or croak "Cannot open $control_file: $!\n";
  # Should I write to a temporary file, instead of re-writing the control file?

  map {
    my $line_before = $_;
    if ($line_before =~ /^Vcs-Svn/) {  # Append Vcs-Svn line to control file after 'Standards' line
      print {$fh} map {
	if ($line_before =~ /Standards/) { $line_before .= "@$replacement \n"; }
	else { $line_before; }
      } @$ctrl_ref;
    }
    if ($line_before =~ /^Vcs-Browser/) { # Append Vcs-Browser line to control file after 'Vcs-Svn' line
      print {$fh} map {
	if ($line_before =~ /Vcs-Svn/) { $line_before .= "@$replacement \n"; }
	else { $line_before; }
      } @$ctrl_ref;
    }
 } @$replacement;
  close $fh;
}

=item remove_old_urls

Remove any reference to no longer used resources, like WebSVN or any old XS-Vcs- fields

=cut

sub remove_old_urls {
  my $control_ref = shift;
  #  print map { "->" . $_ . "\n" } @$control_ref;
}

=item testvcs

Test for presence of Version Control System fields in control file, if not present
append correct field name and URLs to debian/control file.

=cut

sub testvcs {
  my $replacements =
    [
     [ 'Vcs-Svn:', 'svn://svn.debian.org/pkg-perl/trunk/$package/' ],
     [ 'Vcs-Browser:', 'http://svn.debian.org/viewsvn/pkg-perl/trunk/$package/' ],
    ];

  map {
    # we need to re-read the file to pick up changes
    my $control_file = shift;
    my @contents = slurp "$fullpath/debian/control";
    my $ctrl_ref = \@contents;
    my $field = $replacements->[$_][0];
    if (grep /^$field/, @contents) { print "Found \"$field\" field.\n"; }
    else {
      print "Did not find $field, appending.\n";
      append_control("$fullpath/debian/control", $replacements->[$_], $ctrl_ref);
    }
    undef $ctrl_ref;
  } 0..(@$replacements - 1);
}

# Process options
# --all
if ($all) {
  my $here = getcwd;
  $fullpath = $here."/".$current;
  sanity_check($fullpath);
}
# --current
if ($current) {
  my $here = getcwd;
  $fullpath = $here . "/";
  sanity_check($fullpath);

  if (! $automatic) {
    print "Running svn up on $fullpath . . .\n";
    print map { $_ } capturex( EXIT_ANY, "svn","up","$fullpath/");
    print "Checking if $fullpath is clean . . .\n";
    my @changed_lines = capturex( EXIT_ANY, "svn","st","$fullpath/");
    if ($#changed_lines > 0) {
      print map { $_ } @changed_lines;
    }
    else {
      print "Target directory apparently unchanged.\n";
    }
  }
  else {  # we're being called by another script
    print "Automated.\n";
  }
}


=back

=cut


1; # End of packagecheck.pl

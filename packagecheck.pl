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

     packagecheck.pl [options]

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
use IPC::System::Simple qw(system capture runx);
use Perl6::Slurp;
use Git;

my $fullpath;      # a variable use to hold path information
my $control_file;  # The control file of our package
my %config;        # hash holding configuration options

# Options
my ($automatic,    # flag for when this script gets called by other scripts
    $vcs,          #
    $version,      # Version of this file
    $homepage, $maintainer, $depends, $watch,
    $create, $rules, $quilt, $all, $package, $help, $current );

GetOptions ( 'help' => \$help,                # print help message
	     'current|c=s' => \$current,      # look for debian package in current dir
	     'version' => \$version,          # the version of this script
	     'auto' => \$automatic,           # make assumptions about our environment
	   );

# Print usage if there is no option or if the option is help
pod2usage(1) if $help;
print "$0 version: $VERSION\n" if $version;
pod2usage(1) unless $version || $help;

=head1 FUNCTIONS

=over 8

=item build_path

Build the path to the dir we are checking. Pass a package name as an arg.

=cut

sub build_path {
  my $cwd = &cwd;
  my $package = shift;
  my $dir = "$cwd/$package";
  return $dir;
}

=item sanity_check

Checks to see if we are in a directory. (Takes a directory as an arg.)

=cut

sub sanity_check {
  my $sane = shift;
  build_path($sane);
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
if ($current) {  # look for checked-out packages in the current dir
  sanity_check("$current");
  $fullpath = build_path($current);
  if (!$automatic) {
    # test which VCS we're using, git or svn. Maybe should be factored out to a sub?
    if (capture([0..128], "ls $fullpath.svn")) {
      $config{'vcs'} = "svn";                        # svn is our VCS
      print "Running svn up in $fullpath . . .\n";   # we use svn if we find it
      my @svnrev = capture("svn up $fullpath");
      print "SVN: $svnrev[-1]";
      print "Checking for uncommitted modifications to directory . . .\n";
      my @svnmods = capture("svn st $fullpath");
      if ($svnmods[-1]) {
	print map { $_ } @svnmods;
	die "Exiting. $fullpath appears to have uncommitted modifications.\n";
      }
      else {
	print "It appears directory is clean.\n";
      }
    }
    else { # No subversion, let's try git
      print "Checking for git repository.\n";
      my $gitrepo;
      $gitrepo = Git->repository (Directory => "$fullpath"); 
      my $lastrev = $gitrepo->command_oneline( [ 'rev-list', '--all' ],
					     STDERR => 0 );
      print "Lat revision: $lastrev\n";              # for debugging
      $config{'vcs'} = "git";                        # git is our VCS
      chdir($fullpath);
      my $git_status = $gitrepo->command_oneline('status');
      print "Checking for uncommitted modifications to directory . . .\n";
      print "$git_status\n"; # <-- This doesn't seem to be working.
      die "die for now.";
    }
  }
  my @contents = slurp "$fullpath/debian/control";
  my $ctrl_ref = \@contents;
  remove_old_urls($ctrl_ref);                        # remove links to old resources
  testvcs("$fullpath/debian/control");               # add any missing URLs
}

=back

=cut


1; # End of packagecheck.pl

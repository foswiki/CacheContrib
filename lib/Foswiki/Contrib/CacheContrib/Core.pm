# Extension for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# CacheContrib is Copyright (C) 2020 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Contrib::CacheContrib::Core;

use strict;
use warnings;

use Foswiki::Func ();
use CHI ();

use constant TRACE => 0; # toggle me

sub new {
  my $class = shift;

  my $this = bless({
      cacheExpire => $Foswiki::cfg{CacheContrib}{CacheExpire} || '1 d',
      driver => $Foswiki::cfg{CacheContrib}{Driver} || 'File',
    @_
  }, $class);

  $this->{cacheRoot} //= Foswiki::Func::getWorkArea('CacheContrib');

  return $this;
}

sub cache {
  my ($this, $namespace) = @_;

  $namespace ||= 'default';

  _writeDebug("cache for $namespace");

  unless (defined $this->{cache}{$namespace}) {
    $this->{cache}{$namespace} = CHI->new(
      driver => $this->{driver},
      root_dir => $this->{cacheRoot},
      expires_in => $this->{cacheExpire},
      namespace => $namespace,
      l1_cache => { 
        driver => 'Memory', 
        max_size => 1024*1024,
        global => 1,
      }
    );
  }

  return $this->{cache}{$namespace};
}

sub purgeCache {
  my ($this, $namespace) = @_;

  if (defined $namespace) {
    _writeDebug("puring cache for $namespace");
    $this->cache($namespace)->purge;
  } else {
    $this->purgeCache($_) foreach $this->cache->get_namespaces();
  }
}

sub clearCache {
  my ($this, $namespace) = @_;

  if (defined $namespace) {
    _writeDebug("clearing cache for $namespace");
    $this->cache($namespace)->clear;
  } else {
    $this->clearCache($_) foreach $this->cache->get_namespaces();
  }
}

sub _writeDebug {
  return unless TRACE;
  print STDERR "CacheContrib::Core - $_[0]\n";
  #Foswiki::Func::writeDebug("CacheContrib::Core - $_[0]");
}

1;

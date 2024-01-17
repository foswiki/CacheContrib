# Extension for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# CacheContrib is Copyright (C) 2020-2024 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Contrib::CacheContrib;

=begin TML

---+ Foswiki::Contrib::CacheContrib

Interface to the caching services. This consists of two parts:

   1 basic caching: cache computational results for a short period of time for faster access
   2 a caching user agent: fetch external resources and cache them

Both of these requirements happen so often in Foswiki plugins that they have been provided as
a basic service to be accessed by third party plugins. For instance, !ImagePlugin caches
image geometries as analysing and extracting this information from pictures can be quite expensive.
!NumberPlugin fetches exchange rates of currencies from an external provider and caches them locally.
!FeedPlugin fetches RSS and Atom feeds and caches them locally when rerendering them on a Foswiki page.
!SolrPlugin serializes binary document formats while indexing their content with interim results cached
locally to speed up reindexing those documents.

=cut

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Contrib::CacheContrib::UserAgent ();

our $VERSION = '3.10';
our $RELEASE = '%$RELEASE%';
our $SHORTDESCRIPTION = 'Caching services for Foswiki extensions';
our $LICENSECODE = '%$LICENSECODE%';
our $NO_PREFS_IN_TOPIC = 1;
our $core;
our %userAgents;

sub _getCore {
  unless (defined $core) {
    require Foswiki::Contrib::CacheContrib::Core;
    $core = Foswiki::Contrib::CacheContrib::Core->new();
  }

  return $core;
}

=begin TML

---++ getUserAgent($namespace) -> $ua

returns a singleton caching user agent compatible to CPAN:LWP::UserAgent.
The optional =namespace= (defaults to "UserAgent") parameter defines the cache section used for this agent.

=cut

sub getUserAgent {
  my $namespace = shift || "UserAgent";

  my $ua = $userAgents{$namespace};

  $ua = $userAgents{$namespace} = Foswiki::Contrib::CacheContrib::UserAgent->new($namespace, @_)
    unless defined $ua;

  return $ua;
}

=begin TML

---++ getCache($namespace, $expire) -> $cache

returns a [[CPAN:CHI][CHI cache object]] for the given namespace.

<verbatim>
my $cache = Foswiki::Contrib::CacheContrib::getCache("ImagePlugin");
</verbatim>

=cut

sub getCache {
  return _getCore()->cache(@_);
}

=begin TML

---++ getExternalResource($url, ...) -> $response

Fetch an external resource using the caching !UserAgent. This is equivalent
to =Foswiki::Func::getExternalResource()= with just adding caching.
It basically is compatible with =[[https://metacpan.org/pod/LWP::UserAgent#get][LWP::UserAgent::get]]=.

Usage:

<verbatim>
my $response = Foswiki::Contrib::CacheContrib::getExternalResource($url);

throw Error::Simple("http error fetching $url: ".$response->code." - ".$response->status_line)
  unless $response->is_success;

my $content = $response->decoded_content();
</verbatim>

=cut

sub getExternalResource {
  return getUserAgent()->get(@_);
}

=begin TML

---++ clearCache($namespace)

clears the cache for the given namespace

=cut

sub clearCache {
  return _getCore()->clearCache(shift);
}

sub cgiClearCache {
  my ($session) = @_;

  my $request = Foswiki::Func::getRequestObject();
  my $namespace = $request->param("namespace");

  return clearCache($namespace);
}

=begin TML

---++ purgeCache($namespace)

purges expired entries of the cache for the given namespace

=cut

sub purgeCache {
  return _getCore->purgeCache(shift);
}

sub cgiPurgeCache {
  my ($session) = @_;

  my $request = Foswiki::Func::getRequestObject();
  my $namespace = $request->param("namespace");

  return purgeCache($namespace);
}

1;

# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
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

package Foswiki::Contrib::CacheContrib::UserAgent;

use strict;
use warnings;

use Foswiki::Func();
use Foswiki::Contrib::CacheContrib();
use LWP::UserAgent();
our @ISA = qw( LWP::UserAgent );

use constant TRACE => 0; # toggle me

sub new {
  my $class = shift;

  my $this = $class->SUPER::new(@_);

  my $proxy = $Foswiki::cfg{PROXY}{HOST};
  if ($proxy) {
    $this->proxy(['http', 'https'], $proxy);

    my $noProxy = $Foswiki::cfg{PROXY}{NoProxy};
    if ($noProxy) {
      my @noProxy = split(/\s*,\s*/, $noProxy);
      $this->no_proxy(@noProxy);
    }
  }

# $this->ssl_opts(
#   verify_hostname => 0,
# );

  $this->agent($Foswiki::cfg{CacheContrib}{UserAgentString} || 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/74.0.3729.169 Chrome/74.0.3729.169 Safari/537.36'); 

  return $this;
}

sub request {
  my $this = shift;
  my @args = @_;
  my $request = $args[0];

  my $method = $request->method();
  return $this->SUPER::request(@args) unless $method =~ /^(GET|HEAD)$/;

  my $uri = $request->uri;
  my $cache = Foswiki::Contrib::CacheContrib::getCache("UserAgent");
  my $key = $uri->as_string();
  my $obj;

  my $cgiRequest = Foswiki::Func::getRequestObject();
  my $refresh = $cgiRequest->param("refresh") || '';
  $refresh = ($refresh =~ /^(on|ua)$/) ? 1:0;

  $obj = $cache->get($key) unless $refresh;

  if (defined $obj) {
    _writeDebug("... found in cache $uri");
    return HTTP::Response->parse($obj);
  } 

  _writeDebug(" ... fetching $uri");
  my $res = $this->SUPER::request(@args);

  ## cache only "200 OK" content
  if ($res->code eq HTTP::Status::RC_OK) {
    $cache->set($key, $res->as_string());
  }

  return $res;
}

sub _writeDebug {
  print STDERR "CacheContrib::UserAgent - $_[0]\n" if TRACE;
}

1;


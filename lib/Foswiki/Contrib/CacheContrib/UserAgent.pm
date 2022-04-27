# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# CacheContrib is Copyright (C) 2020-2022 Michael Daum http://michaeldaumconsulting.com
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
#use Data::Dump qw(dump);
our @ISA = qw( LWP::UserAgent );

use constant TRACE => 0; # toggle me

sub new {
  my $class = shift;
  my $namespace = shift || "UserAgent";
  my %params = @_;

  my $this = $class->SUPER::new(%params);

  my $proxy = $Foswiki::cfg{PROXY}{HOST};
  if ($proxy) {
    $this->proxy(['http', 'https'], $proxy);

    my $noProxy = $Foswiki::cfg{PROXY}{NoProxy};
    if ($noProxy) {
      my @noProxy = split(/\s*,\s*/, $noProxy);
      $this->no_proxy(@noProxy);
    }
  }

  #$this->ssl_opts(verify_hostname => 0);
  my $sslCAPath = $Foswiki::cfg{CacheContrib}{SSLCAPath};
  $this->ssl_opts(SSL_ca_path => $sslCAPath) if $sslCAPath;

  $this->agent($Foswiki::cfg{CacheContrib}{UserAgentString} || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36'); 
  $this->{namespace} = $namespace;
  $this->{expire} = $params{expire};
  $this->{ignoreParams} = {};

  return $this;
}

sub getCache {
  my ($this, $expire) = @_;

  $expire //= $this->{expire};
  return Foswiki::Contrib::CacheContrib::getCache($this->{namespace}, $expire);
}

sub ignoreParams {
  my ($this, @keys) = @_;

  if (@keys) {
    $this->{ignoreParams}{$_} = 1 foreach @keys;
  }

  return keys %{$this->{ignoreParams}};
}

sub getCacheKey {
  my ($this, $request) = @_;

  my @key = ();
  my $uri = $request->uri();

  push @key, $uri->scheme();
  push @key, $uri->authority();
  push @key, $uri->path();

  my %query = $uri->query_form();
  foreach my $key (keys %query) {
    next if $this->{ignoreParams}{$key};
    push @key, "$key=$query{$key}";
  }

  my $key = join("::", @key);
  _writeDebug("key=$key");

  return $key;
}

sub request {
  my $this = shift;
  my @args = @_;
  my $request = $args[0];

  my $method = $request->method();
  return $this->SUPER::request(@args) unless $method =~ /^(GET|HEAD)$/;

  my $key = $this->getCacheKey($request);
  my $obj;

  my $cgiRequest = Foswiki::Func::getRequestObject();
  my $refresh = $cgiRequest->param("refresh") || '';
  $refresh = ($refresh =~ /^(on|ua|$this->{namespace})$/) ? 1:0;

  $obj = $this->getCache->get($key) unless $refresh;

  if (defined $obj) {
    _writeDebug("... found in cache $key");
    return HTTP::Response->parse($obj);
  } 

  _writeDebug(" ... fetching $key");
  my $res = $this->SUPER::request(@args);

  ## cache only "200 OK" content
  if ($res->code eq HTTP::Status::RC_OK) {
    $this->getCache->set($key, $res->as_string());
  } else {
    #_writeDebug("res=".dump($res));
  }

  return $res;
}

sub _writeDebug {
  print STDERR "CacheContrib::UserAgent - $_[0]\n" if TRACE;
}

1;


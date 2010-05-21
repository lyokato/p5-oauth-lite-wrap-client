use strict;
use warnings;

use Test::More tests => 5;

use OAuth::Lite::WRAP::Client::Response;

my $str = q{wrap_refresh_token=53ce29cc3c78eec5e3ee2f77680082928bdbbc90&wrap_access_token=0698dd96194d493fb4d97b0468767fb5|d1b6cd9ec301426ab835d35ab32dac5a};
my $res = OAuth::Lite::WRAP::Client::Response->parse($str);

is($res->access_token, "0698dd96194d493fb4d97b0468767fb5|d1b6cd9ec301426ab835d35ab32dac5a");
is($res->param("wrap_access_token"), "0698dd96194d493fb4d97b0468767fb5|d1b6cd9ec301426ab835d35ab32dac5a");

is($res->refresh_token, "53ce29cc3c78eec5e3ee2f77680082928bdbbc90");
is($res->param("wrap_refresh_token"), "53ce29cc3c78eec5e3ee2f77680082928bdbbc90");

$res->expires_in;

is($res->as_string, 'wrap_access_token=0698dd96194d493fb4d97b0468767fb5%7Cd1b6cd9ec301426ab835d35ab32dac5a&wrap_refresh_token=53ce29cc3c78eec5e3ee2f77680082928bdbbc90');


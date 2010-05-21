package OAuth::Lite::WRAP::Client::Error;

use strict;
use warnings;

use overload q{""} => \&message, fallback => 1;

sub throw {
    my ($class, $message) = @_;
    die $class->new($message);
}

sub new {
    my ($class, $message) = @_;
    bless { message => $message }, $class;
}

sub message { $_[0]->{message} }

package OAuth::Lite::WRAP::Client::Error::InvalidResponseFormat;
our @ISA = qw(OAuth::Lite::WRAP::Client::Error);

package OAuth::Lite::WRAP::Client::Error::TokenRequestFailed;
our @ISA = qw(OAuth::Lite::WRAP::Client::Error);

package OAuth::Lite::WRAP::Client::Error::MissingParam;
our @ISA = qw(OAuth::Lite::WRAP::Client::Error);

package OAuth::Lite::WRAP::Client::Error::InsecureRequest;
our @ISA = qw(OAuth::Lite::WRAP::Client::Error);

package OAuth::Lite::WRAP::Client::Error::InsecureResponse;
our @ISA = qw(OAuth::Lite::WRAP::Client::Error);

package OAuth::Lite::WRAP::Client::Error;

1;

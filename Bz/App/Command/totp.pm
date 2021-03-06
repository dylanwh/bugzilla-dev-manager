package Bz::App::Command::totp;
use parent 'Bz::App::Base';
use Bz;

use IPC::System::Simple qw( capture );

sub abstract {
    return "execute oathtool with the totp secret for the provided account";
}

sub execute {
    my ($self, $opt, $args) = @_;
    my $login = shift @$args;

    if ($login && $login !~ /\@/) {
        oathtool($login);
        return;
    }

    my $workdir = Bz->current_workdir;

    if (!$login) {
        $login = Bz->config->params->maintainer;
        info("defaulting to $login");
    }

    my $dbh = $workdir->dbh;
    my ($user_id) = $dbh->selectrow_array("SELECT userid FROM profiles WHERE login_name=?", undef, $login);
    die "invalid user: $login\n" unless $user_id;
    my ($secret) = $dbh->selectrow_array("SELECT value FROM profile_mfa WHERE user_id=? AND name='secret'", undef, $user_id);
    die "$login does not have TOTP enabled\n" unless $secret;

    require Convert::Base32;
    oathtool(Convert::Base32::encode_base32($secret));
}

sub oathtool {
    my ($secret32) = @_;
    my $code = capture('oathtool', '--totp', '--base32', $secret32);
    chomp($code);
    print "$code\n";
    clipboard($code);
}

1;

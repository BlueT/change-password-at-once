#!/usr/bin/perl
# http://stupidfool.org/perl/docs/perldoc/Net/SSH/Perl.html

use Net::SSH::Perl;

$user = "matthew";
$pass = "23242621";
@IPs=qw/127.0.0.1 192.168.1.104/;
#$cmdcat = "cat /etc/redhat-release";

print "now Smoking.....\n";

foreach $host (@IPs) {
    #print "login to $host\n";
    my $ssh = Net::SSH::Perl->new($host,protocol => 2);
    $ssh->login($user, $pass);
    print "We're now in $host\n";
    ($_) = $ssh->cmd($cmdcat);
#    /pdate 3/?$ssh->cmd($cmd3):/pdate 4/?$ssh->cmd($cmd4):(print "unknown OS: $host\n")&&(($_, $stderr) = $ssh->cmd(ls));;
    #print "lshw installed (or not :p)\n";
    open(F, ">$host");
    $ssh->cmd("echo \"$pass\"|sudo -S ls");
#    ($lshw)=$ssh->cmd('sudo lshw');
	($lshw)=$ssh->cmd('sudo ls');
    #print "$lshw";
    print F "$lshw";
    print "got $host info\n";
    $ssh->cmd("exit");
}
close F;


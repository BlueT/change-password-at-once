#!/usr/bin/env perl

use utf8;
use Net::SSH::Expect;
use Data::Dumper;
use Parallel::ForkManager;

# Set MAX fork process number
my $MAX_PROCESSES = 30;


my ($user, $pass_orig, $pass_new);
my @IPs;


# Read hosts we need to change password from file
open(IPS, '<', "ChangePasswordAtOnce.list") or die $!;
while(<IPS>){
        # slurp commented lines and the newline character
        chomp;
        next if /^\s+?#/;
        s/\s+?#[\w\W]+?$//;
        
        # Put the hosts into array
        push @IPs, $_;
}
close IPS;


# Get the name and old/new password for login and change
print "Username: ";
chomp($user = <STDIN>);
print "Current Password: ";
chomp($pass_orig = <STDIN>);
print "New Password: ";
chomp($pass_new = <STDIN>);


# List down all hosts
print "Going to change passwords on the following hosts:\n";
print Dumper @IPs;


# Initial the Fork Manager
my $pm = new Parallel::ForkManager($MAX_PROCESSES);


# Do the jobs on all servers
foreach my $host (@IPs) {
        
        # Forks and returns the pid for the child:
        my $pid = $pm->start and next;

        # Making an ssh connection with user-password authentication
        # 1) construct the object
        my $ssh = Net::SSH::Expect->new (
                host => $host,
                password=> $pass_orig,
                user => $user,
                raw_pty => 1
        );

        # 2) logon to the SSH server using those credentials.
        # test the login output to make sure we had success
        my $login_output = $ssh->login();
        if ($login_output !~ /Welcome/) {
                die "Login has failed. Login output was $login_output";
        }


        $ssh->send("passwd");
        #~ print $ssh->peek(1);
        $ssh->peek(1);
        $ssh->waitfor('[\w\W]+UNIX[\w\W]+\s*\z', 1) or die "prompt 'password' not found after 1 second";
        #~ print $ssh->peek(1);
        $ssh->peek(1);
        $ssh->send($pass_orig);
        #~ print $ssh->peek(1);
        $ssh->peek(1);
        $ssh->waitfor('\s*\z', 1) or die "prompt 'New password:' not found";
        #~ print $ssh->peek(1);
        $ssh->peek(1);
        $ssh->send($pass_new);
        #~ print $ssh->peek(1);
        $ssh->peek(1);
        $ssh->waitfor('\s*\z', 1) or die "prompt 'Confirm new password:' not found";
        #~ print $ssh->peek(1);
        $ssh->peek(1);
        $ssh->send($pass_new);
        #~ print $ssh->peek(1);
        $ssh->peek(1);
        

        # check that we have the system prompt again.
        $ssh->waitfor('[>$#]\s*\z', 1, -re);  # waitfor() in a list context
        print $ssh->peek(1);
        my $before_match = $ssh->before;
        not $ssh->match ?
                print "Password changed on $host\n"
                :
                warn "passwd failed. passwd said '$before_match'.";
        

        # closes the ssh connection
        $ssh->close();
        
        $pm->finish; # Terminates the child process

}

$pm->wait_all_children;


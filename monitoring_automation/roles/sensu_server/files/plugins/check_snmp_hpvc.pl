#!/usr/bin/perl

# author: Patrick Zambelli <patrick.zambelli@wuerth-phoenix.com>
# adapted for HP BladeSystem from check_snmp_IBM_Bladecenter.pl 
# author Eric Schultz <eric.schultz@mentaljynx.com>
# what:    monitor various aspects of the HP Bladesystem
# license: GPL - http://www.fsf.org/licenses/gpl.txt
#
# =========================================================================== #
# Usage: $PROGNAME -H <host> -C <snmp_community> -t <test_name> [-n <ele-num>] [-w <low>,<high>] [-c <low>,<high>] [-o <timeout>] \n"; }
#/usr/lib/nagios/plugins/check_snmp_HP_Bladesystem.pl -H 10.62.5.161 -C public -w 3: -c 4: -t Fan-Conditions
# OK Fan-Conditions (2) Fan return codes: 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 
# The overall return condition is 2 = OK. Array of integers holds the return status of the single fans.
#

use strict;
require 5.6.0;
use lib qw( /usr/local/nagios/libexec );
use utils qw(%ERRORS $TIMEOUT &print_revision &support &usage);
use Net::SNMP;
use Getopt::Long;
use vars qw/$exit $message $opt_version $opt_timeout $opt_help $opt_command $opt_host $opt_community $opt_verbose 
$opt_port $opt_mountpoint $snmp_session $PROGNAME $TIMEOUT $test_details $test_name $test_num $uplinks/;

$PROGNAME      = "check_snmp_hpvc.pl";
$opt_verbose   = undef;
$opt_host      = undef;
$opt_community = 'public';
$opt_command   = undef;
$opt_port      = 161;
$message       = undef;
$exit          = 'OK';
$test_details  = undef;
$test_name     = undef;
$test_num      = 1;
$uplinks       = undef;


# =========================================================================== #
# =====> MAIN
# =========================================================================== #
process_options();

alarm( $TIMEOUT ); # make sure we don't hang Nagios

my $snmp_error;
($snmp_session,$snmp_error) = Net::SNMP->session(
		-version => 'snmpv2c',
		-hostname => $opt_host,
		-community => $opt_community,
		-port => $opt_port,
		);

#my $operStatusX1oid="1.3.6.1.2.1.2.2.1.8.1017";
my $operStatusX2oid="1.3.6.1.2.1.2.2.1.8.1018";
my $operStatusX3oid="1.3.6.1.2.1.2.2.1.8.1019";
#my $operStatusx4oid="1.3.6.1.2.1.2.2.1.8.1020";

my $operStatusX2 = undef;
my $operStatusX3 = undef;
my $res = "Ok";
$|=1;

my ($operStatusX2,$operStatusX3,$operStatusX_text)=('','','');

if($test_name =~ m/^uplinks$/i){
    
  if($uplinks =~ m/x2/i) { 
	$operStatusX2 = SNMP_getvalue($snmp_session,$operStatusX2oid);
     
	$operStatusX_text='UnKnown';
	$operStatusX_text='X2 is down' if $operStatusX2 == 2;
	$operStatusX_text='X2 is Up' if $operStatusX2 == 1;
        $res = "CRITICAL" if($operStatusX2 == 2 );
   }	
  elsif($uplinks =~ m/x3/i) {
        $operStatusX3 = SNMP_getvalue($snmp_session,$operStatusX3oid);

        $operStatusX_text='UnKnown';
        $operStatusX_text='X3 is down' if $operStatusX3 == 2;
        $operStatusX_text='X3 is Up' if $operStatusX3 == 1;
        $res = "CRITICAL" if($operStatusX3 == 2 );
  }
  else {
        $res = "UNKNOWN"; 
	}

}



$snmp_session->close;
alarm( 0 ); # we're not going to hang after this.



print "$res: Uplink $operStatusX_text\n";
exit $ERRORS{$res};

# =========================================================================== #
# =====> Sub-Routines
# =========================================================================== #


sub process_options {
	Getopt::Long::Configure( 'bundling' );
	GetOptions(
			'V'     => \$opt_version,       'version'     => \$opt_version,
			'v'     => \$opt_verbose,       'verbose'     => \$opt_verbose,
			'h'     => \$opt_help,          'help'        => \$opt_help,
			'H:s'   => \$opt_host,          'hostname:s'  => \$opt_host,
			'p:i'   => \$opt_port,          'port:i'      => \$opt_port,
			'C:s'   => \$opt_community,     'community:s' => \$opt_community,
			'o:i'   => \$TIMEOUT,           'timeout:i'   => \$TIMEOUT,
			'T:s'	=> \$test_details,	'test-help:s' => \$test_details,
			't:s'	=> \$test_name,		'test:s'      => \$test_name,
			'n:i'	=> \$test_num,		'ele-number:i'      => \$test_num,
			'u:s'	=> \$uplinks,		'ele-number:i'      => \$uplinks
		  );
	if ( defined($opt_version) ) { local_print_revision(); }
	if ( defined($opt_verbose) ) { $SNMP::debugging = 1; }
	if ( !defined($opt_host) || defined($opt_help) 
		|| defined($test_details) || !defined($test_name) ) {
		
		print_help();
		if(defined($test_details)) { print_test_details($test_details); }
		exit $ERRORS{UNKNOWN};
		}
	}

sub print_test_details{
	my ($t_name) = @_;
	print "\n\nDETAILS FOR: $t_name\n";
	my %test_help;
	$test_help{'System-State'}=<<__END;
Returns the System State Code, Values are:
	2	ok
	3	warning
	4	critical
	1	Unknown
__END
	
	$test_help{'uplinks'}=<<__END;;
Returns the status of the virtual connect uplinks. 
__END

	print $test_help{$t_name};
}

sub local_print_revision { print_revision( $PROGNAME, '$Revision: 1.0 $ ' ); }

sub print_usage { print "Usage: $PROGNAME -H <host> -C <snmp_community> -t <test_name> [-o <timeout>] \n"; }

sub SNMP_getvalue{
	my ($snmp_session,$oid) = @_;

	my $res = $snmp_session->get_request(
			-varbindlist => [$oid]);
	
	if(!defined($res)){
		print "ERROR: ".$snmp_session->error."\n";
		exit;
		}
	
	return($res->{$oid});
	}

sub print_help {
	local_print_revision();
	print "SNMP check for HP Virtual Connects\n";
	print_usage();
print <<EOT;
	-v, --verbose
		print extra debugging information
	-h, --help
		print this help message
	-H, --hostname=HOST
		name or IP address of host to check
	-C, --community=COMMUNITY NAME
		community name for the host's SNMP agent
	-T, --test-help=TEST NAME
		print Test Specific help for A Specific Test
	-t, --test=TEST NAME
		test to run
        -u, --uplink-port=port
                x2 or x3 only at the moment. 

POSSIBLE TESTS:
	uplinks
EOT

	}

sub verbose (@) {
	return if ( !defined($opt_verbose) );
	print @_;
	}

#!/usr/bin/perl -w
use strict;
###########################################################
#
# Author: Mick Shaw
# File: DOESVariableCounter.pl
# Date: 04/17/2020
#
# 
# This script will be used to set Avaya DOES variables 
# to zero or any other value when calls in the DOES 
# Genesys Queue(s) reach a certain threshold
#
# The DOES variables can then be used to dynamically
# route a predefined number calls to the third-party
# call-center
#
# TODO 
# Need Access to Genesys API to read calls in queue
#
# "$PBX" variable defines the CM instance. The connection
# details of each instance are defined in the OSSI
# Module (cli_ossi.pm).
#
# Note: If the $PBX variable changes, the OSSI Module must
# be updated as well
#
#	
#
#
###########################################################

###########################################################

# COMMUNICATION MANAGER API INTERFACE
# The cli_ossi module listed below is a modified version of
# Ben Roy's Definity.pm which is used to interface with
# Communication Manager via XML Interface.
# https://github.com/benroy73/pbxd/blob/master/pbx_lib/lib/PBX/DEFINITY.pm

require "/opt/Avaya-Utility-Script/cli_ossi.pm";
import cli_ossi;
use lib '/opt/Avaya-Utility-Script/SNMP_Session-1.13/lib';
use lib '/opt/Avaya-Utility-Script/Otherlibs';

###########################################################

#############################################################

use Getopt::Long;
use Pod::Usage;
use Net::Nslookup;
use Net::MAC;
use Mail::Send;
use MIME::Lite;

#############################################################
# COMMUNICATION MANAGER CONNECTION
# The $pbx variable is defined in the cli_ossi.pm module
# which provides connection details for Aura Communication Manager
my $pbx = 'PSCC';
#############################################################

# Intialize variables
my $debug ='';
my $node;
my $BU_Assignment;
my $BV_Assignment;
my $CMVariable;
my $emailaddresses = 'voice.eng@dc.gov';
my $msg;

###########################################################
#
# OSSI Feild identifiers
#
# Relevant FID
#-------------------------------------------------
# 7005ff49 = Variable BU Assignment
# 7005ff4a = Variable BV Assignment
###########################################################
sub get_Variables()
{

$node->pbx_command("display variable BU");
if ($node->last_command_succeeded())
{
my @ossi_output = $node->get_ossi_objects();
my $hash_ref = $ossi_output[0];
my $BU_Variable = $hash_ref->{'7005ff49'};
my $BV_Variable = $hash_ref->{'7005ff4a'};
return ($BU_Variable,$BV_Variable);

}
}


$node = new cli_ossi($pbx, $debug);
unless( $node && $node->status_connection() ) {
die("ERROR: Login failed for ". $node->get_node_name() );
}

sub setBU_Variable
{

my %field_params = ( '7005ff49' => $BU_Assignment );
my $command = "change variable BU";
$node->pbx_command( $command, %field_params );
if ($node->last_command_succeeded())
{
return(0);
}
else {
		print "Error: ". $node->get_last_error_message ."\n";
		return(1);
	}
}
sub setBV_Variable{

my %field_params = ( '7005ff4a' => $BV_Assignment );
my $command = "change variable BV";
$node->pbx_command( $command, %field_params );
if ($node->last_command_succeeded())
{
return(0);
}
else {
                print "Error: ". $node->get_last_error_message ."\n";
                return(1);
        }
}

$node = new cli_ossi($pbx, $debug);
unless( $node && $node->status_connection() ) {
die("ERROR: Login failed for ". $node->get_node_name() );
}

#Get variable BF and BU values

($BU_Assignment, $BV_Assignment) = &get_Variables();

print "DOES Variable BU is currently set to $BU_Assignment\n";
print "DOES Variable BV is currently set to $BV_Assignment\n";


# Reset Variable Assignments

$BU_Assignment = 0;
$BV_Assignment = 0;
#Reset PSCC variable BU.

setBU_Variable();
print "DOES Variable BU has been set to $BU_Assignment\n";
setBV_Variable();
print "DOES Variable BV has been set to $BV_Assignment\n";


$node->do_logoff();

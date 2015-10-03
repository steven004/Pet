#######################################################################################
# This file is just an example about how to use Pet
# Author: Li, Xin
# Revision History:
#   V0.1    03/14/2011  the initial version
#
#######################################################################################

use IQstream::IQstream;
use Servers::TCPReplayer;

# The description of the test suite
TestSuiteName("TCPReplay TEST - M1 Oct.5th 1-9");
TestSuitePurpose("To replay M1's Pcap file to find any problems in our system ");
TestSuiteDes("5 hours traffic");
TestSuiteEnv("Pure IP transport network, 2 RNs; Cells: xxxxx");
TestRecTo(CONSOLE|HTML|TMS);



sub TestBedSetup {
	
	#add your scripts here#
	1;
}

sub TestBedClearup {
	#add your scripts here#
	1;
}


1;

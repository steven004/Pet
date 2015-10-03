#######################################################################################
# This file is just an example about how to use Pet
# Author: Li, Xin
# Revision History:
#   V0.1    03/11/2011  the initial version
#
#######################################################################################

require 5.8.1;
use strict;
use Pet::Pet;
use Pet::MathForTest;

# The description of the test suite
TestSuiteName("An example to show how Pet test plan works");
TestSuitePurpose("To provide an example/template for test engineers to write test plans/cases/testbeds. ");
TestSuiteDes("In this test suite, there are some cases to do addition, subtraction and so on, to show how Pet works");
TestSuiteEnv("There is no equipment required for this example, we just do some mathematics");
TestRecTo(&CONSOLE | &HTML | &EMAIL);

sub TestBedSetup {

	#add your scripts here#
	1;

}

sub TestBedClearup {
	#add your scripts here#
	1;
}


1;

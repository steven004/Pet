Perl Engine for Testing
==================================

PET (Perl Engine for Testing) implements a framework to write test scripts and
record test results in different ways.

Pet can be used as an engine, and also can be used as a Perl module, built in your program.

For more information, see Document folder to get the implementation and user guide.

**This module is free to use, but I have no time to maintain. If anybody is interested, please let me know**

NAME
----

::

    Pet::Recorder::TestRecorder - provides a framework for writing test scripts and recording test results.

    Version = 1.0.0


QUICK START GUIDE
------------------

It's easy to use the subroutines provided by TestRecorder package, just like using any general package for Perl. You need install the TestRecorder Package first, and then, in your code, use or require this module, invoke any subroutines provided by it. Comparing general packages, the TestRecorder package might be much easier. This module defines a bunch of public constants, subroutines and different ways of test records. All the public constants and subroutines are exported by the use Pet::Recorder::TestRecorder; statement.

While you are working in the Sycamore SQA Automation environment, that means you are running your code in a view of sqa VOB, this package is already installed, so that you can directly use the package without any worry about the installation. For more detailed information about the public members of this module, refer to CONSTANTS, SUBROUTINES and RECORD OPTIONS parts.

From reviewability and maintainability point of view, we suggest all scripts writers to follow the conventions below while writing scripts:

    -         Invoke TestSuite related subroutines to indicate the attributes of the test in TestSuite.pl file or TestPlan.pl file.

    -         Invoke TestStart subroutine to start test, and indicate the test attributes as arguments for it.

    -         Start a test case by using the CaseStart() subroutine, followed by a bare block.

    -         Finish a test case by using the CaseEnd() subroutine, after block of the case.

    -         Multiple TestStep related subroutines can be invoked in a case block, each invoking means a test step to be recorded.

    -         Use Log related subroutines to record any logs, which will be recorded in log file.

    -         Invoke TestEnd subroutine to finish a test task.

    -         Use Environment Variables to define the test report path and formats of test records if you do not like to default setting.




SYNOPSIS
---------

.. code-block:: perl

    use strict;
    use Pet::Recorder::TestRecorder;

    # load your module...
    use MyModule;
    # I'm testing MyModule version $MyModule::VERSION

    TestSuiteName("TestSuite Example");
    TestSuiteDes("Show some subroutines of TestRecorder Package here");

     TestStart(User => 'Xin',
               TestPlan => 'Test Demo',
                 ReleaseNo => 'Pet V1.0',
                 MailAddress => 'steven004@gmail.com');

     CaseStart("The 1st test case");
     {
            Step(PASS, "the 1st step");                  # Step 1 pass
            Step(2==(1+1), "the 2nd step");              # Step 2 pass
            Pass("the 3rd step");                        # Step 3 pass
            Is(3*2, 6, "The 4th Step");                          # step 4 pass: 3*2==6
            Like("Hello World!", "Hello", "The 5th step");       # Step 5 pass
            Isnt(1, 2, "The 6th step");                  # Step 6 pass
            Fail("The 7th step");                        # Step 7 fail
            TestLog(ERROR, "Step 7 failed");             # Record a ERROR message in Log file
     } CaseEnd();                                         # Case fail since there is one step fail

     CaseStart("The 2nd test case");
     {
             Step(myModule::myfun1(parameters), "step 1") || last;
             Like(myObj->get_alarms(), "LOS", "Step 2") || last;
             Step(MyObj->hit_time()<50, "Step 3") || last;        # if myObj hit time is less than 50ms, then pass.
     } CaseEnd();                                                # Case will pass if all steps pass, otherwise fail.

     CaseStart("The 3rd test case example");
     {
             my $myResult = PASS;
             myModule::Checkfun1(parameters) or next;     # if fail, run continue block to do some cleaning and case end
             myModule::Checkfun2(Parameters) or next;
             myModule::Checkfun3(Parameters) or next;
             last;                         # the case passed, go to CaseEnd¡­
     }continue                          # if the case failed, then do something before the CaseEnd¡­
     {
             $myResult = FAIL;
             myModule::cleaningfun();       # do some cleaning
     } CaseEnd($myResult, "some description");

     CaseStart("The 4th Case");
     {
             Isnt(4+1, 5, "Should pass");
             Fail("Just failed");
             Pass("Just passed");
             TestLog(DEBUG, "Pass just be tested");
             TestLog(WARNING, "Warning message");
             TestLog(TRACE, "Trace message");
             TestLog(ERROR, "Error message");
             TestLog(INFO, "Information");
             Fail("Just Failed");
             WarningMsg("no condition, just failed, tested");
             InfoMsg("direct information");
             DebugMsg("Direct Debug message");
             ErrorMsg("direct Error Message");
     } CaseEnd();

     CaseStart("The 5th Case");
     {
             Steps q{
                     Mymath::sum::2::3::4::5==14; #result is __result__## a Tea-like step
                     ::maximum::$i::$j::$k; ###also Tea-like, but no object, invoke the public function
                     90*90>180; #Should pass #What¡¯s wrong # A Perl statement
                     #A comment line
                     Port::::Up; #Should Fail, format error.
             };
     } CaseEnd();

     TestEnd();



License
-------

This software is licensed under the `MIT license <http://en.wikipedia.org/wiki/MIT_License>`_.

© 2010 Steven LI


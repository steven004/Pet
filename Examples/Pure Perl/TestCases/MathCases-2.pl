
#Same as MathCases-1.pl, just for testing. 

CaseStart("The first Case");
{
	Step(3*2==6, "1st step -- 3*2==6");
	Step(' ', "2nd step -- true");
  sleep 2;
	Is(3*2, 6, "3rd step -- 3*2 is 6?");
} CaseEnd();

CaseStart("The second Case");
{
	Is(5, 4+1, "5 isnt 4+1?");
  sleep 1;
	Like("The People's Republic of China", "China", "China is PRC?");
  Unlike("Shanghai", "Suzhou", "Shanghai unlike Suzhou");
}CaseEnd(8-7==1, "8-7==1?");

CaseStart("The third Case");
{
  Isnt('4+1', '5', "Should pass");
  Fail("Just failed");
  sleep 3;
	Pass("Just passed");
	TestLog(DEBUG, "Pass just be tested");
  sleep 1;
	Fail("Just Failed");
	WarningMsg("no condition, just failed, tested");
} CaseEnd();


CaseStart("The 4th Case");
{
  Isnt(4+1, 5, "Should pass");
  sleep 1;
  Fail("Just failed");
	Pass("Just passed");
	TestLog(DEBUG, "Pass just be tested");
  TestLog(WARNING, "Warning message");
  sleep 1;
  TestLog(TRACE, "Trace message");
  TestLog(ERROR, "Error message");
  TestLog(INFO, "Information");
	Fail("Just Failed");
	WarningMsg("no condition, just failed, tested");
  InfoMsg("direct information");
  DebugMsg("Direct Debug message");
  ErrorMsg("direct Error Message");
} CaseEnd();

our ($i, $j, $s, $c, $k) = (10, 20, 30, 'Li xin', 'x');

CaseStart("The 5th Case");
{
  TestLog(TRACE, "------- Steps Example ---------");

    Steps q{
        Math::add::2::3::5::6==16; #__result__==16? should pass
        ::mysum::4::5::6::7==22; # __result__ ==22? should pass # What's wrong
        $i > 10; # \$i==__result__ \$i>10?
        $i < $j; # \$i==__result__ \$i<20?
        $c =~ $k; # Li xin has x # what's wrong
        sleep(10); #sleep 3 seconds ## Do not use it, will not really sleep.
        $i+$j == $s; # Result=__result__==$s? Pass#
        #asjkldf;j kag;h ak;lg
        ;
        ($i+$j)*$s > 100; # __result__ > 100; should pass
        Math::::2::5::7 == 20;  # Error Step.
        Math::sub::100::20 == 80; # Error Step Example
    };

} CaseEnd();

1;


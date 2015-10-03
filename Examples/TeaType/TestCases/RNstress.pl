
#Do some RN rebooting while PCAP running. 

CaseStart("Setup the test environment");
{
	Unlike($SUT->GetAlarms(), "Critical", "Confirm the system is healthy");
	Is($CN->GetAttributes(OperStatus), "up", "CN is up", "CN is down");
	Is($RN1->GetAttributes(OperStatus), "up", "RN1 is up", "RN1 is down");
	Is($RN2->GetAttributes(OperStatus), "up", "RN2 is up", "RN2 is down");
	Step($CONFIG->Download(), "Download config: __result__");
	sleep 200;
	Step($SUT->Reboot(Cold), "__result__");
	sleep 200;
} CaseEnd();

CaseStart("Run PCAP1 File");
{
	Steps q{
		PCAP1::Start::loop::10
		test::Timer::Start
		sleep 200;
		CN::CurrentTrafficKPI>0.0
		test::Timer::waitto::20m;#wait to 20m of the PCAP running
		CN::CurrentTrafficKPI>10%
		RN1::CurrentTrafficKPI>15%
		RN2::CurrentTrafficKPI>7%
		test::Timer::waitto::2h30m;# 2 and half hours
		CN::CurrentTrafficKPI>20%		
	}
}CaseEnd($SUT->GetAlarms());

CaseStart("Run both PCAP1 and PCAP2");
{
	Step($PCAP2->Start(loop, 5));
	test->Timer(waitto, '3h');
	Step($CN->CurrentTrafficKPI()>30%);
}CaseEnd();

CaseStart("Rebooting RNs");
{
	Step($RN1->Reboot(Cold));
	Step($RN2->Reboot(Cold));
	sleep 500;
	Step($CN->CurrentTrafficKPI()>1%);
	Step($RN1->CurrentTrafficKPI()>1%);
	Step($RN1->CurrentTrafficKPI()>1%);
	sleep 1000;
	Step($CN->CurrentTrafficKPI()>20%);
	Step($RN1->CurrentTrafficKPI()>20%);
	Step($RN1->CurrentTrafficKPI()>20%);
	Step($SUT->GetAlarms());
} CaseEnd();

CaseStart("Recover the test bed");
{
	Step($PCAP1->stop());
	Step($PCAP2->stop());
	sleep 50;
	Step($SUT->GetAlarms());
} CaseEnd();

1;


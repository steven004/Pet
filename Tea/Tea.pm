package Pet::Tea::Tea;

## ~*~ Tea: Test Engine Alpha ~*~ ##

## Executes scripts in the SQA library based on user defined 
## test configurations and test data input files to form 
## complete test cases and suites, and reports them

$VERSION = '1.2';

## User contributed documentation below, search for =head

use strict;

use base qw(Pet::Tea::Base);
use IQstream::Objects;
use Pet::Tea::Symbols;
use Pet::Tea::Parser;
use Pet::Tea::Runtime;
use Pet::Tea::Extensions;
use Data::Dumper;
use Pet::Recorder::TestRecorder;


## This is the constructor

sub new {

   my($class,%args) = @_;

   my $self = {
		_symbols     => '',
		_testcase    => '',
		_parser      => '',
		_config      => '',
		_input       => '',
		_errmsg      => '',
		_testcase    => '',
		_engineer    => '', ## required by DB
		_buildid     => '', ## Testcase to log
		_version     => '', ## results to DB
		_config_file => '',
		_input_file  => '',
		_outputdir   => '',
   };

   bless $self, $class;

   $self->errmode('return'); ## default to return on error

   ## initialize our parsing and symbol objects, the symbol object
   ## is responsible for initializing user defined modules to 
   ## be used during runtime, and executing methods of the modules

   $self->{_symbols} = new Pet::Tea::Symbols(Errmode => $self->errmode());
   $self->{_parser} = new Pet::Tea::Parser(Errmode => $self->errmode());

   ## break out the user args if they were given

   my($input_file,$config_file);

   for(keys %args) {

      if(/^-?Errmode$/i) {
          $self->errmode($args{$_});
      } elsif(/^-?Config$/i) {
          $config_file = $args{$_};
      } elsif(/^-?Input$/i) {
         $input_file = $args{$_};
      } elsif(/^-?Output$/i) {
          $self->{_outputdir} = $args{$_};
      } elsif(/^-?Engineer$/i) {
          $self->{_engineer} = $args{$_};
      } elsif(/^-?Version$/i) {
          $self->{_version} = $args{$_};
      } elsif(/^-?Build/i) {
          $self->{_buildid} = $args{$_};
      } 

   }

   ## create the directory structure for output logs

   $self->init_output_dir();

   ## give the log root directory to the symbols object
   ## so any objects used for testing can get to it

   $self->symbols()->output_dir($self->output_dir());

   ## now initialize the configuration and test input if
   ## they have been specified, otherwise load them later

   if(defined $config_file) {
      $self->init_config($config_file)
         or die $self->errmsg();
   }

   if(defined $input_file) {
      $self->init_input($input_file)
         or die $self->errmsg();
   }

   return $self;

}

## this object method calls the parser to read 
## the config file and then keeps a reference to
## the returned data structure.  It also passes the
## data to the symbol object wich initializes any
## test objects defined in config, returns 1 on success,
## or raises an error then returns undef on failure

sub init_config {

   my($self,$file) = @_;

   return $self->error('You must specify a config file to load!')
	if ! $file;

   ## store the file name incase its later needed

   $self->{_config_file} = $file;

   my $parse = $self->{_parser};
   my $symbols = $self->symbols();

   ## try to parse the data, or trap the error message

   my $map = $parse->config_file($file)
      or  return $self->error( $parse->errmsg() );

   ## expand macros should the exist

   if(scalar(keys %{$map->{MACRO_MAP}}) > 0) {
       $parse->config_macro_exp($map->{MACRO_MAP},$map->{CONFIG_MAP});
       $parse->config_template_exp($map->{MACRO_MAP},$map->{CONFIG_TEMPLATE});
   }

   ## substitute template names for actual templates in config map entries

   if(scalar(keys %{$map->{CONFIG_TEMPLATE}}) > 0) {
      $parse->config_template_subs($map->{CONFIG_TEMPLATE},$map->{CONFIG_MAP});
   }

   ## try to initialize user defined test objects

   $symbols->init( $map->{CONFIG_MAP} )
      or return $self->error( $symbols->errmsg() );

   my $symbol_table = $symbols->table();

   ## add a reference to this engine to allow
   ## running additional input files specified 
   ## in the test input file 

   $symbol_table->{engine} = $self;

   $symbols->table($symbol_table);

   ## store a reference to the config
 
   $self->config($map);

   return 1;

}

## this object method calls the parser to read
## the input file and then keeps a reference to
## the returned data structure.  It returns 1
## on success, or raises an error then returns 
## undef on failure

sub init_input {

   my($self,$file) = @_;

   return $self->error('You must specify an input file to load!')
        if ! $file;

   $self->{_input_file} = $file;

   my $parse = $self->{_parser};

   ## try to parse the file, or trap the error message

   my $test_data = $parse->input_file($file)
       or return $self->error( $parse->errmsg() );

   ## expand macros should they exist

   my $macro_map = $self->config()->{MACRO_MAP};

   if(scalar(keys %$macro_map) > 0) {
      $parse->input_macro_exp($macro_map,$test_data);
   }

   $self->proc_list($test_data->{PROCS});

   $self->input($test_data);

   return 1;
 
}

## the invoke method is used to kick off this engine
## for the first time, it makes sure everything is set
## to go, creates a Test::Testcase object, then
## runs the input file using run_test(). It returns
## 1 on success, or raises an error then returns
## undef on failure

## not really used in Pet framework


sub invoke {

   my $self = shift;

   ## insure everything required is defined

   my $possible_error = $self->errmsg();

   return $self->error($possible_error) if $possible_error;

   return $self->error('invoke() not allowed inside test, use run_test()')
		if $self->testcase();

   return $self->error('Config file not set, use init_config()') 
          if ! $self->config();

   ## try to create a new testcase object

   my $testcase = $self->init_reporting() or return;

   ## store a reference to the testcase

   $self->testcase($testcase);

   ## run the test

   my $success = $self->run_test();
   
   $testcase->end(); ## end the testcase

   return $success; ## return the result

}

## the run_test() method runs all procedures in the current 
## input file, or the only one!  It does this by creating
## a Tea::Runtime object and telling that what to do.
## it is special, it can be called from within the user
## defined input file to execute other input files. returns
## 1 on success, or raises an error then returns
## undef on failure

sub run_test {

   my ($self,$input) = @_;

   ## make sure that if i am called from inside the input file
   ## the user gave me an input file to run or else i will
   ## go out to lunch, stuck on the same incomplete call to myself

   return $self->error('An input file must be specified to call run_test()')
      if(caller eq 'Pet::Tea::Symbols' && !$input);
	
   my($original_input);

   ## if i have been called from the user input file (not invoke),
   ## save a reference to the original before i open the next, or else
   ## i wont know what to do when im finished running the new one

   $original_input = $self->input() if $input;

   $self->init_input($input) or return if $original_input;

   ## create a Tea::Runtime object

   my $runtime = new Pet::Tea::Runtime(Errmode => 'return');

   ## set the required reference

   $runtime->testcase( $self->testcase() );
   $runtime->symbols( $self->symbols() );
   $runtime->proc_list( $self->proc_list() );

   ## run the test

   my $success = $runtime->invoke();

   ## make the original input file current

   $self->input($original_input) if $original_input;

   ## return success or raise an error

   $success ? 1 : $self->error( $runtime->error() );

}   

## this method is only called from the input file
## to repeat a test
  
sub repeat_test {

   my ($self,$test,$times) = @_;

   for(my $i=0;$i<$times;$i++) {

      $self->run_test($test) or return;

   } 

   1;

}


## this method creates the directory structure where
## test output will be stored.  Default is ./output/timestamp
## if it has been specified we will attempt to create the
## sepecified structure plus a timestamp directory

sub init_output_dir {

   my $self = shift;

   ## build a timestamp for this run

    my ($sec, $min, $hour, $mday, $mon, $year) = localtime;

    my $month = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
    $year %= 100;

    my $str = sprintf("%02d%s%02d_%02d%02d%02d",
		      $mday, $month, $year, $hour, $min, $sec);

   ## default the output directory if not specified

   $self->output_dir('output') if ! $self->output_dir();

   ## append the timestamp to the ouput dir path

   $self->output_dir($self->output_dir().'/'. $str.'/');

   my(@desired_path,$existing_path);

   (@desired_path) = split(/\/+/,$self->output_dir());

   ## create the required directory structure for output
   
   while ( ! -e $self->output_dir() && @desired_path > 0) {

      $existing_path .= (shift @desired_path) . '/';

      if(! -e $existing_path) {

          mkdir $existing_path, 0777 or return
             $self->error("failed creating $existing_path: $!");

      } 

   }
      
   return;

}

######################################################################
## dump_guts(): debugging sub to dump the contents of this instance

sub dump_guts {

   my $self = shift;

   print Dumper($self);

   return 1;

}

## init_testbed() and run_case_file() functions for TEA extension for PET module
## Added by Peng Wan, 2010-02-05

######################################################################
## This is the constructor for PET Invoke

sub InitTestbed {

   my($class,%args) = @_;

   my $self = {

		_symbols => '',
		_testcase => '',
		_parser   => '',
		_config   => '',
		_input    => '',
		_errmsg   => '',
		_testcase => '',
		_engineer => '', ## required by DB
		_buildid  => '', ## Testcase to log
		_version  => '', ## results to DB
		_config_file => '',
		_input_file => '',
		_outputdir => '',
		_mailto => '',

              };

   bless $self, $class;
   
   $self->errmode('return'); ## default to return on error

   ## initialize our parsing and symbol objects, the symbol object
   ## is responsible for initializing user defined modules to 
   ## be used during runtime, and executing methods of the modules

   $self->{_symbols} = new Pet::Tea::Symbols(Errmode => $self->errmode());
   $self->{_parser} = new Pet::Tea::Parser(Errmode => $self->errmode());

   ## break out the user args if they were given

   my($input_file,$config_file);

   for(keys %args) {

      if(/^-?Errmode$/i) {
          $self->errmode($args{$_});
      } elsif(/^-?Config$/i) {
          $config_file = $args{$_};
#      } elsif(/^-?Input$/i) {
#         $input_file = $args{$_};
      } elsif(/^-?Output$/i) {
          $self->{_outputdir} = $args{$_};
      } elsif(/^-?Engineer$/i) {
          $self->{_engineer} = $args{$_};
      } elsif(/^-?Version$/i) {
          $self->{_version} = $args{$_};
      } elsif(/^-?Build/i) {
          $self->{_buildid} = $args{$_};
      } elsif(/^-?MailTo/i) {
          $self->{_mailto} = $args{$_};
      }  

   }

   ## create the directory structure for output logs

   $self->init_output_dir();

   ## give the log root directory to the symbols object
   ## so any objects used for testing can get to it

   $self->symbols()->output_dir($self->output_dir());

   ## now initialize the configuration and test input if
   ## they have been specified, otherwise load them later

   if(defined $config_file) {
      $self->init_config($config_file)
         or die $self->errmsg();
   }

	# export these parameters outside, 
	# then other perl scripts can invoke them
	my $symboles_table = $self->symbols()->table();
	no strict 'refs';	
	for my $symbol (keys %{$symboles_table}) {
		${"main::$symbol"} = $symboles_table->{$symbol};
	}
   return $self;

}

######################################################################
## RunCaseFile(): run the desinated testcase file

# sub RunCaseFile_by_TEA {
   # my $self = shift;
   # my $input_file = shift;
   # $self->init_input($input_file)
         # or die $self->errmsg();
	# return $self->invoke();
# }

######################################################################
## RunCaseFile(): run the desinated testcase file

sub RunCaseFile {
	my $self = shift;
	my $file = shift;
	open(FILE,$file) or return $self->error("$file: $!");
	my @lines = <FILE>;
	close(FILE);

	foreach(@lines) { chomp; s/\r$//; s/\t$//; s/^"//; s/"$//; s/^\s+//;}

	my @caseContent;
	my $test_start = 0;
	my $case_start = 0;
	my %TestAttr = (
		name	=> undef,
		purpose	=> undef,
		desc 	=> undef,
		mail	=> $self->{_mailto},
	);   
	for(my $i=0;$i<scalar(@lines);$i++) {
		my $currentLine = $lines[$i]; 		
		next if $currentLine =~ /^\s+?$/;
		next if $currentLine =~ /^#/;
		if ($currentLine =~ /^test_start/i){
			$test_start = 1;
			TestStart(%TestAttr);
		}elsif (!$test_start){
			my($key,@rest) = split(/\s/,$currentLine);
			my $desc = join (' ',@rest);
			if($key =~ /name/i) {
				$TestAttr{name} = $desc;
			}elsif($key =~ /desc|setup|restrict/i) {
				$TestAttr{desc} = $desc;
			}elsif($key =~ /purpose/i) {
				$TestAttr{purpose} = $desc;
			}
		}elsif($currentLine =~ s/^Testcase::procedure(::|=)//i){
			if($case_start) {
				if(scalar(@caseContent)) {
					package main;
					eval join("\n", @caseContent);
					if ($@) {	print $@; }						
				}
				CaseEnd(); 
				@caseContent =();
			}
			$case_start = 1;
			CaseStart($currentLine);
		}elsif(!$case_start) {
			die "Need to Start Test first" unless $test_start;
		}elsif($currentLine =~ s/^Test::wait(::|=)//i) {		
			if($currentLine =~ s/(\D+)$//) {
				my $unit = $1;
				print "unit=$unit.\n";
				if($unit =~ /m$/i) {
					$currentLine *=60;
				}elsif($unit =~ /h$/i) {
					$currentLine *= 60*60;
				}elsif($unit !~ /s$/i) {
					die "Note supported waiting time: $currentLine";
				}
			}
			if($currentLine) {
				push @caseContent, "sleep $currentLine;";
				# push @caseContent, 'Pass("Sleeping $currentLine seconds\n");';
			}

		}else {
			next unless $currentLine;
			# tea like command
			if($currentLine =~ /::/ ) { 
				push @caseContent, "Steps(\"$currentLine\");";			
			}else {
				push @caseContent, $currentLine;
			}
		}
	}
	if($case_start) {
		if(scalar(@caseContent)) {
			package main;
			eval join("\n", @caseContent);
			if ($@) {	print $@; }						
		}
		CaseEnd(); 
		@caseContent =();
	}
	TestEnd() if $test_start;	
}



1;


#!/usr/bin/env genome-perl

#Written by Malachi Griffith

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
};

use above "Genome";
use Test::More tests=>7; #One per 'ok', 'is', etc. statement below
use Genome::Model::ClinSeq::Command::DumpIgvXml;
use Data::Dumper;

use_ok('Genome::Model::ClinSeq::Command::DumpIgvXml') or die;

#Define the test where expected results are stored
my $expected_output_dir = $ENV{"GENOME_TEST_INPUTS"} . "/Genome-Model-ClinSeq-Command-DumpIgvXml2/2014-03-18/";
ok(-e $expected_output_dir, "Found test dir: $expected_output_dir") or die;

#Create a temp dir for results
my $temp_dir = Genome::Sys->create_temp_directory();
ok($temp_dir, "created temp directory: $temp_dir") or die;

#Get an existing ClinSeq build to use as a test
my $clinseq_build_id = 119971814;
my $clinseq_build = Genome::Model::Build->get($clinseq_build_id);
ok($clinseq_build, "Obtained a clinseq build from id: $clinseq_build_id") or die;

#Create the dump-igv-xml command
my $igv_xml_cmd = Genome::Model::ClinSeq::Command::DumpIgvXml->create(builds=>[$clinseq_build], outdir=>$temp_dir);
$igv_xml_cmd->queue_status_messages(1);
my $r = $igv_xml_cmd->execute();
is($r, 1, 'Testing for successful execution.  Expecting 1.  Got: '.$r);

#Dump the output of dump-igv-xml to a log file
my @output = $igv_xml_cmd->status_messages();
my $igv_log_file = $temp_dir . "/DumpIgvXml.log.txt";
my $log = IO::File->new(">$igv_log_file");
$log->print(join("\n", @output));
ok(-e $igv_log_file, "Wrote message file from dump-igv-xml to a log file: $igv_log_file");

#The first time we run this we will need to save our initial result to diff against
#Genome::Sys->shellcmd(cmd => "cp -r -L $temp_dir/* $expected_output_dir");

#Perform a diff between the stored results and those generated by this test
my @diff = `diff -r $expected_output_dir $temp_dir`;
ok(@diff == 5, "Only expected differences from expected results and actual for:\nexpected: $expected_output_dir\nactual: $temp_dir\n")
or do { 
  diag("differences are:");
  diag(@diff);
  my $diff_line_count = scalar(@diff);
  print "\n\nFound $diff_line_count differing lines\n\n";
  Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-dump-igv-xml-test-result");
  Genome::Sys->shellcmd(cmd => "mv $temp_dir /tmp/last-dump-igv-xml-test-result");
};


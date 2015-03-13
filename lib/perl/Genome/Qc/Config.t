#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Genome::Test::Factory::InstrumentData::MergedAlignmentResult;

my $pkg = 'Genome::Qc::Config';
use_ok($pkg);

my $config = $pkg->create(name => 'test');
ok($config->isa($pkg), "Config created");

done_testing;


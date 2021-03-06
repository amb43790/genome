#!/gsc/bin/perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

use_ok("Genome::Test::Factory::Model::ClinSeq");
use_ok("Genome::Test::Factory::Model::RnaSeq");

my $input_patient = Genome::Individual->create(name => "FAKE_INDIVIDUAL");
my $input_subject = Genome::Sample->create(name => "FAKE_SAMPLE", source => $input_patient);
my $input_model = Genome::Test::Factory::Model::RnaSeq->setup_object(subject_id => $input_subject->id);
ok($input_model->isa("Genome::Model::RnaSeq"), "Generated an rna-seq model for input");
my $m = Genome::Test::Factory::Model::ClinSeq->setup_object(tumor_rnaseq_model => $input_model);
ok($m->isa("Genome::Model::ClinSeq"), "Generated a clinseq model");

done_testing;


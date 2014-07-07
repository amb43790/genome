#!/usr/bin/env genome-perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above "Genome";
use Sub::Install;
use Genome::Test::Factory::Model::ReferenceSequence;
use Genome::Test::Factory::Build;
use Genome::Model::Tools::DetectVariants2::Result::Vcf;
use Genome::Model::Tools::Bed::Convert::VcfToBed;
use Genome::VariantReporting::Framework::TestHelpers qw(test_cmd_and_result_are_in_sync);

use Test::More;

my $cmd_class = 'Genome::VariantReporting::Fpkm::Run';
use_ok($cmd_class) or die;

my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('runners', $cmd_class->name), $cmd_class);

my $result_class = 'Genome::VariantReporting::Fpkm::RunResult';
use_ok($result_class) or die;
use_ok('Genome::Model::Tools::Vcf::AnnotateWithFpkm') or die;

my $cmd = generate_test_cmd();
ok($cmd->isa($cmd_class), "Command created correctly");
ok($cmd->execute(), 'Command executed');
is(ref($cmd->output_result), $result_class, 'Found software result after execution');

test_cmd_and_result_are_in_sync($cmd);

done_testing();

sub generate_test_cmd {
     Sub::Install::reinstall_sub({
        into => 'Genome::Model::Tools::Vcf::AnnotateWithFpkm',
        as => 'execute',
        code => sub {my $self = shift; my $output_file = $self->output_file; `touch $output_file`; return 1;},
    });

    my $input_result = $result_class->__define__();

    my %params = (
        input_result      => $input_result,
        tumor_sample_name => 'TEST-patient1-somval_tumor1',
        variant_type      => 'snvs',
        fpkm_file         => 'some_fpkm_file',
    );
    my $cmd = $cmd_class->create(%params);
    return $cmd;
}

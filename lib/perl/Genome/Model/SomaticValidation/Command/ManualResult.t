#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above 'Genome';
use Genome::Utility::Text;

use Test::More tests => 8;

use_ok('Genome::Model::SomaticValidation::Command::ManualResult');

my $temp_build_data_dir = File::Temp::tempdir('t_SomaticValidation_Build-XXXXX', CLEANUP => 1, TMPDIR => 1);
my $temp_dir = File::Temp::tempdir('Model-Command-Define-SomaticValidation-XXXXX', CLEANUP => 1, TMPDIR => 1);


my $somatic_variation_build = &setup_somatic_variation_build;
isa_ok($somatic_variation_build, 'Genome::Model::Build::SomaticVariation', 'setup test somatic variation build');

my $data = Genome::Utility::Text::table_to_tab_string([[qw(1 10003 10004 A/T)]]);
my $revised_bed_file = Genome::Sys->create_temp_file_path;
Genome::Sys->write_file($revised_bed_file, $data);
ok(-s $revised_bed_file, 'created a revised bed file');


my $cmd = Genome::Model::SomaticValidation::Command::ManualResult->create(
    variant_file => $revised_bed_file,
    variant_type => 'snv',
    source_build => $somatic_variation_build,
    description => 'curated for testing purposes',
);
isa_ok($cmd, 'Genome::Model::SomaticValidation::Command::ManualResult', 'created command');
ok($cmd->execute, 'executed command');

my $result = $cmd->manual_result;
isa_ok($result, 'Genome::Model::Tools::DetectVariants2::Result::Manual', 'created manual result');
is($result->sample, $somatic_variation_build->tumor_model->subject, 'result has expected sample');
is($result->control_sample, $somatic_variation_build->normal_model->subject, 'result has expected control sample');


sub setup_somatic_variation_build {
    use Genome::Test::Factory::Model::SomaticValidation;
    use Genome::Test::Factory::Model::SomaticVariation;

    # Why are SomaticValidation tests just using SomaticVariation models?
    my $somvar_build = Genome::Test::Factory::Model::SomaticVariation->setup_somatic_variation_build();

    my $dir = ($temp_dir . '/' . 'fake_samtools_result');
    Genome::Sys->create_directory($dir);
    my $result = Genome::Model::Tools::DetectVariants2::Result->__define__(
        detector_name => 'the_bed_detector',
        detector_version => 'r599',
        detector_params => '--fake',
        output_dir => Cwd::abs_path($dir),
        id => -2013,
    );
    $result->lookup_hash($result->calculate_lookup_hash());

    my $data = Genome::Utility::Text::table_to_tab_string([
        [qw(1 10003 10004 A/T)],
        [qw(2  8819  8820 A/G)],
    ]);
    my $bed_file = $dir . '/snvs.hq.bed';
    Genome::Sys->write_file($bed_file, $data);

    $result->add_user(user => $somvar_build, label => 'uses');

    return $somvar_build;
}

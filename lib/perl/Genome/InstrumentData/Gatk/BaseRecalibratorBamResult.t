#! /gsc/bin/perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
}

use strict;
use warnings;

use above 'Genome';

require Genome::Utility::Test;
use Test::More;

my $class = 'Genome::InstrumentData::Gatk::BaseRecalibratorBamResult';
use_ok($class) or die;
my $result_data_dir = Genome::Utility::Test->data_dir_ok($class, 'v1');

# Inputs
use_ok('Genome::InstrumentData::Gatk::Test') or die;
my $gatk_test = Genome::InstrumentData::Gatk::Test->get;
my $bam_source = $gatk_test->bam_source;
my $reference_build = $gatk_test->reference_build;
my $version = '2.4';
my %params = (
    version => $version,
    bam_source => $bam_source,
    reference_build => $reference_build,
    known_sites => [ $gatk_test->known_site ],
);

# Get [fails as expected]
my $base_recalibrator_bam_result = Genome::InstrumentData::Gatk::BaseRecalibratorBamResult->get_with_lock(%params);
ok(!$base_recalibrator_bam_result, 'Failed to get existing gatk indel realigner result');

# Create
$base_recalibrator_bam_result = Genome::InstrumentData::Gatk::BaseRecalibratorBamResult->get_or_create(%params);
ok($base_recalibrator_bam_result, 'created gatk indel realigner');

# Outputs
my $base_recalibrator_result = $base_recalibrator_bam_result->base_recalibrator_result;
ok($base_recalibrator_result, 'base recalibrator result');
$base_recalibrator_result = $base_recalibrator_bam_result->get_base_recalibrator_result;
ok($base_recalibrator_result, '"get" base recalibrator result');
ok(-s $base_recalibrator_bam_result->base_recalibrator_result->recalibration_table_file, 'base recalibrator result recalibration table file');
is($base_recalibrator_bam_result->bam_path, $base_recalibrator_bam_result->output_dir.'/'.$base_recalibrator_bam_result->id.'.bam', 'bam file named correctly');
ok(-s $base_recalibrator_bam_result->bam_path, 'bam file exists');#bam produced is the same except for the knowns file in the header
ok(-s $base_recalibrator_bam_result->bam_path.'.bai', 'bam index exists');
ok(-s $base_recalibrator_bam_result->bam_flagstat_file, 'bam flagstat file exists');
Genome::Utility::Test::compare_ok($base_recalibrator_bam_result->bam_flagstat_file, $result_data_dir.'/expected.bam.flagstat', 'flagstat matches');
ok(-s $base_recalibrator_bam_result->bam_md5_path, 'bam md5 path exists');
Genome::Utility::Test::compare_ok(
    $base_recalibrator_bam_result->bam_md5_path,
    $result_data_dir.'/expected.bam.md5',
    'md5 matches',
    filters => [
        sub{ my $line = shift; $line =~ s/\s+.+//; return $line; }, # extract md5
    ],
);

# Users
my @bam_source_users = $bam_source->users;
ok(@bam_source_users, 'add users to bam source');
is_deeply([map { $_->label } @bam_source_users], ['bam source', 'bam source'], 'bam source users haver correct label');
my @users = sort { $a->id <=> $b->id } map { $_->user } @bam_source_users;
is_deeply(\@users, [$base_recalibrator_result, $base_recalibrator_bam_result], 'bam source is used by base recal and base recal bam results');

my $sr_user = $base_recalibrator_result->users;
ok($sr_user, 'add user to base recalibrator result');
is($sr_user->label, 'recalibration table', 'sr user has correct label');
my $user = $sr_user->user;
is($user, $base_recalibrator_bam_result, 'base recalibrator is used by base recalibrator bam result');

# Base recalibrator params
my %base_recalibrator_params = $base_recalibrator_bam_result->base_recalibrator_params;
is_deeply(
    \%base_recalibrator_params,
    {
        version => $version,
        bam_source => $bam_source,
        reference_build => $reference_build,
        known_sites => [ $gatk_test->known_site ],
    },
    'base recalibrator params',
);

# Allocation params
is(
    $base_recalibrator_bam_result->resolve_allocation_disk_group_name,
    'info_genome_models',
    'resolve_allocation_disk_group_name',
);
is(
    $base_recalibrator_bam_result->resolve_allocation_kilobytes_requested,
    160,
    'resolve_allocation_kilobytes_requested',
);
like(
    $base_recalibrator_bam_result->resolve_allocation_subdirectory,
    qr(^model_data/gatk/base_recalibrator_bam-),
    'resolve_allocation_subdirectory',
);

#print $base_recalibrator->output_dir."\n"; <STDIN>;
done_testing();

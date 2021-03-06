package Genome::Model::Tools::EpitopePrediction::ParseNetmhcpanKeyMutant;


use strict;
use warnings;
use Data::Dumper;
use Genome;

class Genome::Model::Tools::EpitopePrediction::ParseNetmhcpanKeyMutant {
    is => ['Genome::Model::Tools::EpitopePrediction::Base'],
    has_input => [
        netmhc_file => {
        	is => 'Text',
            doc => 'Raw output file from Netmhc',
        },
        parsed_file => {
        	is => 'Text',
            doc => 'File to write the parsed output',
        },
        output_type => {
            is => 'Text',
            doc => 'Type of epitopes to report in the final output - select \'top\' to report the top epitopes in terms of fold changes,  \'all\' to report all predictions ',
            valid_values => ['top','all'],
        },
        key_file => {
            is => 'Text',
            doc => 'Key file for lookup of FASTA IDs'
        },
        
    ],
};

sub help_brief {
	"FOR NETMHCPAN : Parses output from NetMHC for MHC Class I epitope prediction; The parsed TSV file contains predictions for only those epitopes that contain the \"mutant\" SNV. This tools requires the lookup \"Key\" file that was generated while generating 21-mer FASTA sequence file.

",
}



sub execute {
    my $self = shift;
	my %netmhc_results;
	my %epitope_seq;
	my %position_score;
	
	my $type = $self->output_type;
	my $input_fh = Genome::Sys->open_file_for_reading($self->netmhc_file);
	my $output_fh = Genome::Sys->open_file_for_writing($self->parsed_file);
	my $key_fh	= Genome::Sys->open_file_for_reading($self->key_file);
	
	
	### HASH FOR KEY FILE LOOKUP#####
	
	my %list_hash;
	while (my $keyline = $key_fh->getline) 
	{
		chomp $keyline;
		
		# >WT_8	>WT.GSTP1.R187W	   
	#	$list_hash{$keyline}  = ();	
		my ($pan_name, $original_name)    = split ( /\t/, $keyline );	
    		$list_hash{$pan_name} =();
		$list_hash{$pan_name}{'name'}   = $original_name;
		
	}
		#print Dumper %list_hash;
	#########
	
	
	while (my $line = $input_fh->getline) {
	chomp $line;
    if ($line =~ /^\s+\d+/) 
    {
	#	print $line."\n";
		my @result_arr = split (/\s+/,$line);
    	#print Dumper(@result_arr);
		# <space>  6  HLA-A*03:01  RLSAWPKLK            MT_8         0.656        41.45     0.12 <= SB
    	    	
    	my $position = $result_arr[1];
    	my $score = $result_arr[6];
    	my $epitope = $result_arr [3];
    	my $protein_pan_name = $result_arr[4];
		
		if ( exists( $list_hash{$protein_pan_name} ) )
		{
			#print $_."\n";
			my $protein = $list_hash{$protein_pan_name}{'name'};
#>MT.FBN3.P1547L
	    		my @protein_arr = split (/\./,$protein);
    	
    	#print Dumper(@protein_arr);
    	
    	my $protein_type = $protein_arr[0];
    	my $protein_name = $protein_arr[1];
    	my $variant_aa =  $protein_arr[2];
       
        $netmhc_results{$protein_type}{$protein_name}{$variant_aa}{$position} = $score;
        $epitope_seq{$protein_type}{$protein_name}{$variant_aa}{$position} = $epitope;
        
   	 }
	}

	}

print $output_fh join("\t","Gene Name","Point Mutation","Sub-peptide Position","MT score", "WT score","MT epitope seq","WT epitope seq","Fold change")."\n";
	my $rnetmhc_results = \%netmhc_results;
	my $epitope_seq = \%epitope_seq;
	my @score_arr;
	for my $k1 ( sort keys %$rnetmhc_results ) {
	 my @positions;
	   if ($k1 eq 'MT')
	   {
      #  print "$k1\t";

        for my $k2 ( sort keys %{$rnetmhc_results->{ $k1 }} ) {
            #print "$k2\t";
     
            for my $k3 ( sort keys %{$rnetmhc_results->{ $k1 }->{ $k2 }} ) {
                #print "\t$k3";
				%position_score = %{$netmhc_results{$k1}{$k2}{$k3}};
				@positions = sort {$position_score{$a} <=> $position_score{$b}} keys %position_score;
				my $total_positions = scalar @positions; 
				
				if ($type eq 'all')
				{
					
				
					for (my $i = 0; $i < $total_positions; $i++){
						
						
						if ($epitope_seq->{'MT'}->{$k2}->{$k3}->{$positions[$i]} ne $epitope_seq->{'WT'}->{$k2}->{$k3}->{$positions[$i]} )
						# Filtering if mutant amino acid present
						{
				
							print $output_fh join("\t",$k2,$k3,$positions[$i],$position_score{$positions[$i]})."\t";
							print $output_fh $rnetmhc_results->{ 'WT'}->{ $k2 }->{ $k3 }->{$positions[$i]}."\t";
							
							print $output_fh $epitope_seq->{'MT'}->{$k2}->{$k3}->{$positions[$i]}."\t";
							print $output_fh $epitope_seq->{'WT'}->{$k2}->{$k3}->{$positions[$i]}."\t";
						
							my $fold_change = $rnetmhc_results->{ 'WT'}->{ $k2 }->{ $k3 }->{$positions[$i]}/$position_score{$positions[$i]};
							my $rounded_FC = sprintf("%.3f", $fold_change);
							print $output_fh $rounded_FC."\n";	
						}
					}
				}
				if ($type eq 'top')
				{
					
					print $output_fh join("\t",$k2,$k3,$positions[0],$position_score{$positions[0]})."\t";
					print $output_fh $rnetmhc_results->{ 'WT'}->{ $k2 }->{ $k3 }->{$positions[0]}."\t";
				
					print $output_fh $epitope_seq->{'MT'}->{$k2}->{$k3}->{$positions[0]}."\t";
					print $output_fh $epitope_seq->{'WT'}->{$k2}->{$k3}->{$positions[0]}."\t";
					my $fold_change = $rnetmhc_results->{ 'WT'}->{ $k2 }->{ $k3 }->{$positions[0]}/$position_score{$positions[0]};
					my $rounded_FC = sprintf("%.3f", $fold_change);
					print $output_fh $rounded_FC."\n";	
				}
		
			}
				
           }
          }
        }

    
    
    return 1;
}



1;


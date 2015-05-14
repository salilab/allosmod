package allosmod_foxs;
use base qw(saliweb::frontend);

use strict;

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

# Add our own JavaScript and CSS to the page header
sub get_start_html_parameters {
  my ($self, $style) = @_;
  my %param = $self->SUPER::get_start_html_parameters($style);
  push @{$param{-script}}, {-language => 'JavaScript',
                            -src => 'html/jquery-1.8.1.min.js' };
  push @{$param{-script}}, {-language => 'JavaScript',
                            -src => 'html/allosmod_foxs.js' };
  push @{$param{-style}->{'-src'}}, 'html/allosmod_foxs.css';
  return %param;
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "AllosMod-FoXS Home"),
        $q->a({-href=>$self->help_url}, "About AllosMod-FoXS"),
        $q->a({-href=>$self->queue_url}, "Queue"),
        $q->a({-href=>$self->contact_url}, "Contact Us"),
	$q->a({-href=>$self->cgiroot . "/help.cgi?type=resources"},"Resources")
        ];
}

sub get_project_menu {
    my $self = shift;
    my $version = $self->version_link;
    my $htmlroot = $self->htmlroot;
    return <<MENU;
<div id="logo">
<center>
<a href="http://modbase.compbio.ucsf.edu/allosmod"><img src="http://modbase.compbio.ucsf.edu/allosmod/html/img/am_logo.gif" /></a>
</center>
<br />
<center>
<a href="http://modbase.compbio.ucsf.edu/foxs"><img src="http://modbase.compbio.ucsf.edu/allosmod/html/img/foxs.gif" /></a>
</center>
</div><br />
<h4><small>Developers:</small></h4><p>Dina Schneidman <br />
Ben Webb<br />
Patrick Weinkam</p>
<h4><small>Acknowledgements:</small></h4>
<p>Ursula Pieper<br />
Elina Tjioe<br />
<br />
Andrej Sali</p>
<p><i>Version $version</i></p>
MENU
#<p>&nbsp;</p>
}

sub get_footer {
    my $self = shift;
    my $htmlroot = $self->htmlroot;
    return <<FOOTER;
<div id="address">
<center><a href="http://www.ncbi.nlm.nih.gov/pubmed/22403063">
<b>P. Weinkam, J. Pons, and A. Sali, Proc Natl Acad Sci U S A., (2012) <i>109 (13),</i> 4875-4880</b></a>:
<a href="http://modbase.compbio.ucsf.edu/allosmod/html/file/Weinkam_PNAS_2012.pdf"><img src="http://modbase.compbio.ucsf.edu/allosmod/html/img/pdf.gif" /></a>,
S.I.:<a href="http://modbase.compbio.ucsf.edu/allosmod/html/file/Weinkam_PNAS_2012_si.pdf"><img src="http://modbase.compbio.ucsf.edu/allosmod/html/img/pdf.gif" /></a>
</center>
<center><a href="http://www.ncbi.nlm.nih.gov/pubmed/20507903">
<b>D. Schneidman-Duhovny, M. Hammel, A. Sali, Nucleic Acids Res., (2010) <i>38</i>, W540-4</b></a>:
<a href="http://modbase.compbio.ucsf.edu/allosmod/html/file/Schneidman-Duhovny_NucAcRes_2010.pdf"><img src="http://modbase.compbio.ucsf.edu/allosmod/html/img/pdf.gif" /></a>
</center>
</div>
FOOTER
}

sub make_dropdown {
    my ($self, $id, $title, $initially_visible, $text) = @_;
   
    my $style = "";
    if (!$initially_visible) {
      $style = " style=\"display:none\"";
    }
    return "<div class=\"dropdown_container\">\n" .
           "<a onclick=\"\$('#${id}').slideToggle('fast')\" " .
           "href=\"#\">$title</a>\n" .
           "<div class=\"dropdown\" id=\"${id}\"$style>\n" .
           $text . "\n</div></div>\n";
}

sub get_advanced_modeling_options {
    my $self = shift;
    my $q = $self->cgi;

    return $self->make_dropdown("advmodel", "Advanced Modeling Options", 0,
      "<input type=\"radio\" name=\"advancedopt\" value=\"ligandmod\" " .
      "onclick=\"\$('#glycmod').slideUp('fast'); " .
      "\$('#ligandmod').slideDown('fast')\"" .
      "\>Model implicit ligand binding" . $q->br .
	     "<div class=\"advopts\" id=\"ligandmod\" style=\"display:none\">\n" .
	     "Radius of ligand binding site (&Aring) " . $q->textfield({-name=>'ligandmod_rAS', -size=>"3",
                                         -value=>"11"}) . $q->br .
	     "Ligand PDB file " . $q->filefield({-name=>"ligandmod_ligfile"}) . $q->br .
	     "PDB file from which ligand was extracted " . $q->textfield({-name=>'ligandmod_ligpdb', -size=>"25",
                                         -value=>""}) . $q->br .
	     "PDB file to define allosteric site contacts " . $q->textfield({-name=>'ligandmod_aspdb', -size=>"25",
                                         -value=>""}) .

      "</div>\n\n" .

      "<input type=\"radio\" name=\"advancedopt\" value=\"glycmod\" " .
      "onclick=\"\$('#ligandmod').slideUp('fast'); " .
      "\$('#glycmod').slideDown('fast')\" />Model " .
      "glycosylation " . $q->br .
      "<div class=\"advopts\" id=\"glycmod\" style=\"display:none\">\n" .
	          "<input type=\"radio\" name=\"glycmodopt\" value=\"option1\" " .
		  "onclick=\"\$('#option1').slideDown('fast');\$('#option2').slideUp('fast')\"" .
		  "\>Option 1: Add flexible sugars to a semi-rigid protein that lacks glycosylation" . $q->br .
		  "<div class=\"glycmodopt\" id=\"option1\" style=\"display:none\">\n" .

       		  "Number of models " . $q->textfield({-name=>'glycmod_nruns', -size=>"3",
						     -value=>"10"}) . $q->br .
	       	  "Glycosylation input file " .
				$q->filefield({-name=>"glycmod_input"}) . $q->br .
		  "Flexible residues at glycosylation sites " .
				'<input type="checkbox" name="glycmod_flexible_sites"' .
				'checked="1" />' . $q->br .
		  "Number of optimization steps " .
				$q->textfield({-name=>'glycmod_num_opt_steps',-size=>"3", -value=>"1"}) .

                  "</div>\n\n" .

	          "<input type=\"radio\" name=\"glycmodopt\" value=\"option2\" " .
		  "onclick=\"\$('#option1').slideUp('fast');\$('#option2').slideDown('fast')\"" .
		  "\>Option 2: Sample multiple protein conformations with rigid sugars (see Sampling Options below)" . $q->br .
		  "<div class=\"glycmodopt\" id=\"option2\" style=\"display:none\">\n" .

		  "WARNING: Rigid bodies can cause problems during simulations, care should be given here" . $q->br .
		  "See the <a href=\"http://modbase.compbio.ucsf.edu/allosmod/help.cgi?type=glyc\"> glycosylation help page</a> for more information" . $q->br .
	       	  "Upload the allosmod.py file generated for this protein using Option 1 on the <a href=\"http://modbase.compbio.ucsf.edu/allosmod\"> AllosMod server</a>" .
				$q->filefield({-name=>"glycmod_python"}) . $q->br .

                  "</div>\n\n" .

      "</div>\n\n" .

      "<input type=\"radio\" name=\"advancedopt\" value=\"addrestr\" " .
      "onclick=\"\$('#addrestr').slideDown('fast')\" />Add restraints " .
      "between specific atoms " . $q->br .
      "<div class=\"advopts\" id=\"addrestr\" style=\"display:none\">\n" .
	          "<input type=\"radio\" name=\"addrestropt\" value=\"addbond\" " .
		  "onclick=\"\$('#addbond').slideDown('fast')\"" .
		  "\>Add bond between two residues using a harmonic restraint" . $q->br .
		  "<div class=\"addrestropt\" id=\"addbond\" style=\"display:none\">\n" .

		  "Calpha-Calpha distance (&Aring) " . $q->textfield({-name=>'addbond_dist', -size=>"3",
                                         -value=>"3.8"}) . $q->br .
	          "Standard deviation of restraint " . $q->textfield({-name=>'addbond_stdev', -size=>"3",
                                         -value=>"3.0"}) . $q->br .
	          "Residue indices (for simulated sequence) separated by commas, one pair per line. " .
				"(for example, click <a href=\"http://modbase.compbio.ucsf.edu/allosmod/html/file/bonds.dat\"> here</a>)" . 
				$q->textarea({-name=>'addbond_indices', -rows=>5, -cols=>10,
                                         -value=>""}) . $q->br .

                  "</div>\n\n" .

	          "<input type=\"radio\" name=\"addrestropt\" value=\"addupper\" " .
		  "onclick=\"\$('#addupper').slideDown('fast')\"" .
		  "\>Add upper bound distance restraint between two residues " . $q->br .
		  "<div class=\"addrestropt\" id=\"addupper\" style=\"display:none\">\n" .

		  "Calpha-Calpha upper bound distance (&Aring) " . $q->textfield({-name=>'addupper_dist', -size=>"3",
                                         -value=>"5.0"}) . $q->br .
	          "Standard deviation of restraint " . $q->textfield({-name=>'addupper_stdev', -size=>"3",
                                         -value=>"2.0"}) . $q->br .
	          "Residue indices (for simulated sequence) separated by commas, one pair per line. " .
				"(for example, click <a href=\"http://modbase.compbio.ucsf.edu/allosmod/html/file/bonds.dat\"> here</a>)" . 
				$q->textarea({-name=>'addupper_indices', -rows=>5, -cols=>10,
                                         -value=>""}) . $q->br .

                  "</div>\n\n" .

	          "<input type=\"radio\" name=\"addrestropt\" value=\"addlower\" " .
		  "onclick=\"\$('#addlower').slideDown('fast')\"" .
		  "\>Add lower bound distance restraint between two residues " . $q->br .
		  "<div class=\"addrestropt\" id=\"addlower\" style=\"display:none\">\n" .

		  "Calpha-Calpha lower bound distance (&Aring) " . $q->textfield({-name=>'addlower_dist', -size=>"3",
                                         -value=>"10.0"}) . $q->br .
	          "Standard deviation of restraint " . $q->textfield({-name=>'addlower_stdev', -size=>"3",
                                         -value=>"1.0"}) . $q->br .
	          "Residue indices (for simulated sequence) separated by commas, one pair per line. " .
				"(for example, click <a href=\"http://modbase.compbio.ucsf.edu/allosmod/html/file/bonds.dat\"> here</a>)" . 
				$q->textarea({-name=>'addlower_indices', -rows=>5, -cols=>10,
                                         -value=>""}) . $q->br .

                  "</div>\n\n" .

      "</div>\n\n" .

      "<input type=\"radio\" name=\"advancedopt\" value=\"break\" " .
      "onclick=\"\$('#break').slideDown('fast')\" />Alter " .
      "residue contact energies " . $q->br .
      "<div class=\"advopts\" id=\"break\" style=\"display:none\">\n" .
		  "break.dat file " . $q->filefield({-name=>"break_input"}) . $q->br .

      "</div>\n\n");
}

sub get_sampling_options {
    my $self = shift;
    my $q = $self->cgi;
    return $self->make_dropdown("sampling", "Sampling Options", 0,
      "<input type=\"radio\" name=\"sampletype\" value=\"comparativemod\" " .
      "checked=\"checked\" onclick=\"\$('#rareconf').slideUp('fast'); " .
      "\$('#multiconf').slideUp('fast'); \$('#interconf').slideUp('fast'); \$('#comparativemod').slideDown('fast')\" />Generate " .
      "static models using MODELLER that are similar to the input structure(s)" . $q->br .
      "<div class=\"sampopts\" id=\"comparativemod\">\n" .
      "Number of comparitive models " . $q->textfield({-name=>'comparativemod_nruns', -size=>"3",
                                         -value=>"10"}) .
      "</div>\n\n" .

      "<input type=\"radio\" name=\"sampletype\" value=\"multiconf\" " .
      "onclick=\"\$('#rareconf').slideUp('fast'); " .
      "\$('#comparativemod').slideUp('fast'); \$('#interconf').slideUp('fast'); \$('#multiconf').slideDown('fast')\" />Sample most probable " .
      "conformations consistent with input crystal structure(s)" . $q->br .
      "<div class=\"sampopts\" id=\"multiconf\" style=\"display:none\">\n" .
      "Number of runs " . $q->textfield({-name=>'multiconf_nruns', -size=>"3",
                                         -value=>"10"}) . $q->br .
      "MD temperature " . $q->textfield({-name=>'multiconf_mdtemp', -size=>"3",
                                         -value=>"300"}) .
      "</div>\n\n" .

      "<input type=\"radio\" name=\"sampletype\" value=\"interconf\" " .
      "onclick=\"\$('#rareconf').slideUp('fast'); " .
      "\$('#comparativemod').slideUp('fast'); \$('#multiconf').slideUp('fast'); \$('#interconf').slideDown('fast')\" />Sample intermediate probablity " .
      "conformations consistent with input crystal structure(s)" . $q->br .
      "<div class=\"sampopts\" id=\"interconf\" style=\"display:none\">\n" .
            "Number of simulations " . $q->textfield({-name=>'interconf_nruns', -size=>"3",
                                         -value=>"30"}) . $q->br .
            "MD temperature scanned or fixed value " . $q->textfield({-name=>'interconf_mdtemp', -size=>"3",
                                         -value=>"scan"}) . $q->br .
            "Increase chain rigidity to maintain secondary structure at high temperature " .
				'<input type="checkbox" name="interconf_locrig"' .
				'checked="1" />' . $q->br .
      "</div>\n\n" .

      "<input type=\"radio\" name=\"sampletype\" value=\"rareconf\" " .
      "onclick=\"\$('#multiconf').slideUp('fast'); " .
      "\$('#comparativemod').slideUp('fast'); \$('#interconf').slideUp('fast'); \$('#rareconf').slideDown('fast')\" />Sample low probability " .
      "conformations consistent with input crystal structure(s)" . $q->br .
      "<div class=\"sampopts\" id=\"rareconf\" style=\"display:none\">\n" .


             "Number of simulations " . $q->textfield({-name=>'rareconf_nruns', -size=>"3",
                                         -value=>"30"}) . $q->br .
             "MD temperature scanned or fixed value " .
                $q->textfield({-name=>'rareconf_mdtemp', -size=>"3",
                               -value=>"scan"}) . $q->br .
             "Increase chain rigidity to maintain secondary structure at high temperature " .
				'<input type="checkbox" name="rareconf_locrig"' .
				'checked="1" />' . $q->br .
             "Include chemical frustration (destabilize buried charged residues) " .
				'<input type="checkbox" name="rareconf_break"' .
				'checked="1" />' . $q->br .
             "Z-score of the residue charge density, residues above this value cause chem. frust." .
                $q->textfield({-name=>'rareconf_cdencutoff', -size=>"3",
                               -value=>"3.5"}) . $q->br .
#             "Quickly cool each structure to increase secondary structure (takes a long time, use sparingly) " .
#				'<input type="checkbox" name="rareconf_quickcool"' .
#				' />' . $q->br .
      "</div>\n");
}

sub get_saxs_options {
    my $self = shift;
    my $q = $self->cgi;
    return $self->make_dropdown("saxs", "SAXS Options", 0,
                  $q->table(
                      $q->Tr($q->td('Maximal q value'),
                             $q->td($q->textfield({-name=>'saxs_qmax', -size=>"10",
                                                   -value=>"0.5"}))),
                      $q->Tr($q->td('Profile size'),
                             $q->td($q->textfield({-name=>'saxs_psize', -size=>"10",
                                                   -value=>"500"})),
                             $q->td('Number of points in the computed profile')),
#                      $q->Tr($q->td('Hydration Layer'),
#                             $q->td('<input type="checkbox" name="saxs_hlayer" ' .
#                                    'checked="1" />'),
#                             $q->td('use hydration layer to improve fitting')),
#                      $q->Tr($q->td('Excluded Volume Adjustment'),
#                             $q->td('<input type="checkbox" name="saxs_exvolume" ' .
#                                    'checked="1" />'),
#                             $q->td('adjust the protein excluded volume ' .
#                                    'to improve fitting')),
#                      $q->Tr($q->td('Implicit Hydrogens'),
#                             $q->td('<input type="checkbox" name="saxs_ihydrogens"' .
#                                    'checked="1" />'),
#                             $q->td('implicitly consider hydrogen atoms')),
                      $q->Tr($q->td('Background adjustment'),
                             $q->td('<input type="checkbox" name="saxs_backadj"' .
                                    ' />'),
                             $q->td('Adjust the background of the ' .
                                    'experimental profile')),
                      $q->Tr($q->td('Residue-based computation'),
                             $q->td('<input type="checkbox" name="saxs_coarse"' .
                                    ' />'),
                             $q->td('Perform coarse grained profile ' .
                                    'computation using only the Ca atoms')),
#                      $q->Tr($q->td('Offset'),
#                             $q->td('<input type="checkbox" name="saxs_offset"' .
#                                    ' />'),
#                             $q->td('use offset in profile fitting')),
                  ));
}

sub get_all_advanced_options {
    my $self = shift;
    return $self->get_advanced_modeling_options() .
           $self->get_sampling_options() .
           $self->get_saxs_options();
}

sub get_alignment {
    my $self = shift;
    my $q = $self->cgi;
    my $seq = $q->param('sequence');
    if (!defined($seq)) {
	return undef, undef;
    }
    $seq =~ s/\s*//g;
    if ($seq eq "") {
	throw saliweb::frontend::InputValidationError("Please provide sequence used in experiment $!");
    }

    my $job = $self->make_job($q->param("name") || "job");
    my @pdbcodes = $q->param("pdbcode");
    my @uplfiles = $q->upload("uploaded_file");

    # Handle PDB codes
    my $found = 0;
    foreach my $code (@pdbcodes) {
	my $pdb = lc $code;
	if(length $pdb > 0 and $pdb =~ /^[0-9]\w{3}$/) { $found = 1; }
    }
    my $arraySize = scalar (@uplfiles);

    if($found != 1 and $arraySize <= 0) {
        throw saliweb::frontend::InputValidationError("Please provide PDB code or upload PDB file $!");
    }

    # check email
    my $email = $q->param('jobemail');
    if(($found == 1 or $arraySize > 0) and length $email <= 0) {
	check_required_email($email);
    }    

    my $aln;
    my $list = $job->directory . "/" . "list";
    # Upload PDBs
    foreach my $code (@pdbcodes) {
      if (defined($code) and $code ne "") {
	  my $pdbfile = saliweb::frontend::get_pdb_chains($code, $job->directory);
	  $pdbfile =~ s/.*[\/\\](.*)/$1/;
	  system("echo $pdbfile >>$list");
      }
    }
    # Upload files into job directory
    my $upl_num = 0;
    foreach my $upl (@uplfiles) {
      if (defined $upl) {
        if(length $upl > 40) { 
	    throw saliweb::frontend::InputValidationError("Please limit the file name length to a maximum of 40 characters");
	}
        my $buffer;
        my $fullpath = $job->directory . "/" . $upl;
        open(OUTFILE, '>', $fullpath)
         or throw saliweb::frontend::InternalError("Cannot open $fullpath: $!");
        while (<$upl>) {
          print OUTFILE $_;
        }
        close OUTFILE;

	system("echo $upl >>$list");

        $upl_num++;
      }
    }

    my $inpseq = $job->directory . "/" . "inpseq";
    system("echo $seq >> $inpseq");

    #preprocess PDB files and get sequence alignment
    my $jobdir = $job->directory;
    my $script_dir = $self->{config}->{allosmod}->{script_directory};
    open(FOO, "$script_dir/get_MULTsi20b.sh inpseq $jobdir |") || die "dont let script output to std out";
    close(FOO);

    #check if alignment fails
    my $tempfile = $job->directory . "/" . "align.ali";
    my $tempread = do {
	local $/ = undef;
	open my $fh, "<", $tempfile
	    or die "could not open $tempfile: $!";
	<$fh>;
    };
    if($tempread =~ "Dynamically" and $tempread =~ "allocated" and $tempread =~ "memory") {
	system("echo ERROR PW >> $jobdir/align.ali");
	throw saliweb::frontend::InputValidationError("Please check that you have uploaded a PDB file and that your input sequence is appropriate");
    }
    
    $aln .= `cat $jobdir/align.ali`;

    return $aln, $job;
}

sub get_index_page {
    my $self = shift;
    my $q = $self->cgi;

    my ($alignment, $job) = $self->get_alignment();
    my $action = (defined($alignment) ? $self->submit_url : $self->index_url);

    my $form;
    if (defined($alignment)) {
      $form = $q->p("Alignment:" . $q->br .
                   $q->textarea({-name=>'alignment', -rows=>10, -cols=>80,
                                 -value=>$alignment})) .
              $q->hidden('jobname', $job->name) .
	      $q->hidden('jobemail') .
           $q->table(
               $q->Tr($q->td("Experimental profile (Required)"),
                      $q->td($q->filefield({-name=>"saxs_profile",
                                            -size=>"25"})))) .
           $q->p("<center>" .
                 $q->input({-type=>"submit", -value=>"Submit"}) .
                 "</center>") .
           $self->get_all_advanced_options();
    } else {
      $form = $q->table(
	      $q->Tr($q->td("Job name "), 
		     $q->td($q->textfield({-name=>"name",
					   -size=>"25"}))) .
              $q->Tr($q->td("Email (Required)"),
		     $q->td($q->textfield({-name=>"jobemail",
					   -value=>$self->email,
					   -size=>"25"})))) .
              $q->table({-id=>'structures'},
                         $q->Tr($q->td("PDB code " .
                                       $q->textfield({-name=>'pdbcode',
                                                      -size=>'4'})) .
				$q->td("or upload PDB file " .
				       $q->filefield({-name=>'uploaded_file'}))
                                )) .
              $q->p($q->button(-value=>'Add more structures',
                               -onClick=>"add_structure()")) .
                  $q->p("Sequence to be used in simulation (specify protein and DNA/RNA, input sugar in adv. opt., " . 
			"see <a href=\"http://modbase.compbio.ucsf.edu/allosmod-foxs/help.cgi?type=help\"> help page</a>)" . $q->br .
                    $q->textarea({-name=>'sequence', -rows=>7, -cols=>80})) .
              $q->p("<center>" .
                    $q->input({-type=>"submit", -value=>"Submit"}) .
                    "</center>");
    }

    my $greeting = <<GREETING;
<p>AllosMod-FoXS combines the <a href="http://modbase.compbio.ucsf.edu/allosmod/"> AllosMod</a> and 
<a href="http://modbase.compbio.ucsf.edu/foxs/index.html"> FoXS</a> web servers. Our combined server allows various 
sampling algorithms from AllosMod to generate structures that are directly inputed into FoXS for small angle X-ray 
scattering profile calculations. The server supports modeling of protein, DNA, RNA, and glycosylation. 
For help, click <a href="http://modbase.compbio.ucsf.edu/allosmod-foxs/help.cgi?type=help"> here</a>.
<br />
<br />&nbsp;</p>
<br />&nbsp;</p>
GREETING
    return $q->h2({-align=>"center"},
                  "AllosMod-FoXS: Structure Generation and SAXS Profile Calculations") .
           $greeting .

           $q->start_form({-name=>"allosmod-foxsform", -method=>"post",
                           -action=>$action}) .
           $form .
           $q->end_form;
}

sub get_submit_page {
    my $self = shift;
    my $q = $self->cgi;

    my $jobname = $q->param('jobname');
    my $email = $q->param('jobemail'); #||"null"; # user's e-mail

    my $job = $self->resume_job($jobname);
    my $jobdir = $job->directory;

    #write uploaded files
    my $file_contents;
    my $user_saxs = $q->upload('saxs_profile');
    if(length $user_saxs <= 0) {
	throw saliweb::frontend::InputValidationError("Please provide SAXS profile $!");
    }
    my $saxsfile = "$jobdir/saxs.dat";
    open(UPLOAD, "> $saxsfile")
	or throw saliweb::frontend::InputValidationError("Cannot open $saxsfile: $!");
    $file_contents = "";
    while (<$user_saxs>) {
        $file_contents .= $_;
    }
    print UPLOAD $file_contents;
    close UPLOAD
	or throw saliweb::frontend::InputValidationError("Cannot close $saxsfile: $!");
    my $filesize = -s "$jobdir/saxs.dat";
    if($filesize == 0) {
	throw saliweb::frontend::InputValidationError("You have uploaded an empty SAXS profile.");
    }

    # rewrite alignment to file
    my $alignment = $q->param('alignment'); #alignment
    my $filename = "$jobdir/align.ali";
    open (FILE,">$filename") or die "I cannot open $filename\n";
    print FILE $alignment;
    close(FILE);

    #check alignment is valid
    my $script_dir = $self->{config}->{allosmod}->{script_directory};
    open(FOO, "$script_dir/check_align.sh $jobdir |") || die "dont let script output to std out";
    close(FOO);
    my $tempfile = "$jobdir/align.ali";
    my $tempread = do {
	local $/ = undef;
	open my $fh, "<", $tempfile
	    or die "could not open $tempfile: $!";
	<$fh>;
    };
    if($tempread =~ "errorfil") {
	throw saliweb::frontend::InputValidationError("Please check that your alignment contains the filenames for all uploaded pdb files and has an entry for the simulated sequence (pm.pdb).");
    }
    if($tempread =~ "errorseq") {
	throw saliweb::frontend::InputValidationError("Please check that your alignment contains entries with the same sequence as the uploaded pdb files.");
    }
    if($tempread =~ "errorlength") {
	throw saliweb::frontend::InputValidationError("Please check that your alignment entries all have the same length.");
    }
    if($tempread =~ "errorblock") {
	throw saliweb::frontend::InputValidationError("Please check that all block residues, i.e. \".\", are aligned to a residue or hetero atom.");
    }
    
    # handle advanced options
    my $advancedopt = $q->param('advancedopt');
    my $ligandmod_rAS = $q->param('ligandmod_rAS');
    my $ligandmod_ligpdb = $q->param('ligandmod_ligpdb');
    my $ligandmod_aspdb = $q->param('ligandmod_aspdb');
    my $glycmod_nruns = $q->param('glycmod_nruns');
    my $glycmod_flexible_sites = $q->param('glycmod_flexible_sites');
    my $glycmod_num_opt_steps = $q->param('glycmod_num_opt_steps');
    my $glycmodopt = $q->param('glycmodopt');
    my $glycmod_python = $q->param('glycmod_python');
    if(($ligandmod_rAS !~ /^\d+$/ and $ligandmod_rAS !~ /^\d+[\.]\d+$/) or
       $ligandmod_rAS <= 0) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible radius of the ligand binding site $!");
    }
    if(($glycmod_nruns !~ /^\d+$/) or $glycmod_nruns <= 0 or $glycmod_nruns > 100) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible number of models for glycosylation $!");
    }
    if(($glycmod_num_opt_steps !~ /^\d+$/) or $glycmod_num_opt_steps <= 0 or $glycmod_num_opt_steps > 10) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible number of models for glycosylation $!");
    }

    $file_contents = "";
    my $filesize2;
    if ($advancedopt eq "ligandmod") {
	my $ligand_input = $q->upload('ligandmod_ligfile');
	my $ligandfile = "$jobdir/lig.pdb";
	open(UPLOAD, "> $ligandfile")
	    or throw saliweb::frontend::InternalError("Cannot open $ligandfile: $!");
	$file_contents = "";
	while (<$ligand_input>) {
		$file_contents .= $_;
	    }
	print UPLOAD $file_contents;
	close UPLOAD
	    or throw saliweb::frontend::InternalError("Cannot close $ligandfile: $!");
	$filesize2 = -s "$jobdir/lig.pdb";
	if($filesize2 == 0) {
	    system("rm $jobdir/lig.pdb");
	    }
    }
    if ($advancedopt eq "glycmod") {
	if ($glycmodopt eq "option1") {
	    my $glyc_input = $q->upload('glycmod_input');
	    my $glycfile = "$jobdir/glyc.dat";
	    open(UPLOAD, "> $glycfile")
		or throw saliweb::frontend::InternalError("Cannot open $glycfile: $!");
	    $file_contents = "";
	    while (<$glyc_input>) {
		$file_contents .= $_;
	    }
	    print UPLOAD $file_contents;
		close UPLOAD
		    or throw saliweb::frontend::InternalError("Cannot close $glycfile: $!");
		$filesize2 = -s "$jobdir/glyc.dat";
	    if($filesize2 == 0) {
		system("rm $jobdir/glyc.dat");
	    }
	}
	if ($glycmodopt eq "option2") {
	    my $glyc_python = $q->upload('glycmod_python');
	    my $glycpython = "$jobdir/allosmod.py";
	    open(UPLOAD, "> $glycpython")
		or throw saliweb::frontend::InternalError("Cannot open $glycpython: $!");
	    $file_contents = "";
	    while (<$glyc_python>) {
		$file_contents .= $_;
	    }
	    print UPLOAD $file_contents;
	    close UPLOAD
		or throw saliweb::frontend::InternalError("Cannot close $glycpython: $!");
		$filesize2 = -s "$jobdir/allosmod.py";
	    if($filesize2 == 0) {
		system("rm $jobdir/allosmod.py");
	    }
	}
	if ($advancedopt eq "break") {
	    my $break_file = $q->upload('break_input');
	    my $breakfile = "$jobdir/break.dat";
	    open(UPLOAD, "> $breakfile")
		or throw saliweb::frontend::InternalError("Cannot open $breakfile: $!");
	    $file_contents = "";
	    while (<$break_file>) {
		$file_contents .= $_;
	    }
	    print UPLOAD $file_contents;
	    close UPLOAD
		or throw saliweb::frontend::InternalError("Cannot close $breakfile: $!");
	    $filesize2 = -s "$jobdir/break.dat";
	    if($filesize2 == 0) {
		system("rm $jobdir/break.dat");
	    }
	}

    }
    
    # handle sampling options
    my $sampletype = $q->param('sampletype');    
    my $comparativemod_nruns = $q->param('comparativemod_nruns');


    my $multiconf_mdtemp = $q->param('multiconf_mdtemp');
    my $multiconf_nruns = $q->param('multiconf_nruns');
    my $interconf_mdtemp = $q->param('interconf_mdtemp');
    my $interconf_nruns = $q->param('interconf_nruns');
    my $interconf_locrig = $q->param('interconf_locrig');
    my $rareconf_mdtemp = $q->param('rareconf_mdtemp');
    my $rareconf_cdencutoff = $q->param('rareconf_cdencutoff');
    my $rareconf_nruns = $q->param('rareconf_nruns');
    my $rareconf_locrig = $q->param('rareconf_locrig');
    my $rareconf_break = $q->param('rareconf_break');
    my $rareconf_quickcool = $q->param('rareconf_quickcool');
    if(($comparativemod_nruns !~ /^\d+$/) or $comparativemod_nruns <= 0 or $comparativemod_nruns > 100) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible number of runs for comparative modeling $!");
    }
    if(($multiconf_nruns !~ /^\d+$/) or $multiconf_nruns <= 0 or $multiconf_nruns > 100) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible number of runs for probable conformations $!");
    }
    if(($rareconf_nruns !~ /^\d+$/) or $rareconf_nruns <= 0 or $rareconf_nruns > 100) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible number of runs for low probability conformations $!");
    }
    if(($multiconf_mdtemp !~ /^\d+$/ and $multiconf_mdtemp !~ /^\d+[\.]\d+$/ and $multiconf_mdtemp ne "scan") or
       ($multiconf_mdtemp <= 0 and $multiconf_mdtemp ne "scan")) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible MD temperature for probable conformations $!");
    }
    if(($rareconf_mdtemp !~ /^\d+$/ and $rareconf_mdtemp !~ /^\d+[\.]\d+$/ and $rareconf_mdtemp ne "scan") or
       ($rareconf_mdtemp <= 0 and $rareconf_mdtemp ne "scan")) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible MD temperature for low probability conformations $!");
    }
    if(($rareconf_cdencutoff !~ /^\d+$/ and $rareconf_cdencutoff !~ /^\d+[\.]\d+$/) or
       $rareconf_cdencutoff <= 0 or $rareconf_cdencutoff > 5) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible charge density Z-score $!");
    }

    # handle additional restraint options
    my $addrestropt = $q->param('addrestropt');
    my $addbond_dist = $q->param('addbond_dist');
    my $addbond_stdev = $q->param('addbond_stdev');
    my $addbond_indices = $q->param('addbond_indices');
    $addbond_indices =~ s/\n+/,/g;
    my $addupper_dist = $q->param('addupper_dist');
    my $addupper_stdev = $q->param('addupper_stdev');
    my $addupper_indices = $q->param('addupper_indices');
    $addupper_indices =~ s/\n+/,/g;
    my $addlower_dist = $q->param('addlower_dist');
    my $addlower_stdev = $q->param('addlower_stdev');
    my $addlower_indices = $q->param('addlower_indices');
    $addlower_indices =~ s/\n+/,/g;

    # make input.dat for allosmod
    if ($advancedopt eq "glycmod") {
	if ($glycmodopt eq "option1") {
	    $sampletype = "null";
	    system("echo NRUNS=$glycmod_nruns >> $jobdir/input.dat");
	    system("echo DEVIATION=4.0 >> $jobdir/input.dat");
	    system("echo SAMPLING=moderate_cm >> $jobdir/input.dat");	
	    if ($glycmod_flexible_sites eq "on") { system("echo ATTACH_GAPS=True >> $jobdir/input.dat"); }
	    system("echo REPEAT_OPTIMIZATION=$glycmod_num_opt_steps >> $jobdir/input.dat");
	}
    }
    if ($advancedopt eq "ligandmod") {
	system("echo LIGPDB=$ligandmod_ligpdb >> $jobdir/input.dat");
	system("echo ASPDB=$ligandmod_aspdb >> $jobdir/input.dat");
	system("echo rAS=$ligandmod_rAS >> $jobdir/input.dat");
    }
    if ($sampletype eq "multiconf") {
	system("echo NRUNS=$multiconf_nruns >> $jobdir/input.dat");
	system("echo MDTEMP=$multiconf_mdtemp >> $jobdir/input.dat");
	system("echo DEVIATION=5.0 >> $jobdir/input.dat");
	system("echo SAMPLING=moderate_am >> $jobdir/input.dat");
    } elsif ($sampletype eq "rareconf") {
	system("echo NRUNS=$rareconf_nruns >> $jobdir/input.dat");
	system("echo MDTEMP=$rareconf_mdtemp >> $jobdir/input.dat");
	system("echo DEVIATION=10.0 >> $jobdir/input.dat");
	if ($rareconf_quickcool eq "on") { system("echo SAMPLING=moderate_am_scan >> $jobdir/input.dat"); 
				       } else { system("echo SAMPLING=moderate_am >> $jobdir/input.dat");}
	system("echo ZCUTOFF=$rareconf_cdencutoff >> $jobdir/input.dat");
	if ($rareconf_locrig eq "on") { system("echo LOCALRIGID=True >> $jobdir/input.dat"); }
	if ($rareconf_break eq "on") { system("echo BREAK=True >> $jobdir/input.dat"); }
    } elsif ($sampletype eq "interconf") {
	system("echo NRUNS=$interconf_nruns >> $jobdir/input.dat");
	system("echo MDTEMP=$interconf_mdtemp >> $jobdir/input.dat");
	system("echo DEVIATION=10.0 >> $jobdir/input.dat");
	system("echo SAMPLING=moderate_am >> $jobdir/input.dat");
	if ($interconf_locrig eq "on") {	system("echo LOCALRIGID=True >> $jobdir/input.dat"); }
    } elsif ($sampletype eq "comparativemod") {
	system("echo NRUNS=$comparativemod_nruns >> $jobdir/input.dat");
	system("echo DEVIATION=4.0 >> $jobdir/input.dat");
	system("echo SAMPLING=fast_cm >> $jobdir/input.dat");
    } elsif ($sampletype eq "null") {
    } else {
	system("echo error sampletype >> $jobdir/input.dat");
    }

    if ($addbond_indices ne "") {
	system("echo HARM $addbond_dist $addbond_stdev $addbond_indices >> $jobdir/input.dat");
    }
    if ($addupper_indices ne "") {
	system("echo UPBD $addupper_dist $addupper_stdev $addupper_indices >> $jobdir/input.dat");
    }
    if ($addlower_indices ne "") {
	system("echo LOBD $addlower_dist $addlower_stdev $addlower_indices >> $jobdir/input.dat");
    }
    if($email =~ "pweinkam" and $email =~ "gmail") {
	system("echo PW=True >> $jobdir/input.dat");
    }

    # handle SAXS options
    my $saxs_qmax = $q->param('saxs_qmax');
    if(($saxs_qmax !~ /^\d[\.]\d+$/ and $saxs_qmax !~ /^\d$/) or
       $saxs_qmax <= 0.0 or $saxs_qmax >= 1.0) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible maximal q value $!");
    }
    my $saxs_psize = $q->param('saxs_psize');
    if(($saxs_psize !~ /^\d+$/ and $saxs_psize !~ /^\d+[\.]\d+$/) or
       $saxs_psize <= 20 or $saxs_psize >= 2000) {
	throw saliweb::frontend::InputValidationError("Please provide a sensible profile size $!");
    }
    my $saxs_hlayer = $q->param('saxs_hlayer');
    if(!$saxs_hlayer) { $saxs_hlayer = 0; } else { $saxs_hlayer = 1; }
    my $saxs_exvolume = $q->param('saxs_exvolume');
    if(!$saxs_exvolume) { $saxs_exvolume = 0; } else { $saxs_exvolume = 1; }
    my $saxs_ihydrogens = $q->param('saxs_ihydrogens');
    if(!$saxs_ihydrogens) { $saxs_ihydrogens = 0; } else { $saxs_ihydrogens = 1; }
    my $saxs_backadj = $q->param('saxs_backadj');
    if(!$saxs_backadj) { $saxs_backadj = 0; } else { $saxs_backadj = 1; }
    my $saxs_offset = $q->param('saxs_offset');
    if(!$saxs_offset) { $saxs_offset = 0; } else { $saxs_offset = 1; }
    my $saxs_coarse = $q->param('saxs_coarse');
    if(!$saxs_coarse) { $saxs_coarse = 0; } else { $saxs_coarse = 1; }
    system("echo qmax $saxs_qmax >> $jobdir/foxs.in");
    system("echo psize $saxs_psize >> $jobdir/foxs.in");
    system("echo hlayer $saxs_hlayer >> $jobdir/foxs.in");
    system("echo exvolume $saxs_exvolume >> $jobdir/foxs.in");
    system("echo ihydrogens $saxs_ihydrogens >> $jobdir/foxs.in");
    system("echo backadj $saxs_backadj >> $jobdir/foxs.in");
    system("echo offset $saxs_offset >> $jobdir/foxs.in");
    system("echo coarse $saxs_coarse >> $jobdir/foxs.in");
    system("echo email $email >> $jobdir/foxs.in");

    # submit job
    $job->submit($email);

    # write subject details into a file and pop up an exit page
    my $return=
      $q->h1("Job Submitted") .
      $q->hr .
      $q->p("Your job has been submitted to the server! " .
            "Your job ID is " . $job->name . ".") .
      $q->p("Results will be found at <a href=\"" .
            $job->results_url . "\">this link</a>.");
    if ($email) {
        $return.=$q->p("You will be notified at $email when job results " .
                       "are available.");
    }

    $return .=
      $q->p("You can check on your job at the " .
            "<a href=\"" . $self->queue_url .
            "\">AllosMod-FoXS queue status page</a>.").
      $q->p("If you experience a problem or you do not receive the results " .
            "for more than 12 hours, please <a href=\"" .
            $self->contact_url . "\">contact us</a>.") .
      $q->p("Thank you for using AllosMod-FoXS!").
      $q->p("<br />- Dina Schneidman and Patrick Weinkam");

    return $return;
}

sub allow_file_download {
    my ($self, $file) = @_;
    return $file eq 'output.zip';
}

sub get_results_page {
    my ($self, $job) = @_;
    my $q = $self->cgi;
    if (-f 'output.zip') {
        return $self->display_ok_job($q, $job);
    } else {
        return $self->display_failed_job($q, $job);
    }
}

sub display_ok_job {
    my ($self, $q, $job) = @_;
    my $return= $q->p("Job '<b>" . $job->name . "</b>' has completed, thank you for using AllosMod-FoXS!");

    $return.= $q->p("<a href=\"" . $job->get_results_file_url("output.zip") .
                    "\">Download output zip file.</a>");
    $return.=$q->p("<br />You will receive a separate email containing a link to visualize the SAXS profiles using FoXS.");

    $return .= $job->get_results_available_time();
    return $return;
}

sub display_failed_job {
    my ($self, $q, $job) = @_;
    my $return= $q->p("AllosMod-FoXS was unable to complete your request: job '<b>" . $job->name);
    $return.= $q->p("For more information, you can " .
                    "<a href=\"" . $job->get_results_file_url("failure.log") .
                    "\">download the log file</a>." .
                    "If the problem is not clear from this log, " .
                    "please <a href=\"" .
                    $self->contact_url . "\">contact us</a> for " .
                    "further assistance.");
    return $return;
}

sub get_help_page {
    my ($self, $display_type) = @_;
    if ($display_type eq "resources") {
	return $self->get_text_file("resources.txt");
    } elsif ($display_type eq "glyc") {
	return $self->get_text_file("help_glyc.txt");
    } else {
	return $self->SUPER::get_help_page($display_type);
    }
}

sub check_required_email {
    my ($email) = @_;
    if($email !~ m/^[\w\.-]+@[\w-]+\.[\w-]+((\.[\w-]+)*)?$/ ) {
	throw saliweb::frontend::InputValidationError("Please provide a valid return email address");
    }
}

sub format_user_error {
    my ($self, $exc) = @_;
    my $q = $self->{'CGI'};
    my $msg = $exc->text;
    my $ret = $q->h2("Invalid input") .
              $q->p("&nbsp;") .
              $q->p($q->b("An error occurred during your request:")) .
              "<div class=\"standout\"><p>$msg</p></div>";
    if ($exc->isa('saliweb::frontend::InputValidationError')) {
	$ret .= $q->p("&nbsp;");
	$ret .= $q->p($q->b("WARNING: If you hit the back button in your web browser, your job may not submit properly."));
        $ret .= $q->p($q->b("Please click <a href=\"http://modbase.compbio.ucsf.edu/allosmod-foxs\"> HERE</a> to reset the page."));
    }
    return $ret;
}

1;

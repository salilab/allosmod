package allosmod;
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
                            -src => 'html/allosmod.js' };
  push @{$param{-style}->{'-src'}}, 'html/allosmod.css';
  return %param;
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "AllosMod Home"),
        $q->a({-href=>$self->help_url}, "About AllosMod"),
#        $q->a({-href=>$self->cgiroot . "/help.cgi?type=help"},"About AllosMod"),
        $q->a({-href=>$self->queue_url}, "Queue"),
        $q->a({-href=>$self->contact_url}, "Contact Us"),
	$q->a({-href=>$self->cgiroot . "/help.cgi?type=resources"},"Resources")
        ];
}

sub get_project_menu {
    my $self = shift;
    my $version = $self->version;
    my $htmlroot = $self->htmlroot;
    return <<MENU;
<div id="logo">
<left>
<a href="http://modbase.compbio.ucsf.edu/allosmod"><img src="$htmlroot/img/am_logo.gif" /></a>
</left>
</div><br />
<h4><small>Developer:</small></h4><p>Patrick Weinkam</p>
<h4><small>Acknowledgements:</small></h4>
<p>Ursula Pieper<br />
Elina Tjioe<br />
Ben Webb<br />
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
<a href="$htmlroot/file/Weinkam_PNAS_2012.pdf"><img src="$htmlroot/img/pdf.gif" /></a>,
S.I.:<a href="http://modbase.compbio.ucsf.edu/allosmod/html/file/Weinkam_PNAS_2012_si.pdf"><img src="$htmlroot/img/pdf.gif" /></a>
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

sub get_all_options_prealign {
    my $self = shift;
    my $q = $self->cgi;
    return "<div class=\"dropdown_container\">\n" .
           "<a onclick=\"\$('#single').slideDown('fast'); \$('#batch').slideUp('fast')\" " .
           "href=\"#\">Model Single Energy Landscape</a>\n" .
           "<div class=\"dropdown\" id=\"single\">\n" .
	   $q->p("Structures used to define landscape:" . $q->br .
	          $q->table({-id=>'structures'},
			   $q->Tr($q->td("PDB code " .
				  $q->textfield({-name=>'pdbcode',
						-size=>'4'})) .
				  $q->td("or upload PDB file " .
					 $q->filefield({-name=>'uploaded_file'})))) .
		  $q->p($q->button(-value=>'Add more structures',
				  -onClick=>"add_structure()"))) .
                  $q->p("Sequence to be used in simulation (specify protein and DNA/RNA, input sugar in adv. opt.)" . $q->br .
		       $q->textarea({-name=>'sequence', -rows=>7, -cols=>77})) .
           "\n</div></div>\n" .

           "<div class=\"dropdown_container\">\n" .
           "<a onclick=\"\$('#batch').slideDown('fast'); \$('#single').slideUp('fast')\" " .
           "href=\"#\">Model Energy Landscapes in Batch Mode</a>\n" .
           "<div class=\"dropdown\" id=\"batch\" style=\"display:none\">\n" .
	         $q->p("Upload directories zip file:    " . 
		       $q->td($q->filefield({-name=>"zip"}))) .
           "\n</div></div>\n";

}

sub get_advanced_modeling_options {
    my $self = shift;
    my $q = $self->cgi;

    return $self->make_dropdown("advmodel", "Advanced Modeling Options", 0,
      "<input type=\"radio\" name=\"advancedopt\" value=\"ligandmod\" " .
      "onclick=\"\$('#glycmod').slideUp('fast'); " .
      "\$('#ligandmod').slideDown('fast')\"" .
      "\>Model ligand binding site" . $q->br .
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

      "</div>\n\n");

}

sub get_sampling_options {
    my $self = shift;
    my $q = $self->cgi;

    return $self->make_dropdown("sampling", "Sampling Options", 0,
      "<input type=\"radio\" name=\"sampletype\" value=\"thermodyn\" " .
      "checked=\"checked\" onclick=\"\$('#rareconf').slideUp('fast'); " .
      "\$('#multiconf').slideUp('fast'); \$('#interconf').slideUp('fast'); \$('#thermodyn').slideDown('fast')\"" .
      "\>Generate a landscape that will be thermodynamically well sampled on the user's computer (using MODELLER)" . $q->br .
 	    "<div class=\"sampopts\" id=\"thermodyn\">\n" .
	    "Number of simulations " . $q->textfield({-name=>'thermodyn_nruns', -size=>"3",
                                         -value=>"10"}) . $q->br .
	    "MD temperature " . $q->textfield({-name=>'thermodyn_mdtemp', -size=>"3",
                                         -value=>"300"}) .

      "</div>\n\n" .

      "<input type=\"radio\" name=\"sampletype\" value=\"multiconf\" " .
      "onclick=\"\$('#rareconf').slideUp('fast'); " .
      "\$('#thermodyn').slideUp('fast'); \$('#interconf').slideUp('fast'); \$('#multiconf').slideDown('fast')\" />Sample most probable " .
      "conformations consistent with input crystal structure(s)" . $q->br .
	    "<div class=\"sampopts\" id=\"multiconf\" style=\"display:none\">\n" .
            "Number of simulations " . $q->textfield({-name=>'multiconf_nruns', -size=>"3",
                                         -value=>"10"}) . $q->br .
            "MD temperature " . $q->textfield({-name=>'multiconf_mdtemp', -size=>"3",
                                         -value=>"300"}) .
      "</div>\n\n" .

      "<input type=\"radio\" name=\"sampletype\" value=\"interconf\" " .
      "onclick=\"\$('#rareconf').slideUp('fast'); " .
      "\$('#thermodyn').slideUp('fast'); \$('#multiconf').slideUp('fast'); \$('#interconf').slideDown('fast')\" />Sample intermediate probablity " .
      "conformations consistent with input crystal structure(s)" . $q->br .
      "<div class=\"sampopts\" id=\"interconf\" style=\"display:none\">\n" .
            "Number of simulations " . $q->textfield({-name=>'interconf_nruns', -size=>"3",
                                         -value=>"30"}) . $q->br .
            "MD temperature " . $q->textfield({-name=>'interconf_mdtemp', -size=>"3",
                                         -value=>"scan"}) . $q->br .
            "Increase chain rigidity to maintain secondary structure at high temperature " .
				'<input type="checkbox" name="interconf_locrig"' .
				'checked="1" />' . $q->br .
      "</div>\n\n" .

      "<input type=\"radio\" name=\"sampletype\" value=\"rareconf\" " .
      "onclick=\"\$('#multiconf').slideUp('fast'); " .
      "\$('#thermodyn').slideUp('fast'); \$('#interconf').slideUp('fast'); \$('#rareconf').slideDown('fast')\" />Sample low probability " .
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
             "Quickly cool each structure to increase secondary structure (takes a long time, use sparingly) " .
				'<input type="checkbox" name="rareconf_quickcool"' .
				' />' . $q->br .
      "</div>\n");
}

sub get_all_advanced_options {
    my $self = shift;
    return $self->get_advanced_modeling_options() .
	$self->get_sampling_options();
}

sub get_alignment {
    my $self = shift;
    my $q = $self->cgi;

    my $seq = $q->param('sequence');
    my $zip = $q->param('zip');
    $seq =~ s/\s*//g;
    $zip =~ s/\s*//g;
    if ($seq eq "" and $zip eq "") {
	return undef, undef;
    }

    my $job = $self->make_job($q->param("name") || "job");
    my @pdbcodes = $q->param("pdbcode");
    my @uplfiles = $q->upload("uploaded_file");

    # Handle PDB codes
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

    my $jobdir = $job->directory;

    my $filesize = -s "$list";
    if($filesize == 0) {
	#batch job
	my $user_zip = $q->upload('zip');
	if($user_zip =~ ".gz" or $user_zip =~ ".tar") {
	    throw saliweb::frontend::InputValidationError("Please upload a zip file instead of a tar or gzip file");
	}
	my $zipfile = $job->directory . "/input.zip";
	open(OUTFILE, '>', $zipfile)
	    or throw saliweb::frontend::InternalError("Cannot open $zipfile: $!");
	while (<$user_zip>) {
	    print OUTFILE $_;
	}
	close OUTFILE;

	my $filesize2 = 0;
	$filesize2 = -s "$zipfile";
#	my $email = $q->param('jobemail');
	if($filesize2 == 0) {
	    return undef, undef;
#	} elsif(length $email <= 0) {
#	    check_required_email($email);
	} else {
	    $aln = "X";
	    system("echo XX >>$list");
	}

    } else{
	#single job
	#check PDB codes
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
#	my $email = $q->param('jobemail');
#	if(($found == 1 or $arraySize > 0) and length $email <= 0) {
#	    check_required_email($email);
#	}    

	my $inpseq = $job->directory . "/" . "inpseq";
	system("echo $seq >> $inpseq");

	#preprocess PDB files and get sequence alignment
	open(FOO, "/netapp/sali/allosmod/get_MULTsi20b.sh inpseq $jobdir |") || die "dont let script output to std out";
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
    }

    return $aln, $job;
}

sub get_index_page {
    my $self = shift;
    my $q = $self->cgi;

    my ($alignment, $job) = $self->get_alignment();
    my $action = (defined($alignment) ? $self->submit_url : $self->index_url);

    my $form;
    if (defined($alignment)) {
	if($alignment eq "X") {
	    #batch job
	    $form = $q->br . $q->br . $q->br . $q->br . $q->br . $q->br . $q->br .
		    $q->p("Click submit to run your batch job. Make sure all alignment files have") . 
		    $q->p("been checked by eye for misalignments (especially near ends of chains)") . $q->br .
			  $q->hidden('jobname', $job->name) .
			  $q->hidden('jobemail') .
			  $q->p("<center>" .
				$q->input({-type=>"submit", -value=>"Submit"}) .
				"</center>");
	} else {
	    #single job
	    $form = $q->p("Verify Alignment:" . $q->br .
			  $q->textarea({-name=>'alignment', -rows=>10, -cols=>77,
					-value=>$alignment})) .
			  $q->hidden('jobname', $job->name) .
			  $q->hidden('jobemail') .
			  $q->p("<center>" .
				$q->input({-type=>"submit", -value=>"Submit"}) .
				"</center>") .
			  $self->get_all_advanced_options();
	}
    } else {
      $form = $q->table(
	      $q->Tr($q->td("Job name "), 
		     $q->td($q->textfield({-name=>"name",
					   -size=>"25"}))) . 
             $q->Tr($q->td("Email"),
		     $q->td($q->textfield({-name=>"jobemail",
					   -value=>$self->email,
					   -size=>"25"})))) .
	      $self->get_all_options_prealign() .
              $q->p("<center>" .
                    $q->input({-type=>"submit", -value=>"Submit"}) .
                    "</center>");
    }

    my $greeting = <<GREETING;
<p>AllosMod is a web server to set up and run simulations based on a modeled energy 
landscape that you create. Carefully designed energy landscapes allow efficient molecular 
dynamics sampling at constant temperatures, thereby providing ergodic 
sampling of conformational space. Use AllosMod to:<br />
<ul>
- Model energy landscapes for protein, DNA, RNA, and/or sugar with either known or modeled structures <br />
- Sample your energy landscapes to predict often and/or rarely populated conformations <br />
- Model energy landscapes for ligand-induced structural and/or dynamic changes, i.e. allostery <br />
- Model energy landscapes for glycosylated proteins (For help, click <a href="http://modbase.compbio.ucsf.edu/allosmod/help.cgi?type=glyc"> here</a>) <br />
</ul>

<p>The AllosMod server runs in two modes: 1) single landscape and 2) batch jobs to set up many 
simulations at once. By creating a single landscape, the server will create input files that can 
be used to submit batch jobs. AllosMod will set up many short 
simulations for each landscape. There are two types of sampling: 1) constant temperature 
molecular dynamics, which will be completed overnight on a single processor on the 
user\'s computer (using MODELLER) or 2) quick, unequilibrated simulations performed on our servers 
within minutes to hours. Sampling is achieved efficiently by starting each simulation at different 
points in conformational space and by storing the energies in memory. <br />
<br />
AllosMod has several options for conformational sampling and contains tools for simulation analysis. 
For more details click on the "About AllosMod" link above and read the paper listed below. <br />
<br />
***<a style="color:red">NEW</a>*** The AllosMod server is integrated with the 
<a href="http://modbase.compbio.ucsf.edu/foxs/index.html"> FoXS server</a> for rigid body modeling of 
small angle X-ray scattering profiles. Our combined server is 
<a href="http://modbase.compbio.ucsf.edu/allosmod-foxs"> AllosMod-FoXS</a>.
<br />&nbsp;</p>
GREETING

    return $q->h2({-align=>"center"},
                  "AllosMod: Modeling of Ligand-induced Protein Dynamics and Beyond") .
           $greeting .

           $q->start_form({-name=>"allosmodform", -method=>"post",
                           -action=>$action}) .
           $form .
           $q->end_form;
}

sub get_submit_page {
    my $self = shift;
    my $q = $self->cgi;

    my $jobname = $q->param('jobname');
    my $email = $q->param('jobemail'); #||undef;      # user's e-mail
    my $zip = $q->param('zip');
    my $aln;
    my $job;

    #skip second page if zip file 
    if (defined($zip)) {
	($aln, $job) = $self->get_alignment();
    } else {
	$job = $self->resume_job($jobname);
    }

###    my $job = $self->resume_job($jobname);
    my $jobdir = $job->directory;

    my $filesize = -s "$jobdir/input.zip";
    if($filesize == 0) {
	#single job

	# rewrite alignment to file
	my $alignment = $q->param('alignment'); #alignment
	my $filename = "$jobdir/align.ali";
	open (FILE,">$filename") or die "I cannot open $filename\n";
	print FILE $alignment;
	close(FILE);

	#check alignment is valid
	open(FOO, "/netapp/sali/allosmod/check_align.sh $jobdir |") || die "dont let script output to std out";
	close(FOO);
	my $tempfile = "$jobdir/align.ali";
	my $tempread = do {
	    local $/ = undef;
	    open my $fh, "<", $tempfile
		or die "could not open $tempfile: $!";
	    <$fh>;
	};
	if($tempread =~ "errorfil") {
	    throw saliweb::frontend::InputValidationError("Please check that your alignment contains the filenames for all uploaded pdb files.");
        }
	if($tempread =~ "errorseq") {
	    throw saliweb::frontend::InputValidationError("Please check that your alignment contains entries with the same sequence as the uploaded pdb files.");
        }
	if($tempread =~ "errorlength") {
	    throw saliweb::frontend::InputValidationError("Please check that your alignment entries all have the same length.");
        }
	if($tempread =~ "errorblock") {
	    throw saliweb::frontend::InputValidationError("Please check that all block residues, i.e. \".\", are aligned to a residue or hetero atoms.");
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
	
	my $file_contents = "";
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
	}

	# handle sampling options
	my $sampletype = $q->param('sampletype');    
	my $thermodyn_nruns = $q->param('thermodyn_nruns');
	my $thermodyn_mdtemp = $q->param('thermodyn_mdtemp');
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
	if(($thermodyn_nruns !~ /^\d+$/) or $thermodyn_nruns <= 0 or $thermodyn_nruns > 100) {
	    throw saliweb::frontend::InputValidationError("Please provide a sensible number of runs $!");
	}
	if(($thermodyn_mdtemp !~ /^\d+$/ and $thermodyn_mdtemp !~ /^\d+[\.]\d+$/ and $thermodyn_mdtemp ne "scan") or
	   ($thermodyn_mdtemp <= 0 and $thermodyn_mdtemp ne "scan")) {
	    throw saliweb::frontend::InputValidationError("Please provide a sensible MD temperature for probable conformations $!");
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
	} elsif ($sampletype eq "thermodyn") {
	    system("echo NRUNS=$thermodyn_nruns >> $jobdir/input.dat");
	    system("echo MDTEMP=$thermodyn_mdtemp >> $jobdir/input.dat");
	    system("echo DEVIATION=1.0 >> $jobdir/input.dat");
	    system("echo SAMPLING=simulation >> $jobdir/input.dat");
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
#	if($email =~ "pweinkam" and $email =~ "gmail") {
#	    system("echo LOCALRIGID=True >> $jobdir/input.dat");
#	}

    } else {
	#batch job

    }

    #submit job
    $job->submit($email);

    ## write subject details into a file and pop up an exit page
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
            "\">AllosMod queue status page</a>.").
      $q->p("Your MODELLER input files should be finished shortly, depending on the number of landscapes to be created. ").
      $q->p("If you experience a problem or you do not receive the results " .
            "for more than 12 hours, please <a href=\"" .
            $self->contact_url . "\">contact us</a>.") .
      $q->p("Thank you for using AllosMod!").
      $q->p("<br />- Patrick Weinkam");

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
    my $return= $q->p("Job '<b>" . $job->name . "</b>' has completed, thank you for using AllosMod!");

    $return.= $q->p("<a href=\"" . $job->get_results_file_url("output.zip") .
                    "\">Download output zip file.</a>");
    $return.=$q->p("<br />It would be wise to double check your run directories: <br /> 1) check that " .
		   "allostericsite.pdb correctly represents the allosteric site (if applicable) <br /> 2) if some " .
		   "runs were not completed, then read error.log. <br />");
    $return .= $job->get_results_available_time();
    return $return;
}

sub display_failed_job {
    my ($self, $q, $job) = @_;
    my $return= $q->p("AllosMod was unable to complete your request: job '<b>" . $job->name);
    $return.=$q->p("This is usually caused by incorrect inputs " .
                   "(e.g. alignment file, PDB files, etc.).");
    $return.=$q->p("For a discussion of some common input errors, please see " .
                   "the " .
                   $q->a({-href=>$self->help_url . "#errors"}, "help page") .
                   ".");
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

sub get_submit_parameter_help {
    my $self = shift;
    return [
        $self->parameter("name", "Job name", 1),
        $self->file_parameter("zip", "All input files in a single zip"),
	    ];
}

sub check_required_email {
    my ($email) = @_;
    if($email !~ m/^[\w\.-]+@[\w-]+\.[\w-]+((\.[\w-]+)*)?$/ ) {
	throw saliweb::frontend::InputValidationError("Please provide a valid return email address");
    }
}

1;
